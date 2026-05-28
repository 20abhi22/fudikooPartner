import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appswitch.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/models/registration/complete-registration.dart';
import 'package:fudiko/models/registration/mapplace-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/agreement.dart';
import 'package:fudiko/screens/others/infoPage4.dart';
import 'package:fudiko/services/map-service.dart';
import 'package:fudiko/services/registration-service.dart';
import 'package:fudiko/utils/constants.dart';

class InfoPage3 extends StatefulWidget {
  final String establishmentName;
  final String establishmentType;
  final String locationId;
  final String description;
  final String dishes;
  final String address;
  final String contact;
  final File? profileImage;

  const InfoPage3({
    super.key,
    required this.establishmentName,
    required this.establishmentType,
    required this.locationId,
    required this.description,
    required this.dishes,
    required this.address,
    required this.contact,
    this.profileImage,
  });

  @override
  State<InfoPage3> createState() => _InfoPage3State();
}

class _InfoPage3State extends State<InfoPage3> {
  bool banquetToggle = false;
  TextEditingController banquetServiceController = TextEditingController();
  @override
  void initState() {
    banquetServiceController.text = "0";
    takeawayController.text = "1";
    deliveryServiceController.text = "1";
    distanceController.text = selectedDistance?.split(' ')[2] ?? '';
    typeOfRestaurantController.text = selectedRestaurantType;
    super.initState();
  }

  @override
  void dispose() {
    banquetServiceController.dispose();
    takeawayController.dispose();
    deliveryServiceController.dispose();
    distanceController.dispose();
    typeOfRestaurantController.dispose();
    super.dispose();
  }

  MapService mapService = MapService();
  RegistrationAuthService registrationAuthService = RegistrationAuthService();
  final List<String> distances = [
    'Up to 1 km',
    'Up to 2 km',
    'Up to 3 km',
    'Up to 4 km',
    'Up to 5 km',
    'Up to 6 km',
    'Up to 7 km',
    'Up to 8 km',
    'Up to 9 km',
    'Up to 10 km',
    'More than 10 km',
  ];
  String selectedRestaurantType = 'Pure Vegetarian';
  String? selectedDistance = 'Up to 1 km';
  TextEditingController takeawayController = TextEditingController();
  TextEditingController deliveryServiceController = TextEditingController();
  TextEditingController distanceController = TextEditingController();
  TextEditingController typeOfRestaurantController = TextEditingController();

  Future<void> complteRegistration() async {
    if (takeawayController.text.isEmpty ||
        deliveryServiceController.text.isEmpty ||
        distanceController.text.isEmpty ||
        typeOfRestaurantController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    } else {
      final parts = widget.locationId.split(',');
final lat = parts[0];
final lng = parts[1];
      print(lat);
      print(lng);


      
      CompleteRegistrationModel details = CompleteRegistrationModel(
        name: widget.establishmentName,
        type: widget.establishmentType,
        address: widget.address,
        phone: widget.contact,
        lat: lat,
        lng: lng,
        description: widget.description,
        availableDishes: widget.dishes,
        banquetService: banquetServiceController.text,
        takeawayService: takeawayController.text,
        deliveryService: deliveryServiceController.text,
        deliveryServiceArea: distanceController.text,
        restaurantTypw: typeOfRestaurantController.text,
        image: widget.profileImage,
      );
      final payload = {
      "name": details.name,
      "type": details.type,
      "address": details.address,
      "phone": details.phone,
      "lat": details.lat,
      "lng": details.lng,
      "description": details.description,
      "availableDishes": details.availableDishes,
      "banquetService": details.banquetService,
      "takeawayService": details.takeawayService,
      "deliveryService": details.deliveryService,
      "deliveryServiceArea": details.deliveryServiceArea,
      "restaurantTypw": details.restaurantTypw,
      "image": details.image,
    };

print(payload);
      CompleteRegistrationModelResponse response = await registrationAuthService.completeRegistration(details);
      if(response.status){
        if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(response.message)),
        );
        slideRightWidget(newPage: InfoPage4(), context: context);
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => InfoPage4()),
          // );
      }else{
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(response.message)),
        );
      }


    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20.h),
              Divider(color: appTextColor, thickness: 1, height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: "Banquet",
                      size: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    AppSwitch(initialValue: false, onToggle: (val) {
                      setState(() {
                        banquetToggle = val;
                        banquetServiceController.text = val == true ? "1" : "0";
                      });
                    }),
                  ],
                ),
              ),
              Divider(color: appTextColor, thickness: 1, height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: "Takeaway service",
                      size: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    AppSwitch(
                      initialValue: true,
                      onToggle: (val) {
                        setState(() {
                          takeawayController.text = val == true ? "1" : "0";
                        });
                      },
                    ),
                  ],
                ),
              ),
              Divider(color: appTextColor, thickness: 1, height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: "Delivery service",
                      size: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    AppSwitch(
                      initialValue: true,
                      onToggle: (val) {
                        setState(() {
                          deliveryServiceController.text = val == true
                              ? "1"
                              : "0";
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildDistanceGrid(),
              ),
              Divider(color: appTextColor, thickness: 1, height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      text: "Type of restaurant ",
                      size: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 60.w),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          text: "Pure Vegetarian",
                          size: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        Checkbox(
                          value: selectedRestaurantType == 'Pure Vegetarian',
                          onChanged: (bool? value) {
                            setState(() {
                              selectedRestaurantType = 'Pure Vegetarian';
                              typeOfRestaurantController.text =
                                  selectedRestaurantType;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Colors.green, width: 2),
                          checkColor: Colors.white,
                          activeColor: appToggleColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          text: "Non Vegetarian",
                          size: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        Checkbox(
                          value: selectedRestaurantType == 'Non Vegetarian',
                          onChanged: (bool? value) {
                            setState(() {
                              selectedRestaurantType = 'Non Vegetarian';
                              typeOfRestaurantController.text =
                                  selectedRestaurantType;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Colors.green, width: 2),
                          checkColor: Colors.white,
                          activeColor: appToggleColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          text: "Both Veg & Non-Veg",
                          size: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        Checkbox(
                          value: selectedRestaurantType == 'Both Veg & Non-Veg',
                          onChanged: (bool? value) {
                            setState(() {
                              selectedRestaurantType = 'Both Veg & Non-Veg';
                              typeOfRestaurantController.text =
                                  selectedRestaurantType;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Colors.green, width: 2),
                          checkColor: Colors.white,
                          activeColor: appToggleColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(color: appTextColor, thickness: 1, height: 20),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.w),
                child: Column(
                  children: [
                    AppText(
                      text: "By proceeding, you confirm that you have read,",
                      size: 11,
                      fontWeight: FontWeight.w400,
                      color: appLinkColor,
                      isCentered: true,
                    ),
                    AppText(
                      text:
                          "understood, and agreed to our Terms and Conditions, Privacy Policy, and Vendor Agreement.",
                      size: 11,
                      fontWeight: FontWeight.w400,
                      color: appLinkColor,
                      isCentered: true,
                    ),
                    SizedBox(height: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AgreementPage()),
                        );
                        // Handle view agreement tap
                      },
                      child: AppText(
                        text: "View Agreement",
                        size: 11,
                        fontWeight: FontWeight.bold,
                        color: appLinkColor,
                        isCentered: true,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: AppButton(
                  text: 'Proceed',
                  onPressed: () {
                    complteRegistration();

                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceGrid() {
    final left = distances.sublist(0, 5);
    final right = distances.sublist(5, 10);
    final last = distances[10];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: left.map(_buildCheckboxRow).toList(),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: right.map(_buildCheckboxRow).toList(),
              ),
            ),
          ],
        ),
        _buildCheckboxRow(last),
      ],
    );
  }

  Widget _buildCheckboxRow(String text) {
    final isChecked = selectedDistance == text;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 14.sp, color: appTextColor2),
          ),
          SizedBox(width: 15.w),
          Container(
            width: 20.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: isChecked ? appToggleColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: appToggleColor, width: 2),
            ),
            child: Checkbox(
              value: isChecked,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedDistance = text;
                    distanceController.text = text.split(' ')[2];
                  } else {
                    selectedDistance = null;
                    distanceController.text = '';
                  }
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
              side: BorderSide.none,
              checkColor: Colors.white,
              activeColor: appToggleColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
