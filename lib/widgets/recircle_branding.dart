import 'package:flutter/material.dart';

/// Displays the supplied ReCircle logo variant for its intended surface.
class ReCircleLogo extends StatelessWidget {
  const ReCircleLogo({super.key, this.onDark = false, this.width = 140});

  final bool onDark;
  final double width;

  static const lightSurfaceAsset =
      'assets/branding/logos/recircle_logo_light.jpg';
  static const darkSurfaceAsset =
      'assets/branding/logos/recircle_logo_dark.jpg';

  @override
  Widget build(BuildContext context) => Image.asset(
    onDark ? darkSurfaceAsset : lightSurfaceAsset,
    width: width,
    fit: BoxFit.contain,
    semanticLabel: 'ReCircle — Nothing Ends. It Transforms.',
  );
}

class ReCircleBrandTitle extends StatelessWidget {
  const ReCircleBrandTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const ReCircleLogo(width: 58),
      const SizedBox(width: 8),
      Flexible(
        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}
