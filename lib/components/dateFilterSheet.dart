import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/utils/constants.dart';

// Standardized "date filter" bottom sheet used by Reservation/Banquet/Catering
// completed-tab filters. Compact rows, single orange accent for the selected
// option, capped height that scrolls instead of overflowing in landscape.
Future<void> showDateFilterSheet({
  required BuildContext context,
  required List<String> options,
  required String selectedValue,
  required String customValue,
  required void Function(String option) onOptionSelected,
  required Future<void> Function() onCustomTap,
  String customLabel = "Custom date range",
}) async {
  final size = MediaQuery.sizeOf(context);
  final isLandscape =
      MediaQuery.orientationOf(context) == Orientation.landscape;
  final sheetMaxHeight = size.height * (isLandscape ? 0.85 : 0.55);
  final sheetMaxWidth = isLandscape ? size.width * 0.55 : double.infinity;

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: sheetMaxHeight),
    builder: (sheetContext) => SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: sheetMaxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: isLandscape
                  ? BorderRadius.circular(20.r)
                  : BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  for (final option in options)
                    _DateFilterTile(
                      label: option,
                      isSelected: selectedValue == option,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onOptionSelected(option);
                      },
                    ),
                  _DateFilterTile(
                    label: customLabel,
                    isSelected: selectedValue == customValue,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onCustomTap();
                    },
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DateFilterTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateFilterTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: isSelected
              ? appButtonColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                text: label,
                size: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? appButtonColor : Colors.black87,
              ),
            ),
            if (isSelected) Icon(Icons.check, color: appButtonColor, size: 18),
          ],
        ),
      ),
    );
  }
}
