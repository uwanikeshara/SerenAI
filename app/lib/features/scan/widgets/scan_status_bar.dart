import 'package:flutter/material.dart';
import '../providers/scan_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';

class ScanStatusBar extends StatelessWidget {
  final ScanState scan;
  final bool cameraReady;
  final VoidCallback onScan;

  const ScanStatusBar({
    super.key,
    required this.scan,
    required this.cameraReady,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (scan.isScanning) ...[
            _buildProgressBar(),
            const SizedBox(height: 12),
            Text(
              scan.faceDetected
                  ? 'Analysing expression...'
                  : 'Position face in oval',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                
              ),
            ),
          ] else if (!scan.isScanning && !scan.isComplete) ...[
            if (!scan.faceDetected && cameraReady)
              const Text(
                'Position your face in the oval',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  
                ),
              ),
            const SizedBox(height: 12),
            GradientButton(
              label: cameraReady ? '  Start Scan' : 'Initializing...',
              onPressed: cameraReady ? onScan : null,
              width: double.infinity,
            ),
          ] else if (scan.isComplete) ...[
            const Text('Scan complete!',
                style: TextStyle(color: AppTheme.accent, fontSize: 14, fontFamily: 'Inter')),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = scan.scanProgress / 100.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Scanning',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter')),
            Text('${scan.scanProgress}%',
                style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
