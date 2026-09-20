import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 홈 맨 위 — 투어가 진행 중일 때만 인사말 자리를 대신한다. 투어 중인지 아닌지를
/// 카드 몇 개를 훑어보지 않고 한눈에 알아보게 하는 것이 목적이다.
///
/// 카드 전체를 앱 아이콘의 배경색으로 칠해서, 아이콘이 배너 위에 얹힌 게 아니라
/// 배너 자체가 아이콘에서 이어진 것처럼 보이게 한다. 주변 [GlassCard]들이 전부
/// 흰 계열이라 이 초록 하나만으로 "지금은 평소와 다른 상태"가 읽힌다.
class TourStartedBanner extends StatelessWidget {
  const TourStartedBanner({super.key});

  /// `assets/app_icon.png`의 배경색.
  static const Color _logoBackground = Color(0xFFD3EEC7);
  static const Color _onLogoBackground = Color(0xFF2C4A22);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassStyle>() ?? GlassStyle.standard;

    return Container(
      decoration: BoxDecoration(
        color: _logoBackground,
        borderRadius: glass.borderRadius,
        boxShadow: glass.shadows,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Image.asset('assets/app_icon.png', width: 64, height: 64),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.md, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '빵투어 진행 중',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _onLogoBackground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.directions_walk, size: 16, color: _onLogoBackground),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '걸음 수를 세고 있어요',
                          style: theme.textTheme.bodySmall?.copyWith(color: _onLogoBackground),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
