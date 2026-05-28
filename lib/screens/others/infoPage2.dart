import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/descriptionBox.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/infoPage3.dart';
import 'package:fudiko/utils/constants.dart';

class InfoPage2 extends StatefulWidget {
  final String establishmentName;
  final String establishmentType;
  final String locationId;
  final File? profileImage;
  const InfoPage2 ({super.key, required this.establishmentName, required this.establishmentType, required this.locationId, this.profileImage});

  @override
  State<InfoPage2> createState() => _InfoPage2State();
}

class _InfoPage2State extends State<InfoPage2> {


  TextEditingController descriptionController = TextEditingController();
  TextEditingController dishesController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController contactController = TextEditingController();


@override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(horizontal: 30.w).copyWith(
          top: 60.h,
          bottom: 40.h,   // ✅ ensures button is visible above keyboard
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
        
        
              DescriptionTextArea(
                hintText: "Describe your shop in a short and clear way so customers quickly know your food and theme.",
        
                maxLength: 450,
                icon: Icons.list,
                onChanged: (value) {
                  setState(() {
                    descriptionController.text = value;
                  });
                },
              ),
              SizedBox(height: 20.h),
              AppTextFeild(text: "Available dishes", icon: Icons.fastfood,iconColor: appTextColor,controller: dishesController,),
              SizedBox(height: 20.h),
              AppTextFeild(text: "Address", icon: Icons.home,iconColor: appTextColor,controller: addressController,),
              SizedBox(height: 20.h),
              AppTextFeild(text: "Contact number", icon: Icons.phone,iconColor: appTextColor,controller: contactController,),
        
              SizedBox(height: 150.h),
              AppButton(text: 'Continue', onPressed: () {
                if(descriptionController.text.isNotEmpty && dishesController.text.isNotEmpty && addressController.text.isNotEmpty && contactController.text.isNotEmpty){
                slideRightWidget(newPage: 
                
                InfoPage3(
                        establishmentName: widget.establishmentName,
                        establishmentType: widget.establishmentType,
                        locationId: widget.locationId,
                        description: descriptionController.text,
                        dishes: dishesController.text,
                        address: addressController.text,
                        contact: contactController.text,
                        profileImage: widget.profileImage,
                      ), context: context);
                
                
                
                 // Navigator.push(
                  //     context,
                  //     MaterialPageRoute(builder: (context) => InfoPage3(
                  //       establishmentName: widget.establishmentName,
                  //       establishmentType: widget.establishmentType,
                  //       locationId: widget.locationId,
                  //       description: descriptionController.text,
                  //       dishes: dishesController.text,
                  //       address: addressController.text,
                  //       contact: contactController.text,
                  //       profileImage: widget.profileImage,
                  //     )),
                  //   );
                }else{
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all the fields')));
                }
        
              }),
            ],
          ),
        ),
      ),
    );
  }
}
