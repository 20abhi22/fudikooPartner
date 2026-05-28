import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/bottomnav.dart';
import 'package:fudiko/models/banquet/all-enquiry-model.dart';
import 'package:fudiko/screens/others/nav/mainnav.dart';
import 'package:fudiko/services/banquet-service.dart';
import 'package:fudiko/utils/constants.dart';

class OfferSendPage extends StatefulWidget {
  final BanquetEnquiryModel enquiry;
  const OfferSendPage({super.key, required this.enquiry});

  @override
  State<OfferSendPage> createState() => _OfferSendPageState();
}

class _OfferSendPageState extends State<OfferSendPage> {
  static const int _currentTabIndex = 1;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _extraOfferController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  bool _isLoading = false;
  final BanquetEnquiryService _service = BanquetEnquiryService();

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
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      bottomNavigationBar: Bottomnav(
        selectedIndex: _currentTabIndex,
        onTabSelected: _onTabSelected,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 40.h),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Align(
                  alignment: Alignment.topLeft,

                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Color(0xFFD66C11),
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(backOrange, width: 32.w, height: 32.h),
                  ),
                ),
                // child: Icon(
                //   Icons.arrow_back_ios,
                //   size: 25.w,
                //   color: appTextColor3,
                // ),
              ),
              SizedBox(height: 20.h),
              AppText(
                text: "Offer a Discount!",
                size: 24.sp,
                fontWeight: FontWeight.w600,
                color: offerTextColor,
                isCentered: false,
              ),
              SizedBox(height: 50.h),
              Container(
                alignment: Alignment.centerLeft,
                child: AppText(
                  text: widget.enquiry.enquiryId,
                  size: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: appTextColor3,
                  isCentered: true,
                ),
              ),
              SizedBox(height: 30.h),
              AppTextFeild(
                fieldBorderRadius: 10.r,
                text: "Your Amount",
                isTextCenter: true,
                iconImagePath: walletIcon,
                iconImagecolor: banquetTagIconColor,
                controller: _amountController,
                keyboardType: TextInputType.number,
                size: 14.sp,
                textColor: offerPageTextColor,
              ),
              SizedBox(height: 5.h),
              AppTextFeild(
                fieldBorderRadius: 10.r,
                text: "Extra offer",
                isTextCenter: true,
                iconImagePath: offerIcon,
                iconImagecolor: banquetTagIconColor,
                controller: _extraOfferController,
                size: 14.sp,
                textColor: offerPageTextColor,
              ),
              SizedBox(height: 5.h),
              // Comments multiline
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10), // 10% opacity
                      offset: Offset(0, 0), // X, Y
                      blurRadius: 10, // Blur
                      spreadRadius: 2, // Spread
                    ),
                  ],
                ),
                child: TextField(
                  controller: _commentsController,
                  maxLines: 5,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Comments",
                    hintStyle: TextStyle(color: offerPageTextColor, fontSize: 14.sp),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.r),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.all(16.w),
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: 150.w,
                      height: 50.h,
                      child: AppButton(
                        size: 14.sp ,
                        borderRadius: 5.r,
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
    );
  }
}
