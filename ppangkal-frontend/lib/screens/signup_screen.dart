import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/activity_level.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_layout.dart';

/// Two soft-outlined pills with a field label above, so the gender choice
/// reads as part of the form instead of a stray full-width toggle.
class _GenderField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _GenderField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
          child: Text(
            '성별',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'female', label: Text('여성')),
            ButtonSegment(value: 'male', label: Text('남성')),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: scheme.onSurfaceVariant,
            selectedBackgroundColor: scheme.primaryContainer,
            selectedForegroundColor: scheme.onPrimaryContainer,
            side: BorderSide(color: scheme.outlineVariant),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            textStyle: theme.textTheme.bodyMedium,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

/// Navigating to `/home` on success is handled by the router's redirect
/// (`lib/router/app_router.dart`), not here.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = 'female';
  String _activityLevel = ActivityLevel.sightseeing;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      gender: _gender,
      age: int.parse(_ageController.text),
      height: double.parse(_heightController.text),
      weight: double.parse(_weightController.text),
      activityLevel: _activityLevel,
    );

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? '회원가입에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.authenticating;

    return AuthLayout(
      title: '회원가입',
      subtitle: '키·몸무게로 하루 목표 칼로리를 계산해 드려요',
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: '이메일'),
              validator: Validators.email,
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: '비밀번호'),
              validator: Validators.password,
            ),
            TextFormField(
              controller: _passwordConfirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호 확인'),
              validator: (v) => v != _passwordController.text ? '비밀번호가 일치하지 않습니다' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '이름'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '이름을 입력하세요' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _GenderField(
              value: _gender,
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(labelText: '나이'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (int.tryParse(v ?? '') == null) ? '숫자' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(labelText: '키', suffixText: 'cm'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? '숫자' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: '몸무게', suffixText: 'kg'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (double.tryParse(v ?? '') == null) ? '숫자' : null,
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: _activityLevel,
              decoration: const InputDecoration(labelText: '여행 스타일 (활동 수준)'),
              items: ActivityLevel.values
                  .map((v) => DropdownMenuItem(value: v, child: Text(ActivityLevel.label(v))))
                  .toList(),
              onChanged: (v) => setState(() => _activityLevel = v!),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
