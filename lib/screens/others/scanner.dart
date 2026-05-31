import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid QR code")));
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

    final localPayload = _ScanPayload.fromQrCode(
      code,
      fallbackType: widget.scannerType,
    );
    return localPayload;
  }

  String? _verificationUrlFromQrCode(String code) {
    final trimmed = code.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        uri.path.contains('verify')) {
      return trimmed;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final verificationUrl = decoded['verification_url']?.toString().trim();
        if (verificationUrl != null && verificationUrl.isNotEmpty) {
          return verificationUrl;
        }
      }
    } catch (_) {}

    return null;
  }

  void _showResultDialog(_ScanPayload payload) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 50.w),
              SizedBox(height: 16.h),
              AppText(
                text: "Coupon Scanned!",
                size: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                isCentered: true,
              ),
              SizedBox(height: 10.h),
              AppText(
                text: payload.displayText,
                size: 14,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
                isCentered: true,
              ),
              SizedBox(height: 24.h),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF545450),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(30.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    backWhite,
                    width: 30.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 300.h,
                  width: 300.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: appButtonColor, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18.r),
                    child: _isScanning
                        ? MobileScanner(
                            controller: _controller,
                            onDetect: _onDetect,
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
                SizedBox(height: 50.h),
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
                SizedBox(height: 10.h),
                AppText(
                  text: "coupon here",
                  size: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
                SizedBox(height: 70.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Image.asset(
                        imageIcon,
                        width: 30.w,
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 40.w),
                    GestureDetector(
                      onTap: () {
                        _controller.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                      child: Image.asset(
                        flashIcon,
                        width: 30.w,
                        fit: BoxFit.contain,
                        color: _torchOn ? Colors.yellow : Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  static _ScanPayload? fromQrCode(
    String rawCode, {
    required ScannerType fallbackType,
  }) {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final json = Map<String, dynamic>.from(decoded);
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
    } catch (_) {
      // Older QR codes may contain only the UUID.
    }

    return _ScanPayload(
      reservationUuid: trimmed,
      scannerType: fallbackType,
      displayText: trimmed,
    );
  }

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
