"""
ForestAI - Model Test Script
=============================
Test the trained model with any image from your system.

Usage:
    python test_model.py                    # interactive mode
    python test_model.py image.jpg          # test single image
    python test_model.py folder/            # test all images in folder
"""

import sys
import os
import numpy as np
from pathlib import Path
from PIL import Image

MODEL_PATH  = Path("../forest_ai/assets/model.tflite")
LABELS_PATH = Path("../forest_ai/assets/labels.txt")

# Edible classes (to know green vs red result)
EDIBLE = {
    "apple", "avocado", "banana", "blueberry", "cherry",
    "grape", "kiwi", "lemon", "lychee", "mango",
    "pineapple", "plum", "pomegranate", "raspberry",
    "strawberry", "watermelon"
}

# ─── Load model ───────────────────────────────────────────────────────────────

def load_model():
    try:
        import tensorflow as tf
        interpreter = tf.lite.Interpreter(model_path=str(MODEL_PATH))
        interpreter.allocate_tensors()
        inp = interpreter.get_input_details()[0]
        out = interpreter.get_output_details()[0]
        return interpreter, inp, out
    except Exception as e:
        print(f"ERROR loading model: {e}")
        sys.exit(1)

def load_labels():
    return LABELS_PATH.read_text().strip().split("\n")

# ─── Inference ────────────────────────────────────────────────────────────────

def predict(interpreter, inp_detail, out_detail, labels, image_path, top_k=3):
    img = Image.open(image_path).convert("RGB").resize((224, 224))
    arr = np.array(img, dtype=np.float32)

    if inp_detail["dtype"] == np.float16:
        arr = arr.astype(np.float16)

    interpreter.set_tensor(inp_detail["index"], np.expand_dims(arr, 0))
    interpreter.invoke()
    probs = interpreter.get_tensor(out_detail["index"])[0].astype(np.float32)

    top_idx  = np.argsort(probs)[::-1][:top_k]
    results  = [(labels[i], float(probs[i])) for i in top_idx]
    return results

# ─── Display ──────────────────────────────────────────────────────────────────

def print_result(image_path, results):
    label, conf = results[0]
    is_edible   = label in EDIBLE
    safe        = conf >= 0.80

    print(f"\n{'='*52}")
    print(f"  Image : {Path(image_path).name}")
    print(f"{'='*52}")

    if not safe:
        print(f"  ⚠️  CANNOT IDENTIFY SAFELY  ({conf*100:.1f}% < 80%)")
        print(f"  DO NOT EAT — confidence too low")
    elif is_edible:
        print(f"  ✅  EDIBLE")
        print(f"  Fruit     : {label.replace('_',' ').title()}")
        print(f"  Confidence: {conf*100:.1f}%")
    else:
        print(f"  ☠️  TOXIC — DO NOT EAT")
        print(f"  Plant     : {label.replace('_',' ').title()}")
        print(f"  Confidence: {conf*100:.1f}%")

    print(f"\n  Top {len(results)} predictions:")
    for i, (lbl, p) in enumerate(results):
        bar    = "█" * int(p * 30)
        marker = "→" if i == 0 else " "
        status = "🟢" if lbl in EDIBLE else "🔴"
        print(f"  {marker} {status} {lbl:<22} {p*100:5.1f}%  {bar}")
    print()

# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    if not MODEL_PATH.exists():
        print(f"ERROR: model not found at {MODEL_PATH.resolve()}")
        sys.exit(1)
    if not LABELS_PATH.exists():
        print(f"ERROR: labels not found at {LABELS_PATH.resolve()}")
        sys.exit(1)

    print("Loading model...")
    interpreter, inp, out = load_model()
    labels = load_labels()
    print(f"Model ready — {len(labels)} classes")

    # ── Mode: command line argument ────────────────────────────────────────
    if len(sys.argv) > 1:
        target = Path(sys.argv[1])
        if target.is_dir():
            images = list(target.glob("**/*.jpg")) + \
                     list(target.glob("**/*.jpeg")) + \
                     list(target.glob("**/*.png"))
            print(f"Testing {len(images)} images in {target}...\n")
            correct, total = 0, 0
            for img_path in images:
                true_label = img_path.parent.name.lower().replace(" ", "_")
                results    = predict(interpreter, inp, out, labels, img_path)
                pred_label, conf = results[0]
                match = pred_label == true_label
                if match: correct += 1
                total += 1
                icon = "✅" if match else "❌"
                print(f"  {icon} {true_label:<22} → {pred_label:<22} {conf*100:.1f}%")
            print(f"\n  Accuracy: {correct}/{total} = {correct/total*100:.1f}%")

        elif target.is_file():
            results = predict(interpreter, inp, out, labels, target)
            print_result(target, results)

        else:
            print(f"ERROR: {target} not found")
            sys.exit(1)
        return

    # ── Mode: interactive ──────────────────────────────────────────────────
    print("\nInteractive mode — type image path or 'q' to quit")
    print("─" * 52)
    while True:
        path = input("\nImage path: ").strip().strip("'\"")
        if path.lower() in ("q", "quit", "exit"):
            break
        if not os.path.exists(path):
            print(f"  File not found: {path}")
            continue
        try:
            results = predict(interpreter, inp, out, labels, path)
            print_result(path, results)
        except Exception as e:
            print(f"  ERROR: {e}")


if __name__ == "__main__":
    main()
