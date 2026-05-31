// lib/screens/others/scanner2.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/models/scanner/scanner_complete_model.dart';
import 'package:fudiko/screens/others/nav/mainnav.dart';
import 'package:fudiko/services/scanner_service.dart';
import 'package:image_picker/image_picker.dart';

class Scanner2 extends StatefulWidget {
  /// The raw UUID value decoded from the QR code.
  final String reservationId;

  /// Which scanner flow produced this QR code.
  /// Defaults to restaurant; pass [ScannerType.banquet] or
  /// [ScannerType.catering] when those flows are ready.
  final ScannerType scannerType;

  const Scanner2({
    super.key,
    required this.reservationId,
    this.scannerType = ScannerType.restaurant,
  });

  @override
  State<Scanner2> createState() => _Scanner2State();
}

/// Extend this enum when banquet / catering QR codes are added.
enum ScannerType { restaurant, banquet, catering }

class _Scanner2State extends State<Scanner2> {
  final TextEditingController _amountController = TextEditingController();
  XFile? _pickedImage;
  bool _isLoading = false;

  // Pick the correct service based on scanner type
  BaseScannerService get _service => switch (widget.scannerType) {
    ScannerType.restaurant => RestaurantScannerService(),
    ScannerType.banquet => BanquetScannerService(),
    ScannerType.catering => CateringScannerService(),
  };

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image == null) return;
      setState(() => _pickedImage = image);
    } catch (_) {
      _showSnack('Error picking image');
    }
  }

  void _showChooseSource() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Submission ─────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_amountController.text.trim().isEmpty) {
      _showSnack('Please enter bill amount');
      return;
    }
    if (_pickedImage == null) {
      _showSnack('Please upload a photo of the bill');
      return;
    }

    setState(() => _isLoading = true);

    final result = await _service.completeReservation(
      reservationId: widget.reservationId,
      billAmount: _amountController.text.trim(),
      billImage: File(_pickedImage!.path),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case ScannerSuccess(:final data):
        _onSuccess(data);
      case ScannerFailure(:final message):
        _showSnack(message);
    }
  }

  void _onSuccess(ScannerCompleteResponse data) {
    // Even when status == false (e.g. "already completed"), the backend
    // returns 200 with a message — show it, then navigate home.
    _showSnack(data.message);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainNavPage(initialIndex: _homeTabIndex),
        ),
        (route) => false,
      );
    });
  }

  int get _homeTabIndex => switch (widget.scannerType) {
    ScannerType.restaurant => 0,
    ScannerType.banquet => 1,
    ScannerType.catering => 3,
  };

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/check.png',
                      width: 100.w,
                      height: 100.w,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 10.h),
                    const AppText(
                      text: "Coupon Verified!",
                      size: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    SizedBox(height: 40.h),

                    // Bill amount input
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AppTextFeild(
                        text: "Enter the Bill Amount",
                        icon: Icons.receipt_long_outlined,
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Bill photo preview or pick button
                    if (_pickedImage != null)
                      _BillPreview(
                        imagePath: _pickedImage!.path,
                        onRemove: () => setState(() => _pickedImage = null),
                      )
                    else
                      Container(
                        height: 60.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AppButton(
                          text: 'Take a Photo of Bill',
                          onPressed: _showChooseSource,
                          size: 15,
                          icon: Icons.camera_alt_sharp,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Submit button
            Padding(
              padding: EdgeInsets.only(bottom: 40.h),
              child: SizedBox(
                width: 150.w,
                height: 50.h,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AppButton(
                        text: 'Submit',
                        onPressed: _submit,
                        bgColor1: Colors.blue,
                        bgColor2: Colors.blue,
                        size: 16,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small extracted widget ─────────────────────────────────────────────────

class _BillPreview extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;

  const _BillPreview({required this.imagePath, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 180.h,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.black12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(File(imagePath), fit: BoxFit.cover),
          ),
        ),
        TextButton(onPressed: onRemove, child: const Text('Remove photo')),
      ],
    );
  }
}
