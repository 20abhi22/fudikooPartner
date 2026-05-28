import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appswitch.dart';
import 'package:fudiko/components/apptext.dart';
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
    } catch (e) {
      print('Error fetching notification settings: $e');
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
        SnackBar(content: Text(success ? "Settings updated" : "Failed to update")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving settings")),
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: EdgeInsets.only(top: 40.h, left: 30.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Icon(Icons.arrow_back_ios_outlined, size: 30.w, color: appTextColor3),
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(appTextColor3, BlendMode.srcIn),
                          child: Image.asset(
                            'assets/images/backarrow_icon.png',
                            width: 28.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 60.h),
                Divider(color: appTextColor, thickness: 1, height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(text: "Remind new orders in every", size: 15, fontWeight: FontWeight.w500, color: appTextColor3),
                          AppText(text: "10 Minutes", size: 15, color: appTextColor3, fontWeight: FontWeight.w500),
                        ],
                      ),
                      AppSwitch(
                        initialValue: _settings?.remindOrdersIn10Mins ?? false,
                        onToggle: (val) {
                          setState(() => _settings!.remindOrdersIn10Mins = val);
                          _saveSettings();
                        },
                      ),
                    ],
                  ),
                ),
                Divider(color: appTextColor, thickness: 1, height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(text: "Party Order Notification", size: 15, fontWeight: FontWeight.w500, color: appTextColor3),
                      AppSwitch(
                        initialValue: _settings?.partyOrders ?? false,
                        onToggle: (val) {
                          setState(() => _settings!.partyOrders = val);
                          _saveSettings();
                        },
                      ),
                    ],
                  ),
                ),
                Divider(color: appTextColor, thickness: 1, height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(text: "Remind the confirmed orders", size: 15, fontWeight: FontWeight.w500, color: appTextColor3),
                          AppText(text: "before 30 minutes", size: 15, color: appTextColor3, fontWeight: FontWeight.w500),
                        ],
                      ),
                      AppSwitch(
                        initialValue: _settings?.remindConfirmedOrders ?? false,
                        onToggle: (val) {
                          setState(() => _settings!.remindConfirmedOrders = val);
                          _saveSettings();
                        },
                      ),
                    ],
                  ),
                ),
                Divider(color: appTextColor, thickness: 1, height: 20),
                if (_isSaving)
                  Padding(
                    padding: EdgeInsets.only(top: 20.h),
                    child: const CircularProgressIndicator(),
                  ),
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
