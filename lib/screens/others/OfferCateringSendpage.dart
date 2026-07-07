import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/bottomnav.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/catering/all-enquiry-model.dart';
import 'package:fudiko/screens/others/nav/mainnav.dart';
import 'package:fudiko/services/catering-service.dart';
import 'package:fudiko/utils/constants.dart';

class OfferCateringSendPage extends StatefulWidget {
  final CateringEnquiryModel enquiry;
  const OfferCateringSendPage({super.key, required this.enquiry});

  @override
  State<OfferCateringSendPage> createState() => _OfferCateringSendPageState();
}

class _OfferCateringSendPageState extends State<OfferCateringSendPage> {
  static const int _currentTabIndex = 1;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _extraOfferController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  bool _isLoading = false;
  final CateringEnquiryService _service = CateringEnquiryService();

  void _onTabSelected(int index) {
    if (index == _currentTabIndex) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainNavPage(initialIndex: index)),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _extraOfferController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _sendOffer() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter an amount")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.offerDiscount(
        uuid: widget.enquiry.uuid,
        amount: _amountController.text,
        extraOffer: _extraOfferController.text,
        comments: _commentsController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Offer sent")),
      );
      if (result['status'] == true) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error sending offer")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final width = screenSize.width;
    final isWideShortPhone = Breakpoints.isWideShortPhone(screenSize);
    final isMobile =
        Breakpoints.isMobileDevice(screenSize) && !isWideShortPhone;
    final horizontalPadding = isWideShortPhone
        ? 28.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(width);
    final verticalPadding = isWideShortPhone
        ? 16.0
        : isMobile
        ? 40.h
        : 40.0;
    const contentMaxWidth = double.infinity;
    final backIconSize = isWideShortPhone
        ? 28.0
        : isMobile
        ? 32.w
        : 28.0;
    final titleGap = isWideShortPhone
        ? 12.0
        : isMobile
        ? 20.h
        : 20.0;
    final titleSize = isWideShortPhone
        ? 22.0
        : isMobile
        ? 24.0
        : 22.0;
    final enquiryTopGap = isWideShortPhone
        ? 24.0
        : isMobile
        ? 50.h
        : 44.0;
    final enquirySize = isWideShortPhone
        ? 18.0
        : isMobile
        ? 20.0
        : 18.0;
    final fieldTopGap = isWideShortPhone
        ? 18.0
        : isMobile
        ? 30.h
        : 28.0;
    final fieldGap = isWideShortPhone
        ? 8.0
        : isMobile
        ? 5.h
        : 8.0;
    final fieldRadius = isWideShortPhone
        ? 10.0
        : isMobile
        ? 10.r
        : 10.0;
    final fieldTextSize = 14.0;
    final commentRadius = isWideShortPhone
        ? 12.0
        : isMobile
        ? 15.r
        : 15.0;
    final commentPadding = isWideShortPhone
        ? 12.0
        : isMobile
        ? 16.w
        : 16.0;
    final commentFontSize = isWideShortPhone
        ? 13.0
        : isMobile
        ? 14.sp
        : 13.0;
    final buttonTopGap = isWideShortPhone
        ? 20.0
        : isMobile
        ? 40.h
        : 36.0;
    final buttonWidth = isWideShortPhone
        ? 140.0
        : isMobile
        ? 150.w
        : 150.0;
    final buttonHeight = isWideShortPhone
        ? 46.0
        : isMobile
        ? 50.h
        : 48.0;
    final buttonRadius = isWideShortPhone
        ? 5.0
        : isMobile
        ? 5.r
        : 5.0;

    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      bottomNavigationBar: Bottomnav(
        selectedIndex: _currentTabIndex,
        onTabSelected: _onTabSelected,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFD66C11),
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          backOrange,
                          width: backIconSize,
                          height: backIconSize,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: titleGap),
                  AppText(
                    text: "Offer a Discount!",
                    size: titleSize,
                    fontWeight: FontWeight.w600,
                    color: offerTextColor,
                    isCentered: false,
                  ),
                  SizedBox(height: enquiryTopGap),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: AppText(
                      text: widget.enquiry.enquiryId,
                      size: enquirySize,
                      fontWeight: FontWeight.w700,
                      color: appTextColor3,
                      isCentered: true,
                    ),
                  ),
                  SizedBox(height: fieldTopGap),
                  AppTextFeild(
                    fieldBorderRadius: fieldRadius,
                    text: "Your Amount",
                    isTextCenter: true,
                    iconImagePath: walletIcon,
                    iconImagecolor: banquetTagIconColor,
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    size: fieldTextSize,
                    textColor: offerPageTextColor,
                    height: isWideShortPhone ? 50.0 : null,
                  ),
                  SizedBox(height: fieldGap),
                  AppTextFeild(
                    fieldBorderRadius: fieldRadius,
                    text: "Extra offer",
                    isTextCenter: true,
                    iconImagePath: offerIcon,
                    iconImagecolor: banquetTagIconColor,
                    controller: _extraOfferController,
                    size: fieldTextSize,
                    textColor: offerPageTextColor,
                    height: isWideShortPhone ? 50.0 : null,
                  ),
                  SizedBox(height: fieldGap),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(commentRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          offset: const Offset(0, 0),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _commentsController,
                      maxLines: isWideShortPhone ? 4 : 5,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "Comments",
                        hintStyle: TextStyle(
                          color: offerPageTextColor,
                          fontSize: commentFontSize,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(commentRadius),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.all(commentPadding),
                      ),
                    ),
                  ),
                  SizedBox(height: buttonTopGap),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: buttonWidth,
                          height: buttonHeight,
                          child: AppButton(
                            size: 14,
                            borderRadius: buttonRadius,
                            text: "Send Offer",
                            onPressed: _sendOffer,
                            bgColor1: banquetOfferIconColor,
                            bgColor2: banquetOfferIconColor,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
