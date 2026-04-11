"""
ForestAI - Dataset Cleaner
===========================
Fixes all issues found in the dataset analysis:
  1. Removes duplicate images across classes
  2. Caps Blueberry to 65 images (balance with other classes)
  3. Resizes all images to 224x224 RGB
  4. Renames folders to clean snake_case (no spaces, no trailing spaces)

Output: ../dataset_clean/  (original dataset is NOT modified)
"""

import os
import re
import shutil
import hashlib
from pathlib import Path
from collections import defaultdict

try:
    from PIL import Image
    import numpy as np
except ImportError:
    os.system("pip install pillow numpy -q")
    from PIL import Image
    import numpy as np

# ─── Config ───────────────────────────────────────────────────────────────────
DATASET_ROOT  = Path("../dataset")
OUTPUT_ROOT   = Path("../dataset_clean")
IMG_SIZE      = 224
MAX_PER_CLASS = 65   # cap Blueberry (462) down to match other classes

# ─── Helpers ──────────────────────────────────────────────────────────────────

def normalize_label(folder_name: str) -> str:
    name = folder_name.strip()
    name = re.sub(r'\s+\d+$', '', name)   # "Mango 1" → "Mango"
    name = name.lower().strip()
    name = re.sub(r'[\s\-]+', '_', name)  # spaces/dashes → underscore
    name = re.sub(r'[^a-z0-9_]', '', name)
    return name

def file_hash(path: Path) -> str:
    """MD5 hash of file content — used to detect true duplicates."""
    h = hashlib.md5()
    h.update(path.read_bytes())
    return h.hexdigest()

def clean_and_save(src_path: Path, dst_path: Path):
    """Open image, convert to RGB 224x224, save as JPEG."""
    with Image.open(src_path) as img:
        img = img.convert("RGB")
        img = img.resize((IMG_SIZE, IMG_SIZE), Image.LANCZOS)
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        img.save(dst_path, "JPEG", quality=95)

# ─── Main ─────────────────────────────────────────────────────────────────────

def run():
    print("=" * 60)
    print("ForestAI Dataset Cleaner")
    print("=" * 60)

    if OUTPUT_ROOT.exists():
        shutil.rmtree(OUTPUT_ROOT)
        print(f"Removed old {OUTPUT_ROOT}")
    OUTPUT_ROOT.mkdir(parents=True)

    # Track hashes globally to detect cross-class duplicates
    seen_hashes = {}        # hash → first class that used it
    stats = defaultdict(lambda: {"total": 0, "saved": 0, "skipped_dup": 0, "skipped_cap": 0})

    total_saved   = 0
    total_skipped = 0

    for category in ["edable", "toxic"]:
        cat_dir = DATASET_ROOT / category
        if not cat_dir.exists():
            print(f"[WARN] Missing: {cat_dir}")
            continue

        for cls_dir in sorted(cat_dir.iterdir()):
            if not cls_dir.is_dir():
                continue

            label     = normalize_label(cls_dir.name)
            out_dir   = OUTPUT_ROOT / category / label
            out_dir.mkdir(parents=True, exist_ok=True)

            img_files = sorted([
                f for f in cls_dir.iterdir()
                if f.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp"}
            ])

            saved_this_class = 0

            for img_path in img_files:
                stats[label]["total"] += 1

                # ── Cap per class ──────────────────────────────────────────
                if saved_this_class >= MAX_PER_CLASS:
                    stats[label]["skipped_cap"] += 1
                    total_skipped += 1
                    continue

                # ── Duplicate detection via MD5 ────────────────────────────
                try:
                    h = file_hash(img_path)
                except Exception:
                    continue

                if h in seen_hashes:
                    prev = seen_hashes[h]
                    if prev != label:
                        stats[label]["skipped_dup"] += 1
                        total_skipped += 1
                        continue
                    # Same class duplicate — also skip
                    stats[label]["skipped_dup"] += 1
                    total_skipped += 1
                    continue

                seen_hashes[h] = label

                # ── Resize & save ──────────────────────────────────────────
                try:
                    dst = out_dir / f"{label}_{saved_this_class:04d}.jpg"
                    clean_and_save(img_path, dst)
                    saved_this_class += 1
                    stats[label]["saved"] += 1
                    total_saved += 1
                except Exception as e:
                    print(f"  [ERROR] {img_path.name}: {e}")

            print(f"  {category}/{label:<25} "
                  f"in={len(img_files):>4}  "
                  f"saved={saved_this_class:>3}  "
                  f"dup_skip={stats[label]['skipped_dup']:>3}  "
                  f"cap_skip={stats[label]['skipped_cap']:>3}")

    # ── Final report ──────────────────────────────────────────────────────────
    print()
    print("=" * 60)
    print("CLEANING COMPLETE")
    print("=" * 60)
    print(f"  Total saved   : {total_saved}")
    print(f"  Total skipped : {total_skipped}")
    print(f"  Output folder : {OUTPUT_ROOT.resolve()}")

    # Verify class counts
    print()
    print("Final class counts in dataset_clean/:")
    grand_total = 0
    for category in ["edable", "toxic"]:
        cat_out = OUTPUT_ROOT / category
        if not cat_out.exists():
            continue
        for cls_dir in sorted(cat_out.iterdir()):
            count = len(list(cls_dir.glob("*.jpg")))
            grand_total += count
            bar = "█" * count
            print(f"  {category}/{cls_dir.name:<25} {count:>3}  {bar}")
    print(f"\n  GRAND TOTAL: {grand_total} images")
    print()
    print("Next step: run zip_dataset.py to prepare for Colab upload")


if __name__ == "__main__":
    run()
