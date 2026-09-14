import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../theme/app_theme.dart';

/// Standard error placeholder. Shows [ApiException.message] — already a
/// user-presentable Korean sentence per `core/api_exception.dart` — plus an
/// optional retry action.
class ErrorView extends StatelessWidget {
  final ApiException error;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ],
        ),
      ),
    );
  }
}
