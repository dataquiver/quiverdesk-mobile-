import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/themes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/widgets/qd_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _loading = false;
  String? _error;

  // Step 1 fields
  final _businessName = TextEditingController();
  final _businessCode = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  String _category = 'SALON';

  // Step 2 fields
  final _ownerName = TextEditingController();
  final _ownerMobile = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;

  static const _categories = [
    'SALON', 'BARBERSHOP', 'SPA', 'DENTAL', 'CLINIC',
    'GYM', 'WELLNESS', 'BEAUTY', 'NAIL', 'OTHER'
  ];

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step == 0) { setState(() => _step = 1); return; }

    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    // Field names must match OnboardBusinessRequest on the backend.
    final nameParts = _ownerName.text.trim().split(RegExp(r'\s+'));
    try {
      await ApiClient.instance.post(ApiEndpoints.onboardBusiness, data: {
        'businessName': _businessName.text.trim(),
        'businessCode': _businessCode.text.trim(),
        'businessCategory': _category,
        'email': _email.text.trim(),
        'phoneNumber': _phone.text.trim(),
        'ownerFirstName': nameParts.first,
        'ownerLastName': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null,
        'ownerEmail': _email.text.trim(),
        'ownerMobileNumber': _ownerMobile.text.trim(),
        'password': _password.text,
        'city': _city.text.trim(),
      });
      if (mounted) setState(() { _step = 2; _loading = false; });
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data['message'] as String? ?? 'Registration failed. Please try again.')
          : 'Could not reach the server. Check your connection.';
      if (mounted) setState(() { _error = message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Registration failed. Please try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QDColors.background,
      appBar: AppBar(
        title: const Text('Register Business'),
        leading: _step > 0 && _step < 2
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _step--))
            : null,
      ),
      body: SafeArea(
        child: _step == 2 ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _StepIndicator(current: _step),
          const SizedBox(height: 24),
          if (_step == 0) ..._step1Fields() else ..._step2Fields(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: QDColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          QDButton(
            label: _step == 0 ? 'Next' : 'Register',
            isLoading: _loading,
            onPressed: _submit,
          ),
          if (_step == 0) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Sign In'),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _step1Fields() => [
    const Text('Business Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 20),
    _field(_businessName, 'Business Name', required: true),
    _field(_businessCode, 'Business Code (short unique code)', required: true,
        hint: 'e.g. GLWS'),
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: _inputDec('Business Category'),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _category = v ?? _category),
    ),
    const SizedBox(height: 16),
    _field(_email, 'Business Email', keyboardType: TextInputType.emailAddress, required: true),
    _field(_phone, 'Phone Number', keyboardType: TextInputType.phone, required: true),
    _field(_city, 'City'),
  ];

  List<Widget> _step2Fields() => [
    const Text('Owner Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 20),
    _field(_ownerName, 'Owner Full Name', required: true),
    _field(_ownerMobile, 'Owner Mobile', keyboardType: TextInputType.phone, required: true),
    const SizedBox(height: 16),
    TextFormField(
      controller: _password,
      obscureText: _obscure,
      decoration: _inputDec('Password').copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
    ),
    const SizedBox(height: 16),
    TextFormField(
      controller: _confirmPassword,
      obscureText: _obscure,
      decoration: _inputDec('Confirm Password'),
      validator: (v) => v != _password.text ? 'Passwords do not match' : null,
    ),
  ];

  Widget _buildSuccess() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: QDColors.success, size: 72),
          const SizedBox(height: 24),
          const Text('Registration Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('Your business has been registered. You can now sign in.',
              textAlign: TextAlign.center, style: TextStyle(color: QDColors.textSecondary)),
          const SizedBox(height: 32),
          QDButton(label: 'Go to Login', onPressed: () => context.go('/login')),
        ],
      ),
    ),
  );

  Widget _field(TextEditingController c, String label, {
    TextInputType? keyboardType, bool required = false, String? hint,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: c,
          keyboardType: keyboardType,
          decoration: _inputDec(label).copyWith(hintText: hint),
          validator: required ? (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null : null,
        ),
      );

  InputDecoration _inputDec(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    filled: true,
    fillColor: QDColors.surface,
  );

  @override
  void dispose() {
    for (final c in [_businessName, _businessCode, _email, _phone, _city,
      _ownerName, _ownerMobile, _password, _confirmPassword]) {
      c.dispose();
    }
    super.dispose();
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
          height: 4,
          decoration: BoxDecoration(
            color: i <= current ? QDColors.primary : QDColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )),
    );
  }
}
