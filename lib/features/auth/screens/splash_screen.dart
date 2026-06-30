import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../app/routes.dart';
import '../../../app/design_system/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)),
    );
    _slideAnim = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) context.read<AuthBloc>().add(AppStarted());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
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
        } else if (state is AuthUnauthenticated) {
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                QDPalette.primary600,
                QDPalette.primary800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => FadeTransition(
                opacity: _fadeAnim,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo mark
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'QD',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: QDPalette.primary600,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'QuiverDesk',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Business Management Platform',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 64),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white.withValues(alpha: 0.8),
                            strokeWidth: 2,
                          ),
                        ),
                      ],
                    ),
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
