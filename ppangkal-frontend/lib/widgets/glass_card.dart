import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Marks that a [GlassCard] ancestor already applied a `BackdropFilter`.
/// Nested `BackdropFilter`s are expensive — each one re-blurs everything
/// beneath it, including the already-blurred layer below — so a nested
/// [GlassCard] detects this scope and skips its own filter, falling back
/// to a plain translucent fill instead.
class _GlassScope extends InheritedWidget {
  const _GlassScope({required super.child});

  static bool isInside(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<_GlassScope>() != null;
  }

  @override
  bool updateShouldNotify(_GlassScope oldWidget) => false;
}

/// Glassmorphism card — translucent blurred background, soft shadow,
/// rounded corners. Every visual value comes from [GlassStyle]
/// (`Theme.of(context).extension<GlassStyle>()`) — screens should use this
/// widget instead of styling a `Container` directly, and should never nest
/// one `GlassCard` inside another's blurred area (see [_GlassScope]).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<GlassStyle>() ?? GlassStyle.standard;
    final surfaceColor = Theme.of(context).colorScheme.surface.withValues(alpha: style.backgroundOpacity);

    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: style.borderRadius,
        border: Border.all(color: style.borderColor, width: style.borderWidth),
        boxShadow: style.shadows,
      ),
      child: child,
    );

    if (_GlassScope.isInside(context)) {
      return decorated;
    }

    return _GlassScope(
      child: ClipRRect(
        borderRadius: style.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: style.blurSigma, sigmaY: style.blurSigma),
          child: decorated,
        ),
      ),
    );
  }
}
