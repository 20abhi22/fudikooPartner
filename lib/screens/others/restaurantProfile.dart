import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/individualMenuUpload.dart';
import 'package:fudiko/screens/others/menuUpload.dart';
import 'package:fudiko/screens/others/restaurantProfileEdit.dart';
import 'package:fudiko/services/profile-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RestaurantProfile extends StatefulWidget {
  const RestaurantProfile({super.key});

  @override
  State<RestaurantProfile> createState() => _RestaurantProfileState();
}

class _RestaurantProfileState extends State<RestaurantProfile> {
  static const int _maxImageBytes = 10 * 1024 * 1024;
  static const double _nativeImageMaxDimension = 2560;
  static const int _nativeImageQuality = 85;
  bool isProfileOpen = false;
  bool isButtonOpen = false;
  PartnerProfileModel? _profile;
  final PartnerService _partnerService = PartnerService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  String _imageUploadStatus = '';
  File? _selectedImage;
  File? _selectedProfilePhoto;

  void _showImageSizeMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image upload failed. The maximum size is 10 MB.'),
      ),
    );
  }

  bool _isUploadTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  void _showUploadTimeoutMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload timed out. Check your connection and try again.'),
      ),
    );
  }

  String _uploadErrorMessage(DioException error, String fallback) {
    final responseData = error.response?.data;
    if (responseData is Map) {
      final errors = responseData['errors'];
      if (errors is Map) {
        for (final fieldErrors in errors.values) {
          if (fieldErrors is List && fieldErrors.isNotEmpty) {
            return fieldErrors.first.toString();
          }
          if (fieldErrors != null) return fieldErrors.toString();
        }
      }

      final message = responseData['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    return fallback;
  }

  Future<File?> _prepareImageForUpload(File imageFile) async {
    if (await imageFile.length() <= _maxImageBytes) return imageFile;

    try {
      final decodedImage = img.decodeImage(await imageFile.readAsBytes());
      if (decodedImage == null) {
        _showImageSizeMessage();
        return null;
      }

      var resizedImage = decodedImage;
      final temporaryDirectory = await getTemporaryDirectory();
      final outputFile = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}'
        'profile_upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      for (var attempt = 0; attempt < 8; attempt++) {
        final quality = 85 - (attempt * 5);
        final compressedBytes = img.encodeJpg(resizedImage, quality: quality);

        if (compressedBytes.length <= _maxImageBytes) {
          await outputFile.writeAsBytes(compressedBytes, flush: true);
          return outputFile;
        }

        final nextWidth = (resizedImage.width * 0.8).round();
        if (nextWidth < 320) break;
        resizedImage = img.copyResize(resizedImage, width: nextWidth);
      }
    } catch (_) {
      // Fall through to the same user-facing maximum-size message.
    }

    _showImageSizeMessage();
    return null;
  }

  bool _isWideShortPhone(BuildContext context) {
    return Breakpoints.isWideShortPhone(MediaQuery.sizeOf(context));
  }

  bool _isNarrowShortPhone(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Breakpoints.isMobileDevice(size) &&
        size.width < 500 &&
        size.height <= 760;
  }

  double _pagePadding(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (_isWideShortPhone(context)) return 24.0;
    return AppDimensions.padding(size.width);
  }

  double _contentMaxWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    if (Breakpoints.isDesktop(width)) return 860;
    if (Breakpoints.isTabletDevice(size) || _isWideShortPhone(context)) {
      return 720;
    }
    return double.infinity;
  }

  Widget _responsiveContent({
    required Widget child,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
    Alignment alignment = Alignment.topCenter,
  }) {
    return Padding(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: _pagePadding(context)),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? _contentMaxWidth(context),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _partnerService.getProfile();
      setState(() => _profile = profile);
    } catch (e, stack) {
      debugPrint('Error fetching partner profile: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission denied')),
          );
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo permission denied')),
          );
          return;
        }
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: _nativeImageMaxDimension,
        maxHeight: _nativeImageMaxDimension,
        imageQuality: _nativeImageQuality,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _isUploading = true;
          _imageUploadStatus = 'Compressing image...';
        });
        final imageFile = await _prepareImageForUpload(File(pickedFile.path));
        if (imageFile == null || !mounted) {
          if (mounted) {
            setState(() {
              _isUploading = false;
              _imageUploadStatus = '';
            });
          }
          return;
        }

        setState(() {
          _selectedImage = File(pickedFile.path); // ← STORE IT HERE
          isProfileOpen = true; // ← KEEP OVERLAY OPEN
        });
        setState(() {
          _selectedImage = imageFile;
          _isUploading = false;
          _imageUploadStatus = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isUploading = true;
      _imageUploadStatus = 'Uploading image...';
    });
    try {
      final response = await _partnerService.uploadRestaurantImage(imageFile);
      if (!mounted) return;

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Image uploaded successfully'),
          ),
        );
        setState(() {
          isProfileOpen = false;
          _selectedImage = null; // ← CLEAR ON SUCCESS
        });
        _fetchProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to upload image'),
          ),
        );
      }
    } on DioException catch (e) {
      if (_isUploadTimeout(e)) {
        _showUploadTimeoutMessage();
        return;
      }
      if (e.response?.statusCode == 413) {
        _showImageSizeMessage();
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_uploadErrorMessage(e, 'Image upload failed')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _imageUploadStatus = '';
        });
      }
    }
  }

  Widget _infoRow({
    required String icon,
    required double iconSize,
    required String text,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(icon, width: iconSize, height: iconSize),
            Expanded(child: Container(height: 0.5, color: appTextColor3)),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            top: isMobile ? 5.h : 6.0,
            right: isMobile ? 10.w : 10.0,
            left: isMobile ? 30.w : 30.0,
            bottom: isMobile ? 5.h : 6.0,
          ),
          child: Text(
            text,
            softWrap: true,
            style: TextStyle(
              fontSize: isMobile ? 12.sp : 12.0,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadProgress() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                AppText(
                  text: _imageUploadStatus.isEmpty
                      ? 'Processing image...'
                      : _imageUploadStatus,
                  size: 14,
                  fontWeight: FontWeight.w500,
                  color: appTextColor3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay({
    required bool isMobile,
    required double pagePadding,
    required double modalRadius,
    required Widget child,
    VoidCallback? onDismiss,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.6)),
          ),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 30.w : pagePadding,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 20.w : 24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(modalRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: isMobile ? 10.r : 10.0,
                      offset: Offset(0, isMobile ? 4.r : 4.0),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showRestaurantImage({
    required String imageUrl,
    required String imageUuid,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        final isMobile =
            Breakpoints.isMobileDevice(size) &&
            !Breakpoints.isWideShortPhone(size);
        final inset = isMobile ? 16.w : 24.0;
        final radius = isMobile ? 12.r : 12.0;
        final errorPadding = isMobile ? 24.w : 24.0;

        var isDeletingImage = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> deleteImage() async {
              if (imageUuid.isEmpty || isDeletingImage) return;

              setDialogState(() => isDeletingImage = true);
              try {
                final messenger = ScaffoldMessenger.of(this.context);
                final response = await _partnerService.deleteRestaurantImage(
                  imageUuid,
                );
                if (!mounted) return;

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      response['message']?.toString() ??
                          'Restaurant image deleted successfully',
                    ),
                  ),
                );

                if (response['status'] == true) {
                  if (context.mounted) Navigator.of(context).pop();
                  await _fetchProfile();
                  return;
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Error deleting image: $e')),
                );
              } finally {
                if (mounted && context.mounted) {
                  setDialogState(() => isDeletingImage = false);
                }
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(inset),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: Stack(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(radius),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(errorPadding),
                                    color: Colors.white,
                                    child: const Icon(
                                      Icons.error,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: inset,
                      right: inset,
                      child: GestureDetector(
                        onTap: () {},
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: imageUuid.isEmpty || isDeletingImage
                                ? null
                                : deleteImage,
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: isMobile ? 42.w : 44.0,
                              height: isMobile ? 42.w : 44.0,
                              child: Center(
                                child: isDeletingImage
                                    ? SizedBox(
                                        width: isMobile ? 18.w : 18.0,
                                        height: isMobile ? 18.w : 18.0,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission denied')),
          );
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo permission denied')),
          );
          return;
        }
      }

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: _nativeImageMaxDimension,
        maxHeight: _nativeImageMaxDimension,
        imageQuality: _nativeImageQuality,
      );
      if (pickedFile == null || !mounted) return;

      setState(() {
        _isUploading = true;
        _imageUploadStatus = 'Compressing image...';
      });
      final imageFile = await _prepareImageForUpload(File(pickedFile.path));
      if (imageFile == null || !mounted) {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _imageUploadStatus = '';
          });
        }
        return;
      }

      setState(() => _selectedProfilePhoto = imageFile);
      await _updateProfilePhoto(imageFile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking photo: $e')));
    }
  }

  Future<void> _updateProfilePhoto(File imageFile) async {
    try {
      if (mounted) {
        setState(() => _imageUploadStatus = 'Uploading image...');
      }
      final response = await _partnerService.updateProfilePhoto(imageFile);
      if (!mounted) return;

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Profile photo updated successfully',
            ),
          ),
        );
        _fetchProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update photo'),
          ),
        );
      }
    } on DioException catch (e) {
      if (_isUploadTimeout(e)) {
        _showUploadTimeoutMessage();
        return;
      }
      if (e.response?.statusCode == 413) {
        _showImageSizeMessage();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_uploadErrorMessage(e, 'Profile photo upload failed')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile photo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _imageUploadStatus = '';
        });
      }
    }
  }

  Future<void> _showProfilePhotoSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        final isMobile =
            Breakpoints.isMobileDevice(size) &&
            !Breakpoints.isWideShortPhone(size);

        return Container(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 20.h : 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfilePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfilePhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        final isMobile =
            Breakpoints.isMobileDevice(size) &&
            !Breakpoints.isWideShortPhone(size);

        return Container(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 20.h : 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _serviceBadge(String label) {
    final size = MediaQuery.sizeOf(context);
    final isMobile =
        Breakpoints.isMobileDevice(size) && !Breakpoints.isWideShortPhone(size);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.w : 12.0,
        vertical: isMobile ? 4.h : 5.0,
      ),
      decoration: BoxDecoration(
        color: appButtonColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isMobile ? 20.r : 20.0),
        border: Border.all(color: appButtonColor, width: 1),
      ),
      child: AppText(
        text: label,
        size: 11,
        fontWeight: FontWeight.w600,
        color: appButtonColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final isWideShortPhone = _isWideShortPhone(context);
    final isNarrowShortPhone = _isNarrowShortPhone(context);
    final isMobile =
        Breakpoints.isMobileDevice(screenSize) && !isWideShortPhone;
    final isTablet = Breakpoints.isTabletDevice(screenSize);
    final pagePadding = _pagePadding(context);
    final gap = isWideShortPhone ? 12.0 : AppDimensions.gap(screenWidth);
    final isLandscape = screenWidth > screenSize.height;
    final bannerHeight = isWideShortPhone
        ? 136.0
        : isNarrowShortPhone
        ? 200.0
        : isTablet && isLandscape
        ? 180.0
        : isMobile
        ? 200.h
        : isTablet
        ? 220.0
        : 230.0;
    final avatarSize = isWideShortPhone
        ? 88.0
        : isMobile
        ? (screenWidth / 3).clamp(96.0, 140.0).toDouble()
        : isTablet && isLandscape
        ? 118.0
        : isTablet
        ? 140.0
        : 150.0;
    final avatarOverlap = avatarSize / 2;
    final avatarRight = isMobile ? 20.w : pagePadding;
    final avatarBottom = -avatarOverlap;
    final galleryHeight = isWideShortPhone
        ? 108.0
        : isMobile
        ? 150.h
        : isTablet && isLandscape
        ? 132.0
        : isTablet
        ? 158.0
        : 170.0;
    final galleryItemWidth = isWideShortPhone
        ? 82.0
        : isMobile
        ? 100.w
        : isTablet && isLandscape
        ? 96.0
        : isTablet
        ? 112.0
        : 120.0;
    final cardPadding = isWideShortPhone
        ? 14.0
        : isMobile
        ? 16.w
        : 20.0;
    final cardRadius = isWideShortPhone
        ? 16.0
        : isMobile
        ? 20.r
        : 20.0;
    final icon20 = isWideShortPhone
        ? 18.0
        : isMobile
        ? 20.w
        : 20.0;
    final icon15 = isWideShortPhone
        ? 14.0
        : isMobile
        ? 15.w
        : 15.0;
    final modalRadius = isWideShortPhone
        ? 14.0
        : isMobile
        ? 15.r
        : 15.0;
    final maxContent = _contentMaxWidth(context);
    final heroPadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 40.w
        : pagePadding + 10.0;
    final heroTitleSize = isWideShortPhone
        ? 24.0
        : isMobile
        ? 35.0
        : isTablet
        ? 31.0
        : 34.0;
    final heroTypeSize = isWideShortPhone
        ? 15.0
        : isMobile
        ? 25.0
        : isTablet
        ? 21.0
        : 23.0;
    final heroBodySize = isWideShortPhone
        ? 11.0
        : isNarrowShortPhone
        ? 12.0
        : isMobile
        ? 15.0
        : 14.0;
    final heroLocationIconSize = isWideShortPhone
        ? 13.0
        : isNarrowShortPhone
        ? 13.0
        : isMobile
        ? 15.w
        : 16.0;
    final heroLocationGap = isWideShortPhone
        ? 4.0
        : isMobile
        ? 5.w
        : 6.0;
    final heroAvailableWidth = screenWidth - (heroPadding * 2);
    final heroHeaderWidth =
        (screenWidth - avatarRight - avatarSize - heroPadding - 10.0)
            .clamp(160.0, heroAvailableWidth)
            .toDouble();
    final heroStarsBottom = isWideShortPhone
        ? 8.0
        : isMobile
        ? 12.h
        : 12.0;
    final heroStarsLeft = heroPadding;
    final heroStarSize = isWideShortPhone
        ? 20.0
        : isMobile
        ? 28.w
        : 28.0;
    final verificationBadgeSize = isWideShortPhone
        ? 38.0
        : isMobile
        ? 40.w
        : 42.0;
    final thirdStarCenter = heroStarsLeft + (heroStarSize * 2.5);
    final verificationBadgeLeft =
        (thirdStarCenter - (verificationBadgeSize / 2))
            .clamp(12.0, screenWidth - verificationBadgeSize - 12.0)
            .toDouble();
    final verificationBadgeTop = bannerHeight + (isWideShortPhone ? 4.0 : 6.0);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Banner + Avatar ──────────────────────────────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      'assets/images/banner1.png',
                      height: bannerHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: EdgeInsets.all(heroPadding),
                      child: SizedBox(
                        width: heroHeaderWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: _profile?.name ?? "Loading...",
                              size: heroTitleSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            AppText(
                              text: _profile?.type ?? "Loading...",
                              size: heroTypeSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: heroLocationIconSize,
                                  color: Colors.white,
                                ),
                                SizedBox(width: heroLocationGap),
                                Expanded(
                                  child: AppText(
                                    text: _profile?.address ?? "Loading...",
                                    size: heroBodySize,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: heroStarsLeft,
                      bottom: heroStarsBottom,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: () {
                          final rating =
                              double.tryParse(_profile?.reviewStar ?? '') ?? 0;
                          final filledStars = rating.clamp(0, 5).round();

                          return List.generate(
                            5,
                            (index) => Icon(
                              index < filledStars
                                  ? Icons.star
                                  : Icons.star_outline,
                              color: Colors.white,
                              size: heroStarSize,
                            ),
                          );
                        }(),
                      ),
                    ),
                    // Positioned(
                    //   left: verificationBadgeLeft,
                    //   top: verificationBadgeTop,
                    //   child: Image.asset(
                    //     'assets/images/verification.png',
                    //     height: verificationBadgeSize,
                    //     width: verificationBadgeSize,
                    //     fit: BoxFit.contain,
                    //   ),
                    // ),
                    // AFTER
                    Positioned(
                      left: verificationBadgeLeft,
                      top: verificationBadgeTop,
                      child: _profile?.currentBadge != null
                          ? SizedBox(
                              width: verificationBadgeSize,
                              height: verificationBadgeSize,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  const ColoredBox(color: Colors.white),
                                  Image.network(
                                    _profile!.currentBadge!.image,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/images/verification.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Image.asset(
                              'assets/images/verification.png',
                              height: verificationBadgeSize,
                              width: verificationBadgeSize,
                              fit: BoxFit.contain,
                            ),
                    ),
                    Positioned(
                      bottom: avatarBottom,
                      right: avatarRight,
                      child: GestureDetector(
                        onTap: _showProfilePhotoSourceDialog,
                        child: Container(
                          height: avatarSize,
                          width: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: isMobile ? 10.r : 10.0,
                                offset: Offset(0, isMobile ? 4.r : 4.0),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(isMobile ? 4.r : 4.0),
                          child: ClipOval(
                            child: _selectedProfilePhoto != null
                                ? Image.file(
                                    _selectedProfilePhoto!,
                                    fit: BoxFit.cover,
                                  )
                                : _profile?.image != null
                                ? Image.network(
                                    _profile!.image!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/images/restaurantLogo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (_profile?.images != null &&
                                      _profile!.images!.isNotEmpty)
                                ? Image.network(
                                    _profile!.images!.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/images/restaurantLogo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/restaurantLogo.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: avatarOverlap + gap),

                SizedBox(height: gap),

                // ── Gallery ───────────────────────────────────────────────────
                // Use a fixed horizontal padding wrapper so the list visually
                // aligns with all other _responsiveContent sections.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pagePadding),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContent),
                      child: SizedBox(
                        height: galleryHeight,
                        child: ListView.builder(
                          itemCount:
                              (_profile?.restaurantImages?.length ?? 0) + 1,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            if (index <
                                (_profile?.restaurantImages?.length ?? 0)) {
                              final restaurantImage =
                                  _profile!.restaurantImages![index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: isMobile ? 10.w : 10.0,
                                ),
                                child: GestureDetector(
                                  onTap: () => _showRestaurantImage(
                                    imageUrl: restaurantImage.image,
                                    imageUuid: restaurantImage.uuid,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 10.r : 10.0,
                                    ),
                                    child: Image.network(
                                      restaurantImage.image,
                                      height: galleryHeight,
                                      width: galleryItemWidth,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: galleryHeight,
                                        width: galleryItemWidth,
                                        color: const Color(0xFFC4C4C4),
                                        child: const Center(
                                          child: Icon(
                                            Icons.error,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: Container(
                                  margin: EdgeInsets.only(
                                    right: isMobile ? 10.w : 10.0,
                                  ),
                                  height: galleryHeight,
                                  width: galleryItemWidth,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC4C4C4),
                                    borderRadius: BorderRadius.circular(
                                      isMobile ? 10.r : 10.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: _isUploading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : Image.asset(
                                            plusIcon,
                                            width: isMobile ? 50.w : 50.0,
                                            height: isMobile ? 50.w : 50.0,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: gap),

                // ── Info card ─────────────────────────────────────────────────
                _responsiveContent(
                  child: Container(
                    padding: EdgeInsets.all(cardPadding),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: isMobile ? 10.r : 10.0,
                          offset: Offset(0, isMobile ? 4.r : 4.0),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RestaurantProfileEdit(profile: _profile),
                                ),
                              ),
                              child: Image.asset(
                                editIcon,
                                width: icon20,
                                height: icon20,
                              ),
                            ),
                          ],
                        ),
                        _infoRow(
                          icon: listMenuIcon,
                          iconSize: icon15,
                          text: (_profile?.description.isNotEmpty == true)
                              ? _profile!.description
                              : "No description available.",
                          isMobile: isMobile,
                        ),
                        _infoRow(
                          icon: dishesIcon,
                          iconSize: icon20,
                          text: _profile?.availableDishes ?? "-",
                          isMobile: isMobile,
                        ),
                        _infoRow(
                          icon: addressPinIcon,
                          iconSize: icon20,
                          text: _profile?.address ?? "-",
                          isMobile: isMobile,
                        ),
                        _infoRow(
                          icon: landPhoneIcon,
                          iconSize: icon20,
                          text: _profile?.phone ?? "-",
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: gap),

                // ── Service badges ────────────────────────────────────────────
                _responsiveContent(
                  child: Wrap(
                    spacing: isMobile ? 8.w : 8.0,
                    runSpacing: isMobile ? 8.h : 8.0,
                    children: [
                      if ((_profile?.banquetService ?? 0) == 1)
                        _serviceBadge("Banquet"),
                      if ((_profile?.takeawayService ?? 0) == 1)
                        _serviceBadge("Takeaway"),
                      if ((_profile?.deliveryService ?? 0) == 1)
                        _serviceBadge("Delivery"),
                    ],
                  ),
                ),

                // ── Add Menu button ───────────────────────────────────────────
                _responsiveContent(
                  padding: EdgeInsets.symmetric(
                    horizontal: pagePadding,
                    vertical: isMobile ? 20.h : 24.0,
                  ),
                  child: AppButton(
                    bgColor1: const Color(0xFFF97A0D),
                    bgColor2: const Color(0xFF934808),
                    borderRadius: isMobile ? 15.r : 15.0,
                    text: "Add Menu",
                    onPressed: () =>
                        setState(() => isButtonOpen = !isButtonOpen),
                  ),
                ),
              ],
            ),
          ),

          // ── Image upload overlay ──────────────────────────────────────────
          if (isProfileOpen)
            _buildOverlay(
              isMobile: isMobile,
              pagePadding: pagePadding,
              modalRadius: modalRadius,
              onDismiss: () => setState(() => isProfileOpen = false),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    height: isMobile ? 150.h : 180.0,
                    padding: EdgeInsets.all(isMobile ? 10.w : 10.0),
                    decoration: BoxDecoration(
                      color: menuUploadBoxColor,
                      borderRadius: BorderRadius.circular(modalRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: isMobile ? 10.r : 10.0,
                          offset: Offset(0, isMobile ? 4.r : 4.0),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              isMobile ? 10.r : 10.0,
                            ),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.file_upload_outlined,
                                  color: Colors.black,
                                  size: isMobile ? 30.w : 30.0,
                                ),
                                SizedBox(height: isMobile ? 10.h : 10.0),
                                AppText(
                                  text: "Click here to choose",
                                  size: 15,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor2,
                                ),
                                AppText(
                                  text: "your image",
                                  size: 15,
                                  fontWeight: FontWeight.w400,
                                  color: appTextColor2,
                                ),
                              ],
                            ),
                          ),
                  ),
                  SizedBox(height: isMobile ? 20.h : 20.0),
                  SizedBox(
                    width: isMobile ? 150.w : 150.0,
                    height: isMobile ? 50.h : 48.0,
                    child: AppButton(
                      text: _isUploading ? 'Uploading...' : 'Upload',
                      size: 15,
                      onPressed: _isUploading
                          ? () {}
                          : () => _selectedImage != null
                                ? _uploadImage(_selectedImage!)
                                : _showImageSourceDialog(),
                      bgColor1: Colors.green,
                      bgColor2: Colors.green,
                      borderRadius: isMobile ? 10.r : 10.0,
                    ),
                  ),
                  SizedBox(height: isMobile ? 20.h : 20.0),
                ],
              ),
            ),

          // ── Add Menu modal ────────────────────────────────────────────────
          if (isButtonOpen)
            _buildOverlay(
              isMobile: isMobile,
              pagePadding: pagePadding,
              modalRadius: modalRadius,
              onDismiss: () => setState(() => isButtonOpen = false),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Add Entire Menu',
                      bgColor1: appTextColor,
                      bgColor2: appTextColor,
                      borderRadius: 13,
                      height: isMobile ? 50.h : 48.0,
                      size: 15,
                      onPressed: () {
                        setState(() => isButtonOpen = false);
                        slideRightWidget(
                          newPage: MenuUpload(),
                          context: context,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: isMobile ? 15.h : 15.0),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Add Individual Items',
                      bgColor1: appTextColor,
                      bgColor2: appTextColor,
                      borderRadius: 13,
                      height: isMobile ? 50.h : 48.0,
                      size: 15,
                      onPressed: () {
                        setState(() => isButtonOpen = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IndividualMenuUpload(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (_isUploading) _buildImageUploadProgress(),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final screenWidth = _screenWidth(context);
  //   final isMobile = Breakpoints.isMobile(screenWidth);
  //   final pagePadding = _pagePadding(context);
  //   final gap = AppDimensions.gap(screenWidth);
  //   final bannerHeight = isMobile ? 200.h : 220.0;
  //   final avatarSize = isMobile
  //       ? (screenWidth / 3).clamp(96.0, 140.0)
  //       : Breakpoints.isTablet(screenWidth)
  //       ? 156.0
  //       : 150.0;
  //   final avatarOverlap = avatarSize / 2;
  //   final galleryHeight = isMobile ? 150.h : 164.0;
  //   final galleryItemWidth = isMobile ? 100.w : 116.0;
  //   final cardPadding = isMobile ? 16.w : 18.0;
  //   final cardRadius = isMobile ? 20.r : 20.0;
  //   final icon20 = isMobile ? 20.w : 20.0;
  //   final icon15 = isMobile ? 15.w : 15.0;
  //   final modalRadius = isMobile ? 15.r : 15.0;

  //   return Scaffold(
  //     body: Stack(
  //       children: [
  //         SingleChildScrollView(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               _responsiveContent(
  //                 padding: EdgeInsets.zero,
  //                 child: Stack(
  //                   clipBehavior: Clip.none,
  //                   children: [
  //                   Image.asset(
  //                     'assets/images/banner1.png',
  //                     height: bannerHeight,
  //                     width: double.infinity,
  //                     fit: BoxFit.cover,
  //                   ),
  //                   Padding(
  //                     padding: EdgeInsets.all(isMobile ? 30.w : 30.0),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         AppText(
  //                           text: _profile?.name ?? "Loading...",
  //                           size: Breakpoints.isTablet(screenWidth)
  //                               ? 42.0
  //                               : Breakpoints.isDesktop(screenWidth)
  //                               ? 38.0
  //                               : 35.0,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.white,
  //                           maxLines: 2,
  //                           overflow: TextOverflow.ellipsis,
  //                         ),
  //                         AppText(
  //                           text: _profile?.type ?? "Loading...",
  //                           size: Breakpoints.isTablet(screenWidth)
  //                               ? 28.0
  //                               : Breakpoints.isDesktop(screenWidth)
  //                               ? 24.0
  //                               : 25.0,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.white,
  //                           maxLines: 1,
  //                           overflow: TextOverflow.ellipsis,
  //                         ),
  //                         Row(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             Icon(
  //                               Icons.location_on,
  //                               size: isMobile ? 15.w : 16.0,
  //                               color: Colors.white,
  //                             ),
  //                             SizedBox(width: isMobile ? 5.w : 6.0),
  //                             Expanded(
  //                               child: AppText(
  //                                 text: _profile?.address ?? "Loading...",
  //                                 size: 15,
  //                                 fontWeight: FontWeight.w400,
  //                                 color: Colors.white,
  //                                 maxLines: 2,
  //                                 overflow: TextOverflow.ellipsis,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                         SizedBox(height: isMobile ? 20.h : 18.0),
  //                         Row(
  //                           children: [
  //                             Wrap(
  //                               children: List.generate(5, (index) {
  //                                 final rating =
  //                                     double.tryParse(
  //                                       _profile?.reviewStar ?? '0',
  //                                     ) ??
  //                                     0;
  //                                 final filledStars = rating.round();
  //                                 return Icon(
  //                                   Icons.star,
  //                                   color: index < filledStars
  //                                       ? Colors.white
  //                                       : Colors.grey,
  //                                   size: isMobile ? 20.w : 20.0,
  //                                 );
  //                               }),
  //                             ),
  //                             SizedBox(width: isMobile ? 10.w : 10.0),
  //                             AppText(
  //                               text: (_profile?.reviewStar ?? '0'),
  //                               size: 11,
  //                               fontWeight: FontWeight.w500,
  //                               color: Colors.white,
  //                             ),
  //                             SizedBox(width: isMobile ? 10.w : 10.0),
  //                             if (_profile?.restaurantType != null &&
  //                                 _profile!.restaurantType.isNotEmpty)
  //                               Container(
  //                                 padding: EdgeInsets.symmetric(
  //                                   horizontal: isMobile ? 8.w : 8.0,
  //                                   vertical: isMobile ? 2.h : 3.0,
  //                                 ),
  //                                 decoration: BoxDecoration(
  //                                   color: Colors.white.withOpacity(0.2),
  //                                   borderRadius: BorderRadius.circular(
  //                                     isMobile ? 10.r : 10.0,
  //                                   ),
  //                                 ),
  //                                 child: AppText(
  //                                   text: _profile!.restaurantType,
  //                                   size: 11,
  //                                   fontWeight: FontWeight.w500,
  //                                   color: Colors.white,
  //                                 ),
  //                               ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   Positioned(
  //                     bottom: -avatarOverlap,
  //                     right: isMobile ? 20.w : 24.0,
  //                     child: GestureDetector(
  //                       onTap: _showProfilePhotoSourceDialog,
  //                       child: Container(
  //                         height: avatarSize,
  //                         width: avatarSize,
  //                         decoration: BoxDecoration(
  //                           shape: BoxShape.circle,
  //                           color: Colors.white,
  //                           boxShadow: [
  //                             BoxShadow(
  //                               color: Colors.black.withOpacity(0.1),
  //                               blurRadius: isMobile ? 10.r : 10.0,
  //                               offset: Offset(0, isMobile ? 4.r : 4.0),
  //                             ),
  //                           ],
  //                         ),
  //                         padding: EdgeInsets.all(isMobile ? 4.r : 4.0),
  //                         child: ClipOval(
  //                           child: _selectedProfilePhoto != null
  //                               ? Image.file(
  //                                   _selectedProfilePhoto!,
  //                                   fit: BoxFit.cover,
  //                                   width: double.infinity,
  //                                   height: double.infinity,
  //                                 )
  //                               : _profile?.image != null
  //                               ? Image.network(
  //                                   _profile!.image!,
  //                                   fit: BoxFit.cover,
  //                                   errorBuilder: (context, error, stackTrace) {
  //                                     print('Profile image error: $error');
  //                                     return Image.asset(
  //                                       'assets/images/restaurantLogo.png',
  //                                       fit: BoxFit.cover,
  //                                     );
  //                                   },
  //                                 )
  //                               : (_profile?.images != null &&
  //                                     _profile!.images!.isNotEmpty)
  //                               ? Image.network(
  //                                   _profile!.images!.first,
  //                                   fit: BoxFit.cover,
  //                                   errorBuilder: (context, error, stackTrace) {
  //                                     print(
  //                                       'Profile fallback image error: $error',
  //                                     );
  //                                     return Image.asset(
  //                                       'assets/images/restaurantLogo.png',
  //                                       fit: BoxFit.cover,
  //                                     );
  //                                   },
  //                                 )
  //                               : Image.asset(
  //                                   'assets/images/restaurantLogo.png',
  //                                   fit: BoxFit.cover,
  //                                 ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   ],
  //                 ),
  //               ),
  //               SizedBox(height: avatarOverlap + gap),
  //               _responsiveContent(
  //                 child: Align(
  //                   alignment: Alignment.centerLeft,
  //                   child: Image.asset(
  //                     'assets/images/verification.png',
  //                     height: isMobile ? 40.h : 42.0,
  //                     width: isMobile ? 40.w : 42.0,
  //                     fit: BoxFit.contain,
  //                   ),
  //                 ),
  //               ),
  //               SizedBox(height: gap),
  //               _responsiveContent(
  //                 child: SizedBox(
  //                 height: galleryHeight,
  //                 child: ListView.builder(
  //                   itemCount: (_profile?.images?.length ?? 0) + 1,
  //                   shrinkWrap: true,
  //                   scrollDirection: Axis.horizontal,
  //                   physics: const BouncingScrollPhysics(),
  //                   itemBuilder: (context, index) {
  //                     if (index < (_profile?.images?.length ?? 0)) {
  //                       print(
  //                         'Loading restaurant image at index $index: ${_profile!.images![index]}',
  //                       );
  //                       return Padding(
  //                         padding: EdgeInsets.only(
  //                           right: isMobile ? 10.w : 10.0,
  //                         ),
  //                         child: GestureDetector(
  //                           onTap: () =>
  //                               _showRestaurantImage(_profile!.images![index]),
  //                           child: ClipRRect(
  //                             borderRadius: BorderRadius.circular(
  //                               isMobile ? 10.r : 10.0,
  //                             ),
  //                             child: Image.network(
  //                               _profile!.images![index],
  //                               height: galleryHeight,
  //                               width: galleryItemWidth,
  //                               fit: BoxFit.cover,
  //                               errorBuilder: (context, error, stackTrace) {
  //                                 print(
  //                                   'Restaurant image[$index] error: $error',
  //                                 );

  //                                 return Container(
  //                                   height: galleryHeight,
  //                                   width: galleryItemWidth,
  //                                   color: const Color(0xFFC4C4C4),
  //                                   child: const Center(
  //                                     child: Icon(
  //                                       Icons.error,
  //                                       color: Colors.grey,
  //                                     ),
  //                                   ),
  //                                 );
  //                               },
  //                             ),
  //                           ),
  //                         ),
  //                       );
  //                     } else {
  //                       return GestureDetector(
  //                         onTap: _showImageSourceDialog,
  //                         child: Container(
  //                           margin: EdgeInsets.only(
  //                             right: isMobile ? 10.w : 10.0,
  //                           ),
  //                           height: galleryHeight,
  //                           width: galleryItemWidth,
  //                           decoration: BoxDecoration(
  //                             color: const Color(0xFFC4C4C4),
  //                             borderRadius: BorderRadius.circular(
  //                               isMobile ? 10.r : 10.0,
  //                             ),
  //                           ),
  //                           child: Center(
  //                             child: _isUploading
  //                                 ? const CircularProgressIndicator(
  //                                     color: Colors.white,
  //                                   )
  //                                 // : Icon(
  //                                 //     Icons.add,
  //                                 //     color: Colors.white,
  //                                 //     size: 50.w,
  //                                 //   ),
  //                                 : Image.asset(
  //                                     plusIcon,
  //                                     width: isMobile ? 50.w : 50.0,
  //                                     height: isMobile ? 50.w : 50.0,
  //                                     // fit: BoxFit.contain,
  //                                     color: Colors.white,
  //                                   ),
  //                           ),
  //                         ),
  //                       );
  //                     }
  //                   },
  //                 ),
  //                 ),
  //               ),
  //               SizedBox(height: gap),
  //               _responsiveContent(
  //                 child: Container(
  //                   padding: EdgeInsets.all(cardPadding),
  //                   width: double.infinity,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white,
  //                     borderRadius: BorderRadius.circular(cardRadius),
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: Colors.black.withOpacity(0.3),
  //                         blurRadius: isMobile ? 10.r : 10.0,
  //                         offset: Offset(0, isMobile ? 4.r : 4.0),
  //                       ),
  //                     ],
  //                   ),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.end,
  //                         children: [
  //                           GestureDetector(
  //                             onTap: () {
  //                               Navigator.push(
  //                                 context,
  //                                 MaterialPageRoute(
  //                                   builder: (context) => RestaurantProfileEdit(
  //                                     profile: _profile,
  //                                   ),
  //                                 ),
  //                               );
  //                             },
  //                             // child: Icon(
  //                             //   Icons.edit_square,
  //                             //   size: 20.w,
  //                             //   color: Colors.black54,
  //                             // ),
  //                             child: Image.asset(
  //                               editIcon,
  //                               width: icon20,
  //                               height: icon20,
  //                               // color: Colors.black54,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       Row(
  //                         children: [
  //                         Image.asset(
  //                             listMenuIcon,
  //                             width: icon15,
  //                             height: icon15,
  //                           ),
  //                         Expanded(
  //                             child: Container(
  //                               height: 0.5,
  //                               color: appTextColor3,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       Padding(
  //                         padding: EdgeInsets.only(
  //                           top: isMobile ? 5.h : 6.0,
  //                           right: isMobile ? 10.w : 10.0,
  //                           left: isMobile ? 30.w : 30.0,
  //                           bottom: isMobile ? 5.h : 6.0,
  //                         ),
  //                         child: AppText(
  //                           text:
  //                               (_profile?.description != null &&
  //                                   _profile!.description.isNotEmpty)
  //                               ? _profile!.description
  //                               : "No description available.",
  //                           size: 12,
  //                           fontWeight: FontWeight.w400,
  //                           color: appTextColor2,
  //                           lineSpacing: 1.2,
  //                         ),
  //                       ),
  //                       Row(
  //                         children: [
  //                           Image.asset(
  //                             dishesIcon,
  //                             width: icon20,
  //                             height: icon20,
  //                             // color: appTextColor3,
  //                           ),
  //                           Expanded(
  //                             child: Container(
  //                               height: 0.5,
  //                               color: appTextColor3,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       Padding(
  //                         padding: EdgeInsets.only(
  //                           top: isMobile ? 5.h : 6.0,
  //                           right: isMobile ? 10.w : 10.0,
  //                           left: isMobile ? 30.w : 30.0,
  //                           bottom: isMobile ? 5.h : 6.0,
  //                         ),
  //                         child: AppText(
  //                           text: _profile?.availableDishes ?? "-",
  //                           size: 12,
  //                           fontWeight: FontWeight.w400,
  //                           color: appTextColor2,
  //                         ),
  //                       ),
  //                       Row(
  //                         children: [
  //                           // Icon(Icons.home, size: 20.w, color: appTextColor3),
  //                           Image.asset(
  //                             addressPinIcon,
  //                             width: icon20,
  //                             height: icon20,
  //                             // color: appTextColor3,
  //                           ),
  //                           Expanded(
  //                             child: Container(
  //                               height: 0.5,
  //                               color: appTextColor3,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       Padding(
  //                         padding: EdgeInsets.only(
  //                           top: isMobile ? 5.h : 6.0,
  //                           right: isMobile ? 10.w : 10.0,
  //                           left: isMobile ? 30.w : 30.0,
  //                           bottom: isMobile ? 5.h : 6.0,
  //                         ),
  //                         child: AppText(
  //                           text: _profile?.address ?? "-",
  //                           size: 12,
  //                           fontWeight: FontWeight.w400,
  //                           color: appTextColor2,
  //                           lineSpacing: 1.2,
  //                         ),
  //                       ),
  //                       Row(
  //                         children: [
  //                           Image.asset(
  //                             landPhoneIcon,
  //                             width: icon20,
  //                             height: icon20,
  //                             // color: appTextColor3,
  //                           ),
  //                           Expanded(
  //                             child: Container(
  //                               height: 0.5,
  //                               color: appTextColor3,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       Padding(
  //                         padding: EdgeInsets.only(
  //                           top: isMobile ? 5.h : 6.0,
  //                           right: isMobile ? 10.w : 10.0,
  //                           left: isMobile ? 30.w : 30.0,
  //                           bottom: isMobile ? 5.h : 6.0,
  //                         ),
  //                         child: AppText(
  //                           text: _profile?.phone ?? "-",
  //                           size: 12,
  //                           fontWeight: FontWeight.w400,
  //                           color: appTextColor2,
  //                           lineSpacing: 1.2,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               SizedBox(height: gap),
  //               _responsiveContent(
  //                 child: Wrap(
  //                   spacing: isMobile ? 8.w : 8.0,
  //                   runSpacing: isMobile ? 8.h : 8.0,
  //                   children: [
  //                     if ((_profile?.banquetService ?? 0) == 1)
  //                       _serviceBadge("Banquet"),
  //                     if ((_profile?.takeawayService ?? 0) == 1)
  //                       _serviceBadge("Takeaway"),
  //                     if ((_profile?.deliveryService ?? 0) == 1)
  //                       _serviceBadge("Delivery"),
  //                   ],
  //                 ),
  //               ),
  //               _responsiveContent(
  //                 padding: EdgeInsets.symmetric(
  //                   horizontal: pagePadding,
  //                   vertical: isMobile ? 20.h : 24.0,
  //                 ),
  //                 child: AppButton(
  //                   bgColor1: const Color(0xFFF97A0D),
  //                   bgColor2: const Color(0xFF934808),
  //                   borderRadius: isMobile ? 15.r : 15.0,
  //                   text: "Add Menu",
  //                   onPressed: () {
  //                     setState(() {
  //                       isButtonOpen = !isButtonOpen;
  //                     });
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         if (isProfileOpen)
  //           Stack(
  //             children: [
  //               Container(
  //                 height: double.infinity,
  //                 width: double.infinity,
  //                 color: Colors.black.withOpacity(0.6),
  //               ),
  //               Center(
  //                 child: Padding(
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: isMobile ? 30.w : pagePadding,
  //                   ),
  //                   child: Container(
  //                     width: isMobile ? double.infinity : 420.0,
  //                     padding: EdgeInsets.all(isMobile ? 20.w : 20.0),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(modalRadius),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: Colors.black.withOpacity(0.1),
  //                           blurRadius: isMobile ? 10.r : 10.0,
  //                           offset: Offset(0, isMobile ? 4.r : 4.0),
  //                         ),
  //                       ],
  //                     ),
  //                     child: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Container(
  //                           width: double.infinity,
  //                           height: isMobile ? 150.h : 170.0,
  //                           padding: EdgeInsets.all(isMobile ? 10.w : 10.0),
  //                           decoration: BoxDecoration(
  //                             color: menuUploadBoxColor,
  //                             borderRadius: BorderRadius.circular(modalRadius),
  //                             boxShadow: [
  //                               BoxShadow(
  //                                 color: Colors.black.withOpacity(0.1),
  //                                 blurRadius: isMobile ? 10.r : 10.0,
  //                                 offset: Offset(0, isMobile ? 4.r : 4.0),
  //                               ),
  //                             ],
  //                           ),
  //                           child: _selectedImage != null
  //                               ? ClipRRect(
  //                                   borderRadius: BorderRadius.circular(
  //                                     isMobile ? 10.r : 10.0,
  //                                   ),
  //                                   child: Image.file(
  //                                     _selectedImage!,
  //                                     fit: BoxFit.cover,
  //                                     width: double.infinity,
  //                                     height: double.infinity,
  //                                   ),
  //                                 )
  //                               : GestureDetector(
  //                                   onTap: _showImageSourceDialog,
  //                                   child: Column(
  //                                     mainAxisAlignment:
  //                                         MainAxisAlignment.center,
  //                                     crossAxisAlignment:
  //                                         CrossAxisAlignment.center,
  //                                     children: [
  //                                       Icon(
  //                                         Icons.file_upload_outlined,
  //                                         color: Colors.black,
  //                                         size: isMobile ? 30.w : 30.0,
  //                                       ),
  //                                       SizedBox(
  //                                         height: isMobile ? 10.h : 10.0,
  //                                       ),
  //                                       AppText(
  //                                         text: "Click here to choose",
  //                                         size: 15,
  //                                         fontWeight: FontWeight.w400,
  //                                         color: appTextColor2,
  //                                       ),
  //                                       AppText(
  //                                         text: "your image",
  //                                         size: 15,
  //                                         fontWeight: FontWeight.w400,
  //                                         color: appTextColor2,
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ),
  //                         ),
  //                         SizedBox(height: isMobile ? 20.h : 20.0),
  //                         SizedBox(
  //                           width: isMobile ? 150.w : 150.0,
  //                           height: isMobile ? 50.h : 48.0,
  //                           child: AppButton(
  //                             text: _isUploading ? 'Uploading...' : 'Upload',
  //                             size: 15,
  //                             onPressed: _isUploading
  //                                 ? () {}
  //                                 : () {
  //                                     if (_selectedImage != null) {
  //                                       _uploadImage(_selectedImage!);
  //                                     } else {
  //                                       _showImageSourceDialog();
  //                                     }
  //                                   },
  //                             bgColor1: Colors.green,
  //                             bgColor2: Colors.green,
  //                             borderRadius: isMobile ? 10.r : 10.0,
  //                           ),
  //                         ),
  //                         SizedBox(height: isMobile ? 20.h : 20.0),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         if (isButtonOpen)
  //           Stack(
  //             children: [
  //               Container(
  //                 height: double.infinity,
  //                 width: double.infinity,
  //                 color: Colors.black.withOpacity(0.6),
  //               ),
  //               Center(
  //                 child: Padding(
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: isMobile ? 30.w : pagePadding,
  //                   ),
  //                   child: Container(
  //                     height: isMobile ? 250.h : null,
  //                     width: isMobile ? double.infinity : 420.0,
  //                     padding: EdgeInsets.only(
  //                       left: isMobile ? 40.w : 40.0,
  //                       right: isMobile ? 40.w : 40.0,
  //                       top: isMobile ? 30.h : 30.0,
  //                       bottom: isMobile ? 30.h : 30.0,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(modalRadius),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: Colors.black.withOpacity(0.1),
  //                           blurRadius: isMobile ? 10.r : 10.0,
  //                           offset: Offset(0, isMobile ? 4.r : 4.0),
  //                         ),
  //                       ],
  //                     ),
  //                     child: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         Column(
  //                           children: [
  //                             SizedBox(
  //                               width: double.infinity,
  //                               child: AppButton(
  //                                 text: 'Add Entire Menu',
  //                                 bgColor1: appTextColor,
  //                                 bgColor2: appTextColor,
  //                                 borderRadius: 13,
  //                                 height: isMobile ? 50.h : 48.0,
  //                                 size: 15,
  //                                 onPressed: () {
  //                                   setState(() {
  //                                     isButtonOpen = !isButtonOpen;
  //                                     slideRightWidget(
  //                                       newPage: MenuUpload(),
  //                                       context: context,
  //                                     );
  //                                     // Navigator.push(
  //                                     //   context,
  //                                     //   MaterialPageRoute(
  //                                     //     builder: (context) => MenuUpload(),
  //                                     //   ),
  //                                     // );
  //                                   });
  //                                 },
  //                               ),
  //                             ),
  //                             SizedBox(height: isMobile ? 15.h : 15.0),
  //                             SizedBox(
  //                               width: double.infinity,
  //                               child: AppButton(
  //                                 text: 'Add Individual Items',
  //                                 bgColor1: appTextColor,
  //                                 bgColor2: appTextColor,
  //                                 borderRadius: 13,
  //                                 height: isMobile ? 50.h : 48.0,

  //                                 size: 15,
  //                                 onPressed: () {
  //                                   setState(() {
  //                                     isButtonOpen = !isButtonOpen;
  //                                     Navigator.push(
  //                                       context,
  //                                       MaterialPageRoute(
  //                                         builder: (context) =>
  //                                             IndividualMenuUpload(),
  //                                       ),
  //                                     );
  //                                   });
  //                                 },
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //       ],
  //     ),
  //   );
  // }
}
