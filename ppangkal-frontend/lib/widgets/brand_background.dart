import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Paints the app-wide [AppBackground] gradient behind one page and makes
/// that page's `Scaffold` transparent so the gradient shows through.
///
/// Applied per route in `lib/router/app_router.dart`, not once around the
/// whole app: every page has to stay opaque as a unit, otherwise a pushed
/// page's transparent Scaffold would let the page underneath show through
/// during and after the transition. [GlassCard]'s `BackdropFilter` also
/// needs this layer underneath to have anything to blur.
class BrandBackground extends StatelessWidget {
  final Widget child;

  static const double maxContentWidth = 600;

  const BrandBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.extension<AppBackground>() ?? AppBackground.brand;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: background.gradient),
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        // Mobile-first layouts stretch awkwardly on the Chrome dev target
        // and tablets — cap the content column instead.
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
