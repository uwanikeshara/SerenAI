import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _current    = 0;

  static const _pages = [
    _OBData(
      icon: Icons.face_retouching_natural,
      gradient: AppTheme.primaryGrad,
      title: 'AI Stress Detection',
      subtitle:
          'Our advanced AI reads your facial micro-expressions in real-time to accurately measure your stress level — no wearables needed.',
    ),
    _OBData(
      icon: Icons.headphones_rounded,
      gradient: AppTheme.accentGrad,
      title: 'Personalised Calm',
      subtitle:
          'Curated soundscapes, binaural beats, and guided breathing exercises adapt to your stress level for immediate relief.',
    ),
    _OBData(
      icon: Icons.bar_chart_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      title: 'Track Your Progress',
      subtitle:
          'Visualise your stress trends over time, build healthy streaks, and celebrate every step toward a calmer mind.',
    ),
  ];

  Future<void> _finish() async {
    await OnboardingService.markOnboardingDone();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (_, i) => _PageContent(data: _pages[i]),
                ),
              ),
              _buildControls(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _current == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _current == i ? AppTheme.primary : AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_current < _pages.length - 1) ...[
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    label: 'Next',
                    onPressed: () => _pageCtrl.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _finish,
              child: const Text('Skip',
                  style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Inter')),
            ),
          ] else ...[
            GradientButton(label: 'Get Started', onPressed: _finish),
          ],
        ],
      ),
    );
  }
}

class _OBData {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  const _OBData({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });
}

class _PageContent extends StatelessWidget {
  final _OBData data;
  const _PageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: data.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Icon(data.icon, size: 72, color: Colors.white),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            data.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
