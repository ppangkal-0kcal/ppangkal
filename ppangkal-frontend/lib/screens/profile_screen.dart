import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/activity_level.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_title.dart';
import '../widgets/stat_column.dart';

/// 마이페이지 tab — profile summary (`GET /users/me`, already cached on
/// [AuthProvider.user]) with an edit sheet backed by `PATCH /users/me`
/// (`AuthProvider.updateProfile`), plus logout.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: PageAppBar('마이페이지'),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: textTheme.headlineSmall),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                [
                                  if (user.gender != null) (user.gender == 'female' ? '여성' : '남성'),
                                  if (user.age != null) '${user.age}세',
                                ].join(' · '),
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          OutlinedButton(
                            onPressed: () => _showEditSheet(context, user),
                            child: const Text('정보 수정'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      StatRow(
                        children: [
                          StatColumn(label: '키', value: user.height != null ? '${user.height!.toStringAsFixed(0)}cm' : '-'),
                          StatColumn(label: '체중', value: user.weight != null ? '${user.weight!.toStringAsFixed(0)}kg' : '-'),
                          StatColumn(label: '목표', value: user.dailyGoalCalories != null ? '${user.dailyGoalCalories}kcal' : '-'),
                        ],
                      ),
                      if (user.activityLevel != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '활동 수준: ${ActivityLevel.label(user.activityLevel!)}',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                      const Divider(height: AppSpacing.xl),
                      if (user.email != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('로그인 이메일', style: textTheme.labelMedium),
                            Text(user.email!, style: textTheme.bodyMedium),
                          ],
                        )
                      // 1.0.0에서 ID로만 가입한 계정 — 이 ID가 유일한 로그인 수단이라 복사할 수
                      // 있게 두고, 이메일 로그인으로 옮겨갈 수 있는 버튼을 함께 보여준다.
                      else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('로그인 ID', style: textTheme.labelMedium),
                                SelectableText(user.id, style: textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'ID 복사',
                            icon: const Icon(Icons.copy_outlined),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: user.id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('로그인 ID를 복사했어요.')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton.tonalIcon(
                        onPressed: () => _showLinkSheet(context),
                        icon: const Icon(Icons.mail_outline),
                        label: const Text('이메일 로그인 설정하기'),
                      ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // 외곽선 버튼 두 개를 세로로 쌓으면 설정 항목이 아니라 주요 동작처럼
                // 보인다 — 카드 하나 안의 목록 행으로 두고, 로그아웃만 색으로 구분한다.
                // (접근권한 고지는 최초 실행 때 한 번 뜨지만, 가이드라인이 언제든 다시
                // 확인할 수 있도록 요구해서 여기에도 둔다.)
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () => context.push('/permissions'),
                        leading: const Icon(Icons.shield_outlined),
                        title: const Text('앱 접근권한 안내'),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                      ),
                      Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
                      ListTile(
                        onTap: () => context.read<AuthProvider>().logout(),
                        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                        title: Text(
                          '로그아웃',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showEditSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _EditProfileSheet(authProvider: context.read<AuthProvider>(), user: user),
    );
  }

  void _showLinkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _LinkCredentialsSheet(authProvider: context.read<AuthProvider>()),
    );
  }
}

/// `PUT /users/me/credentials` — moves an ID-only (1.0.0) account to
/// email+password login.
class _LinkCredentialsSheet extends StatefulWidget {
  final AuthProvider authProvider;

  const _LinkCredentialsSheet({required this.authProvider});

  @override
  State<_LinkCredentialsSheet> createState() => _LinkCredentialsSheetState();
}

class _LinkCredentialsSheetState extends State<_LinkCredentialsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final ok = await widget.authProvider.linkCredentials(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('이제 이메일로 로그인할 수 있어요.')));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(widget.authProvider.errorMessage ?? '설정에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이메일 로그인 설정', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text('설정 후에는 ID 대신 이메일과 비밀번호로 로그인해요.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: '이메일'),
              validator: Validators.email,
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호', helperText: '8자 이상'),
              validator: Validators.password,
            ),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호 확인'),
              validator: (v) => v != _passwordController.text ? '비밀번호가 일치하지 않습니다' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('설정하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final AuthProvider authProvider;
  final User user;

  const _EditProfileSheet({required this.authProvider, required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _ageController = TextEditingController(text: widget.user.age?.toString() ?? '');
  late final _heightController = TextEditingController(text: widget.user.height?.toString() ?? '');
  late final _weightController = TextEditingController(text: widget.user.weight?.toString() ?? '');
  late final _goalController = TextEditingController(text: widget.user.dailyGoalCalories?.toString() ?? '');
  late String _activityLevel = widget.user.activityLevel ?? ActivityLevel.sightseeing;
  bool _saving = false;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final ok = await widget.authProvider.updateProfile({
      'age': int.parse(_ageController.text),
      'height': double.parse(_heightController.text),
      'weight': double.parse(_weightController.text),
      'activity_level': _activityLevel,
      'daily_goal_calories': int.parse(_goalController.text),
    });

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.authProvider.errorMessage ?? '수정에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정보 수정', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: '나이'),
              keyboardType: TextInputType.number,
              validator: (v) => (int.tryParse(v ?? '') == null) ? '숫자를 입력하세요' : null,
            ),
            TextFormField(
              controller: _heightController,
              decoration: const InputDecoration(labelText: '키 (cm)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (double.tryParse(v ?? '') == null) ? '숫자를 입력하세요' : null,
            ),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: '몸무게 (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (double.tryParse(v ?? '') == null) ? '숫자를 입력하세요' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _activityLevel,
              decoration: const InputDecoration(labelText: '활동 수준'),
              items: ActivityLevel.values
                  .map((v) => DropdownMenuItem(value: v, child: Text(ActivityLevel.label(v))))
                  .toList(),
              onChanged: (v) => setState(() => _activityLevel = v!),
            ),
            TextFormField(
              controller: _goalController,
              decoration: const InputDecoration(labelText: '목표 칼로리 (kcal)'),
              keyboardType: TextInputType.number,
              validator: (v) => (int.tryParse(v ?? '') == null) ? '숫자를 입력하세요' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
