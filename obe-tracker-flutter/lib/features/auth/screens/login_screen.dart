import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/core/constants/app_strings.dart';
import 'package:obe_tracker/features/shared/widgets/loading_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text, _passwordCtrl.text);
    result.when(
      success: (user) {
        if (!mounted) return;
        final role = user.role.toLowerCase();
        context.go('/$role/dashboard');
      },
      failure: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppTheme.error),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 440 : double.infinity),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Brand
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text(AppStrings.appName,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Bangladesh University of Professionals',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFF6B7280)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.loginTitle,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(AppStrings.loginSubtitle,
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 24),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email or Student ID',
                              hintText: 'e.g. admin@bup.edu.bd or 23549009001',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email or Student ID is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: AppStrings.passwordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: const Text(AppStrings.forgotPassword),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Submit
                          LoadingButton(
                            onPressed: _submit,
                            isLoading: isLoading,
                            label: AppStrings.loginButton,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'CO–PO Mapping & Attainment Tracking System v1.0',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
