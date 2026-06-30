import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/themes.dart';
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
          const SnackBar(content: Text('Password changed successfully'), backgroundColor: QDColors.success),
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
      backgroundColor: QDColors.background,
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.lock_outline, size: 64, color: QDColors.primary),
              const SizedBox(height: 24),
              _field(_current, 'Current Password'),
              _field(_newPass, 'New Password',
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null),
              _field(_confirm, 'Confirm New Password',
                  validator: (v) => v != _newPass.text ? 'Passwords do not match' : null),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: QDColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              QDButton(label: 'Change Password', isLoading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: c,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: QDColors.surface,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: validator ?? (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
      );

  @override
  void dispose() {
    _current.dispose(); _newPass.dispose(); _confirm.dispose();
    super.dispose();
  }
}
