"""
SerenAI — Data Preparation Pipeline
=====================================
Supports TWO FER2013 formats:
  ✅ Format A (folders): train/ test/ with subfolders per emotion  ← YOU HAVE THIS
  ✅ Format B (CSV):     fer2013.csv

Auto-detects which format you have.

Usage: python data_prep.py
"""

import os
import cv2
import numpy as np
import pandas as pd
from pathlib import Path
from sklearn.model_selection import train_test_split
from tqdm import tqdm
import zipfile

# ── Configuration ──────────────────────────────────────────────
IMG_SIZE    = 96
DATA_DIR    = Path("data")
OUTPUT_DIR  = Path("processed")
FER_CSV     = DATA_DIR / "fer2013.csv"
FER_TRAIN   = DATA_DIR / "train"       # Folder format — train/angry/, train/happy/ …
FER_TEST    = DATA_DIR / "test"
CK_DIR      = DATA_DIR / "CK+"

EMOTION_LABELS = [
    'angry', 'disgust', 'fear', 'happy', 'sad', 'surprise', 'neutral'
]

# Map folder names → label index
FOLDER_TO_IDX = {
    'angry':    0,
    'disgust':  1,
    'fear':     2,
    'happy':    3,
    'sad':      4,
    'surprise': 5,
    'neutral':  6,
}

STRESS_WEIGHTS = {
    'angry':    1.0,
    'disgust':  0.85,
    'fear':     0.90,
    'sad':      0.75,
    'neutral':  0.45,
    'surprise': 0.25,
    'happy':    0.10,
}


def augment(img: np.ndarray):
    """Return list of augmented variants."""
    variants = [img]
    # Horizontal flip
    variants.append(np.fliplr(img))
    # Brightness jitter
    bright = np.clip(img * np.random.uniform(0.8, 1.2), 0, 1)
    variants.append(bright)
    # Rotation ±12°
    h, w = img.shape[:2]
    for angle in [12, -12]:
        M   = cv2.getRotationMatrix2D((w // 2, h // 2), angle, 1.0)
        rot = cv2.warpAffine(img, M, (w, h))
        variants.append(rot)
    return variants


def load_fer2013_folders():
    """
    Load FER2013 from image folders (train/ + test/).
    Each subfolder name is the emotion label.
    """
    print("\n[DATA PREP] Loading FER2013 (folder format — train/ + test/) ...")

    if not FER_TRAIN.exists():
        return [], []

    images, labels = [], []

    for split_dir in [FER_TRAIN, FER_TEST]:
        if not split_dir.exists():
            continue
        for emotion_folder in sorted(split_dir.iterdir()):
            if not emotion_folder.is_dir():
                continue
            label_name = emotion_folder.name.lower()
            label_idx  = FOLDER_TO_IDX.get(label_name)
            if label_idx is None:
                print(f"  [SKIP] Unknown folder: {emotion_folder.name}")
                continue

            img_files = list(emotion_folder.glob("*.jpg")) + \
                        list(emotion_folder.glob("*.png")) + \
                        list(emotion_folder.glob("*.jpeg"))

            for img_path in tqdm(img_files, desc=f"  {split_dir.name}/{emotion_folder.name}"):
                img_bgr = cv2.imread(str(img_path))
                if img_bgr is None:
                    continue
                img_rgb     = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
                img_resized = cv2.resize(img_rgb, (IMG_SIZE, IMG_SIZE))
                img_norm    = img_resized.astype(np.float32) / 255.0

                images.append(img_norm)
                labels.append(label_idx)

                # Augment minority classes
                if label_name in ('disgust', 'fear'):
                    for aug in augment(img_norm)[1:]:
                        images.append(aug)
                        labels.append(label_idx)

    print(f"[DATA PREP] Folder format: {len(images)} samples loaded")
    return images, labels


def load_fer2013_csv():
    """Load FER2013 from CSV (pixel string format)."""
    print("\n[DATA PREP] Loading FER2013 (CSV format) ...")
    if not FER_CSV.exists():
        return [], []

    df     = pd.read_csv(FER_CSV)
    images = []
    labels = []

    for _, row in tqdm(df.iterrows(), total=len(df), desc="Processing FER2013 CSV"):
        pixels = np.array(row['pixels'].split(), dtype=np.uint8).reshape(48, 48)
        img    = cv2.resize(pixels, (IMG_SIZE, IMG_SIZE))
        img_rgb = cv2.cvtColor(img, cv2.COLOR_GRAY2RGB)
        img_norm = img_rgb.astype(np.float32) / 255.0
        label   = int(row['emotion'])

        images.append(img_norm)
        labels.append(label)

        if EMOTION_LABELS[label] in ('disgust', 'fear'):
            for aug in augment(img_norm)[1:]:
                images.append(aug)
                labels.append(label)

    print(f"[DATA PREP] CSV format: {len(images)} samples loaded")
    return images, labels


def load_ck_plus():
    """Load optional CK+ dataset."""
    images, labels = [], []
    if not CK_DIR.exists():
        return [], []

    print("\n[DATA PREP] Loading CK+ ...")
    label_map = {
        'anger': 0, 'angry': 0,
        'disgust': 1,
        'fear': 2,
        'happy': 3, 'happiness': 3,
        'sadness': 4, 'sad': 4,
        'surprise': 5,
        'neutral': 6,
    }

    for emotion_folder in CK_DIR.iterdir():
        if not emotion_folder.is_dir():
            continue
        label = label_map.get(emotion_folder.name.lower())
        if label is None:
            continue
        for img_path in emotion_folder.glob("*.png"):
            img_bgr = cv2.imread(str(img_path))
            if img_bgr is None:
                continue
            img_rgb  = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
            img_resized = cv2.resize(img_rgb, (IMG_SIZE, IMG_SIZE))
            img_norm = img_resized.astype(np.float32) / 255.0
            images.append(img_norm)
            labels.append(label)
            for aug in augment(img_norm)[1:]:
                images.append(aug)
                labels.append(label)

    print(f"[DATA PREP] CK+ samples (with augmentation): {len(images)}")
    return images, labels


def save_splits(images, labels):
    """Split and save as numpy arrays."""
    OUTPUT_DIR.mkdir(exist_ok=True)

    X = np.array(images, dtype=np.float32)
    y = np.array(labels, dtype=np.int32)

    X_train, X_temp, y_train, y_temp = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.5, random_state=42, stratify=y_temp
    )

    np.save(OUTPUT_DIR / "X_train.npy", X_train)
    np.save(OUTPUT_DIR / "y_train.npy", y_train)
    np.save(OUTPUT_DIR / "X_val.npy",   X_val)
    np.save(OUTPUT_DIR / "y_val.npy",   y_val)
    np.save(OUTPUT_DIR / "X_test.npy",  X_test)
    np.save(OUTPUT_DIR / "y_test.npy",  y_test)

    print(f"\n✅ Splits saved:")
    print(f"   Train : {len(X_train)} samples")
    print(f"   Val   : {len(X_val)}   samples")
    print(f"   Test  : {len(X_test)}  samples")
    print(f"   Output: {OUTPUT_DIR.resolve()}")


def main():
    DATA_DIR.mkdir(exist_ok=True)

    # ── Auto-detect dataset format ─────────────────────────────
    if FER_TRAIN.exists():
        print("\n✅ Detected: FER2013 folder format (train/ + test/)")
        fer_images, fer_labels = load_fer2013_folders()
    elif FER_CSV.exists():
        print("\n✅ Detected: FER2013 CSV format (fer2013.csv)")
        fer_images, fer_labels = load_fer2013_csv()
    else:
        print(
            "\n❌ FER2013 dataset not found!\n"
            "\n   You have TWO options:\n"
            "\n   OPTION A (Folder format — what you likely downloaded):\n"
            "     1. Extract the Kaggle ZIP\n"
            "     2. You should see a 'train' folder and a 'test' folder\n"
            "     3. Copy BOTH folders into:  ml\\data\\\n"
            "        So you get:  ml\\data\\train\\  and  ml\\data\\test\\\n"
            "\n   OPTION B (CSV format):\n"
            "     1. Get fer2013.csv\n"
            "     2. Place it at:  ml\\data\\fer2013.csv\n"
        )
        return

    ck_images, ck_labels = load_ck_plus()

    all_images = fer_images + ck_images
    all_labels = fer_labels + ck_labels

    if not all_images:
        print("\n❌ No data loaded.")
        return

    print(f"\n[DATA PREP] Total samples (before split): {len(all_images)}")
    save_splits(all_images, all_labels)
    print("\n✅ Data preparation complete! Run: python train.py")


if __name__ == "__main__":
    main()
