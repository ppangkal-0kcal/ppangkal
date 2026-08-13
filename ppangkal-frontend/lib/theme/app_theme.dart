import 'dart:ui';

import 'package:flutter/material.dart';

/// Spacing scale — screens should reach for these instead of writing raw
/// `EdgeInsets`/`SizedBox` numbers, so the whole app's rhythm can be tuned
/// from one place.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Calorie balance status (안전/주의/초과) — semantic names so call sites
/// never hardcode which literal color means what.
@immutable
class CalorieStatusColors extends ThemeExtension<CalorieStatusColors> {
  final Color safe;
  final Color warning;
  final Color over;

  const CalorieStatusColors({
    required this.safe,
    required this.warning,
    required this.over,
  });

  /// 신호등 3색. 배경이 밝은 크림 계열이라 파스텔톤은 묻혀서 안 보이므로,
  /// 셋 다 명도를 낮추고 채도를 맞춰 서로 같은 무게로 읽히게 잡았다.
  static const CalorieStatusColors brand = CalorieStatusColors(
    safe: Color(0xFF2F9E5F),
    warning: Color(0xFFE0A008),
    over: Color(0xFFD64545),
  );

  @override
  CalorieStatusColors copyWith({Color? safe, Color? warning, Color? over}) {
    return CalorieStatusColors(
      safe: safe ?? this.safe,
      warning: warning ?? this.warning,
      over: over ?? this.over,
    );
  }

  @override
  CalorieStatusColors lerp(ThemeExtension<CalorieStatusColors>? other, double t) {
    if (other is! CalorieStatusColors) return this;
    return CalorieStatusColors(
      safe: Color.lerp(safe, other.safe, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      over: Color.lerp(over, other.over, t)!,
    );
  }
}

/// Glassmorphism card styling — [GlassCard] (`lib/widgets/glass_card.dart`)
/// reads every value from here; screens never set blur/opacity/radius
/// literals directly.
@immutable
class GlassStyle extends ThemeExtension<GlassStyle> {
  final double blurSigma;
  final double backgroundOpacity;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;
  final BorderRadius borderRadius;

  const GlassStyle({
    required this.blurSigma,
    required this.backgroundOpacity,
    required this.borderColor,
    required this.borderWidth,
    required this.shadows,
    required this.borderRadius,
  });

  static const GlassStyle standard = GlassStyle(
    blurSigma: 16,
    backgroundOpacity: 0.55,
    borderColor: Color(0x33FFFFFF),
    borderWidth: 1,
    shadows: [
      BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  @override
  GlassStyle copyWith({
    double? blurSigma,
    double? backgroundOpacity,
    Color? borderColor,
    double? borderWidth,
    List<BoxShadow>? shadows,
    BorderRadius? borderRadius,
  }) {
    return GlassStyle(
      blurSigma: blurSigma ?? this.blurSigma,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      shadows: shadows ?? this.shadows,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  GlassStyle lerp(ThemeExtension<GlassStyle>? other, double t) {
    if (other is! GlassStyle) return this;
    return GlassStyle(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t) ?? blurSigma,
      backgroundOpacity: lerpDouble(backgroundOpacity, other.backgroundOpacity, t) ?? backgroundOpacity,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t) ?? borderWidth,
      shadows: t < 0.5 ? shadows : other.shadows,
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t)!,
    );
  }
}

/// Full-screen background gradient that sits behind the tab shell
/// (`lib/widgets/main_shell.dart`) — [GlassCard]'s `BackdropFilter` has
/// nothing to blur without a busy-enough layer underneath it.
@immutable
class AppBackground extends ThemeExtension<AppBackground> {
  final Gradient gradient;

  const AppBackground({required this.gradient});

  /// 위쪽은 거의 흰 크림, 아래로 갈수록 시드컬러(#E8C39E)에 수렴한다.
  /// 중간 스톱을 하나 둔 건 [GlassCard]의 `BackdropFilter`가 흐릴 만한
  /// 명암 변화를 만들어 주기 위한 것 — 2색 그라데이션은 너무 밋밋해서
  /// 유리 질감이 거의 드러나지 않는다.
  static const AppBackground brand = AppBackground(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF6EA), Color(0xFFF3D9BC), Color(0xFFE8C39E)],
    ),
  );

  @override
  AppBackground copyWith({Gradient? gradient}) => AppBackground(gradient: gradient ?? this.gradient);

  @override
  AppBackground lerp(ThemeExtension<AppBackground>? other, double t) {
    if (other is! AppBackground) return this;
    return AppBackground(gradient: Gradient.lerp(gradient, other.gradient, t) ?? gradient);
  }
}

/// App-wide [ThemeData]. Previously inlined in `main.dart`.
ThemeData buildAppTheme() {
  // 브랜드 시드컬러 — 구운 빵 껍질 색(크림/베이지). 이 한 줄만 바꾸면 전체 톤이 바뀜.
  const seedColor = Color(0xFFE8C39E);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    extensions: const [
      CalorieStatusColors.brand,
      GlassStyle.standard,
      AppBackground.brand,
    ],
  );
}
