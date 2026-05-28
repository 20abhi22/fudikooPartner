// lib/screens/others/scanner.dart
// Only the _showResultDialog change is needed — rest of the file stays as-is.
// Replace the "Done" TextButton's onPressed with the snippet below.

// ── Inside _showResultDialog ────────────────────────────────────────────────
//
// Replace:
//
//   onPressed: () {
//     Navigator.pop(context);
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const Scanner2()),
//     );
//   },
//
// With:
//
//   onPressed: () {
//     Navigator.pop(context);
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => Scanner2(
//           reservationId: _scannedCode!,
//           scannerType: ScannerType.restaurant, // change per flow
//         ),
//       ),
//     );
//   },
//
// ── Also fix firstOrNull ────────────────────────────────────────────────────
//
// Replace:
//   final barcode = capture.barcodes.firstOrNull;
//
// With:
//   final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
//
// ── Also fix tap-to-start ──────────────────────────────────────────────────
//
// Replace:
//   onTap: () => setState(() => _isScanning = true),
//
// With:
//   onTap: () async {
//     setState(() => _isScanning = true);
//     await _controller.start();
//   },
//
// ── Also fix Scan Again ────────────────────────────────────────────────────
//
// Replace:
//   _controller.start();
//
// With:
//   await _controller.start();
// And make onPressed async:
//   onPressed: () async { ... }

// ── Full corrected scanner.dart ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fudiko/screens/others/scanner2.dart';

class Scanner extends StatefulWidget {
  const Scanner({super.key});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = false;
  bool _torchOn = false;
  String? _scannedCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await ImagePicker()
        .pickImage(source: ImageSource.gallery);
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
      setState(() => _scannedCode = code);
      _showResultDialog(code);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scannedCode != null) return;
    // firstOrNull requires package:collection — use isNotEmpty instead
    final barcode =
        capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    if (barcode?.rawValue != null) {
      setState(() => _scannedCode = barcode!.rawValue);
      _controller.stop();
      _showResultDialog(_scannedCode!);
    }
  }

  void _showResultDialog(String code) {
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
                text: code,
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
                        setState(() => _scannedCode = null);
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
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scanner2(
                              reservationId: _scannedCode!,
                              scannerType: ScannerType.restaurant,
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
                  text: _isScanning
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