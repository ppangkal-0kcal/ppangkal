import 'package:flutter/material.dart';

import '../widgets/empty_view.dart';

/// Placeholder for bottom-tab destinations that don't have a real screen
/// yet (통계/마이페이지) — swap for the real screen when it's built.
class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const EmptyView(message: '준비 중입니다.', icon: Icons.construction_outlined),
    );
  }
}
