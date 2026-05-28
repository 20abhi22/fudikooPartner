import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/individualMenuUpload.dart';
import 'package:fudiko/screens/others/menuUpload.dart';
import 'package:fudiko/screens/others/restaurantProfileEdit.dart';
import 'package:fudiko/services/profile-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class RestaurantProfile extends StatefulWidget {
  const RestaurantProfile({super.key});

  @override
  State<RestaurantProfile> createState() => _RestaurantProfileState();
}

class _RestaurantProfileState extends State<RestaurantProfile> {
  bool isProfileOpen = false;
  bool isButtonOpen = false;
  PartnerProfileModel? _profile;
  final PartnerService _partnerService = PartnerService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  File? _selectedImage;
  File? _selectedProfilePhoto;

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
      print('Error fetching partner profile: $e');
      print(stack); // ← add this
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

      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path); // ← STORE IT HERE
          isProfileOpen = true; // ← KEEP OVERLAY OPEN
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
    setState(() => _isUploading = true);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showRestaurantImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16.w),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.w),
                      color: Colors.white,
                      child: const Icon(Icons.error, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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

      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null || !mounted) return;

      final imageFile = File(pickedFile.path);
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
    // TODO: Connect this to the backend profile-photo update endpoint.
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile photo selected')));
  }

  Future<void> _showProfilePhotoSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
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
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
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
      ),
    );
  }

  Widget _serviceBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: appButtonColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
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
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Image.asset(
                      'assets/images/banner1.png',
                      height: 200.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: EdgeInsets.all(30.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: _profile?.name ?? "Loading...",
                            size: 35,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          AppText(
                            text: _profile?.type ?? "Loading...",
                            size: 25,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 15.w,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5.w),
                              AppText(
                                text: _profile?.address ?? "Loading...",
                                size: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          SizedBox(height: 20.h),
                          Row(
                            children: [
                              Wrap(
                                children: List.generate(5, (index) {
                                  final rating =
                                      double.tryParse(
                                        _profile?.reviewStar ?? '0',
                                      ) ??
                                      0;
                                  final filledStars = rating.round();
                                  return Icon(
                                    Icons.star,
                                    color: index < filledStars
                                        ? Colors.white
                                        : Colors.grey,
                                    size: 20.w,
                                  );
                                }),
                              ),
                              SizedBox(width: 10.w),
                              AppText(
                                text: (_profile?.reviewStar ?? '0'),
                                size: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10.w),
                              if (_profile?.restaurantType != null &&
                                  _profile!.restaurantType.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: AppText(
                                    text: _profile!.restaurantType,
                                    size: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: -screenWidth / 6.w,
                      right: 20.w,
                      child: GestureDetector(
                        onTap: _showProfilePhotoSourceDialog,
                        child: Container(
                          height: screenWidth / 3.w,
                          width: screenWidth / 3.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10.r,
                                offset: Offset(0, 4.r),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(4.r),
                          child: ClipOval(
                            child: _selectedProfilePhoto != null
                                ? Image.file(
                                    _selectedProfilePhoto!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : _profile?.image != null
                                ? Image.network(
                                    _profile!.image!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Profile image error: $error');
                                      return Image.asset(
                                        'assets/images/restaurantLogo.png',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : (_profile?.images != null &&
                                      _profile!.images!.isNotEmpty)
                                ? Image.network(
                                    _profile!.images!.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print(
                                        'Profile fallback image error: $error',
                                      );
                                      return Image.asset(
                                        'assets/images/restaurantLogo.png',
                                        fit: BoxFit.cover,
                                      );
                                    },
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
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.only(left: 40.w),
                  child: Image.asset(
                    'assets/images/verification.png',
                    height: 40.h,
                    width: 40.w,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 40.h),
                SizedBox(
                  height: 150.h,
                  child: ListView.builder(
                    itemCount: (_profile?.images?.length ?? 0) + 1,
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index < (_profile?.images?.length ?? 0)) {
                        print(
                          'Loading restaurant image at index $index: ${_profile!.images![index]}',
                        );
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: GestureDetector(
                            onTap: () =>
                                _showRestaurantImage(_profile!.images![index]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.network(
                                _profile!.images![index],
                                height: 150.h,
                                width: 100.w,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                    'Restaurant image[$index] error: $error',
                                  );

                                  return Container(
                                    height: 150.h,
                                    width: 100.w,
                                    color: Color(0xFFC4C4C4),
                                    child: Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Color(0xFFC4C4C4),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      } else {
                        return GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 5.w),
                            height: 150.h,
                            width: 100.w,
                            decoration: BoxDecoration(
                              color: Color(0xFFC4C4C4),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Center(
                              child: _isUploading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  // : Icon(
                                  //     Icons.add,
                                  //     color: Colors.white,
                                  //     size: 50.w,
                                  //   ),
                                  : Image.asset(
                                      plusIcon,
                                      width: 50.w,
                                      height: 50.w,
                                      // fit: BoxFit.contain,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10.r,
                          offset: Offset(0, 4.r),
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RestaurantProfileEdit(
                                      profile: _profile,
                                    ),
                                  ),
                                );
                              },
                              // child: Icon(
                              //   Icons.edit_square,
                              //   size: 20.w,
                              //   color: Colors.black54,
                              // ),
                              child: Image.asset(
                                editIcon,
                                width: 20.w,
                                height: 20.w,
                                // color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                          Image.asset(listMenuIcon,width: 15.w,height: 15.w),    
                          Expanded(
                              child: Container(
                                height: 0.5,
                                color: appTextColor3,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: 5.h,
                            right: 10.w,
                            left: 30.w,
                            bottom: 5.h,
                          ),
                          child: AppText(
                            text:
                                (_profile?.description != null &&
                                    _profile!.description.isNotEmpty)
                                ? _profile!.description
                                : "No description available.",
                            size: 12,
                            fontWeight: FontWeight.w400,
                            color: appTextColor2,
                            lineSpacing: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            Image.asset(
                              dishesIcon,
                              width: 20.w,
                              height: 20.w,
                              // color: appTextColor3,
                            ),
                            Expanded(
                              child: Container(
                                height: 0.5,
                                color: appTextColor3,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: 5.h,
                            right: 10.w,
                            left: 30.w,
                            bottom: 5.h,
                          ),
                          child: AppText(
                            text: _profile?.availableDishes ?? "-",
                            size: 12,
                            fontWeight: FontWeight.w400,
                            color: appTextColor2,
                          ),
                        ),
                        Row(
                          children: [
                            // Icon(Icons.home, size: 20.w, color: appTextColor3),
                            Image.asset(
                              addressPinIcon,
                              width: 20.w,
                              height: 20.w,
                              // color: appTextColor3,
                            ),
                            Expanded(
                              child: Container(
                                height: 0.5,
                                color: appTextColor3,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: 5.h,
                            right: 10.w,
                            left: 30.w,
                            bottom: 5.h,
                          ),
                          child: AppText(
                            text: _profile?.address ?? "-",
                            size: 12,
                            fontWeight: FontWeight.w400,
                            color: appTextColor2,
                            lineSpacing: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            Image.asset(
                              landPhoneIcon,
                              width: 20.w,
                              height: 20.w,
                              // color: appTextColor3,
                            ),
                            Expanded(
                              child: Container(
                                height: 0.5,
                                color: appTextColor3,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            top: 5.h,
                            right: 10.w,
                            left: 30.w,
                            bottom: 5.h,
                          ),
                          child: AppText(
                            text: _profile?.phone ?? "-",
                            size: 12,
                            fontWeight: FontWeight.w400,
                            color: appTextColor2,
                            lineSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Wrap(
                    spacing: 8.w,
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
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 20.h,
                  ),
                  child: AppButton(
                    bgColor1: Color(0xFFF97A0D),
                    bgColor2: Color(0xFF934808),
                    borderRadius: 15.r,
                    text: "Add Menu",
                    onPressed: () {
                      setState(() {
                        isButtonOpen = !isButtonOpen;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          if (isProfileOpen)
            Stack(
              children: [
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.6),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.r),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 150.h,
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: menuUploadBoxColor,
                              borderRadius: BorderRadius.circular(15.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10.r,
                                  offset: Offset(0, 4.r),
                                ),
                              ],
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10.r),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.file_upload_outlined,
                                          color: Colors.black,
                                          size: 30.w,
                                        ),
                                        SizedBox(height: 10.h),
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
                          SizedBox(height: 20.h),
                          SizedBox(
                            width: 150.w,
                            height: 50.h,
                            child: AppButton(
                              text: _isUploading ? 'Uploading...' : 'Upload',
                              size: 15,
                              onPressed: _isUploading
                                  ? () {}
                                  : () {
                                      if (_selectedImage != null) {
                                        _uploadImage(_selectedImage!);
                                      } else {
                                        _showImageSourceDialog();
                                      }
                                    },
                              bgColor1: Colors.green,
                              bgColor2: Colors.green,
                              borderRadius: 10.r,
                            ),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (isButtonOpen)
            Stack(
              children: [
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.6),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: Container(
                      height: 250.h,
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        left: 40.w,
                        right: 40.w,
                        top: 30.h,
                        bottom: 30.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.r),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text: 'Add Entire Menu',
                                  bgColor1: appTextColor,
                                  bgColor2: appTextColor,
                                  borderRadius: 13,
                                  height: 50.h,
                                  size: 15,
                                  onPressed: () {
                                    setState(() {
                                      isButtonOpen = !isButtonOpen;
                                      slideRightWidget(
                                        newPage: MenuUpload(),
                                        context: context,
                                      );
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) => MenuUpload(),
                                      //   ),
                                      // );
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 15.h),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text: 'Add Individual Items',
                                  bgColor1: appTextColor,
                                  bgColor2: appTextColor,
                                  borderRadius: 13,
                                  height: 50.h,

                                  size: 15,
                                  onPressed: () {
                                    setState(() {
                                      isButtonOpen = !isButtonOpen;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              IndividualMenuUpload(),
                                        ),
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
