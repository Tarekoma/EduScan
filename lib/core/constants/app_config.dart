/// Application-wide configuration values. No business logic here — just tunables
/// that a maintainer may reasonably want to change in one place.
abstract final class AppConfig {
  static const String appName = 'EduScan';

  /// Branding tagline shown under the logo on the splash/login screens.
  static const String tagline = 'Scan Today. Brighter Tomorrow.';

  /// Shared path to the app logo (registered under `flutter.assets`).
  static const String logoAsset = 'assets/images/EduScan_app_logo.png';

  /// Responsive breakpoints (logical pixels).
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Feature flags — the core attendance workflow must keep working when these
  /// are disabled.
  static const bool pickupEnabled = true;
  static const bool parentPortalEnabled = true;
  static const bool excelEnabled = true;
}
