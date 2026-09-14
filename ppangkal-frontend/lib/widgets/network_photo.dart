import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Bakery/bread photo from R2 (`photo_url`/`image_url`), disk-cached so a
/// phone on mobile data doesn't refetch the same images every visit. A null
/// or broken URL shows a neutral placeholder instead of an error box.
class NetworkPhoto extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final IconData placeholderIcon;

  const NetworkPhoto({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.placeholderIcon = Icons.bakery_dining_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: colorScheme.onSurfaceVariant),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: url == null
          ? placeholder
          : kIsWeb
          // The R2 bucket sends no CORS headers, which breaks Flutter web's
          // XHR image loading — fall back to a plain <img> element there.
          // Mobile doesn't care about CORS and keeps the disk cache below.
          ? Image.network(
              url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (_, _, _) => placeholder,
            )
          : CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              // Decode at display size, not the 1080px source — keeps long
              // menu lists light on memory.
              memCacheWidth: width != null ? (width! * MediaQuery.devicePixelRatioOf(context)).round() : null,
              placeholder: (_, _) => placeholder,
              errorWidget: (_, _, _) => placeholder,
            ),
    );
  }
}
