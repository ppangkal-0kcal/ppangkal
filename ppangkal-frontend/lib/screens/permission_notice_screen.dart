import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_permission.dart';
import '../providers/permission_notice_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

/// 앱 접근권한 사전 고지 (정보통신망법 제22조의2 / 방송미디어통신위원회
/// 「앱 접근권한 동의 가이드라인」). 최초 실행 시 로그인보다 먼저 한 번 뜨고,
/// 이후에는 마이페이지에서 다시 열 수 있다 — 가이드라인이 고지 내용을 언제든
/// 다시 확인할 수 있도록 요구한다.
///
/// 고지 내용은 [appPermissions]에서 온다. 권한을 추가하면 그 목록만 고치면 된다.
class PermissionNoticeScreen extends StatelessWidget {
  const PermissionNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final provider = context.watch<PermissionNoticeProvider>();

    // 최초 실행이면 "확인"을 눌러야 넘어가고, 마이페이지에서 다시 연 것이면
    // 그냥 닫으면 된다.
    final isFirstRun = provider.acknowledged != true;

    final required = appPermissions.where((p) => p.required).toList();
    final optional = appPermissions.where((p) => !p.required).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 접근권한 안내'),
        automaticallyImplyLeading: !isFirstRun,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Text(
                    '빵칼은 아래 기능을 위해 기기의 접근권한을 사용해요.',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '권한은 해당 기능을 처음 쓸 때 요청하고, 언제든 휴대폰 설정에서 다시 바꿀 수 있어요.',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (required.isNotEmpty) ...[
                    _GroupLabel(text: '필수적 접근권한'),
                    const SizedBox(height: AppSpacing.sm),
                    for (final permission in required)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _PermissionCard(permission: permission),
                      ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _GroupLabel(text: '선택적 접근권한'),
                  const SizedBox(height: AppSpacing.sm),
                  for (final permission in optional)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _PermissionCard(permission: permission),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  const _NoticeFooter(),
                ],
              ),
            ),
            if (isFirstRun)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: FilledButton(
                  onPressed: () {
                    // 디스크 쓰기를 기다리지 않는다 — `acknowledge()`는 상태를 먼저
                    // 동기로 바꾸고 저장은 뒤에서 한다. 저장을 기다리면 사용자가
                    // 그만큼 멈춰 서고, 실패해도 화면이 넘어가지 못한다.
                    unawaited(context.read<PermissionNoticeProvider>().acknowledge());
                    // 고지를 본 뒤에는 `/permissions`도 머물 수 있는 경로가 되므로
                    // (마이페이지에서 다시 열기 위해) redirect가 자동으로 내보내주지
                    // 않는다 — 스플래시로 보내 로그인/홈 분기를 다시 태운다.
                    GoRouter.of(context).go('/splash');
                  },
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('확인'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final AppPermission permission;

  const _PermissionCard({required this.permission});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(permission.icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(permission.name, style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(permission.purpose, style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  permission.fallback,
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeFooter extends StatelessWidget {
  const _NoticeFooter();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('알아두실 점', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          const _Bullet('필수적 접근권한은 없어요. 모두 선택 권한이라, 허용하지 않아도 빵칼을 쓸 수 있어요.'),
          const _Bullet('위치 정보는 기기 안에서만 쓰고 서버로 보내지 않아요.'),
          const _Bullet('촬영한 섭취 사진은 기기 갤러리에만 저장되고 업로드하지 않아요.'),
          const _Bullet('허용/거부는 휴대폰 설정 > 애플리케이션 > 빵칼 > 권한에서 언제든 바꿀 수 있어요.'),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('· ', style: textTheme.bodyMedium),
          Expanded(child: Text(text, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
