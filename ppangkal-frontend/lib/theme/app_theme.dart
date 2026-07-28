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

  static const CalorieStatusColors grayscale = CalorieStatusColors(
    // TODO(design): 초록/노랑/빨강으로 교체
    safe: Color(0xFFBDBDBD),
    // TODO(design): 초록/노랑/빨강으로 교체
    warning: Color(0xFF9E9E9E),
    // TODO(design): 초록/노랑/빨강으로 교체
    over: Color(0xFF616161),
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

/// App-wide [ThemeData]. Previously inlined in `main.dart`.
ThemeData buildAppTheme() {
  // TODO(design): 팀원이 브랜드 시드컬러로 교체할 지점. 이 한 줄만 바꾸면 전체 톤이 바뀜.
  const seedColor = Color(0xFF757575);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    extensions: const [
      CalorieStatusColors.grayscale,
      GlassStyle.standard,
    ],
  );
}
