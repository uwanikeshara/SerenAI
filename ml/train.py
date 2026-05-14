"""
SerenAI — MobileNetV2 Emotion Model Training
==============================================
Two-phase training:
  Phase 1 — Freeze MobileNetV2 base, train head
  Phase 2 — Unfreeze top layers, fine-tune end-to-end

Usage: python train.py
"""

import os
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path

import tensorflow as tf
from tensorflow.keras import layers, Model, callbacks
from tensorflow.keras.applications import MobileNetV2
from sklearn.utils.class_weight import compute_class_weight

# ── Config ─────────────────────────────────────────────────────
IMG_SIZE        = 96
NUM_CLASSES     = 7
BATCH_SIZE      = 64
PHASE1_EPOCHS   = 20
PHASE2_EPOCHS   = 30
PROCESSED_DIR   = Path("processed")
CHECKPOINT_DIR  = Path("checkpoints")
PLOTS_DIR       = Path("plots")

EMOTION_LABELS  = ['angry', 'disgust', 'fear', 'happy', 'sad', 'surprise', 'neutral']


def load_data():
    X_train = np.load(PROCESSED_DIR / "X_train.npy")
    y_train = np.load(PROCESSED_DIR / "y_train.npy")
    X_val   = np.load(PROCESSED_DIR / "X_val.npy")
    y_val   = np.load(PROCESSED_DIR / "y_val.npy")
    X_test  = np.load(PROCESSED_DIR / "X_test.npy")
    y_test  = np.load(PROCESSED_DIR / "y_test.npy")
    print(f"[TRAIN] Train: {X_train.shape}  Val: {X_val.shape}  Test: {X_test.shape}")
    return (X_train, y_train), (X_val, y_val), (X_test, y_test)


def build_model():
    """MobileNetV2 base + custom stress-detection head."""
    base = MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights='imagenet'
    )
    base.trainable = False   # Phase 1: frozen

    inputs = tf.keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
    x = base(inputs, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dense(256, activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.4)(x)
    x = layers.Dense(128, activation='relu')(x)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(NUM_CLASSES, activation='softmax')(x)

    model = Model(inputs, outputs)
    return model, base


def get_class_weights(y_train):
    classes = np.unique(y_train)
    weights = compute_class_weight('balanced', classes=classes, y=y_train)
    return dict(zip(classes, weights))


def plot_history(history, filename):
    PLOTS_DIR.mkdir(exist_ok=True)
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

    ax1.plot(history.history['accuracy'],     label='Train Acc')
    ax1.plot(history.history['val_accuracy'], label='Val Acc')
    ax1.set_title('Accuracy'); ax1.legend(); ax1.grid(True)

    ax2.plot(history.history['loss'],     label='Train Loss')
    ax2.plot(history.history['val_loss'], label='Val Loss')
    ax2.set_title('Loss'); ax2.legend(); ax2.grid(True)

    plt.savefig(PLOTS_DIR / filename)
    plt.close()
    print(f"[TRAIN] Plot saved: {PLOTS_DIR / filename}")


def main():
    CHECKPOINT_DIR.mkdir(exist_ok=True)

    # ── Load ───────────────────────────────────────────────────
    (X_train, y_train), (X_val, y_val), (X_test, y_test) = load_data()

    # One-hot encode
    y_train_oh = tf.keras.utils.to_categorical(y_train, NUM_CLASSES)
    y_val_oh   = tf.keras.utils.to_categorical(y_val,   NUM_CLASSES)
    y_test_oh  = tf.keras.utils.to_categorical(y_test,  NUM_CLASSES)

    class_weights = get_class_weights(y_train)
    print(f"[TRAIN] Class weights: {class_weights}")

    model, base = build_model()
    model.summary()

    # ── Phase 1: Train head only ──────────────────────────────
    print("\n[TRAIN] === PHASE 1: Feature Extraction ===")
    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-3),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    cb1 = [
        callbacks.ModelCheckpoint(
            CHECKPOINT_DIR / "best_phase1.h5",
            monitor='val_accuracy', save_best_only=True, verbose=1
        ),
        callbacks.EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True),
        callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=3, min_lr=1e-6),
    ]

    h1 = model.fit(
        X_train, y_train_oh,
        validation_data=(X_val, y_val_oh),
        epochs=PHASE1_EPOCHS,
        batch_size=BATCH_SIZE,
        class_weight=class_weights,
        callbacks=cb1
    )
    plot_history(h1, "phase1_history.png")

    # ── Phase 2: Fine-tune top layers ────────────────────────
    print("\n[TRAIN] === PHASE 2: Fine-Tuning ===")
    base.trainable = True
    # Freeze bottom 100 layers, unfreeze the rest
    for layer in base.layers[:100]:
        layer.trainable = False

    model.compile(
        optimizer=tf.keras.optimizers.Adam(1e-5),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    cb2 = [
        callbacks.ModelCheckpoint(
            CHECKPOINT_DIR / "best_final.h5",
            monitor='val_accuracy', save_best_only=True, verbose=1
        ),
        callbacks.EarlyStopping(monitor='val_loss', patience=8, restore_best_weights=True),
        callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=4, min_lr=1e-7),
    ]

    h2 = model.fit(
        X_train, y_train_oh,
        validation_data=(X_val, y_val_oh),
        epochs=PHASE2_EPOCHS,
        batch_size=BATCH_SIZE,
        class_weight=class_weights,
        callbacks=cb2
    )
    plot_history(h2, "phase2_history.png")

    # ── Evaluate ──────────────────────────────────────────────
    print("\n[TRAIN] === Evaluation on Test Set ===")
    test_loss, test_acc = model.evaluate(X_test, y_test_oh, verbose=0)
    print(f"   Test Accuracy : {test_acc * 100:.2f}%")
    print(f"   Test Loss     : {test_loss:.4f}")

    # ── Save final model ──────────────────────────────────────
    model.save(CHECKPOINT_DIR / "serenai_emotion_model.h5")
    print(f"\n✅ Model saved: {CHECKPOINT_DIR / 'serenai_emotion_model.h5'}")
    print("   Next step: python convert_tflite.py")


if __name__ == "__main__":
    main()
