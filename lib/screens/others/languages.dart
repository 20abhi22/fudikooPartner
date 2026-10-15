import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';
import 'package:fudiko/widgets/app_shell.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  String selectedLanguage = TranslatorService.currentLanguage == 'ar'
      ? "Arabic"
      : "English";

  /// True while the new language is being applied across the app.
  bool _isApplying = false;

  /// Warm-up progress, 0..1.
  double _progress = 0;

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

  Future<void> _changeLanguage(String language, String langCode) async {
    if (_isApplying || selectedLanguage == language) return;

    setState(() {
      selectedLanguage = language;
      _isApplying = true;
      _progress = 0;
    });

    await TranslatorService.setLanguage(langCode);

    // Translate everything up front rather than letting each screen fetch its
    // own copy on first visit, so the app is already in the new language by
    // the time the loader clears.
    await TranslatorService.warmUp(
      langCode,
      onProgress: (value) {
        if (mounted) setState(() => _progress = value);
      },
    );

    if (!mounted) return;
    setState(() => _isApplying = false);

    // Root navigator: a nested reset would leave any surrounding shell wrapped
    // around the fresh AppShell.
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (route) => false,
    );
  }

  Widget _buildApplyingOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: appTextColor,
                    // Indeterminate until the first batch reports, so the ring
                    // never sits frozen at zero.
                    value: _progress == 0 ? null : _progress,
                  ),
                ),
                const SizedBox(height: 18),
                // Plain Text on purpose: this label must not wait on the very
                // translation pass it is reporting on.
                Text(
                  'Applying $selectedLanguage...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: appTextColor5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(_progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: appTextColor2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [language] identifies the choice internally; [nativeName] is what the
  /// tile shows.
  Widget _buildLanguageTile(
    String language,
    String nativeName,
    String langCode,
  ) {
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
          // Plain Text, not AppText: a language is named in its own script on
          // every screen of this list, so "العربية" must stay "العربية" whether
          // the app is currently in English or in Arabic.
          child: Text(
            nativeName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor3,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Leaving halfway would strand a half-translated cache on screen.
      canPop: !_isApplying,
      child: Stack(
        children: [
          _buildPage(context),
          if (_isApplying) _buildApplyingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
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
              _buildLanguageTile("English", "English", "en"),
              const Divider(thickness: 1, color: Colors.grey, height: 1),
              _buildLanguageTile("Arabic", "العربية", "ar"),
              const Divider(thickness: 1, color: Colors.grey, height: 1),
            ],
          ),
        ),
      ),
    );
  }
}
