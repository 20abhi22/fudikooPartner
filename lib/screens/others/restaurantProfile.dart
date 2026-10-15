import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/auth_network_image.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/individualMenuUpload.dart';
import 'package:fudiko/screens/others/menuUpload.dart';
import 'package:fudiko/screens/others/restaurantProfileEdit.dart';
import 'package:fudiko/services/profile-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/error_messages.dart';
import 'package:fudiko/utils/snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RestaurantProfile extends StatefulWidget {
  const RestaurantProfile({super.key});

  @override
  State<RestaurantProfile> createState() => _RestaurantProfileState();
}

class _RestaurantProfileState extends State<RestaurantProfile>
    with WidgetsBindingObserver {
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
  double? _selectedImageAspectRatio;
  File? _selectedProfilePhoto;

  // ── Badge-anchor measurement state ─────────────────────────────────────
  final GlobalKey _bannerStackKey = GlobalKey();
  final GlobalKey _thirdStarKey = GlobalKey();
  Offset? _badgeAnchor; // 3rd star's bottom-center, relative to banner Stack

  void _showImageSizeMessage() {
    if (!mounted) return;
    showErrorSnack(context, 'Image upload failed. The maximum size is 10 MB.');
  }

  bool _isUploadTimeout(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
  }

  void _showUploadTimeoutMessage() {
    if (!mounted) return;
    showErrorSnack(
      context,
      'Upload timed out. Check your connection and try again.',
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

  Future<double?> _resolveImageAspectRatio(File file) async {
    try {
      final decoded = await decodeImageFromList(await file.readAsBytes());
      if (decoded.width == 0 || decoded.height == 0) return null;
      return decoded.width / decoded.height;
    } catch (_) {
      return null;
    }
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
    WidgetsBinding.instance.addObserver(this);
    _fetchProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBadgeAnchor());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Rotation / font-scale changes can change wrap height — re-measure.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBadgeAnchor());
  }

  void _measureBadgeAnchor() {
    final starBox =
        _thirdStarKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox =
        _bannerStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (starBox == null || stackBox == null || !starBox.attached) return;

    final starTopLeftInStack =
        stackBox.globalToLocal(starBox.localToGlobal(Offset.zero));
    final starCenterX = starTopLeftInStack.dx + starBox.size.width / 2;
    // Anchor the badge to the banner's actual rendered bottom edge (not
    // just below the star) so it always lands fully in the white space
    // beneath the banner, regardless of how tall the banner grows.
    final bannerBottom = stackBox.size.height;
    final anchor = Offset(starCenterX, bannerBottom);

    if (_badgeAnchor != anchor && mounted) {
      setState(() => _badgeAnchor = anchor);
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _partnerService.getProfile();
      if (!mounted) return;
      debugPrint(
        'Partner profile images: ${profile.restaurantImages?.map((i) => i.image).toList()}',
      );
      setState(() => _profile = profile);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _measureBadgeAnchor());
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
          showErrorSnack(context, 'Camera permission denied');
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
        final aspectRatio = await _resolveImageAspectRatio(imageFile);
        if (!mounted) return;
        setState(() {
          _selectedImage = imageFile;
          _selectedImageAspectRatio = aspectRatio;
          _isUploading = false;
          _imageUploadStatus = '';
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnack(
          context,
          friendlyErrorMessage(
            e,
            fallback: 'We could not open that image. Please try another.',
          ),
        );
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
        showSuccessSnack(
          context,
          response['message'] ?? 'Image uploaded successfully',
        );
        setState(() {
          isProfileOpen = false;
          _selectedImage = null; // ← CLEAR ON SUCCESS
          _selectedImageAspectRatio = null;
        });
        _fetchProfile();
      } else {
        showErrorSnack(
          context,
          response['message'] ?? 'Failed to upload image',
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
        showErrorSnack(context, _uploadErrorMessage(e, 'Image upload failed'));
      }
    } catch (e) {
      if (mounted) {
        showErrorSnack(
          context,
          friendlyErrorMessage(
            e,
            fallback: 'We could not upload that image. Please try again.',
          ),
        );
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
                final response = await _partnerService.deleteRestaurantImage(
                  imageUuid,
                );
                if (!mounted) return;

                showStatusSnack(
                  this.context,
                  response['status'] == true,
                  response['message']?.toString() ??
                      'Restaurant image deleted successfully',
                );

                if (response['status'] == true) {
                  if (context.mounted) Navigator.of(context).pop();
                  await _fetchProfile();
                  return;
                }
              } catch (e) {
                if (!mounted) return;
                showErrorSnack(
                  this.context,
                  friendlyErrorMessage(
                    e,
                    fallback:
                        'We could not delete that image. Please try again.',
                  ),
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
                            child: AuthNetworkImage(
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
          showErrorSnack(context, 'Camera permission denied');
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
      showErrorSnack(
        context,
        friendlyErrorMessage(
          e,
          fallback: 'We could not open that photo. Please try another.',
        ),
      );
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
        showSuccessSnack(
          context,
          response['message'] ?? 'Profile photo updated successfully',
        );
        _fetchProfile();
      } else {
        showErrorSnack(
          context,
          response['message'] ?? 'Failed to update photo',
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
      showErrorSnack(
        context,
        _uploadErrorMessage(e, 'Profile photo upload failed'),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(
        context,
        friendlyErrorMessage(
          e,
          fallback: 'We could not update your profile photo. Please try again.',
        ),
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

  // ── Banner (responsive height, measured badge anchor) ──────────────────
  Widget _buildBanner({
    required double bannerMinHeight,
    required double heroPadding,
    required double heroHeaderWidth,
    required double heroTitleSize,
    required double heroTypeSize,
    required double heroBodySize,
    required double heroLocationIconSize,
    required double heroLocationGap,
    required double heroStarSize,
    required double verificationBadgeSize,
    required double avatarSize,
    required double avatarOverlap,
    required double avatarRight,
    required bool isMobile,
  }) {
    return Stack(
      key: _bannerStackKey,
      clipBehavior: Clip.none,
      children: [
        // Background image fills whatever height the content ends up
        // needing. It does NOT determine the Stack's size — the content
        // Column below (a non-Positioned child) does that.
        Positioned.fill(
          child: Image.asset(
            'assets/images/banner1.png',
            fit: BoxFit.cover,
          ),
        ),

        // Content — sizes the Stack's HEIGHT (via minHeight + intrinsic
        // content height). The outer SizedBox(width: double.infinity)
        // forces the Stack's WIDTH to fill the available space, so the
        // Positioned.fill banner image behind it still spans edge-to-edge
        // instead of shrinking to hug the text content's width.
        //
        // NotificationListener + SizeChangedLayoutNotifier: AppText
        // translates its text ASYNCHRONOUSLY (see AppText._translate()),
        // so the name/type/address can reflow to a different number of
        // lines well after the initial frame — moving the star row and
        // silently invalidating a one-time badge measurement. This
        // re-measures the badge anchor any time this content's rendered
        // size changes, for any reason (translation landing late, font
        // scale, text length), not just right after the profile loads.
        NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (notification) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _measureBadgeAnchor());
            return false;
          },
          child: SizeChangedLayoutNotifier(
            child: SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: bannerMinHeight),
                child: Padding(
                  padding: EdgeInsets.all(heroPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                SizedBox(
                  width: heroHeaderWidth,
                  child: AppText(
                    text: _profile?.name ?? "Loading...",
                    size: heroTitleSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    // AppText only defaults softWrap=true when maxLines is
                    // set — since we intentionally have no maxLines (full
                    // name, no truncation), softWrap must be set explicitly
                    // or the text clips mid-word instead of wrapping.
                    softWrap: true,
                  ),
                ),
                SizedBox(
                  width: heroHeaderWidth,
                  child: AppText(
                    text: _profile?.type ?? "Loading...",
                    size: heroTypeSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: heroHeaderWidth,
                  child: Row(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 10.h : 10.0),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: () {
                    final rating =
                        double.tryParse(_profile?.reviewStar ?? '') ?? 0;
                    final filledStars = rating.clamp(0, 5).round();

                    return List.generate(5, (index) {
                      final star = Icon(
                        index < filledStars
                            ? Icons.star
                            : Icons.star_outline,
                        color: Colors.white,
                        size: heroStarSize,
                      );
                      return index == 2
                          ? Container(key: _thirdStarKey, child: star)
                          : star;
                    });
                  }(),
                ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Verification badge — positioned from the MEASURED 3rd-star
        // anchor. Hidden until the first measurement completes (one
        // frame), which is imperceptible in practice.
        if (_badgeAnchor != null)
          Positioned(
            left: _badgeAnchor!.dx - (verificationBadgeSize / 2),
            // Sit just below the banner's bottom edge, in the white space.
            top: _badgeAnchor!.dy + 8.0,
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

        // Avatar — hangs below the banner via negative bottom offset,
        // independent of the banner's now-dynamic height.
        Positioned(
          bottom: -avatarOverlap,
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
                    ? Image.file(_selectedProfilePhoto!, fit: BoxFit.cover)
                    : _profile?.image != null
                    ? AuthNetworkImage(
                        _profile!.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/restaurantLogo.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : (_profile?.images != null &&
                          _profile!.images!.isNotEmpty)
                    ? AuthNetworkImage(
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

    // Renamed from `bannerHeight` → `bannerMinHeight`: this is now a floor,
    // not a fixed height. The banner Stack grows taller automatically if
    // the hero content (title/type/address/stars) needs more room.
    final bannerMinHeight = isWideShortPhone
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

    final isOverlayOpen = isProfileOpen || isButtonOpen;

    return PopScope(
      canPop: !isOverlayOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isProfileOpen) {
          setState(() => isProfileOpen = false);
        } else if (isButtonOpen) {
          setState(() => isButtonOpen = false);
        }
      },
      child: Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Banner + Avatar ──────────────────────────────────────
                _buildBanner(
                  bannerMinHeight: bannerMinHeight,
                  heroPadding: heroPadding,
                  heroHeaderWidth: heroHeaderWidth,
                  heroTitleSize: heroTitleSize,
                  heroTypeSize: heroTypeSize,
                  heroBodySize: heroBodySize,
                  heroLocationIconSize: heroLocationIconSize,
                  heroLocationGap: heroLocationGap,
                  heroStarSize: heroStarSize,
                  verificationBadgeSize: verificationBadgeSize,
                  avatarSize: avatarSize,
                  avatarOverlap: avatarOverlap,
                  avatarRight: avatarRight,
                  isMobile: isMobile,
                ),

                SizedBox(height: avatarOverlap + gap),

                SizedBox(height: gap),

                // ── Gallery ───────────────────────────────────────────────
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
                                    child: AuthNetworkImage(
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

                // ── Info card ─────────────────────────────────────────────
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

                // ── Service badges ────────────────────────────────────────
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

                // ── Add Menu button ───────────────────────────────────────
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

          // ── Image upload overlay ──────────────────────────────────────
          if (isProfileOpen)
            _buildOverlay(
              isMobile: isMobile,
              pagePadding: pagePadding,
              modalRadius: modalRadius,
              onDismiss: () => setState(() => isProfileOpen = false),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedImage != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: isMobile ? 260.h : 280.0,
                      ),
                      child: Container(
                        width: double.infinity,
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(modalRadius),
                          child: AspectRatio(
                            // Falls back to a sane default while the
                            // resolution is still being decoded, so the box
                            // doesn't jump from square to a wildly different
                            // shape once the real ratio lands.
                            aspectRatio: _selectedImageAspectRatio ?? (4 / 3),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
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
                      child: GestureDetector(
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

          // ── Add Menu modal ────────────────────────────────────────────
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
      ),
    );
  }
}
