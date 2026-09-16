import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_layout.dart';

/// Email + password login. Accounts created by app 1.0.0 only have a user
/// ID, so an "기존 ID로 로그인" mode stays available until they link an email
/// from 마이페이지. Navigating to `/home` on success is handled by the
/// router's redirect (`lib/router/app_router.dart`), not here.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userIdController = TextEditingController();
  bool _legacyIdMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = _legacyIdMode
        ? await auth.loginWithUserId(_userIdController.text.trim())
        : await auth.login(email: _emailController.text.trim(), password: _passwordController.text);

    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? '로그인에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.authenticating;

    return AuthLayout(
      title: '빵칼',
      subtitle: '걸은 만큼 맛있게, 대전 빵투어',
      footer: TextButton(
        onPressed: () => context.push('/signup'),
        child: const Text('계정이 없으신가요? 회원가입'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_legacyIdMode)
              TextFormField(
                controller: _userIdController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => isLoading ? null : _submit(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'ID를 입력하세요' : null,
                decoration: const InputDecoration(
                  labelText: '사용자 ID',
                  helperText: '이전 버전에서 발급받은 ID (마이페이지에서 이메일 로그인으로 바꿀 수 있어요)',
                  helperMaxLines: 2,
                  prefixIcon: Icon(Icons.person_outline),
                ),
              )
            else ...[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: Validators.email,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => isLoading ? null : _submit(),
                validator: (v) => (v == null || v.isEmpty) ? '비밀번호를 입력하세요' : null,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ],
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
                  : const Text('로그인'),
            ),
            TextButton(
              onPressed: isLoading ? null : () => setState(() => _legacyIdMode = !_legacyIdMode),
              child: Text(_legacyIdMode ? '이메일로 로그인' : '이전 버전 ID로 로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
