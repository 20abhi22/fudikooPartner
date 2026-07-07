import 'package:flutter/widgets.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';

typedef ResponsiveWidgetBuilder =
    Widget Function(BuildContext context, BoxConstraints constraints);

class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder mobile;
  final ResponsiveWidgetBuilder tablet;
  final ResponsiveWidgetBuilder desktop;
  final double? breakpointWidth;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
    this.breakpointWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = breakpointWidth ?? constraints.maxWidth;

        if (Breakpoints.isDesktop(width)) {
          return desktop(context, constraints);
        }

        if (Breakpoints.isTablet(width)) {
          return tablet(context, constraints);
        }

        return mobile(context, constraints);
      },
    );
  }
}
