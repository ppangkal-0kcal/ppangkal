import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/activity_level.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
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
      appBar: AppBar(title: const Text('마이페이지')),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatColumn(label: '키', value: user.height != null ? '${user.height!.toStringAsFixed(0)}cm' : '-'),
                          StatColumn(label: '체중', value: user.weight != null ? '${user.weight!.toStringAsFixed(0)}kg' : '-'),
                          StatColumn(label: '목표', value: user.dailyGoalCalories != null ? '${user.dailyGoalCalories}kcal' : '-'),
                        ],
                      ),
                      if (user.activityLevel != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('활동 수준: ${user.activityLevel}', style: textTheme.bodyMedium),
                      ],
                      const Divider(height: AppSpacing.xl),
                      // 비밀번호 없는 MVP 로그인이라 이 ID가 곧 로그인 수단 —
                      // 잃어버리면 다시 들어올 방법이 없으므로 복사할 수 있게 노출.
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
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('로그아웃'),
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
              items: ActivityLevel.values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
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
