import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/scan_provider.dart';
import '../widgets/face_overlay_painter.dart';
import '../widgets/scan_status_bar.dart';
import '../../../ml/inference_engine.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  CameraController? _camCtrl;
  bool _cameraReady = false;
  bool _permGranted = false;
  bool _processing  = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camCtrl?.stopImageStream();
    _camCtrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camCtrl == null) return;
    if (state == AppLifecycleState.inactive) {
      _camCtrl!.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permGranted = false);
      return;
    }
    if (mounted) setState(() => _permGranted = true);

    final cameras = await availableCameras();
    // Prefer front camera
    CameraDescription? front;
    for (final cam in cameras) {
      if (cam.lensDirection == CameraLensDirection.front) {
        front = cam;
        break;
      }
    }
    if (front == null && cameras.isNotEmpty) front = cameras.first;
    if (front == null) return;

    _camCtrl = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    await _camCtrl!.initialize();
    if (!mounted) return;

    setState(() => _cameraReady = true);
  }

  Future<void> _startScan() async {
    ref.read(scanProvider.notifier).startScan();

    await _camCtrl!.startImageStream((frame) async {
      if (_processing) return;
      _processing = true;
      final orientation = _camCtrl!.description.sensorOrientation;
      await ref.read(scanProvider.notifier).processFrame(frame, orientation);
      _processing = false;
    });
  }

  void _stopAndNavigate(ScanState scan) {
    _camCtrl?.stopImageStream();
    // Navigate to results
    context.push('/results', extra: {
      'stress_score':    scan.stressScore,
      'stress_level':    _stressLevel(scan.stressScore),
      'emotion_probs':   scan.emotionProbs,
      'dominant_emotion': emotionLabels[scan.dominantEmotionIndex],
    });
    ref.read(scanProvider.notifier).resetScan();
  }

  String _stressLevel(double score) {
    if (score >= 65) return 'high';
    if (score >= 35) return 'medium';
    return 'low';
  }

  @override
  Widget build(BuildContext context) {
    final scanAsync = ref.watch(scanProvider);

    // React to scan complete
    ref.listen<AsyncValue<ScanState>>(scanProvider, (_, next) {
      next.whenData((scan) {
        if (scan.isComplete) _stopAndNavigate(scan);
      });
    });

    if (!_permGranted) return _buildPermissionDenied();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_cameraReady && _camCtrl != null)
            CameraPreview(_camCtrl!),

          // Loading overlay
          if (!_cameraReady)
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),

          // Face mesh overlay (CustomPainter)
          if (_cameraReady)
            const FaceOverlayPainterWidget(),

          // Top bar — close button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () {
                    _camCtrl?.stopImageStream();
                    ref.read(scanProvider.notifier).resetScan();
                    context.go('/home');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),

          // Status + scan button at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: scanAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => _buildErrorBar(e.toString()),
                data: (scan) => ScanStatusBar(
                  scan: scan,
                  cameraReady: _cameraReady,
                  onScan: _startScan,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, color: AppTheme.textSecondary, size: 60),
            const SizedBox(height: 16),
            const Text('Camera Access Required',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Please grant camera permission in Settings.',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBar(String msg) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentWarm.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentWarm),
      ),
      child: Text(msg, style: const TextStyle(color: AppTheme.accentWarm, fontFamily: 'Inter')),
    );
  }
}
