// lib/screens/others/scanner2.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
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

  double _contentMaxWidth(Size size) {
    if (Breakpoints.isDesktop(size.width)) return 460;
    if (Breakpoints.isTabletDevice(size)) return 440;
    return double.infinity;
  }

  bool _isWideShortPhone(Size size) {
    return Breakpoints.isWideShortPhone(size);
  }

  EdgeInsets _contentPadding(Size size) {
    final isMobile = Breakpoints.isMobileDevice(size);
    return EdgeInsets.symmetric(
      horizontal: _isWideShortPhone(size)
          ? 28.0
          : isMobile
          ? 30.w
          : AppDimensions.padding(size.width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isWideShortPhone = _isWideShortPhone(screenSize);
    final isMobile =
        Breakpoints.isMobileDevice(screenSize) && !isWideShortPhone;
    final checkIconSize = isWideShortPhone
        ? 80.0
        : isMobile
        ? 100.w
        : 90.0;
    final fieldRadius = isWideShortPhone
        ? 16.0
        : isMobile
        ? 20.r
        : 18.0;
    final fieldTextSize = isWideShortPhone
        ? 14.0
        : isMobile
        ? 16.0
        : 14.0;
    final smallGap = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.h
        : 10.0;
    final fieldGap = isWideShortPhone
        ? 12.0
        : isMobile
        ? 20.h
        : 18.0;
    final largeGap = isWideShortPhone
        ? 20.0
        : isMobile
        ? 40.h
        : 36.0;
    final photoButtonHeight = isWideShortPhone
        ? 50.0
        : isMobile
        ? 60.h
        : 56.0;
    final submitBottom = isWideShortPhone
        ? 18.0
        : isMobile
        ? 40.h
        : 40.0;
    final submitWidth = isWideShortPhone
        ? 140.0
        : isMobile
        ? 150.w
        : 150.0;
    final submitHeight = isWideShortPhone
        ? 46.0
        : isMobile
        ? 50.h
        : 48.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: _contentPadding(screenSize),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWideShortPhone
                            ? 440.0
                            : _contentMaxWidth(screenSize),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isWideShortPhone ? 12.0 : 24.0),
                          Image.asset(
                            'assets/images/check.png',
                            width: checkIconSize,
                            height: checkIconSize,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: smallGap),
                          const AppText(
                            text: "Coupon Verified!",
                            size: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          SizedBox(height: largeGap),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(fieldRadius),
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
                              fieldBorderRadius: fieldRadius,
                              size: fieldTextSize,
                              height: isWideShortPhone ? 50.0 : null,
                            ),
                          ),
                          SizedBox(height: fieldGap),
                          if (_pickedImage != null)
                            _BillPreview(
                              imagePath: _pickedImage!.path,
                              onRemove: () =>
                                  setState(() => _pickedImage = null),
                            )
                          else
                            Container(
                              height: photoButtonHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  fieldRadius,
                                ),
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
                                borderRadius: fieldRadius,
                              ),
                            ),
                          SizedBox(height: largeGap),
                          SizedBox(
                            width: submitWidth,
                            height: submitHeight,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : AppButton(
                                    text: 'Submit',
                                    onPressed: _submit,
                                    bgColor1: Colors.blue,
                                    bgColor2: Colors.blue,
                                    size: 16,
                                  ),
                          ),
                          SizedBox(height: submitBottom),
                        ],
                      ),
                    ),
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

// ── Small extracted widget ─────────────────────────────────────────────────

class _BillPreview extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;

  const _BillPreview({required this.imagePath, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isWideShortPhone = Breakpoints.isWideShortPhone(screenSize);
    final isMobile =
        Breakpoints.isMobileDevice(screenSize) && !isWideShortPhone;
    final previewHeight = isWideShortPhone
        ? 130.0
        : isMobile
        ? 180.h
        : 180.0;
    final radius = isWideShortPhone
        ? 12.0
        : isMobile
        ? 12.r
        : 12.0;

    return Column(
      children: [
        Container(
          height: previewHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.black12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.file(File(imagePath), fit: BoxFit.cover),
          ),
        ),
        TextButton(onPressed: onRemove, child: const Text('Remove photo')),
      ],
    );
  }
}
