import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _loading       = false;
  bool _obscure       = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {'username': _nameCtrl.text.trim()},
      );
      if (res.user != null) {
        // Save the full name the user typed into the profile
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id':       res.user!.id,
            'username': _nameCtrl.text.trim(),
          });
        } catch (_) {}
        if (mounted) context.go('/home');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.accentWarm,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGrad),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
                    onPressed: () => context.go('/login'),
                  ),
                  const SizedBox(height: 20),
                  Text('Create Account',
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 8),
                  Text('Start your mindfulness journey today',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 40),

                  _field(_nameCtrl, 'Full Name', 'Jane Doe', Icons.person_outline,
                      (v) => v!.isNotEmpty ? null : 'Required'),
                  const SizedBox(height: 16),
                  _field(_emailCtrl, 'Email', 'you@example.com', Icons.email_outlined,
                      (v) => v!.contains('@') ? null : 'Enter valid email',
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Min 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                    ),
                    validator: (v) => v == _passwordCtrl.text ? null : 'Passwords do not match',
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Create Account',
                    loading: _loading,
                    onPressed: _register,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon,
    String? Function(String?) validator, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
      ),
      validator: validator,
    );
  }
}
