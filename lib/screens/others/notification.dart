import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appswitch.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/notification/notification-settings-model.dart';
import 'package:fudiko/services/notification-settings-service.dart';
import 'package:fudiko/utils/constants.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  NotificationSettingsModel? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  final NotificationSettingsService _service = NotificationSettingsService();

  bool _isWideShortPhone(BuildContext context) {
    return Breakpoints.isWideShortPhone(MediaQuery.sizeOf(context));
  }

  EdgeInsetsGeometry _pagePadding(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    if (_isWideShortPhone(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    }
    final isMobile = Breakpoints.isMobileDevice(size);
    return EdgeInsets.symmetric(
      horizontal: isMobile ? 20.w : AppDimensions.padding(width),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final settings = await _service.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;
    setState(() => _isSaving = true);
    try {
      final success = await _service.saveSettings(_settings!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Settings updated" : "Failed to update"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving settings")));
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = _isWideShortPhone(context);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final topPadding = isWideShortPhone
        ? 20.0
        : isMobile
        ? 40.h
        : 28.0;
    final backIconSize = isWideShortPhone
        ? 24.0
        : isMobile
        ? 28.w
        : 28.0;
    final headerGap = isWideShortPhone
        ? 28.0
        : isMobile
        ? 60.h
        : 48.0;
    final rowVerticalPadding = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.h
        : 14.0;
    final dividerHeight = isWideShortPhone
        ? 16.0
        : isMobile
        ? 20.0
        : 18.0;

    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.only(
          top: (isTablet || isWideShortPhone) ? 12.0 : 0.0,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: topPadding,
                          left: isWideShortPhone
                              ? 24.0
                              : isMobile
                              ? 30.w
                              : AppDimensions.padding(width),
                          right: isWideShortPhone
                              ? 24.0
                              : isMobile
                              ? 20.w
                              : AppDimensions.padding(width),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                appTextColor3,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/images/backarrow_icon.png',
                                width: backIconSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: headerGap),
                    Divider(
                      color: appTextColor,
                      thickness: 1,
                      height: dividerHeight,
                    ),
                    _NotificationSettingRow(
                      padding: _pagePadding(
                        context,
                      ).add(EdgeInsets.symmetric(vertical: rowVerticalPadding)),
                      title: "Remind new orders in every",
                      subtitle: "10 Minutes",
                      value: _settings?.remindOrdersIn10Mins ?? false,
                      onToggle: (val) {
                        setState(() => _settings!.remindOrdersIn10Mins = val);
                        _saveSettings();
                      },
                    ),
                    Divider(
                      color: appTextColor,
                      thickness: 1,
                      height: dividerHeight,
                    ),
                    _NotificationSettingRow(
                      padding: _pagePadding(
                        context,
                      ).add(EdgeInsets.symmetric(vertical: rowVerticalPadding)),
                      title: "Party Order Notification",
                      value: _settings?.partyOrders ?? false,
                      onToggle: (val) {
                        setState(() => _settings!.partyOrders = val);
                        _saveSettings();
                      },
                    ),
                    Divider(
                      color: appTextColor,
                      thickness: 1,
                      height: dividerHeight,
                    ),
                    _NotificationSettingRow(
                      padding: _pagePadding(
                        context,
                      ).add(EdgeInsets.symmetric(vertical: rowVerticalPadding)),
                      title: "Remind the confirmed orders",
                      subtitle: "before 30 minutes",
                      value: _settings?.remindConfirmedOrders ?? false,
                      onToggle: (val) {
                        setState(() => _settings!.remindConfirmedOrders = val);
                        _saveSettings();
                      },
                    ),
                    Divider(
                      color: appTextColor,
                      thickness: 1,
                      height: dividerHeight,
                    ),
                    if (_isSaving)
                      Padding(
                        padding: EdgeInsets.only(
                          top: isWideShortPhone
                              ? 14.0
                              : isMobile
                              ? 20.h
                              : 20.0,
                        ),
                        child: const CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _NotificationSettingRow extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onToggle;

  const _NotificationSettingRow({
    required this.padding,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: title,
                  size: 15,
                  fontWeight: FontWeight.w500,
                  color: appTextColor3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  AppText(
                    text: subtitle!,
                    size: 15,
                    color: appTextColor3,
                    fontWeight: FontWeight.w500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(width: AppDimensions.gap(MediaQuery.sizeOf(context).width)),
          AppSwitch(initialValue: value, onToggle: onToggle),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fudiko/components/appswitch.dart';
// import 'package:fudiko/components/apptext.dart';
// import 'package:fudiko/utils/constants.dart';

// class NotificationPage extends StatelessWidget {
//   const NotificationPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           GestureDetector(
//             onTap: (){
//               Navigator.pop(context);
//             },
//             child: Padding(
//               padding:  EdgeInsets.only(top: 40.h,left: 30.w),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   Icon(
//                     Icons.arrow_back_ios_outlined,
//                     size: 30.w,
//                     color: appTextColor3,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           SizedBox(height: 60.h),
//           Divider(color: appTextColor, thickness: 1, height: 20),
//           Padding(
//             padding:  EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     AppText(
//                       text: "Remind new orders in every",
//                       size: 15,
//                       fontWeight: FontWeight.w500,
//                       color: appTextColor3,
//                     ),
//                     AppText(
//                       text: "10 Minutes",
//                       size: 15,
//                       color: appTextColor3,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ],
//                 ),
//                 AppSwitch(initialValue: true, onToggle: (val) {}),
//               ],
//             ),
//           ),
//           Divider(color: appTextColor, thickness: 1, height: 20),
//           Padding(
//             padding:  EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 AppText(
//                   text: "Party Order Notification",
//                   size: 15,
//                   fontWeight: FontWeight.w500,
//                   color: appTextColor3,
//                 ),
//                 AppSwitch(initialValue: true, onToggle: (val) {}),
//               ],
//             ),
//           ),
//           Divider(color: appTextColor, thickness: 1, height: 20),
//           Padding(
//             padding:  EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     AppText(
//                       text: "Remind the confirmed orders",
//                       size: 15,
//                       fontWeight: FontWeight.w500,
//                       color: appTextColor3,
//                     ),
//                     AppText(
//                       text: "before 30 minutes ",
//                       size: 15,
//                       color: appTextColor3,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ],
//                 ),
//                 AppSwitch(initialValue: true, onToggle: (val) {}),
//               ],
//             ),
//           ),
//           Divider(color: appTextColor, thickness: 1, height: 20),

//         ],
//       ),
//     );
//   }
// }
