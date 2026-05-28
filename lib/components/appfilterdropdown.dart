import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';

class AppFilterDropDown extends StatefulWidget {
  final List<String>? items;
  final String hint;
  final IconData? icon;
  final String? iconImage;
  final IconData? suffixIcon;
  final Color? textColor;
  final double? height;
  final VoidCallback? toogleDropdown;
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
  _AppFilterDropDownState createState() => _AppFilterDropDownState();
}

class _AppFilterDropDownState extends State<AppFilterDropDown> {
  String? selectedValue;
  bool isOpen = false;


  void selectItem(String value) {
    setState(() {
      selectedValue = value;
      isOpen = false;
    });
    widget.onChanged?.call(value);
  }

  void toggleDropdown() {
    setState(() {
      isOpen = !isOpen;
    });
    widget.toogleDropdown?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: toggleDropdown,
          child: Container(
            height: widget.height?.h ?? 45.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.fieldBorderRadius ?? 12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.icon != null)
                  Positioned(
                    left: 12.w,
                    child: widget.iconImage != null
                        ? Image.asset(
                            widget.iconImage!,
                            height: 20.w,
                            width: 20.w,
                          )
                        : Icon(widget.icon, size: 20.w, color: Colors.black87),
                  ),

                Center(
                  child: AppText(
                    text: selectedValue ?? widget.hint,
                    size: 12,
                    color: widget.textColor ?? Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                Positioned(
                  right: 12.w,
                  child: Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 15.w,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOpen && widget.items != null && widget.items!.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppText(
                                text: item,
                                size: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (selectedValue == item)
                              Icon(
                                Icons.check,
                                size: 16.w,
                                color: Colors.green,
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
