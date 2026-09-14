import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_layout.dart';

/// MVP login is user_id-based, no password (FRONTEND_API_GUIDE.md §1) —
/// the id shown on the home screen after signup is what gets typed back
/// in here on a later visit. Navigating to `/home` on success is handled
/// by the router's redirect (`lib/router/app_router.dart`), not here.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(userId);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _userIdController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => isLoading ? null : _submit(),
            decoration: const InputDecoration(
              labelText: '사용자 ID',
              helperText: '회원가입 때 발급받은 ID를 입력하세요',
              prefixIcon: Icon(Icons.person_outline),
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
    );
  }
}
