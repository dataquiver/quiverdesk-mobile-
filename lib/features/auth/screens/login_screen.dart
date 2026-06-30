import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../app/routes.dart';
import '../../../app/design_system/design_system.dart';
import '../../../core/widgets/qd_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = 'v${info.version}');
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthBloc>().add(
      LoginRequested(_emailCtrl.text.trim(), _passCtrl.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            if (user.isPlatformAdmin) {
              context.go(AppRoutes.platformDashboard);
            } else if (user.isBusinessOwner) {
              context.go(AppRoutes.businessDashboard);
            } else {
              context.go(AppRoutes.staffDashboard);
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: QDPalette.error500,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(QDRadius.xs),
                ),
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 64),

                // Logo mark + wordmark
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [QDPalette.primary500, QDPalette.primary700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: QDPalette.primary500.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'QD',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: QDPalette.neutral900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in to your QuiverDesk account',
                        style: TextStyle(
                          fontSize: 15,
                          color: QDPalette.neutral400,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _QDTextField(
                        controller: _emailCtrl,
                        label: 'Email or Mobile',
                        prefixIcon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _QDTextField(
                        controller: _passCtrl,
                        label: 'Password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: QDPalette.neutral400,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: QDTextButton(
                          label: 'Forgot Password?',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return QDButton(
                            label: 'Sign In',
                            isLoading: state is AuthLoading,
                            onPressed: _submit,
                            icon: Icons.login_rounded,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: QDPalette.neutral500, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.register),
                      child: const Text(
                        'Register Business',
                        style: TextStyle(
                          color: QDPalette.primary600,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_appVersion.isNotEmpty)
                  Center(
                    child: Text(
                      _appVersion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: QDPalette.neutral300,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QDTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  const _QDTextField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: QDPalette.neutral800,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: QDPalette.neutral400, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: QDPalette.primary500, fontSize: 12),
        prefixIcon: Icon(prefixIcon, color: QDPalette.neutral400, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: QDPalette.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QDRadius.input),
          borderSide: const BorderSide(color: QDPalette.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QDRadius.input),
          borderSide: const BorderSide(color: QDPalette.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QDRadius.input),
          borderSide: const BorderSide(color: QDPalette.primary500, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QDRadius.input),
          borderSide: const BorderSide(color: QDPalette.error500),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(QDRadius.input),
          borderSide: const BorderSide(color: QDPalette.error500, width: 1.5),
        ),
      ),
    );
  }
}
