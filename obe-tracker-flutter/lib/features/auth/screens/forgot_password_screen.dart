import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import 'package:obe_tracker/features/shared/widgets/loading_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result =
        await ref.read(authProvider.notifier).forgotPassword(_emailCtrl.text);
    setState(() => _isLoading = false);
    result.when(
      success: (_) => setState(() => _otpSent = true),
      failure: (e) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e), backgroundColor: AppTheme.error)),
    );
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await ref.read(authProvider.notifier).resetPassword(
        _emailCtrl.text, _otpCtrl.text, _passwordCtrl.text);
    setState(() => _isLoading = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successful. Please log in.')),
        );
        context.go('/login');
      },
      failure: (e) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e), backgroundColor: AppTheme.error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otpSent ? 'Enter OTP & New Password' : 'Forgot Password',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _otpSent
                            ? 'A 6-digit OTP has been sent to your email. It expires in 10 minutes.'
                            : 'Enter your email to receive a one-time password.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),

                      // Email (always shown)
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: !_otpSent,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Email is required' : null,
                      ),

                      if (_otpSent) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: '6-Digit OTP',
                            prefixIcon: Icon(Icons.pin_outlined),
                            counterText: '',
                          ),
                          validator: (v) =>
                              (v == null || v.length != 6) ? 'Enter the 6-digit OTP' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            helperText: 'Min 8 chars, at least 1 letter and 1 digit',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}').hasMatch(v)) {
                              return 'Must be ≥8 chars with letter and digit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) =>
                              v != _passwordCtrl.text ? 'Passwords do not match' : null,
                        ),
                      ],

                      const SizedBox(height: 24),
                      LoadingButton(
                        onPressed: _otpSent ? _resetPassword : _sendOtp,
                        isLoading: _isLoading,
                        label: _otpSent ? 'Reset Password' : 'Send OTP',
                      ),

                      if (_otpSent) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _otpSent = false),
                            child: const Text('Use a different email'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
