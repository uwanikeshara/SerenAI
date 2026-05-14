import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ml/inference_engine.dart';

// ── Scan state ─────────────────────────────────────────────────

class ScanState {
  final bool isScanning;
  final bool faceDetected;
  final double stressScore;
  final List<double> emotionProbs;
  final int dominantEmotionIndex;
  final bool isComplete;
  final String? error;
  final int scanProgress; // 0-100

  const ScanState({
    this.isScanning     = false,
    this.faceDetected   = false,
    this.stressScore    = 0,
    this.emotionProbs   = const [],
    this.dominantEmotionIndex = 6, // neutral default
    this.isComplete     = false,
    this.error,
    this.scanProgress   = 0,
  });

  ScanState copyWith({
    bool? isScanning,
    bool? faceDetected,
    double? stressScore,
    List<double>? emotionProbs,
    int? dominantEmotionIndex,
    bool? isComplete,
    String? error,
    int? scanProgress,
  }) =>
      ScanState(
        isScanning:           isScanning          ?? this.isScanning,
        faceDetected:         faceDetected         ?? this.faceDetected,
        stressScore:          stressScore          ?? this.stressScore,
        emotionProbs:         emotionProbs         ?? this.emotionProbs,
        dominantEmotionIndex: dominantEmotionIndex ?? this.dominantEmotionIndex,
        isComplete:           isComplete           ?? this.isComplete,
        error:                error,
        scanProgress:         scanProgress         ?? this.scanProgress,
      );
}

// ── Notifier ───────────────────────────────────────────────────

class ScanNotifier extends AsyncNotifier<ScanState> {
  // Engine runs on main isolate — safe for rootBundle asset loading
  final InferenceEngine _engine = InferenceEngine();

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableClassification: false,
    ),
  );

  // Rolling window of results for smoothing
  final List<InferenceResult> _window = [];
  static const _windowSize = 10;
  Timer? _scanTimer;
  bool _processing = false;

  @override
  Future<ScanState> build() async {
    ref.onDispose(_dispose);
    // Load the TFLite model from assets (must be on main isolate)
    await _engine.init();
    return const ScanState();
  }

  void startScan() {
    if (state.value?.isScanning ?? false) return;
    _window.clear();
    state = AsyncData(const ScanState(isScanning: true, scanProgress: 0));

    // 5-second scan window
    _scanTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (t.tick >= 50) {
        t.cancel();
        _finaliseScan();
      } else {
        final progress = ((t.tick / 50) * 100).toInt();
        final current = state.value ?? const ScanState();
        state = AsyncData(current.copyWith(scanProgress: progress));
      }
    });
  }

  Future<void> processFrame(CameraImage frame, int sensorOrientation) async {
    if (_processing) return;
    if (!(state.value?.isScanning ?? false)) return;
    if (!_engine.isReady) return;

    _processing = true;
    try {
      // Decode ML kit exact rotation
      final InputImageRotation rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation270deg;
      
      // Detect face with MediaPipe
      final inputImage = InputImage.fromBytes(
        bytes: frame.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(frame.width.toDouble(), frame.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: frame.planes[0].bytesPerRow,
        ),
      );
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        final current = state.value ?? const ScanState();
        state = AsyncData(current.copyWith(faceDetected: false, error: null));
        _processing = false;
        return;
      }

      // Convert full frame to img.Image for cropping, applying exact physical sensor geometry rotation manually
      final image = _convertCameraImage(frame, sensorOrientation);
      if (image == null) { _processing = false; return; }

      final face   = faces.first;
      final bb     = face.boundingBox;

      // Expand bounding box by 20% to capture full chin and forehead
      final paddingX = bb.width * 0.20;
      final paddingY = bb.height * 0.20;

      final left   = (bb.left - paddingX).clamp(0.0, image.width.toDouble() - 1).toInt();
      final top    = (bb.top - paddingY).clamp(0.0, image.height.toDouble() - 1).toInt();
      final width  = (bb.width + (paddingX * 2)).clamp(1.0, (image.width  - left).toDouble()).toInt();
      final height = (bb.height + (paddingY * 2)).clamp(1.0, (image.height - top).toDouble()).toInt();

      final crop  = img.copyCrop(image, x: left, y: top, width: width, height: height);
      
      // Ensure the crop is perfectly square before the model sees it
      final size  = crop.width > crop.height ? crop.height : crop.width;
      final squareCrop = img.copyCrop(crop, 
        x: (crop.width - size) ~/ 2, 
        y: (crop.height - size) ~/ 2, 
        width: size, 
        height: size
      );

      final bytes = preprocessFaceCrop(squareCrop);

      // Run TFLite inference on main isolate
      final result = _engine.infer(bytes);
      if (result != null) _handleResult(result);

    } catch (_) {
      // Silently continue — don't crash scan on single frame error
    }
    _processing = false;
  }

  void _handleResult(InferenceResult result) {
    _window.add(result);
    if (_window.length > _windowSize) _window.removeAt(0);

    // Rolling-average smoothing
    final avgScore = _window.map((r) => r.stressScore).reduce((a, b) => a + b) / _window.length;
    final avgProbs = List.generate(7, (i) =>
      _window.map((r) => r.emotionProbabilities[i]).reduce((a, b) => a + b) / _window.length,
    );
    final domIdx = avgProbs.indexOf(avgProbs.reduce((a, b) => a > b ? a : b));

    final current = state.value ?? const ScanState();
    state = AsyncData(current.copyWith(
      faceDetected:         true,
      stressScore:          avgScore,
      emotionProbs:         avgProbs,
      dominantEmotionIndex: domIdx,
      error:                null,
    ));
  }

  void _finaliseScan() {
    if (_window.isEmpty) {
      state = AsyncData(
        const ScanState(error: 'No face detected. Please ensure your face is visible and well-lit.'),
      );
      return;
    }
    final current = state.value ?? const ScanState();
    state = AsyncData(current.copyWith(
      isScanning:   false,
      isComplete:   true,
      scanProgress: 100,
      error:        null,
    ));
  }

  void resetScan() {
    _scanTimer?.cancel();
    _window.clear();
    _processing = false;
    state = const AsyncData(ScanState());
  }

  img.Image? _convertCameraImage(CameraImage frame, int sensorOrientation) {
    try {
      final plane = frame.planes[0];
      final bytes = plane.bytes;
      final w = frame.width;
      final h = frame.height;
      final image = img.Image(width: w, height: h);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final lum = bytes[y * plane.bytesPerRow + x];
          image.setPixelRgb(x, y, lum, lum, lum);
        }
      }
      
      // Transform unrotated buffer to match bounding box plane 
      return img.copyRotate(image, angle: sensorOrientation);
    } catch (_) {
      return null;
    }
  }

  void _dispose() {
    _scanTimer?.cancel();
    _faceDetector.close();
    _engine.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────
final scanProvider =
    AsyncNotifierProvider<ScanNotifier, ScanState>(ScanNotifier.new);

// Recent scans from Supabase — Streamed for Realtime UI Updates
final recentScansProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return Stream.value([]);
  
  return Supabase.instance.client
      .from('stress_scans')
      .stream(primaryKey: ['id'])
      .eq('user_id', uid)
      .order('scanned_at', ascending: false)
      .handleError((_) => const Stream.empty()) // Prevent Realtime crashes from surfacing as raw errors
      .map((data) {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        return data
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => DateTime.parse(e['scanned_at']).isAfter(sevenDaysAgo))
            .toList();
      });
});
