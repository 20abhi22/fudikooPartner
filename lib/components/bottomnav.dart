import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';

class Bottomnav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final bool banquetEnabled;
  final bool cateringEnabled;
  final bool takeawayEnabled;

  const Bottomnav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.banquetEnabled = true,
    this.cateringEnabled = true,
    this.takeawayEnabled = true,
  });

  static const _activeColor = Color(0xFFC95F05);
  static const _inactiveColor = Color.fromARGB(255, 70, 68, 68);

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'label': 'Reservation',
        'icon': 'assets/icons/tabs/reservation_icon.png',
        'badge': 2,
      },
      {
        'label': 'Banquet',
        'icon': 'assets/icons/tabs/banquet_icon.png',
        'badge': 1,
        'enabled': banquetEnabled,
      },
      {
        'label': 'Offers',
        'icon': 'assets/icons/tabs/offers_icon.png',
        'badge': 0,
      },
      {
        'label': 'Catering',
        'icon': 'assets/icons/tabs/catering_icon.png',
        'badge': 0,
        'enabled': cateringEnabled,
      },
      {
        'label': 'Take Away',
        'icon': 'assets/icons/tabs/takeaway_icon.png',
        'badge': 0,
        'enabled': takeawayEnabled,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000), // 25% opacity black
            offset: Offset(0, 0),
            blurRadius: 35,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == selectedIndex;
          final badge = item['badge'] as int;
          final isEnabled = item['enabled'] as bool? ?? true;

          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        !isEnabled
                            ? Colors.grey.shade300
                            : isSelected
                            ? _activeColor
                            : _inactiveColor,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        item['icon'] as String,
                        width: 30.w,
                        height: 30.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 20.w,
                            minHeight: 20.h,
                          ),
                          child: Center(
                            child: Text(
                              '$badge',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                AppText(
                  size: 12.sp,
                  text: item['label'] as String,
                  color: !isEnabled
                      ? Colors.grey.shade300
                      : isSelected
                      ? _activeColor
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // import 'package:flutter/material.dart';
  // import 'package:flutter_screenutil/flutter_screenutil.dart';

  // class Bottomnav extends StatelessWidget {
  //   final int selectedIndex;
  //   final Function(int) onTabSelected;

  //   const Bottomnav({
  //     super.key,
  //     required this.selectedIndex,
  //     required this.onTabSelected,
  //   });

  //   @override
  //   Widget build(BuildContext context) {
  //     final items = [
  //       {'label': 'Reservation', 'icon': Icons.calendar_today_outlined, 'badge': 2},
  //       {'label': 'Banquet', 'icon': Icons.wine_bar, 'badge': 1},
  //       {'label': 'Offers', 'icon': Icons.percent, 'badge': 0},
  //       {'label': 'Take Away', 'icon': Icons.delivery_dining, 'badge': 0},
  //       {'label': 'Profile', 'icon': Icons.person, 'badge': 0},
  //     ];

  //     return Container(
  //       padding:  EdgeInsets.symmetric(vertical: 10.h),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         boxShadow: [
  //           BoxShadow(color: Colors.black12, blurRadius: 50, offset: Offset.zero),
  //         ],
  //       ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceAround,
  //         children: items.asMap().entries.map((entry) {
  //           final index = entry.key;
  //           final item = entry.value;
  //           final isSelected = index == selectedIndex;

  //           return GestureDetector(
  //             onTap: () => onTabSelected(index),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Stack(
  //                   clipBehavior: Clip.none,
  //                   children: [
  //                     Icon(
  //                       item['icon'] as IconData,
  //                       size: 28.w,
  //                       color: isSelected ? Colors.orange : Colors.grey[700],
  //                     ),
  //                     if ((item['badge'] as int) > 0)
  //                       Positioned(
  //                         top: -6,
  //                         right: -6,
  //                         child: Container(
  //                           padding: const EdgeInsets.all(4),
  //                           decoration: const BoxDecoration(
  //                             color: Colors.red,
  //                             shape: BoxShape.circle,
  //                           ),
  //                           constraints:  BoxConstraints(
  //                             minWidth: 20.w,
  //                             minHeight: 20.h,
  //                           ),
  //                           child: Center(
  //                             child: Text(
  //                               '${item['badge']}',
  //                               style:  TextStyle(
  //                                 color: Colors.white,
  //                                 fontSize: 12.sp,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                   ],
  //                 ),
  //                  SizedBox(height: 4.h),
  //                 Text(
  //                   item['label'] as String,
  //                   style: TextStyle(
  //                     color: isSelected ? Colors.orange : Colors.grey[700],
  //                     fontWeight: isSelected
  //                         ? FontWeight.bold
  //                         : FontWeight.normal,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //     );
  //   }
  // }
}
