import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/screens/others/nav/mainnav.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  String selectedLanguage = TranslatorService.currentLanguage == 'ar'
      ? "Arabic"
      : "English";

  bool _isWideShortPhone(BuildContext context) {
    return Breakpoints.isWideShortPhone(MediaQuery.sizeOf(context));
  }

  EdgeInsetsGeometry _pagePadding(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    if (_isWideShortPhone(context)) return EdgeInsets.zero;
    final isMobile = Breakpoints.isMobileDevice(size);
    return EdgeInsets.symmetric(
      horizontal: isMobile ? 0 : AppDimensions.padding(width),
    );
  }

  void _changeLanguage(String language, String langCode) async {
    setState(() => selectedLanguage = language);
    await TranslatorService.setLanguage(langCode);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavPage()),
      (route) => false,
    );
  }

  Widget _buildLanguageTile(String language, String langCode) {
    final size = MediaQuery.sizeOf(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final bool isSelected = selectedLanguage == language;

    return GestureDetector(
      onTap: () => _changeLanguage(language, langCode),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? appLangBg : Colors.transparent,
        ),
        padding: EdgeInsets.symmetric(
          vertical: isWideShortPhone
              ? 16.0
              : isMobile
              ? 20.h
              : 20.0,
        ),
        child: Center(
          child: AppText(
            text: language,
            size: 15,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : appTextColor3,
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
    final topPadding = isWideShortPhone
        ? 20.0
        : isMobile
        ? 40.h
        : 28.0;
    final headerGap = isWideShortPhone
        ? 28.0
        : isMobile
        ? 60.h
        : 48.0;
    final backIconSize = isWideShortPhone
        ? 24.0
        : isMobile
        ? 28.w
        : 28.0;

    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.only(
          top: (isTablet || isWideShortPhone) ? 12.0 : 0.0,
        ),
        child: Padding(
          padding: _pagePadding(context),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
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
              const Divider(thickness: 1, color: Colors.grey, height: 1),
              _buildLanguageTile("English", "en"),
              const Divider(thickness: 1, color: Colors.grey, height: 1),
              _buildLanguageTile("Arabic", "ar"),
              const Divider(thickness: 1, color: Colors.grey, height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
