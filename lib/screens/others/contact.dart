import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/support/support-information-model.dart';
import 'package:fudiko/services/support-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final SupportService _supportService = SupportService();
  SupportInformationModel? _supportInformation;

  bool _isWideShortPhone(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Breakpoints.isWideShortPhone(size);
  }

  @override
  void initState() {
    super.initState();
    _loadSupportInformation();
  }

  Future<void> _loadSupportInformation() async {
    try {
      final supportInformation = await _supportService.getSupportInformation();
      if (!mounted) return;
      setState(() => _supportInformation = supportInformation);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load support information')),
      );
    }
  }

  Future<void> _launchSupportUri(Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app is available for this action')),
      );
    }
  }

  double _contentMaxWidth(double width, bool isWideShortPhone) {
    if (Breakpoints.isDesktop(width)) return 560;
    if (Breakpoints.isTabletDevice(MediaQuery.sizeOf(context)) ||
        isWideShortPhone) {
      return 520;
    }
    return double.infinity;
  }

  Widget _contactCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final size = MediaQuery.sizeOf(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final cardHeight = isWideShortPhone
        ? 64.0
        : isMobile
        ? 70.h
        : 70.0;
    final cardRadius = isWideShortPhone
        ? 12.0
        : isMobile
        ? 15.r
        : 15.0;
    final iconSize = isWideShortPhone
        ? 30.0
        : isMobile
        ? 35.w
        : 35.0;
    final textSize = isWideShortPhone
        ? 15.0
        : isMobile
        ? 16.sp
        : 16.0;
    final sideGap = isWideShortPhone
        ? 16.0
        : isMobile
        ? 20.w
        : 20.0;
    final trailingGap = isWideShortPhone
        ? 32.0
        : isMobile
        ? 50.w
        : 50.0;

    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: sideGap),
              Icon(icon, size: iconSize, color: appButtonColor),
              SizedBox(width: sideGap),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: textSize,
                      fontWeight: FontWeight.w500,
                      color: appTextColor3,
                    ),
                  ),
                ),
              ),
              SizedBox(width: trailingGap),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = _isWideShortPhone(context);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final pagePadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(width);
    final cardPadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 20.w
        : AppDimensions.padding(width);
    final backTopPadding = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.h
        : 28.0;
    final backIconSize = isWideShortPhone
        ? 24.0
        : isMobile
        ? 28.w
        : 28.0;
    final topGap = isWideShortPhone
        ? 28.0
        : isMobile
        ? 100.h
        : 84.0;
    final cardGap = isWideShortPhone
        ? 14.0
        : isMobile
        ? 20.h
        : 20.0;
    final verticalPadding = isWideShortPhone
        ? 16.0
        : isMobile
        ? 0.0
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        minimum: EdgeInsets.only(
          top: (isTablet || isWideShortPhone) ? 12.0 : 0.0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: verticalPadding),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: pagePadding,
                            right: pagePadding,
                            top: backTopPadding,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ColorFiltered(
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
                          ),
                        ),
                      ),
                      SizedBox(height: topGap),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: _contentMaxWidth(width, isWideShortPhone),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: cardPadding,
                            ),
                            child: Column(
                              children: [
                                _contactCard(
                                  context: context,
                                  icon: Icons.mail,
                                  label: 'Mail Us',
                                  onTap:
                                      _supportInformation
                                              ?.contactEmail
                                              .isNotEmpty ==
                                          true
                                      ? () => _launchSupportUri(
                                          Uri(
                                            scheme: 'mailto',
                                            path: _supportInformation!
                                                .contactEmail,
                                          ),
                                        )
                                      : null,
                                ),
                                SizedBox(height: cardGap),
                                _contactCard(
                                  context: context,
                                  icon: Icons.message,
                                  label: 'Chat with Us',
                                  onTap:
                                      _supportInformation
                                              ?.whatsappLink
                                              .isNotEmpty ==
                                          true
                                      ? () => _launchSupportUri(
                                          Uri.parse(
                                            _supportInformation!.whatsappLink,
                                          ),
                                        )
                                      : null,
                                ),
                                SizedBox(height: cardGap),
                                _contactCard(
                                  context: context,
                                  icon: Icons.phone,
                                  label: 'Contact Us',
                                  onTap:
                                      _supportInformation
                                              ?.contactUsPhone
                                              .isNotEmpty ==
                                          true
                                      ? () => _launchSupportUri(
                                          Uri(
                                            scheme: 'tel',
                                            path: _supportInformation!
                                                .contactUsPhone,
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isWideShortPhone ? 16.0 : 24.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
