import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/api/api_config.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/services/scanner_service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/snackbar.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fudiko/screens/others/scanner2.dart';

/// Explicit camera lifecycle states. Replaces the old combination of
/// `_isScanning` / `_isResolvingCode` bools, which could disagree with
/// each other and leave the UI stuck on the built-in mobile_scanner
/// error icon with no way to recover.
enum _CameraState {
  idle, // showing the "tap to scan" placeholder
  starting, // start() in flight
  scanning, // camera live, actively detecting
  resolving, // a code was found and is being verified with the backend
  permissionDenied,
  error,
}

class Scanner extends StatefulWidget {
  final ScannerType scannerType;

  const Scanner({super.key, this.scannerType = ScannerType.restaurant});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> with WidgetsBindingObserver {
  static const String _allowedQrUrlPrefix =
      '${ApiConfig.baseUrl}/';

  final ScannerVerificationService _verificationService =
      ScannerVerificationService();

  MobileScannerController? _controller;
  _CameraState _cameraState = _CameraState.idle;
  bool _torchOn = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (controller.value.isRunning) {
        controller.stop();
        if (mounted && _cameraState == _CameraState.scanning) {
          setState(() => _cameraState = _CameraState.idle);
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // Camera lifecycle
  // ---------------------------------------------------------------------

  Future<void> _startScanning() async {
    if (_cameraState == _CameraState.starting ||
        _cameraState == _CameraState.scanning) {
      return;
    }

    setState(() {
      _cameraState = _CameraState.starting;
      _errorMessage = null;
    });

    // mobile_scanner leaves a blank preview if start() is called again on
    // a controller that was previously stopped, so every scan attempt
    // gets a freshly created controller.
final oldController = _controller;
final newController = MobileScannerController(autoStart: false); // <-- key change
_controller = newController;

if (oldController != null) {
  try { await oldController.stop(); } catch (_) {}
  try { await oldController.dispose(); } catch (_) {}
}

try {
  await newController.start(); // <-- uncommented, now safe
  if (!mounted) return;
  setState(() {
    _cameraState = _CameraState.scanning;
    _torchOn = false;
  });
} on MobileScannerException catch (e) {
  if (!mounted) return;
  setState(() {
    _cameraState = e.errorCode == MobileScannerErrorCode.permissionDenied
        ? _CameraState.permissionDenied
        : _CameraState.error;
    _errorMessage = _messageForError(e);
  });
} catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraState = _CameraState.error;
        _errorMessage = 'Could not start the camera. Please try again.';
      });
    }
  }

  Future<void> _stopScanning() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.stop();
    } catch (_) {
      // Already stopped/disposed — nothing to do.
    }
  }

  String _messageForError(MobileScannerException e) {
    switch (e.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera access is denied. Enable it in Settings to scan a QR code.';
      case MobileScannerErrorCode.unsupported:
        return 'Scanning is not supported on this device.';
      default:
        return e.errorDetails?.message ??
            'Something went wrong opening the camera.';
    }
  }

  // ---------------------------------------------------------------------
  // Scanning / verification
  // ---------------------------------------------------------------------

  Future<void> _pickFromGallery() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image == null || !mounted) return;

    // Stop the live camera (if running) so a live detection can't race
    // with the code we're about to resolve from the picked image.
    await _stopScanning();
    if (!mounted) return;

    _controller ??= MobileScannerController();
    final controller = _controller!;

    setState(() => _cameraState = _CameraState.resolving);

    BarcodeCapture? result;
    try {
      result = await controller.analyzeImage(image.path);
    } catch (_) {
      result = null;
    }
    if (!mounted) return;

    final code = (result?.barcodes.isNotEmpty ?? false)
        ? result!.barcodes.first.rawValue
        : null;

    if (code == null) {
      setState(() => _cameraState = _CameraState.idle);
      showErrorSnack(context, 'No QR code found in image');
      return;
    }

    await _handleScannedCode(code);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_cameraState != _CameraState.scanning) return;
    final barcode =
        capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final value = barcode?.rawValue;
    if (value == null) return;

    // Flip state synchronously so a burst of frames arriving before the
    // controller actually stops can't trigger this twice.
    setState(() => _cameraState = _CameraState.resolving);
    unawaited(_processDetectedCode(value));
  }

  Future<void> _processDetectedCode(String code) async {
    await _stopScanning();
    if (!mounted) return;
    await _handleScannedCode(code);
  }

  Future<void> _handleScannedCode(String code) async {
    final verificationUrl = _verificationUrlFromQrCode(code);
    if (verificationUrl == null) {
      if (!mounted) return;
      setState(() => _cameraState = _CameraState.idle);
      _showRejectionDialog('Invalid QR code. Please scan a Fudikko QR code.');
      return;
    }

    // Loading indicator (resolving state) stays up for the entire network
    // round trip; the confirmation/rejection dialog only appears once the
    // verify call has actually returned.
    final result = await _verificationService.verify(verificationUrl);
    if (!mounted) return;
    setState(() => _cameraState = _CameraState.idle);

    switch (result) {
      case ScannerVerifySuccess(:final data):
        final payload = _ScanPayload.fromVerifiedJson(
          data,
          fallbackType: widget.scannerType,
        );
        if (payload == null) {
          _showRejectionDialog(
            'Invalid QR code. Please scan a Fudikko QR code.',
          );
          return;
        }
        _showResultDialog(payload);
      case ScannerVerifyFailure(:final message):
        _showRejectionDialog(message);
    }
  }

  String? _verificationUrlFromQrCode(String code) {
    final trimmed = code.trim();
    if (_isAllowedFudikkoApiUrl(trimmed)) return trimmed;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final verificationUrl =
            decoded['verification_url']?.toString().trim();
        if (verificationUrl != null &&
            _isAllowedFudikkoApiUrl(verificationUrl)) {
          return verificationUrl;
        }
      }
    } catch (_) {
      // Not JSON — fall through to null.
    }

    return null;
  }

  bool _isAllowedFudikkoApiUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == ApiConfig.host &&
        value.startsWith(_allowedQrUrlPrefix);
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

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
                    text: 'Coupon Scanned!',
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
                          onPressed: () {
                            Navigator.pop(context);
                            _startScanning();
                          },
                          child: AppText(
                            text:'Scan Again',
                            color: appButtonColor,
                            fontWeight: FontWeight.w400,
                            size: 14,
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
                                  reservationId: payload.reservationUuid,
                                  scannerType: payload.scannerType,
                                ),
                              ),
                            );
                          },
                          child: const AppText(
                            text: 'Done',
                            color: Colors.green,
                            size: 14,
                            fontWeight: FontWeight.w400,
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

  void _showRejectionDialog(String message) {
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
                  Icon(Icons.cancel, color: Colors.red, size: iconSize),
                  SizedBox(height: gap16),
                  AppText(
                    text: 'Verification Failed',
                    size: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    isCentered: true,
                  ),
                  SizedBox(height: gap16 / 2),
                  AppText(
                    text: message,
                    size: 14,
                    fontWeight: FontWeight.w500,
                    color: appTextColor2,
                    isCentered: true,
                  ),
                  SizedBox(height: gap24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startScanning();
                      },
                      child: AppText(
                        text: 'Try Again',
                        color: appButtonColor,
                        fontWeight: FontWeight.w400,
                        size: 14,
                      ),
                    ),
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

  bool _isWideShortPhone(Size size) => Breakpoints.isWideShortPhone(size);

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

  Widget _cameraArea(bool shouldRotate) {
    final controller = _controller;
    final showLiveCamera =
        controller != null &&
        (_cameraState == _CameraState.scanning ||
            (_cameraState == _CameraState.resolving &&
                controller.value.isRunning));

    if (showLiveCamera) {
      return Stack(
        fit: StackFit.expand,
        children: [
          RotatedBox(
            quarterTurns: shouldRotate ? 3 : 0,
            child: MobileScanner(
              key: ValueKey(controller),
              controller: controller,
              onDetect: _onDetect,
              // NOTE: if your installed mobile_scanner version expects
              // `(context, error, child)`, add a third `Widget? child`
              // parameter here.
              errorBuilder: (context, error, child) {
  return _cameraErrorView(_messageForError(error));
},
            ),
          ),
          if (_cameraState == _CameraState.resolving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      );
    }

    switch (_cameraState) {
      case _CameraState.permissionDenied:
      case _CameraState.error:
        return _cameraErrorView(_errorMessage);
      case _CameraState.starting:
      case _CameraState.resolving:
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      case _CameraState.idle:
      case _CameraState.scanning:
        return GestureDetector(
          onTap: _startScanning,
          child: Image.asset('assets/images/scanner.png', fit: BoxFit.contain),
        );
    }
  }

  Widget _cameraErrorView(String? message) {
    final isPermissionIssue = _cameraState == _CameraState.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPermissionIssue ? Icons.no_photography : Icons.error_outline,
              color: Colors.white70,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Camera unavailable',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (isPermissionIssue) {
                  openAppSettings();
                } else {
                  _startScanning();
                }
              },
              child: Text(
                isPermissionIssue ? 'Open Settings' : 'Retry',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
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

    final statusText = switch (_cameraState) {
      _CameraState.resolving => 'Verifying coupon...',
      _CameraState.scanning => 'Point camera at QR code',
      _CameraState.starting => 'Opening camera...',
      _CameraState.permissionDenied => 'Camera access needed',
      _CameraState.error => 'Camera unavailable',
      _CameraState.idle => 'Tap to start scanning',
    };

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
                                  child: _cameraArea(shouldRotateCameraPreview),
                                ),
                              ),
                              SizedBox(height: statusGap),
                              AppText(
                                text: statusText,
                                size: 16,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                isCentered: true,
                              ),
                              SizedBox(height: labelGap),
                              AppText(
                                text: 'coupon here',
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
                                    onTap: _cameraState == _CameraState.scanning
                                        ? () {
                                            final controller = _controller;
                                            if (controller == null) return;
                                            try {
                                              controller.toggleTorch();
                                              setState(
                                                () => _torchOn = !_torchOn,
                                              );
                                            } catch (_) {
                                              // Torch unsupported — ignore.
                                            }
                                          }
                                        : null,
                                    child: Image.asset(
                                      flashIcon,
                                      width: toolIconSize,
                                      fit: BoxFit.contain,
                                      color: _cameraState != _CameraState.scanning
                                          ? Colors.white38
                                          : _torchOn
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