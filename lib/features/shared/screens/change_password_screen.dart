import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/design_system/design_system.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/widgets/qd_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.instance.post(ApiEndpoints.changePassword, data: {
        'currentPassword': _current.text,
        'newPassword': _newPass.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDPalette.surfaceBackground,
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(QDSpace.x6),
            children: [
              const SizedBox(height: QDSpace.x4),
              // Icon header
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: QDPalette.primary50,
                    borderRadius: BorderRadius.circular(QDRadius.md),
                    border: Border.all(color: QDPalette.primary100),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      size: 36, color: QDPalette.primary500),
                ),
              ),
              const SizedBox(height: QDSpace.x5),
              const Center(
                child: Text('Update your password',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: QDPalette.neutral700)),
              ),
              const SizedBox(height: QDSpace.x6),
              _field(_current, 'Current Password'),
              _field(_newPass, 'New Password',
                  validator: (v) =>
                      (v?.length ?? 0) < 6 ? 'Min 6 characters' : null),
              _field(_confirm, 'Confirm New Password',
                  validator: (v) =>
                      v != _newPass.text ? 'Passwords do not match' : null),
              if (_error != null) ...[
                const SizedBox(height: QDSpace.x2),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: QDPalette.errorBg,
                    borderRadius: BorderRadius.circular(QDRadius.xs),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: QDPalette.error500, fontSize: 13)),
                ),
              ],
              const SizedBox(height: QDSpace.x6),
              QDButton(
                  label: 'Change Password',
                  isLoading: _loading,
                  icon: Icons.lock_reset_rounded,
                  onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: QDSpace.x3),
        child: TextFormField(
          controller: c,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: IconButton(
              icon: Icon(_obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: validator ?? (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
      );

  @override
  void dispose() {
    _current.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }
}
