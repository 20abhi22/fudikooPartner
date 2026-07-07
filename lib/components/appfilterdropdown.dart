import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';

class AppFilterDropDown extends StatefulWidget {
  final List<String>? items;
  final String hint;
  final IconData? icon;
  final String? iconImage;
  final IconData? suffixIcon;
  final Color? textColor;
  final double? height;
  final FutureOr<void> Function()? toogleDropdown;
  final double? fieldBorderRadius;
  final Function(String)? onChanged;

  const AppFilterDropDown({
    super.key,
    this.items,
    required this.hint,
    this.icon,
    this.iconImage,
    this.suffixIcon,
    this.textColor,
    this.height,
    this.toogleDropdown,
    this.fieldBorderRadius,
    this.onChanged,
  });

  @override
  State<AppFilterDropDown> createState() => _AppFilterDropDownState();
}

class _AppFilterDropDownState extends State<AppFilterDropDown> {
  String? selectedValue;
  bool isOpen = false;

  void selectItem(String value) {
    if (selectedValue == value) {
      closeDropdown();
      return;
    }

    setState(() {
      selectedValue = value;
      isOpen = false;
    });
    widget.onChanged?.call(value);
  }

  Future<void> toggleDropdown() async {
    final hasInlineItems = widget.items != null && widget.items!.isNotEmpty;

    if (hasInlineItems) {
      setState(() {
        isOpen = !isOpen;
      });
      widget.toogleDropdown?.call();
      return;
    }

    if (isOpen) {
      closeDropdown();
      return;
    }

    setState(() {
      isOpen = true;
    });

    await Future<void>.value(widget.toogleDropdown?.call());

    if (!mounted) return;
    setState(() {
      isOpen = false;
    });
  }

  void closeDropdown() {
    if (!isOpen) return;

    setState(() {
      isOpen = false;
    });
  }

  double _dropdownWidth(BuildContext context, BoxConstraints constraints) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final usesTabletLayout = _usesTabletLayout(size);
    final labels = <String>[
      widget.hint,
      if (selectedValue != null) selectedValue!,
      ...?widget.items,
    ];
    final appTextSize = _responsiveFontSize(12, size);
    final textStyle = TextStyle(
      fontSize: _renderedAppTextFontSize(appTextSize, size),
      fontWeight: FontWeight.w500,
    );
    final maxTextWidth = labels
        .map((label) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: textStyle),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();
          return painter.width;
        })
        .fold<double>(
          0,
          (maxWidth, width) => width > maxWidth ? width : maxWidth,
        );

    final hasLeading = widget.icon != null || widget.iconImage != null;
    final leadingWidth = hasLeading
        ? _scaled(20, size) + _scaled(8, size)
        : 0.0;
    final arrowWidth = _scaled(15, size) + _scaled(8, size);
    final horizontalPadding = _scaled(24, size);
    final minWidth = _scaled(110, size);
    final screenMaxWidth =
        screenWidth - (usesTabletLayout ? 40 : 40.w);
    final parentMaxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : screenMaxWidth;
    final maxWidth = parentMaxWidth.clamp(minWidth, screenMaxWidth);

    return (maxTextWidth + leadingWidth + arrowWidth + horizontalPadding).clamp(
      minWidth,
      maxWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => closeDropdown(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = MediaQuery.sizeOf(context);
          final height = _responsiveHeight(size);
          final radius = _responsiveRadius(size);
          final horizontalPadding = _scaled(12, size);
          final iconSize = _scaled(20, size);
          final arrowSize = _scaled(15, size);
          final gap = _scaled(8, size);

          return SizedBox(
            width: _dropdownWidth(context, constraints),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: toggleDropdown,
                  child: Container(
                    height: height,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (widget.icon != null || widget.iconImage != null) ...[
                          SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: _buildLeadingIcon(iconSize),
                          ),
                          SizedBox(width: gap),
                        ],
                        Expanded(
                          child: Center(
                            child: AppText(
                              text: selectedValue ?? widget.hint,
                              size: _responsiveFontSize(12, size),
                              color: widget.textColor ?? Colors.black87,
                              fontWeight: FontWeight.w500,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: gap),
                        AnimatedRotation(
                          turns: isOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          child: Icon(
                            widget.suffixIcon ?? Icons.keyboard_arrow_down,
                            size: arrowSize,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child:
                      isOpen && widget.items != null && widget.items!.isNotEmpty
                      ? Container(
                          margin: EdgeInsets.only(top: gap),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(radius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: widget.items!
                                .map(
                                  (item) => GestureDetector(
                                    onTap: () => selectItem(item),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: horizontalPadding,
                                        vertical: _scaled(12, size),
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.withValues(
                                              alpha: 0.2,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: AppText(
                                              text: item,
                                              size: _responsiveFontSize(12, size),
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w400,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (selectedValue == item)
                                            Icon(
                                              Icons.check,
                                              size: _scaled(16, size),
                                              color: Colors.green,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeadingIcon(double iconSize) {
    if (widget.iconImage != null) {
      return Image.asset(
        widget.iconImage!,
        height: iconSize,
        width: iconSize,
        fit: BoxFit.contain,
      );
    }

    if (widget.icon != null) {
      return Icon(widget.icon, size: iconSize, color: Colors.black87);
    }

    return const SizedBox.shrink();
  }

  bool _usesTabletLayout(Size size) {
    return Breakpoints.isTablet(size.width) ||
        (Breakpoints.isMobile(size.width) &&
            size.width >= 500 &&
            size.height <= 760);
  }

  double _responsiveHeight(Size size) {
    final height = widget.height ?? 45;
    if (Breakpoints.isMobile(size.width) && !_usesTabletLayout(size)) {
      return height.h;
    }
    return height;
  }

  double _responsiveRadius(Size size) {
    final radius = widget.fieldBorderRadius ?? 12;
    if (Breakpoints.isMobile(size.width) && !_usesTabletLayout(size)) {
      return radius.r;
    }
    return radius;
  }

  double _responsiveFontSize(double baseSize, Size size) {
    if (Breakpoints.isDesktop(size.width)) return baseSize * 1.04;
    // Make tablet text slightly smaller than base to improve fit
    if (_usesTabletLayout(size)) return baseSize * 0.9;
    return baseSize.sp;
  }

  double _renderedAppTextFontSize(double appTextSize, Size size) {
    if (Breakpoints.isDesktop(size.width)) return appTextSize * 1.08;
    if (Breakpoints.isTablet(size.width)) return appTextSize * 1.04;
    return appTextSize.sp;
  }

  double _scaled(double value, Size size) {
    if (Breakpoints.isMobile(size.width) && !_usesTabletLayout(size)) {
      return value.w;
    }
    return value;
  }
}
