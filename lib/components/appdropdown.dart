import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        GestureDetector(
          onTap: _toggleDropdown, // ← fix: call internal toggle
          child: Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.r),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.grey),
                  SizedBox(width: 12.w),
                ],
                Expanded(
                  child: Text(
                    selectedValue ?? widget.hint,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: selectedValue == null ? Colors.grey : Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.grey,
                  size: 40.w,
                ),
              ],
            ),
          ),
        ),

        // Dropdown list
        if (isOpen)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.r),
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
                      vertical: 14.h,
                      horizontal: 40.w,
                    ),
                    decoration: BoxDecoration(
                      border: !isLast
                          ? Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 15.sp,
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