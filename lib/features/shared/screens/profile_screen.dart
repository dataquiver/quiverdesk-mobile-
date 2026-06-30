import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/themes.dart';
import '../../../app/routes.dart';
import '../../../core/auth/token_storage.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await TokenStorage.getUserName() ?? '';
    final email = await TokenStorage.getUserEmail() ?? '';
    final role = await TokenStorage.getUserRole() ?? '';
    if (mounted) setState(() { _name = name; _email = email; _role = role; });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
              context.go(AppRoutes.login);
            },
            child: const Text('Sign Out', style: TextStyle(color: QDColors.error)),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String code) {
    return switch (code) {
      'PLATFORM_ADMIN' => 'Platform Administrator',
      'BUSINESS_OWNER' => 'Business Owner',
      'BRANCH_MANAGER' => 'Branch Manager',
      'RECEPTIONIST' => 'Receptionist',
      'STYLIST' => 'Stylist',
      'DOCTOR' => 'Doctor',
      'STAFF' => 'Staff',
      _ => code,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: QDColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QDColors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: QDColors.primary,
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: QDColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_email, style: const TextStyle(color: QDColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: QDColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _roleLabel(_role),
                    style: const TextStyle(
                      color: QDColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          _tile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => context.push(AppRoutes.changePassword),
          ),
          const SizedBox(height: 8),
          _tile(
            icon: Icons.logout,
            title: 'Sign Out',
            color: QDColors.error,
            onTap: _logout,
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'QuiverDesk v1.0.0',
              style: TextStyle(fontSize: 12, color: QDColors.textHint),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? QDColors.textPrimary;
    return Material(
      color: QDColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: QDColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w500))),
              const Icon(Icons.chevron_right, color: QDColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
