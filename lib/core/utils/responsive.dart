import 'package:flutter/widgets.dart';

import '../constants/app_config.dart';

enum ScreenSize { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize {
    final width = MediaQuery.sizeOf(this).width;
    if (width < AppConfig.mobileBreakpoint) return ScreenSize.mobile;
    if (width < AppConfig.tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;
}

/// Picks a value based on the current screen size. [tablet] and [desktop]
/// fall back to smaller values when omitted.
T responsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  return switch (context.screenSize) {
    ScreenSize.mobile => mobile,
    ScreenSize.tablet => tablet ?? mobile,
    ScreenSize.desktop => desktop ?? tablet ?? mobile,
  };
}
