import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/screens/others/nav/mainnav.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/translator_service.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
String selectedLanguage = TranslatorService.currentLanguage == 'ar' ? "Arabic" : "English";  
void _changeLanguage(String language, String langCode) async {
  setState(() => selectedLanguage = language);
  await TranslatorService.setLanguage(langCode); // ← await now

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MainNavPage()),
    (route) => false,
  );
}

  Widget _buildLanguageTile(String language, String langCode) {
    final bool isSelected = selectedLanguage == language;
    return GestureDetector(
      onTap: () => {_changeLanguage(language, langCode),
              setState(() {
          selectedLanguage = language;
        }),
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? appLangBg : Colors.transparent,
        ),
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: AppText(
            text: language,
            size: 15,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white :  appTextColor3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            onTap: (){
              Navigator.pop(context);
            },
            child: Padding(
              padding:  EdgeInsets.only(top: 40.h, left: 30.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Icon(
                  //   Icons.arrow_back_ios_outlined,
                  //   size: 30,
                  //   color: appTextColor3,
                  // ),
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(appTextColor3, BlendMode.srcIn),
                    child: Image.asset(
                      'assets/images/backarrow_icon.png',
                      width: 28.w,
                      fit: BoxFit.contain,),
                  ),
                ],
              ),
            ),
          ),

           SizedBox(height: 60.h),

          const Divider(thickness: 1, color: Colors.grey,height: 1,),
          _buildLanguageTile("English", "en"),

          const Divider(thickness: 1, color: Colors.grey,height: 1,),
          _buildLanguageTile("Arabic", "ar"),

          const Divider(thickness: 1, color: Colors.grey,height: 1,),
        ],
      ),
    );
  }
}
