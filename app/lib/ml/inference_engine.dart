import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// ── Labels (match training order exactly) ───────────────────────
const emotionLabels = [
  'angry', 'disgust', 'fear', 'happy', 'sad', 'surprise', 'neutral',
];

// Stress contribution of each emotion (from training config)
const _stressWeights = {
  'angry':    1.00,
  'disgust':  0.85,
  'fear':     0.90,
  'sad':      0.75,
  'neutral':  0.45,
  'surprise': 0.25,
  'happy':    0.10,
};

// ── Result ────────────────────────────────────────────────────────
class InferenceResult {
  final List<double> emotionProbabilities; // already-softmaxed [0..1] from model
  final int dominantIndex;
  final double stressScore; // 0..100
  const InferenceResult({
    required this.emotionProbabilities,
    required this.dominantIndex,
    required this.stressScore,
  });
}

// ── Engine — runs on main isolate (safe for rootBundle) ──────────
class InferenceEngine {
  Interpreter? _interpreter;
  bool _ready = false;
  bool get isReady => _ready;

  /// Load the TFLite model. Must be called from the main isolate.
  Future<void> init() async {
    if (_ready) return;
    try {
      final data  = await rootBundle.load('assets/models/stress_model.tflite');
      final bytes = data.buffer.asUint8List();
      _interpreter = Interpreter.fromBuffer(
        bytes,
        options: InterpreterOptions()..threads = 2,
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Run inference. Returns null if engine not ready.
  InferenceResult? infer(Uint8List rgbBytes) {
    if (!_ready || _interpreter == null) return null;
    try {
      return _runInference(_interpreter!, rgbBytes);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _ready = false;
  }
}

// ── Core Inference ────────────────────────────────────────────────
InferenceResult _runInference(Interpreter interpreter, Uint8List rgbBytes) {
  // Model expects: [1, 96, 96, 3] float32 in [0.0, 1.0]
  // The model's final activation is softmax, so output is already a probability distribution.
  // DO NOT apply softmax again — it was applied during training.
  final input = List.generate(
    1,
    (_) => List.generate(
      96,
      (y) => List.generate(
        96,
        (x) {
          final base = (y * 96 + x) * 3;
          return [
            rgbBytes[base]     / 255.0,  // R normalised to [0,1]
            rgbBytes[base + 1] / 255.0,  // G normalised to [0,1]
            rgbBytes[base + 2] / 255.0,  // B normalised to [0,1]
          ];
        },
      ),
    ),
  );

  // Output buffer — model outputs softmax probabilities directly
  final output = [List.filled(7, 0.0)];
  interpreter.run(input, output);

  // probs is already a valid probability distribution (sums to ~1.0)
  final probs = List<double>.from(output[0]);

  // Find dominant emotion
  var maxVal = 0.0;
  var maxIdx = 0;
  for (int i = 0; i < probs.length; i++) {
    if (probs[i] > maxVal) {
      maxVal = probs[i];
      maxIdx = i;
    }
  }

  // Compute weighted stress score 0..100
  double stressScore = 0.0;
  for (int i = 0; i < probs.length; i++) {
    stressScore += probs[i] * (_stressWeights[emotionLabels[i]] ?? 0.5);
  }

  return InferenceResult(
    emotionProbabilities: probs,
    dominantIndex:        maxIdx,
    stressScore:          (stressScore * 100).clamp(0.0, 100.0),
  );
}

// ── Preprocessing ─────────────────────────────────────────────────
/// Resize face crop to 96×96 RGB and return raw bytes [0..255].
/// The model was trained on RGB images normalized to [0,1].
/// Normalization happens inside _runInference (/ 255.0).
Uint8List preprocessFaceCrop(img.Image face) {
  // Resize to 96x96 (matches training IMG_SIZE)
  final resized = img.copyResize(face, width: 96, height: 96,
      interpolation: img.Interpolation.linear);
  final bytes = Uint8List(96 * 96 * 3);
  int idx = 0;
  for (int y = 0; y < 96; y++) {
    for (int x = 0; x < 96; x++) {
      final pixel = resized.getPixel(x, y);
      
      // CRITICAL FIX: The python training script (data_prep.py) converts the original
      // FER2013 data to Grayscale, and then duplicates it across 3 RGB channels to fit MobileNet.
      // Passing live full-color images from the camera completely ruins the trained filter weights!
      // We must calculate grayscale luma first padding the channels perfectly.
      int gray = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).toInt();
      
      bytes[idx++] = gray;
      bytes[idx++] = gray;
      bytes[idx++] = gray;
    }
  }
  return bytes;
}
