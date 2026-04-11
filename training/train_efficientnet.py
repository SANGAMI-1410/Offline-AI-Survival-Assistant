"""
ForestAI - EfficientNetB0 Training Script
==========================================
Trains a fruit identification model on the local dataset.
Exports: model.tflite + labels.txt (ready to drop into Flutter assets)

Usage:
    pip install tensorflow pillow numpy scikit-learn matplotlib
    python train_efficientnet.py

Output:
    output/model.tflite   <- copy to forest_ai/assets/
    output/labels.txt     <- copy to forest_ai/assets/
    output/training_plot.png
"""

import os
import re
import json
import shutil
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
from PIL import Image

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix

# ─── Configuration ────────────────────────────────────────────────────────────

DATASET_ROOT   = Path("../dataset")
OUTPUT_DIR     = Path("output")
IMG_SIZE       = 224          # EfficientNetB0 native input
BATCH_SIZE     = 32
EPOCHS_HEAD    = 20           # phase 1: train head only
EPOCHS_FINETUNE= 30           # phase 2: fine-tune top layers
LEARNING_RATE  = 1e-3
FINETUNE_LR    = 1e-5
SEED           = 42

OUTPUT_DIR.mkdir(exist_ok=True)

# ─── Label map builder ────────────────────────────────────────────────────────

def normalize_label(folder_name: str) -> str:
    """Convert folder name to clean snake_case label."""
    name = folder_name.strip()
    # Remove trailing numbers like 'Mango 1' → 'mango'
    name = re.sub(r'\s+\d+$', '', name)
    name = name.lower().strip()
    name = re.sub(r'[\s\-]+', '_', name)
    name = re.sub(r'[^a-z0-9_]', '', name)
    return name


def build_label_map():
    """Scan dataset folders and return (label_list, label_to_idx, paths_with_labels)."""
    paths, labels = [], []
    label_set = set()

    for category in ["edable", "toxic"]:
        category_dir = DATASET_ROOT / category
        if not category_dir.exists():
            print(f"[WARN] Missing directory: {category_dir}")
            continue
        for class_dir in sorted(category_dir.iterdir()):
            if not class_dir.is_dir():
                continue
            label = normalize_label(class_dir.name)
            label_set.add(label)
            for img_path in class_dir.glob("*"):
                if img_path.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp"}:
                    paths.append(img_path)
                    labels.append(label)

    label_list = sorted(label_set)
    label_to_idx = {l: i for i, l in enumerate(label_list)}

    print(f"\nFound {len(label_list)} classes, {len(paths)} total images")
    print("Classes:", label_list)
    return label_list, label_to_idx, paths, labels


# ─── Dataset pipeline ─────────────────────────────────────────────────────────

def load_and_preprocess(image_path: Path, label_idx: int):
    img = Image.open(image_path).convert("RGB").resize((IMG_SIZE, IMG_SIZE))
    arr = np.array(img, dtype=np.float32)
    # EfficientNet expects [0, 255] — it handles normalization internally
    return arr, label_idx


def build_tf_dataset(paths, label_indices, batch_size, augment=False):
    path_strs = [str(p) for p in paths]

    def parse_fn(path, label):
        img = tf.io.read_file(path)
        img = tf.image.decode_jpeg(img, channels=3)
        img = tf.image.resize(img, [IMG_SIZE, IMG_SIZE])
        img = tf.cast(img, tf.float32)
        return img, label

    def augment_fn(img, label):
        img = tf.image.random_flip_left_right(img)
        img = tf.image.random_flip_up_down(img)
        img = tf.image.random_brightness(img, max_delta=0.2)
        img = tf.image.random_contrast(img, 0.8, 1.2)
        img = tf.image.random_saturation(img, 0.8, 1.2)
        img = tf.image.random_hue(img, 0.05)
        img = tf.clip_by_value(img, 0.0, 255.0)
        return img, label

    ds = tf.data.Dataset.from_tensor_slices((path_strs, label_indices))
    ds = ds.map(parse_fn, num_parallel_calls=tf.data.AUTOTUNE)
    if augment:
        ds = ds.map(augment_fn, num_parallel_calls=tf.data.AUTOTUNE)
    ds = ds.batch(batch_size).prefetch(tf.data.AUTOTUNE)
    return ds


# ─── Model builder ────────────────────────────────────────────────────────────

def build_model(num_classes: int):
    """EfficientNetB0 with custom classification head."""
    base = keras.applications.EfficientNetB0(
        include_top=False,
        weights="imagenet",
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        pooling="avg",
    )
    base.trainable = False  # frozen for phase 1

    inputs = keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
    x = base(inputs, training=False)
    x = layers.Dropout(0.3)(x)
    x = layers.Dense(256, activation="relu")(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(num_classes, activation="softmax")(x)

    model = keras.Model(inputs, outputs)
    return model, base


# ─── Training ─────────────────────────────────────────────────────────────────

def train():
    print("=" * 60)
    print("ForestAI — EfficientNetB0 Training")
    print("=" * 60)

    label_list, label_to_idx, all_paths, all_labels = build_label_map()
    num_classes = len(label_list)

    # Save labels.txt
    labels_path = OUTPUT_DIR / "labels.txt"
    labels_path.write_text("\n".join(label_list))
    print(f"Saved labels → {labels_path}")

    # Encode labels
    label_indices = [label_to_idx[l] for l in all_labels]

    # Train/val/test split: 70 / 15 / 15
    train_paths, val_paths, train_labels, val_labels = train_test_split(
        all_paths, label_indices, test_size=0.30, random_state=SEED,
        stratify=label_indices
    )
    val_paths, test_paths, val_labels, test_labels = train_test_split(
        val_paths, val_labels, test_size=0.50, random_state=SEED,
        stratify=val_labels
    )

    print(f"\nSplit  →  train: {len(train_paths)}  val: {len(val_paths)}  test: {len(test_paths)}")

    train_ds = build_tf_dataset(train_paths, train_labels, BATCH_SIZE, augment=True)
    val_ds   = build_tf_dataset(val_paths,   val_labels,   BATCH_SIZE, augment=False)
    test_ds  = build_tf_dataset(test_paths,  test_labels,  BATCH_SIZE, augment=False)

    # ── Phase 1: Train head ────────────────────────────────────────────────────
    print("\n── Phase 1: Training classification head (base frozen) ──")
    model, base = build_model(num_classes)
    model.compile(
        optimizer=keras.optimizers.Adam(LEARNING_RATE),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    model.summary()

    callbacks_p1 = [
        keras.callbacks.EarlyStopping(
            monitor="val_accuracy", patience=5, restore_best_weights=True
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.5, patience=3, min_lr=1e-6
        ),
        keras.callbacks.ModelCheckpoint(
            str(OUTPUT_DIR / "best_head.keras"),
            save_best_only=True, monitor="val_accuracy"
        ),
    ]

    history1 = model.fit(
        train_ds, validation_data=val_ds,
        epochs=EPOCHS_HEAD, callbacks=callbacks_p1
    )

    # ── Phase 2: Fine-tune top layers ─────────────────────────────────────────
    print("\n── Phase 2: Fine-tuning top layers of EfficientNetB0 ──")
    # Unfreeze top 30 layers of base
    base.trainable = True
    for layer in base.layers[:-30]:
        layer.trainable = False

    model.compile(
        optimizer=keras.optimizers.Adam(FINETUNE_LR),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    callbacks_p2 = [
        keras.callbacks.EarlyStopping(
            monitor="val_accuracy", patience=8, restore_best_weights=True
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.5, patience=3, min_lr=1e-7
        ),
        keras.callbacks.ModelCheckpoint(
            str(OUTPUT_DIR / "best_finetune.keras"),
            save_best_only=True, monitor="val_accuracy"
        ),
    ]

    history2 = model.fit(
        train_ds, validation_data=val_ds,
        epochs=EPOCHS_FINETUNE, callbacks=callbacks_p2
    )

    # ── Evaluate ──────────────────────────────────────────────────────────────
    print("\n── Test Evaluation ──")
    test_loss, test_acc = model.evaluate(test_ds)
    print(f"Test accuracy: {test_acc * 100:.2f}%  |  Test loss: {test_loss:.4f}")

    # Detailed report
    y_pred, y_true = [], []
    for batch_imgs, batch_labels in test_ds:
        preds = model.predict(batch_imgs, verbose=0)
        y_pred.extend(np.argmax(preds, axis=1))
        y_true.extend(batch_labels.numpy())
    print("\nClassification Report:")
    print(classification_report(y_true, y_pred, target_names=label_list))

    # ── Training curve ────────────────────────────────────────────────────────
    _plot_history(history1, history2)

    # ── Export to TFLite ──────────────────────────────────────────────────────
    export_tflite(model)

    print("\n✅  Done!")
    print(f"   Copy  output/model.tflite  →  forest_ai/assets/model.tflite")
    print(f"   Copy  output/labels.txt    →  forest_ai/assets/labels.txt")


def export_tflite(model):
    """Export Keras model → TFLite with float16 quantization."""
    print("\n── Exporting to TFLite ──")

    # Full precision (fallback / debugging)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    fp32_path = OUTPUT_DIR / "model_fp32.tflite"
    fp32_path.write_bytes(tflite_model)
    print(f"Saved float32 model → {fp32_path}  ({len(tflite_model)/1024:.1f} KB)")

    # Float16 quantization (2x smaller, same accuracy)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    tflite_fp16 = converter.convert()
    fp16_path = OUTPUT_DIR / "model.tflite"
    fp16_path.write_bytes(tflite_fp16)
    print(f"Saved float16 model → {fp16_path}  ({len(tflite_fp16)/1024:.1f} KB)")

    # Verify the TFLite model
    interpreter = tf.lite.Interpreter(model_path=str(fp16_path))
    interpreter.allocate_tensors()
    inp = interpreter.get_input_details()
    out = interpreter.get_output_details()
    print(f"TFLite input  shape: {inp[0]['shape']}  dtype: {inp[0]['dtype']}")
    print(f"TFLite output shape: {out[0]['shape']}  dtype: {out[0]['dtype']}")


def _plot_history(h1, h2):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

    # Combine histories
    acc  = h1.history["accuracy"]      + h2.history["accuracy"]
    val_acc = h1.history["val_accuracy"] + h2.history["val_accuracy"]
    loss = h1.history["loss"]          + h2.history["loss"]
    val_loss = h1.history["val_loss"]  + h2.history["val_loss"]
    split_ep = len(h1.history["accuracy"])

    epochs = range(1, len(acc) + 1)

    ax1.plot(epochs, acc, label="Train")
    ax1.plot(epochs, val_acc, label="Val")
    ax1.axvline(split_ep, color="gray", linestyle="--", label="Fine-tune starts")
    ax1.set_title("Accuracy")
    ax1.set_xlabel("Epoch")
    ax1.legend()
    ax1.set_ylim(0, 1)

    ax2.plot(epochs, loss, label="Train")
    ax2.plot(epochs, val_loss, label="Val")
    ax2.axvline(split_ep, color="gray", linestyle="--", label="Fine-tune starts")
    ax2.set_title("Loss")
    ax2.set_xlabel("Epoch")
    ax2.legend()

    plt.tight_layout()
    plot_path = OUTPUT_DIR / "training_plot.png"
    plt.savefig(plot_path, dpi=120)
    print(f"Saved training plot → {plot_path}")
    plt.close()


if __name__ == "__main__":
    # Check GPU
    gpus = tf.config.list_physical_devices("GPU")
    print(f"GPUs available: {len(gpus)}")
    if gpus:
        for g in gpus:
            tf.config.experimental.set_memory_growth(g, True)

    train()
