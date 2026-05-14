import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/database/local_db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Status bar overlay
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Supabase
    await Supabase.initialize(
      url: 'https://dicdziqqedcorngwtdao.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpY2R6aXFxZWRjb3JuZ3d0ZGFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MzAxODgsImV4cCI6MjA5MTUwNjE4OH0.qV_KQzhVmRjltADY4kfB9kzqfbtBRdfxEyaUOBKLFYA',
    );

    // Init local DB
    final db = LocalDatabase();

    runApp(
      ProviderScope(
        overrides: [
          localDbProvider.overrideWithValue(db),
        ],
        child: const SerenAIApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('FATAL INITIALIZATION ERROR: $e');
    debugPrint(stack.toString());
    
    // Fallback app if critical services fail
    runApp(InitErrorApp(error: e.toString()));
  }
}

class InitErrorApp extends StatelessWidget {
  final String error;
  const InitErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF080C14),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                'Initialization Failed',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'The app encountered an error during startup. Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => main(), // Simple retry
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SerenAIApp extends ConsumerWidget {
  const SerenAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'SerenAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
