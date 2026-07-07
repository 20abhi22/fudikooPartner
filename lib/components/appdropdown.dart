import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';

class AppDropDown extends StatefulWidget {
  final List<String>? items;
  final String hint;
  final IconData? icon;
  final Color? textColor;
  final Function(String)? onChanged;

  const AppDropDown({
    super.key,
    this.items,
    required this.hint,
    this.icon,
    this.textColor,
    this.onChanged,
  });

  @override
  _AppDropDownState createState() => _AppDropDownState();
}

class _AppDropDownState extends State<AppDropDown> {
  String? selectedValue;
  bool isOpen = false;

  final List<String> _defaultItems = [
    'Restaurant',
    'Cafe',
    'Cool Bar',
    'Bar',
    'Buffet',
  ];

  List<String> get _items => widget.items ?? _defaultItems;

  void _toggleDropdown() {
    setState(() {
      isOpen = !isOpen;
    });
  }

  void _selectItem(String value) {
    setState(() {
      selectedValue = value;
      isOpen = false;
    });
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = Breakpoints.isMobile(screenWidth);
    final fieldHeight = isMobile ? 60.h : 56.0;
    final horizontalPadding = isMobile ? 40.w : 24.0;
    final radius = isMobile ? 20.r : 18.0;
    final shadowBlur = isMobile ? 10.r : 10.0;
    final shadowOffset = Offset(0, isMobile ? 4.r : 4.0);
    final iconGap = isMobile ? 12.w : 12.0;
    final arrowSize = isMobile ? 40.w : 30.0;
    final headerFontSize = isMobile ? 16.sp : 14.0;
    final itemFontSize = isMobile ? 15.sp : 14.0;
    final menuTopMargin = isMobile ? 4.h : 4.0;
    final itemVerticalPadding = isMobile ? 14.h : 13.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        GestureDetector(
          onTap: _toggleDropdown, // ← fix: call internal toggle
          child: Container(
            height: fieldHeight,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: shadowBlur,
                  offset: shadowOffset,
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.grey),
                  SizedBox(width: iconGap),
                ],
                Expanded(
                  child: Text(
                    selectedValue ?? widget.hint,
                    style: TextStyle(
                      fontSize: headerFontSize,
                      color: selectedValue == null ? Colors.grey : Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.grey,
                  size: arrowSize,
                ),
              ],
            ),
          ),
        ),

        // Dropdown list
        if (isOpen)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: menuTopMargin),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: shadowBlur,
                  offset: shadowOffset,
                ),
              ],
            ),
            child: Column(
              children: _items.map((item) {
                final isLast = item == _items.last;
                return GestureDetector(
                  onTap: () => _selectItem(item),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: itemVerticalPadding,
                      horizontal: horizontalPadding,
                    ),
                    decoration: BoxDecoration(
                      border: !isLast
                          ? Border(
                              bottom: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: itemFontSize,
                        fontWeight: selectedValue == item
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selectedValue == item
                            ? Colors.orange
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
