"""
SerenAI — Convert Keras Model → TFLite
=========================================
Applies full-integer quantization for fast mobile inference.
Output: models/stress_model.tflite  + models/labels.txt

Usage: python convert_tflite.py
"""

import os
import numpy as np
import tensorflow as tf
from pathlib import Path
import shutil

CHECKPOINT = Path("checkpoints") / "serenai_emotion_model.h5"
MODELS_DIR = Path("models")

# Must match training order
LABELS = [
    'angry',    # 0
    'disgust',  # 1
    'fear',     # 2
    'happy',    # 3
    'sad',      # 4
    'surprise', # 5
    'neutral',  # 6
]

STRESS_WEIGHTS = {
    'angry': 1.0, 'disgust': 0.85, 'fear': 0.90,
    'sad': 0.75,  'neutral': 0.45, 'surprise': 0.25, 'happy': 0.10,
}


def load_representative_data():
    """Generator for full-int quantization calibration."""
    proc = Path("processed")
    if (proc / "X_val.npy").exists():
        X_val = np.load(proc / "X_val.npy")
        for i in range(min(200, len(X_val))):
            yield [X_val[i:i+1].astype(np.float32)]
    else:
        for _ in range(200):
            yield [np.random.rand(1, 96, 96, 3).astype(np.float32)]


def convert():
    MODELS_DIR.mkdir(exist_ok=True)

    print(f"[CONVERT] Loading model: {CHECKPOINT}")
    model = tf.keras.models.load_model(str(CHECKPOINT))
    print("[CONVERT] Model loaded ✅")

    # ── Dynamic range quantization (smaller, fast) ───────────
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = load_representative_data

    tflite_model = converter.convert()

    out_path = MODELS_DIR / "stress_model.tflite"
    out_path.write_bytes(tflite_model)
    size_mb = out_path.stat().st_size / (1024 * 1024)

    print(f"\n✅ TFLite model saved: {out_path}")
    print(f"   Size: {size_mb:.2f} MB")

    # Write labels file
    labels_path = MODELS_DIR / "labels.txt"
    labels_path.write_text("\n".join(LABELS))
    print(f"   Labels: {labels_path}")

    # ── Verify inference ─────────────────────────────────────
    print("\n[CONVERT] Verifying inference ...")
    interpreter = tf.lite.Interpreter(model_path=str(out_path))
    interpreter.allocate_tensors()

    inp_details  = interpreter.get_input_details()
    out_details  = interpreter.get_output_details()

    dummy_input = np.random.rand(1, 96, 96, 3).astype(np.float32)
    interpreter.set_tensor(inp_details[0]['index'], dummy_input)
    interpreter.invoke()
    output = interpreter.get_tensor(out_details[0]['index'])[0]

    dominant_idx   = int(np.argmax(output))
    dominant_label = LABELS[dominant_idx]
    stress_score   = sum(output[i] * STRESS_WEIGHTS[LABELS[i]] for i in range(len(LABELS))) * 100

    print(f"   Dominant emotion: {dominant_label} ({output[dominant_idx]*100:.1f}%)")
    print(f"   Stress score    : {stress_score:.1f}")
    print("\n✅ Conversion complete!")
    print("   Copy  models/stress_model.tflite → app/assets/models/")
    print("   Copy  models/labels.txt          → app/assets/models/")


if __name__ == "__main__":
    convert()
