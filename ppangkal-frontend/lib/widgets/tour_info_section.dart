import 'package:flutter/material.dart';

import '../models/tour_info.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// TourAPI enrichment block for a bakery detail (`tour_info` —
/// FRONTEND_API_GUIDE.md §2 steps 2~3). The caller decides whether to show
/// this at all (skip when `tour_info` is `null` or `TourInfo.isEmpty`);
/// each row here still checks its own field for null since a populated
/// `tour_info` can still be missing individual sub-fields
/// (backend/src/routes/bakeries.routes.ts's `fetchTourInfoSafely`).
class TourInfoSection extends StatelessWidget {
  final TourInfo info;

  const TourInfoSection({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('한국관광공사 제공 정보', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (info.overview != null) ...[
            Text(info.overview!, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (info.signatureMenu != null) _InfoRow(label: '대표 메뉴', value: info.signatureMenu!),
          if (info.recommendedMenu != null) _InfoRow(label: '추천 메뉴', value: info.recommendedMenu!),
          if (info.openTime != null) _InfoRow(label: '영업시간', value: info.openTime!),
          if (info.restDate != null) _InfoRow(label: '휴무일', value: info.restDate!),
          if (info.parking != null) _InfoRow(label: '주차', value: info.parking!),
          if (info.packaging != null) _InfoRow(label: '포장', value: info.packaging!),
          if (info.tel != null) _InfoRow(label: '전화', value: info.tel!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 64, child: Text(label, style: textTheme.labelMedium)),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
