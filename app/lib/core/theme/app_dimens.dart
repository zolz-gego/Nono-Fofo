/// Spacing, radii and durations shared across the app.
abstract final class AppDimens {
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double radiusSm = 12;
  static const double radiusMd = 20;
  static const double radiusLg = 32;

  /// Minimum tap target for small fingers.
  static const double minTapTarget = 56;

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
}
