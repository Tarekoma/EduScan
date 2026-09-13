import 'package:flutter/material.dart';

enum BadgeTone { neutral, positive, warning, negative, info }

/// Small rounded status chip used across attendance and pickup UIs.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
  });

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (tone) {
      BadgeTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      BadgeTone.positive => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      BadgeTone.warning => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      BadgeTone.negative => (scheme.errorContainer, scheme.onErrorContainer),
      BadgeTone.info => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
