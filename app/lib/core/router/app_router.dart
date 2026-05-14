import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/permissions_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/scan/screens/scan_screen.dart';
import '../../features/scan/screens/breathing_screen.dart';
import '../../features/results/screens/results_screen.dart';
import '../../features/audio/screens/audio_player_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/journal/screens/journal_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/content/screens/content_screen.dart';
import '../widgets/main_scaffold.dart';
import '../providers/onboarding_provider.dart';

// Navigator keys — shell tabs share _shellKey; full-screen pushes use _rootKey
final _rootKey  = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = Supabase.instance.client;
  final onboardingAsync = ref.watch(onboardingStatusProvider);
  final permissionsAsync = ref.watch(permissionsStatusProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      if (onboardingAsync.isLoading || permissionsAsync.isLoading) return '/splash';

      final onboarded  = onboardingAsync.value ?? false;
      final seenPerms  = permissionsAsync.value ?? false;
      final isLoggedIn = client.auth.currentSession != null;
      final loc        = state.uri.path;

      if (loc == '/splash') {
        if (!onboarded) return '/onboarding';
        if (!isLoggedIn) return '/login';
        if (!seenPerms) return '/permissions';
        return '/home';
      }
      
      if (!isLoggedIn &&
          loc != '/login' && loc != '/register' && loc != '/onboarding') {
        return '/login';
      }
      
      if (isLoggedIn) {
        if (loc == '/login' || loc == '/register') {
          return seenPerms ? '/home' : '/permissions';
        }
        // If they are logged in, going anywhere else, but haven't seen perms yet
        if (!seenPerms && loc != '/permissions' && loc != '/onboarding') {
          return '/permissions';
        }
      }
      return null;
    },
    routes: [
      // ── Auth / onboarding ──────────────────────────────────────
      GoRoute(path: '/splash',      builder: (_, __) => const SplashPage()),
      GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionsScreen()),
      GoRoute(path: '/login',       builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',    builder: (_, __) => const RegisterScreen()),

      // ── Shell (tabs with bottom nav bar) ──────────────────────
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/scan',     builder: (_, __) => const ScanScreen()),
          GoRoute(path: '/content',  builder: (_, __) => const ContentScreen()),
          GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
          GoRoute(path: '/profile',  builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Full-screen push routes (use root navigator → proper back stack) ──
      GoRoute(
        parentNavigatorKey: _rootKey, // renders ABOVE the shell nav bar
        path: '/breathe',
        builder: (_, __) => const BreathingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/journal',
        builder: (_, __) => const JournalScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/results',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ResultsScreen(scanData: extra);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/audio',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return AudioPlayerScreen(trackData: extra);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080C14),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      ),
    );
  }
}
