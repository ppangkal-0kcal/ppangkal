import 'package:flutter/material.dart';

/// The app's `AppBar`: a short bar whose contents sit low inside it.
///
/// `AppBar` centres everything in `toolbarHeight`, so raising the bar to push
/// the title down also pushes the body down with it. Padding the bar's
/// contents instead moves only them: the bar stays short (so the body starts
/// higher) while the title rests half the padding lower than it otherwise
/// would.
///
/// The padding goes on the back button and the actions too — padding the
/// title alone would leave it hanging below the arrow on any pushed screen.
///
/// Every screen's `appBar:` should be one of these so titles line up from
/// page to page.
class PageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool automaticallyImplyLeading;

  /// Must stay twice the gap between [toolbarHeight] and the height the bar
  /// would need to place the title here on its own — see the class comment.
  static const double _drop = 24;
  static const double toolbarHeight = 76;

  const PageAppBar(
    this.title, {
    super.key,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final showBack = automaticallyImplyLeading && Navigator.of(context).canPop();

    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBack ? const _Dropped(child: BackButton()) : null,
      title: _Dropped(child: Text(title)),
      actions: [for (final action in actions) _Dropped(child: action)],
    );
  }
}

class _Dropped extends StatelessWidget {
  final Widget child;

  const _Dropped({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: PageAppBar._drop),
      child: child,
    );
  }
}
