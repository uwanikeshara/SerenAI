import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/theme/app_theme.dart';

enum _BreathPhase { inhale, holdIn, exhale, holdOut }

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  // Technique presets — [inhale, holdIn, exhale, holdOut] seconds
  static const _techniques = [
    _Technique('Box Breathing',   '4-4-4-4', [4, 4, 4, 4],
        'Inhale 4s · Hold 4s · Exhale 4s · Hold 4s\nBest for stress & focus'),
    _Technique('4-7-8 Relaxing', '4-7-8',   [4, 7, 8, 0],
        'Inhale 4s · Hold 7s · Exhale 8s\nBest before sleep or anxiety'),
    _Technique('Deep Calm',      '5-0-5',   [5, 0, 5, 0],
        'Inhale 5s · Exhale 5s\nPerfect for a quick reset'),
  ];

  int _techniqueIndex = 0;
  int _cycles        = 0;
  int _totalCycles   = 4;
  bool _running      = false;
  _BreathPhase _phase = _BreathPhase.inhale;
  int _secondsLeft   = 0;

  late AnimationController _circleCtrl;
  late AnimationController _glowCtrl;
  late Animation<double>   _scaleAnim;
  late Animation<double>   _glowAnim;

  // Ambient audio player
  late final AudioPlayer _ambientPlayer;

  // Ambient sounds — rotates per technique
  static const _ambientUrls = [
    'https://cdn.pixabay.com/audio/2022/10/30/audio_347753b738.mp3', // Forest rain
    'https://cdn.pixabay.com/audio/2022/06/07/audio_b9a9b9c91d.mp3', // Ocean
    'https://cdn.pixabay.com/audio/2022/10/31/audio_35b3e6f4a7.mp3', // Stream
  ];

  bool _soundOn = true;

  @override
  void initState() {
    super.initState();
    _ambientPlayer = AudioPlayer();

    _circleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _circleCtrl, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _circleCtrl.dispose();
    _glowCtrl.dispose();
    _ambientPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  _Technique get _current => _techniques[_techniqueIndex];

  int _dur(_BreathPhase phase) => _current.durations[phase.index];

  Future<void> _startAmbient() async {
    if (!_soundOn) return;
    try {
      await _ambientPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(_ambientUrls[_techniqueIndex % _ambientUrls.length])),
      );
      await _ambientPlayer.setLoopMode(LoopMode.one);
      await _ambientPlayer.setVolume(0.35);
      await _ambientPlayer.play();
    } catch (_) {}
  }

  Future<void> _stopAmbient() async {
    try {
      await _ambientPlayer.stop();
    } catch (_) {}
  }

  Future<void> _startBreathing() async {
    setState(() { _running = true; _cycles = 0; });
    WakelockPlus.enable();
    await _startAmbient();
    await _runCycle();
  }

  Future<void> _runCycle() async {
    for (final phase in _BreathPhase.values) {
      if (!_running || !mounted) return;
      final dur = _dur(phase);
      if (dur == 0) continue;

      setState(() { _phase = phase; _secondsLeft = dur; });

      // Animate circle expand/contract
      _circleCtrl.duration = Duration(seconds: dur);
      if (phase == _BreathPhase.inhale) {
        _circleCtrl.forward(from: _circleCtrl.value);
      } else if (phase == _BreathPhase.exhale) {
        _circleCtrl.reverse(from: _circleCtrl.value);
      }
      // Hold phases — stay where they are

      for (int i = dur; i > 0; i--) {
        if (!_running || !mounted) return;
        setState(() => _secondsLeft = i);
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (!mounted || !_running) return;
    final newCycles = _cycles + 1;
    setState(() => _cycles = newCycles);

    if (newCycles < _totalCycles) {
      await _runCycle();
    } else {
      await _stopAmbient();
      WakelockPlus.disable();
      setState(() => _running = false);
      _circleCtrl.reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Well done! Breathing exercise complete. 🌿'),
            backgroundColor: AppTheme.stressLow,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _stop() {
    setState(() { _running = false; _cycles = 0; _secondsLeft = 0; });
    _circleCtrl.stop();
    _circleCtrl.reset();
    _stopAmbient();
    WakelockPlus.disable();
  }

  String get _phaseLabel {
    switch (_phase) {
      case _BreathPhase.inhale:  return 'Inhale';
      case _BreathPhase.holdIn:  return 'Hold';
      case _BreathPhase.exhale:  return 'Exhale';
      case _BreathPhase.holdOut: return 'Hold';
    }
  }

  Color get _phaseColor {
    switch (_phase) {
      case _BreathPhase.inhale:  return AppTheme.accent;
      case _BreathPhase.holdIn:  return AppTheme.primary;
      case _BreathPhase.exhale:  return const Color(0xFF5B9BFF);
      case _BreathPhase.holdOut: return AppTheme.accentWarm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_running,
      onPopInvoked: (didPop) {
        if (!didPop && _running) {
          _stop();
          if (context.canPop()) context.pop();
          else context.go('/home');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: AppTheme.textPrimary, size: 22),
                        onPressed: () {
                          _stop();
                          if (context.canPop()) context.pop();
                          else context.go('/home');
                        },
                      ),
                      const Expanded(
                        child: Text('Breathing Exercise',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                      // Sound toggle
                      IconButton(
                        icon: Icon(
                          _soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: _soundOn ? AppTheme.primary : AppTheme.textSecondary,
                          size: 22,
                        ),
                        onPressed: () async {
                          setState(() => _soundOn = !_soundOn);
                          if (!_soundOn) {
                            await _stopAmbient();
                          } else if (_running) {
                            await _startAmbient();
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // ── Technique tabs ──────────────────────────
                if (!_running) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _techniques.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final selected = i == _techniqueIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _techniqueIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primary.withOpacity(0.2)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? AppTheme.primary : AppTheme.divider,
                              ),
                            ),
                            child: Text(_techniques[i].name,
                                style: TextStyle(
                                  color: selected
                                      ? AppTheme.primary
                                      : AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(_current.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        )),
                  ),
                ],

                const Spacer(),

                // ── Breathing circle ────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_circleCtrl, _glowCtrl]),
                  builder: (_, __) {
                    final scale  = _running ? _scaleAnim.value : 0.7;
                    final color  = _running ? _phaseColor : AppTheme.primary;
                    final glow   = _running ? _glowAnim.value : 0.2;

                    return SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow
                          Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color.withOpacity(glow * 0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(glow * 0.5),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Inner fill
                          Transform.scale(
                            scale: scale * 0.72,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    color.withOpacity(0.85),
                                    color.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Label + countdown
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _running ? _phaseLabel : 'Ready',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_running) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '$_secondsLeft',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w200,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Cycle counter
                if (_running)
                  Text(
                    'Cycle ${_cycles + 1} of $_totalCycles',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),

                const Spacer(),

                // ── Controls ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      if (!_running) ...[
                        // Cycle picker
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Cycles: ',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                )),
                            ...[3, 4, 6, 8].map((n) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => setState(() => _totalCycles = n),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _totalCycles == n
                                        ? AppTheme.primary.withOpacity(0.2)
                                        : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _totalCycles == n
                                          ? AppTheme.primary
                                          : AppTheme.divider,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text('$n',
                                        style: TextStyle(
                                          color: _totalCycles == n
                                              ? AppTheme.primary
                                              : AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        )),
                                  ),
                                ),
                              ),
                            )),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _running ? _stop : _startBreathing,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            backgroundColor: _running
                                ? AppTheme.accentWarm.withOpacity(0.15)
                                : AppTheme.primary,
                            foregroundColor:
                                _running ? AppTheme.accentWarm : Colors.white,
                            elevation: 0,
                            side: _running
                                ? const BorderSide(color: AppTheme.accentWarm)
                                : BorderSide.none,
                          ),
                          child: Text(
                            _running ? 'Stop Exercise' : 'Begin Breathing',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Technique {
  final String name;
  final String pattern;
  final List<int> durations; // [inhale, holdIn, exhale, holdOut]
  final String description;
  const _Technique(this.name, this.pattern, this.durations, this.description);
}
