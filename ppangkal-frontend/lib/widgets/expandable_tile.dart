import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A header row that toggles its body open/closed. Used where a card holds
/// several records that are each worth a glance but not worth the vertical
/// space when expanded (통계's 빵집 기록, 지난 투어 리포트).
///
/// Deliberately not Material's `ExpansionTile`: that one draws its own
/// dividers, insets and `ListTile` paddings, which fight the [GlassCard]
/// layout these sit inside.
class ExpandableTile extends StatefulWidget {
  final String title;

  /// Small line under the title — visible whether open or closed, so the
  /// collapsed row still says when/where.
  final String? subtitle;

  /// Right-aligned summary (총 kcal, 밸런스 …) that stays readable collapsed.
  final Widget? trailing;

  final Widget child;
  final bool initiallyExpanded;

  const ExpandableTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<ExpandableTile> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: textTheme.titleSmall),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(widget.subtitle!, style: textTheme.labelSmall),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  widget.trailing!,
                ],
                const SizedBox(width: AppSpacing.xs),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    semanticLabel: _expanded ? '접기' : '펼치기',
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SizedBox(width: double.infinity, child: widget.child),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}
