import 'package:flutter/material.dart';

/// Wagfound responsive breakpoints — used across the whole app so every
/// section adapts consistently instead of each page picking its own rules.
class Breakpoints {
  static const mobile = 600.0;
  static const tablet = 1024.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;

  /// Content is centered and capped in width on large screens so text
  /// lines and cards don't stretch edge-to-edge on a wide monitor.
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w > 1280 ? 1280 : w;
  }

  /// Pet-grid column count. A fixed maxCrossAxisExtent alone tends to
  /// collapse to a single, oversized column on phones — this keeps two
  /// columns down to small phone widths instead.
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 420) return 2;
    if (w < mobile) return 2;
    if (w < tablet) return 3;
    if (w < 1280) return 4;
    return 5;
  }

  /// Card aspect ratio — mobile cards run slightly taller relative to
  /// width since the name/location/button stack needs the same room
  /// in a narrower card.
  static double gridChildAspectRatio(BuildContext context) {
    return isMobile(context) ? 0.62 : 0.68;
  }
}