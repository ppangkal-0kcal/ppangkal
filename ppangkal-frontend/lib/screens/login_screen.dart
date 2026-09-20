import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_layout.dart';

/// Email + password login. Navigating to `/home` on success is handled by
/// the router's redirect (`lib/router/app_router.dart`), not here.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

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
          ],
        ),
      ),
    );
  }
}
