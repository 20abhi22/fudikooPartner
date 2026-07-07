import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/services/scanner_service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fudiko/screens/others/scanner2.dart';

class Scanner extends StatefulWidget {
  final ScannerType scannerType;

  const Scanner({super.key, this.scannerType = ScannerType.restaurant});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  static const String _allowedQrUrlPrefix =
      'https://fudikko.bitwissenddev.in/api/';

  final MobileScannerController _controller = MobileScannerController();
  final ScannerVerificationService _verificationService =
      ScannerVerificationService();
  bool _isScanning = false;
  bool _torchOn = false;
  bool _isResolvingCode = false;
  String? _scannedCode;
  _ScanPayload? _scanPayload;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;

    final result = await _controller.analyzeImage(image.path);
    if (result == null || result.barcodes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No QR code found in image")),
      );
      return;
    }

    final code = result.barcodes.first.rawValue;
    if (code != null) {
      await _handleScannedCode(code);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scannedCode != null || _isResolvingCode) return;
    // firstOrNull requires package:collection — use isNotEmpty instead
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    if (barcode?.rawValue != null) {
      _controller.stop();
      _handleScannedCode(barcode!.rawValue!);
    }
  }

  Future<bool> _handleScannedCode(String code) async {
    setState(() => _isResolvingCode = true);

    final payload = await _resolveScanPayload(code);

    if (!mounted) return false;
    setState(() => _isResolvingCode = false);

    if (payload == null) {
      if (_isScanning) await _controller.start();
      if (!mounted) return false;
      setState(() => _scannedCode = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid QR code. Please scan a Fudikko QR code."),
        ),
      );
      return false;
    }

    setState(() {
      _scannedCode = code;
      _scanPayload = payload;
    });
    _showResultDialog(payload);
    return true;
  }

  Future<_ScanPayload?> _resolveScanPayload(String code) async {
    final verificationUrl = _verificationUrlFromQrCode(code);
    if (verificationUrl != null) {
      final result = await _verificationService.verify(verificationUrl);
      switch (result) {
        case ScannerVerifySuccess(:final data):
          return _ScanPayload.fromVerifiedJson(
            data,
            fallbackType: widget.scannerType,
          );
        case ScannerVerifyFailure(:final message):
          if (!mounted) return null;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          return null;
      }
    }

    return null;
  }

  String? _verificationUrlFromQrCode(String code) {
    final trimmed = code.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && _isAllowedFudikkoApiUrl(trimmed)) {
      return trimmed;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final verificationUrl = decoded['verification_url']?.toString().trim();
        if (verificationUrl != null &&
            _isAllowedFudikkoApiUrl(verificationUrl)) {
          return verificationUrl;
        }
      }
    } catch (_) {}

    return null;
  }

  bool _isAllowedFudikkoApiUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'fudikko.bitwissenddev.in' &&
        value.startsWith(_allowedQrUrlPrefix);
  }

  void _showResultDialog(_ScanPayload payload) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        final isWideShortPhone = _isWideShortPhone(screenSize);
        final isMobile =
            Breakpoints.isMobileDevice(screenSize) && !isWideShortPhone;
        final radius = isWideShortPhone
            ? 16.0
            : isMobile
            ? 16.r
            : 16.0;
        final padding = isWideShortPhone
            ? 24.0
            : isMobile
            ? 24.w
            : 24.0;
        final iconSize = isWideShortPhone
            ? 48.0
            : isMobile
            ? 50.w
            : 48.0;
        final gap16 = isWideShortPhone
            ? 16.0
            : isMobile
            ? 16.h
            : 16.0;
        final gap10 = isWideShortPhone
            ? 10.0
            : isMobile
            ? 10.h
            : 10.0;
        final gap24 = isWideShortPhone
            ? 24.0
            : isMobile
            ? 24.h
            : 24.0;

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: iconSize),
                  SizedBox(height: gap16),
                  AppText(
                    text: "Coupon Scanned!",
                    size: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    isCentered: true,
                  ),
                  SizedBox(height: gap10),
                  AppText(
                    text: payload.displayText,
                    size: 14,
                    fontWeight: FontWeight.w500,
                    color: appTextColor2,
                    isCentered: true,
                  ),
                  SizedBox(height: gap24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            setState(() {
                              _scannedCode = null;
                              _scanPayload = null;
                            });
                            await _controller.start();
                          },
                          child: Text(
                            "Scan Again",
                            style: TextStyle(color: appButtonColor),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            final scan = _scanPayload;
                            if (scan == null) return;
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scanner2(
                                  reservationId: scan.reservationUuid,
                                  scannerType: scan.scannerType,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Done",
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _contentMaxWidth(Size size) {
    if (Breakpoints.isDesktop(size.width)) return 480;
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
    final shouldRotateCameraPreview = screenSize.width > screenSize.height;
    final pagePadding = AppDimensions.padding(screenSize.width);
    final headerPadding = isWideShortPhone
        ? 16.0
        : isMobile
        ? 30.r
        : pagePadding;
    final backSize = isWideShortPhone
        ? 26.0
        : isMobile
        ? 30.w
        : 26.0;
    final scannerRadius = isWideShortPhone
        ? 18.0
        : isMobile
        ? 20.r
        : 20.0;
    final clipRadius = isWideShortPhone
        ? 16.0
        : isMobile
        ? 18.r
        : 18.0;
    final statusGap = isWideShortPhone
        ? 18.0
        : isMobile
        ? 50.h
        : 42.0;
    final labelGap = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.h
        : 10.0;
    final actionGap = isWideShortPhone
        ? 20.0
        : isMobile
        ? 70.h
        : 56.0;
    final toolIconSize = isWideShortPhone
        ? 28.0
        : isMobile
        ? 30.w
        : 28.0;
    final toolGap = isWideShortPhone
        ? 32.0
        : isMobile
        ? 40.w
        : 38.0;

    return Scaffold(
      backgroundColor: const Color(0xFF545450),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scannerSize = isWideShortPhone
                ? (constraints.maxHeight * 0.44).clamp(170.0, 240.0).toDouble()
                : isMobile
                ? 300.w.clamp(260.0, 320.0).toDouble()
                : 300.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(headerPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Image.asset(
                              backWhite,
                              width: backSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
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
                              Container(
                                height: scannerSize,
                                width: scannerSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    scannerRadius,
                                  ),
                                  border: Border.all(
                                    color: appButtonColor,
                                    width: 3,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    clipRadius,
                                  ),
                                  child: _isScanning
                                      ? RotatedBox(
                                          quarterTurns:
                                              shouldRotateCameraPreview ? 3 : 0,
                                          child: MobileScanner(
                                            controller: _controller,
                                            onDetect: _onDetect,
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () async {
                                            setState(() => _isScanning = true);
                                            await _controller.start();
                                          },
                                          child: Image.asset(
                                            'assets/images/scanner.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: statusGap),
                              AppText(
                                text: _isResolvingCode
                                    ? "Verifying coupon..."
                                    : _isScanning
                                    ? "Point camera at QR code"
                                    : "Tap to start scanning",
                                size: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                isCentered: true,
                              ),
                              SizedBox(height: labelGap),
                              AppText(
                                text: "coupon here",
                                size: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                              SizedBox(height: actionGap),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: _pickFromGallery,
                                    child: Image.asset(
                                      imageIcon,
                                      width: toolIconSize,
                                      fit: BoxFit.contain,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: toolGap),
                                  GestureDetector(
                                    onTap: () {
                                      _controller.toggleTorch();
                                      setState(() => _torchOn = !_torchOn);
                                    },
                                    child: Image.asset(
                                      flashIcon,
                                      width: toolIconSize,
                                      fit: BoxFit.contain,
                                      color: _torchOn
                                          ? Colors.yellow
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isWideShortPhone ? 16.0 : 24.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScanPayload {
  final String reservationUuid;
  final String displayText;
  final ScannerType scannerType;

  const _ScanPayload({
    required this.reservationUuid,
    required this.displayText,
    required this.scannerType,
  });

  static _ScanPayload? fromVerifiedJson(
    Map<String, dynamic> json, {
    required ScannerType fallbackType,
  }) {
    final reservationRaw = json['reservation'];
    final reservation = reservationRaw is Map
        ? Map<String, dynamic>.from(reservationRaw)
        : null;

    final uuid = reservation?['uuid']?.toString().trim();
    if (uuid == null || uuid.isEmpty) return null;

    final type =
        _scannerTypeFromQrType(json['type']?.toString()) ?? fallbackType;
    final reservationId = reservation?['reservation_id']?.toString();

    return _ScanPayload(
      reservationUuid: uuid,
      scannerType: type,
      displayText: reservationId == null || reservationId.isEmpty
          ? uuid
          : reservationId,
    );
  }

  static ScannerType? _scannerTypeFromQrType(String? type) {
    switch (type?.trim().toLowerCase()) {
      case 'reservation':
        return ScannerType.restaurant;
      case 'enquiry':
        return ScannerType.banquet;
      case 'catering-enquiry':
      case 'catering_enquiry':
      case 'catering':
        return ScannerType.catering;
      default:
        return null;
    }
  }
}
