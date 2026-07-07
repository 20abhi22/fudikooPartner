import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';

class AppText extends StatefulWidget {
  final String text;
  final double size;
  final FontWeight fontWeight;
  final FontStyle? fontStyle;
  final Color? color;
  final bool? isCentered;
  final double? lineSpacing;
  final bool? softWrap;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText({
    super.key,
    required this.text,
    required this.size,
    required this.fontWeight,
    this.fontStyle,
    this.color,
    this.isCentered,
    this.lineSpacing,
    this.softWrap,
    this.maxLines,
    this.overflow,
  });

  @override
  State<AppText> createState() => _AppTextState();
}

class _AppTextState extends State<AppText> {
  String _translated = '';

  @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(AppText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _translate();
  }

  Future<void> _translate() async {
    final sourceText = widget.text;
    final result = await TranslatorService.translate(widget.text);

    if (mounted && sourceText == widget.text) {
      setState(() => _translated = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Text(
      _translated.isEmpty ? widget.text : _translated,
      textAlign: widget.isCentered ?? false ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontStyle: widget.fontStyle ?? FontStyle.normal,
        fontSize: _responsiveFontSize(widget.size, screenWidth),
        fontWeight: widget.fontWeight,
        color: widget.color ?? appTextColor,
        height: widget.lineSpacing ?? 1.2,
      ),
      softWrap: widget.softWrap ?? (widget.maxLines != null),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }

  double _responsiveFontSize(double baseSize, double width) {
    final fallbackBody = AppDimensions.body(width);
    final base = baseSize <= 0 ? fallbackBody : baseSize;

    if (Breakpoints.isDesktop(width)) return base * 1.08;
    if (Breakpoints.isTablet(width)) return base * 1.04;
    return base.sp;
  }
}
