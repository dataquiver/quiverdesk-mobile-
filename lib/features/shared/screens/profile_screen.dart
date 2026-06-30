import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/design_system/design_system.dart';
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
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
              context.go(AppRoutes.login);
            },
            child: const Text('Sign Out',
                style: TextStyle(color: QDPalette.error500)),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String code) => switch (code) {
    'PLATFORM_ADMIN'  => 'Platform Administrator',
    'BUSINESS_OWNER'  => 'Business Owner',
    'BRANCH_MANAGER'  => 'Branch Manager',
    'RECEPTIONIST'    => 'Receptionist',
    'STYLIST'         => 'Stylist',
    'DOCTOR'          => 'Doctor',
    'STAFF'           => 'Staff',
    _                 => code,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(QDSpace.screenPad),
        children: [
          // Avatar card
          Container(
            padding: const EdgeInsets.all(QDSpace.x6),
            decoration: BoxDecoration(
              color: QDPalette.surfaceCard,
              borderRadius: BorderRadius.circular(QDRadius.card),
              border: Border.all(color: QDPalette.neutral100),
              boxShadow: QDShadow.card,
            ),
            child: Column(
              children: [
                QDAvatar(name: _name.isNotEmpty ? _name : 'User', size: 80, radius: QDRadius.xl),
                const SizedBox(height: 14),
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: QDPalette.neutral900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_email,
                    style: const TextStyle(
                        color: QDPalette.neutral500, fontSize: 14)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: QDPalette.primary50,
                    borderRadius: BorderRadius.circular(QDRadius.full),
                    border: Border.all(color: QDPalette.primary100),
                  ),
                  child: Text(
                    _roleLabel(_role),
                    style: const TextStyle(
                      color: QDPalette.primary600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: QDSpace.cardGap),

          // Actions
          _tile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            onTap: () => context.push(AppRoutes.changePassword),
          ),
          const SizedBox(height: QDSpace.x2),
          _tile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            color: QDPalette.error500,
            onTap: _logout,
          ),
          const SizedBox(height: QDSpace.x8),
          const Center(
            child: Text(
              'QuiverDesk v1.0.0',
              style: TextStyle(fontSize: 12, color: QDPalette.neutral300),
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
    final c = color ?? QDPalette.neutral800;
    return Material(
      color: QDPalette.surfaceCard,
      borderRadius: BorderRadius.circular(QDRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(QDRadius.card),
        splashColor: QDPalette.primary50,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: QDSpace.screenPad, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(QDRadius.card),
            border: Border.all(color: QDPalette.neutral100),
          ),
          child: Row(
            children: [
              Icon(icon, color: c, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        color: c, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: QDPalette.neutral300, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
