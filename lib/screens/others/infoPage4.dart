import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/nav/mainnav.dart';
import 'package:fudiko/utils/constants.dart';

class InfoPage4 extends StatefulWidget {
  const InfoPage4({super.key});

  @override
  State<InfoPage4> createState() => _InfoPage4State();
}

class _InfoPage4State extends State<InfoPage4> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      pushWidgetWhileRemove(newPage: const MainNavPage(), context: context);
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => const MainNavPage()),
      // );
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  double _contentMaxWidth(double width) {
    if (Breakpoints.isDesktop(width)) return 460;
    if (Breakpoints.isTablet(width)) return 440;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isMobile = Breakpoints.isMobileDevice(size);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final shouldCenterContent = isWideShortPhone || isTablet;
    final horizontalPadding = isWideShortPhone
        ? 28.0
        : isTablet
        ? 64.0
        : isMobile
        ? 40.w
        : AppDimensions.padding(width);
    final verticalPadding = isWideShortPhone
        ? 18.0
        : isTablet
        ? 32.0
        : isMobile
        ? 24.h
        : AppDimensions.margin(width);
    final contentMaxWidth = isWideShortPhone
        ? 380.0
        : isTablet
        ? 600.0
        : _contentMaxWidth(width);
    final imageSize = isWideShortPhone
        ? 96.0
        : isTablet
        ? 140.0
        : isMobile
        ? 100.w
        : 100.0;
    final imageGap = isWideShortPhone
        ? 16.0
        : isTablet
        ? 24.0
        : isMobile
        ? 20.h
        : 20.0;
    final titleGap = isWideShortPhone
        ? 8.0
        : isTablet
        ? 12.0
        : isMobile
        ? 10.h
        : 10.0;
    final titleSize = isWideShortPhone
        ? 22.0
        : isTablet
        ? 29.0
        : 25.0;
    final bodySize = isWideShortPhone
        ? 14.0
        : isTablet
        ? 17.0
        : 15.0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: shouldCenterContent
                    ? (constraints.maxHeight - (verticalPadding * 2))
                          .clamp(0.0, double.infinity)
                          .toDouble()
                    : 0,
              ),
              child: Align(
                alignment: shouldCenterContent
                    ? Alignment.center
                    : Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedCheckmark(
                        size: imageSize,
                        circleColor: const Color(0xFF34C37C),
                      ),
                      SizedBox(height: imageGap),
                      AppText(
                        text: "You're all set!",
                        size: titleSize,
                        fontWeight: FontWeight.bold,
                        isCentered: true,
                      ),
                      SizedBox(height: titleGap),
                      AppText(
                        text:
                            "Your details are under review.\nOnce approved, you’ll be able to manage \nyour orders, reach more food lovers.",
                        size: bodySize,
                        fontWeight: FontWeight.w400,
                        color: appTextColor2,
                        isCentered: true,
                        lineSpacing: 1.2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedCheckmark extends StatefulWidget {
  const AnimatedCheckmark({
    super.key,
    required this.size,
    this.circleColor = const Color(0xFF2FAE6E),
    this.checkColor = Colors.white,
    this.strokeWidthFactor = 0.11,
    this.duration = const Duration(milliseconds: 900),
  });

  final double size;
  final Color circleColor;
  final Color checkColor;
  final double strokeWidthFactor;
  final Duration duration;

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _circleScale;
  late final Animation<double> _checkDraw;
  late final Animation<double> _shadowIntensity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _circleScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 0,
              end: 1.08,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 60,
          ),
          TweenSequenceItem(
            tween: Tween<double>(
              begin: 1.08,
              end: 1,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 40,
          ),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5)),
        );
    _checkDraw = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1, curve: Curves.easeInOutCubic),
    );
    _shadowIntensity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CheckmarkPainter(
              circleScale: _circleScale.value,
              checkDraw: _checkDraw.value,
              shadowIntensity: _shadowIntensity.value,
              circleColor: widget.circleColor,
              checkColor: widget.checkColor,
              strokeWidthFactor: widget.strokeWidthFactor,
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter({
    required this.circleScale,
    required this.checkDraw,
    required this.shadowIntensity,
    required this.circleColor,
    required this.checkColor,
    required this.strokeWidthFactor,
  });

  final double circleScale;
  final double checkDraw;
  final double shadowIntensity;
  final Color circleColor;
  final Color checkColor;
  final double strokeWidthFactor;

  @override
  void paint(Canvas canvas, Size size) {
    if (circleScale <= 0) return;

    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.45;
    final scaledRadius = radius * circleScale;
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: scaledRadius));

    if (shadowIntensity > 0) {
      canvas.save();
      canvas.translate(0, size.shortestSide * 0.035 * shadowIntensity);
      canvas.drawShadow(
        circlePath,
        Colors.black.withValues(alpha: 0.35 * shadowIntensity),
        6 * shadowIntensity,
        false,
      );
      canvas.drawPath(
        circlePath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18 * shadowIntensity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * shadowIntensity),
      );
      canvas.restore();
    }

    canvas.drawPath(circlePath, Paint()..color = circleColor);
    if (checkDraw <= 0) return;

    final r = scaledRadius;
    final checkPath = Path()
      ..moveTo(center.dx - r * 0.5, center.dy + r * 0.02)
      ..lineTo(center.dx - r * 0.12, center.dy + r * 0.38)
      ..lineTo(center.dx + r * 0.55, center.dy - r * 0.32);
    final strokeWidth = size.shortestSide * strokeWidthFactor;
    final partialPath = _extractProgress(checkPath, checkDraw);

    if (shadowIntensity > 0) {
      canvas.drawPath(
        partialPath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25 * shadowIntensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * shadowIntensity),
      );
    }

    canvas.drawPath(
      partialPath,
      Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _extractProgress(Path path, double progress) {
    if (progress >= 1) return path;

    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold<double>(
      0,
      (sum, metric) => sum + metric.length,
    );
    final targetLength = totalLength * progress;
    final result = Path();
    var consumed = 0.0;

    for (final metric in metrics) {
      if (consumed >= targetLength) break;
      final remaining = targetLength - consumed;
      final take = remaining.clamp(0, metric.length).toDouble();
      result.addPath(metric.extractPath(0, take), Offset.zero);
      consumed += metric.length;
    }

    return result;
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.circleScale != circleScale ||
        oldDelegate.checkDraw != checkDraw ||
        oldDelegate.shadowIntensity != shadowIntensity ||
        oldDelegate.circleColor != circleColor ||
        oldDelegate.checkColor != checkColor ||
        oldDelegate.strokeWidthFactor != strokeWidthFactor;
  }
}
