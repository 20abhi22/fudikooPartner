import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/utils/translator_service.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? bgColor1;
  final Color? bgColor2;
  final double? size;
  final IconData? icon;
  final double? borderRadius;
  final bool? isShadow;
  final FontWeight? fontWeight;
  final double? height;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor1,
    this.bgColor2,
    this.size,
    this.icon,
    this.borderRadius,
    this.isShadow,
    this.fontWeight,
    this.height,
    this.width,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  String _translated = '';

  @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(covariant AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _translate();
    }
  }

  Future<void> _translate() async {
    final sourceText = widget.text;
    final result = await TranslatorService.translate(sourceText);

    if (mounted && sourceText == widget.text) {
      setState(() {
        _translated = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final screenWidth = size.width;
        final isWideShortPhone = _isWideShortPhone(size);
        final borderRadius = _responsiveRadius(
          screenWidth,
          isWideShortPhone,
        );
        final height = _resolvedHeight(
          screenWidth,
          constraints,
          isWideShortPhone,
        );
        final buttonWidth = _resolvedWidth(
          screenWidth,
          constraints,
          isWideShortPhone,
        );

        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: height ?? 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                colors: [
                  widget.bgColor1 ?? const Color(0xFFC95F05),
                  widget.bgColor2 ?? const Color(0xFFF97A0D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: widget.isShadow == false
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: SizedBox(
              width: buttonWidth,
              height: height,
              child: TextButton(
                onPressed: widget.onPressed,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.icon == null ? 12 : 16,
                    vertical: height == null ? 10 : 0,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.icon != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: _responsiveIconSize(
                              screenWidth,
                              isWideShortPhone,
                            ),
                          ),
                        ),
                      Center(
                        child: Text(
                          _translated.isEmpty ? widget.text : _translated,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _responsiveFontSize(
                              widget.size ?? 20,
                              screenWidth,
                              isWideShortPhone,
                            ),
                            fontWeight: widget.fontWeight ?? FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isWideShortPhone(Size size) =>
      Breakpoints.isMobile(size.width) &&
      size.width >= 500 &&
      size.height <= 760;

  double _responsiveFontSize(
    double baseSize,
    double width,
    bool isWideShortPhone,
  ) {
    if (Breakpoints.isDesktop(width)) return baseSize * 1.04;
    if (Breakpoints.isTablet(width)) return baseSize * 1.08;
    if (isWideShortPhone) return baseSize * 0.88;
    return baseSize.sp;
  }

  double _responsiveIconSize(double width, bool isWideShortPhone) {
    if (Breakpoints.isDesktop(width)) return 24;
    if (Breakpoints.isTablet(width)) return 24;
    if (isWideShortPhone) return 20;
    return 25.w;
  }

  double _responsiveRadius(double width, bool isWideShortPhone) {
    final radius = widget.borderRadius ?? 20;
    if (isWideShortPhone) return radius.clamp(0, 14).toDouble();
    if (Breakpoints.isMobile(width)) return radius.r;
    return radius;
  }

  double? _resolvedHeight(
    double width,
    BoxConstraints constraints,
    bool isWideShortPhone,
  ) {
    if (widget.height != null) {
      if (isWideShortPhone) return widget.height;
      return Breakpoints.isMobile(width) ? widget.height!.h : widget.height;
    }

    if (constraints.hasTightHeight) {
      return constraints.maxHeight;
    }

    if (isWideShortPhone) return 46;
    return null;
  }

  double? _resolvedWidth(
    double width,
    BoxConstraints constraints,
    bool isWideShortPhone,
  ) {
    if (widget.width != null) {
      if (isWideShortPhone) return widget.width;
      return Breakpoints.isMobile(width) ? widget.width!.w : widget.width;
    }

    if (constraints.hasTightWidth) {
      return constraints.maxWidth;
    }

    return null;
  }
}
