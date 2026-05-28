import 'package:flutter/material.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appdropdown.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/components/menucard.dart';
import 'package:fudiko/utils/constants.dart';

class EstablishmentSelect extends StatefulWidget {
  const EstablishmentSelect({super.key});

  @override
  State<EstablishmentSelect> createState() => _EstablishmentSelectState();
}

class _EstablishmentSelectState extends State<EstablishmentSelect> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  Image.asset(
                    'assets/images/banner1.png',
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: GestureDetector(
                      onTap: (){
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back_ios_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 35),
              ConstrainedBox(
                constraints: BoxConstraints(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 90), // Optional top spacing
      
                      AppTextFeild(text: "Establishment Name"),
                      SizedBox(height: 20),
                      AppDropDown(
                        items: ['Restaurant', 'Cafe', 'Cool Bar','Bar', 'Buffet'],
                        hint: 'Establishment type',
                      ),
                      SizedBox(height: 20),
      
                      AppTextFeild(text: "Location"),
                      SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 100),
                        child: AppButton(text: 'Add', onPressed: () {}),
                      ),
                      SizedBox(height: 60), // Optional bottom spacing
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
