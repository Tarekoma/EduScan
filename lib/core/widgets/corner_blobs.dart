import 'package:flutter/material.dart';

/// Two soft, oversized circles peeking in from opposite corners — a purely
/// decorative brand touch shared by the splash and login screens. Purely
/// presentational; carries no state or data.
class CornerBlobs extends StatelessWidget {
  const CornerBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
    return Positioned.fill(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: -70,
              left: -70,
              child: _Blob(size: 200, color: color),
            ),
            Positioned(
              bottom: -80,
              right: -80,
              child: _Blob(size: 220, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
