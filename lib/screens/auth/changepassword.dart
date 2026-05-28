import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/apptextfeild.dart';
import 'package:fudiko/models/forgotpassword/changepassword-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/auth/login.dart';
import 'package:fudiko/services/fogotpassword-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/tokens.dart';

class ChangePassword extends StatefulWidget {
  final String? token;
  const ChangePassword({super.key,this.token});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {

  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  ForgotPasswordService forgotPasswordService = ForgotPasswordService();

  Future<void> changePassword() async{
    if(_newPassword.text == _confirmPassword.text){
      NewPasswordModel user = NewPasswordModel(newPassword: _newPassword.text);
      NewPasswordResponseModel response = await forgotPasswordService.changePassword(user,widget.token ?? await getToken());
      if(response.status){
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
        pushWidgetWhileRemove(newPage: Login(), context: context);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => Login()),
        // );
      }else{
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    }else{
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password doesn't match")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 30.w, right: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            AppText(
              text: "Set your new password",
              size: 15,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
            ),

            SizedBox(height: 40.h),
            AppTextFeild(text: "New Password", icon: Icons.lock,controller: _newPassword,),
            SizedBox(height: 20.h),
            AppTextFeild(text: "Confirm Password", icon: Icons.lock,controller: _confirmPassword,),
            SizedBox(height: 30.h),
            AppButton(text: 'Update', onPressed: () {

              changePassword();


            }),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
