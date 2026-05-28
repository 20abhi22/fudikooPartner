import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/descriptionBox.dart';
import 'package:fudiko/screens/others/restaurantProfile.dart';
import 'package:fudiko/services/profile-service.dart';
import 'package:fudiko/utils/constants.dart';

class RestaurantBioEditPage extends StatefulWidget {
  final String establishmentName;
  final String establishmentType;
  final String location;
  final double lat;
  final double lng;
  final String description;
  final String availableDishes;
  final String phone;

  const RestaurantBioEditPage({
    super.key,
    required this.establishmentName,
    required this.establishmentType,
    required this.location,
    required this.lat,
    required this.lng,
    this.description = '',
    this.availableDishes = '',
    this.phone = '',
  });

  @override
  State<RestaurantBioEditPage> createState() => _RestaurantBioEditPageState();
}

class _RestaurantBioEditPageState extends State<RestaurantBioEditPage> {
  late TextEditingController _descriptionController;
  late TextEditingController _availableDishesController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  bool _isUpdating = false;
  final PartnerService _partnerService = PartnerService();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.description);
    _availableDishesController = TextEditingController(
      text: widget.availableDishes,
    );
    _addressController = TextEditingController(text: widget.location);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _availableDishesController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_descriptionController.text.isEmpty ||
        _availableDishesController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final response = await _partnerService.updateProfile(
        name: widget.establishmentName,
        type: widget.establishmentType,
        address: _addressController.text,
        phone: _phoneController.text,
        lat: widget.lat,
        lng: widget.lng,
        description: _descriptionController.text,
        availableDishes: _availableDishesController.text,
        restaurantType: widget.establishmentType,
      );

      if (!mounted) return;

      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Profile updated successfully',
            ),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RestaurantProfile()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update profile'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/banner1.png',
                  height: 150.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.all(30.w),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    // child: Icon(
                    //   Icons.arrow_back_ios_outlined,
                    //   size: 30.w,
                    //   color: Colors.white,
                    child: Image.asset(
                      backWhite,
                      width: 28.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 50.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DescriptionTextArea(
                      hintText:
                          "Describe your shop in a short and clear way so customers quickly know your food and theme.",
                      maxLength: 450,
                      iconImagePath: listMenuIcon,
                      iconColor: Color(0xFFD68541),
                      
                      controller: _descriptionController,
                    ),
                    SizedBox(height: 20.h),
                    AppTextFeild(
                      text: "Available dishes",
                      iconImagePath: dishesIcon,
                      iconColor: appTextColor,
                      controller: _availableDishesController,
                    ),
                    SizedBox(height: 20.h),
                    AppTextFeild(
                      text: "Address",
                      iconImagePath: addressPinIcon,
                      iconColor: appTextColor,
                      controller: _addressController,
                    ),
                    SizedBox(height: 20.h),
                    AppTextFeild(
                      text: "Contact number",
                      iconImagePath: landPhoneIcon,
                      iconColor: appTextColor,
                      controller: _phoneController,
                    ),

                    SizedBox(height: 50.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 100.w),
                      child: AppButton(
                        text: _isUpdating ? 'Updating...' : 'Update',
                        onPressed: _isUpdating ? () {} : _updateProfile,
                      ),
                    ),
                    SizedBox(height: 50.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
