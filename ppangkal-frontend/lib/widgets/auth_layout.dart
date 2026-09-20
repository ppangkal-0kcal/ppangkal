import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Shared frame for the login/signup screens: brand mark + title on top,
/// the form inside a [GlassCard], width-capped so it doesn't stretch
/// edge to edge on the Chrome dev target or tablets.
class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBack;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.showBack = false,
  });

  static const double _maxWidth = 420;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The designer icon is a full-bleed square (the 0-kcal badge and the
                  // knife handle run to the edges), so it's clipped to a squircle rather
                  // than a circle — a circular crop would cut both off.
                  // Center keeps the 72px mark from being stretched by the column's
                  // CrossAxisAlignment.stretch.
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/app_icon.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, textAlign: TextAlign.center, style: textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  GlassCard(child: child),
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
