import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Minus/count/plus control for adjusting a bread item's quantity
/// (`lib/screens/bread_menu_screen.dart`). [min] defaults to 0 — a bread
/// item starts unselected, not "1 by default".
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 0,
    this.max = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: quantity > min ? () => onChanged(quantity - 1) : null,
        ),
        SizedBox(
          width: AppSpacing.xl,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: quantity < max ? () => onChanged(quantity + 1) : null,
        ),
      ],
    );
  }
}
