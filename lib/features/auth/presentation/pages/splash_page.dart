import 'package:flutter/material.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/corner_blobs.dart';

/// Shown while [AuthCubit] resolves the initial Firebase auth state
/// (`AuthStatus.unknown`). The router already navigates away the moment that
/// resolves — there is no artificial delay here.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: Stack(
        children: [
          const CornerBlobs(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppConfig.logoAsset,
                      width: 128,
                      height: 128,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppConfig.appName,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConfig.tagline.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
