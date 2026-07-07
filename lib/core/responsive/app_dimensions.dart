import 'dart:math' as math;

import 'package:fudiko/core/responsive/breakpoints.dart';

class AppDimensions {
  const AppDimensions._();

  static double headline(double width) {
    if (Breakpoints.isDesktop(width)) return 34;
    if (Breakpoints.isTablet(width)) return 30;
    return 26;
  }

  static double title(double width) {
    if (Breakpoints.isDesktop(width)) return 24;
    if (Breakpoints.isTablet(width)) return 22;
    return 20;
  }

  static double body(double width) {
    if (Breakpoints.isDesktop(width)) return 17;
    if (Breakpoints.isTablet(width)) return 16;
    return 15;
  }

  static double caption(double width) {
    if (Breakpoints.isDesktop(width)) return 13;
    if (Breakpoints.isTablet(width)) return 12;
    return 11;
  }

  static double padding(double width) {
    if (Breakpoints.isDesktop(width)) return 32;
    if (Breakpoints.isTablet(width)) return 24;
    return 16;
  }

  static double gap(double width) {
    if (Breakpoints.isDesktop(width)) return 24;
    if (Breakpoints.isTablet(width)) return 20;
    return 14;
  }

  static double margin(double width) {
    if (Breakpoints.isDesktop(width)) return 40;
    if (Breakpoints.isTablet(width)) return 28;
    return 16;
  }

  static int gridColumns(double availableWidth) {
    final columns = (availableWidth / 280).floor();
    return math.max(1, math.min(columns, 6));
  }
}
