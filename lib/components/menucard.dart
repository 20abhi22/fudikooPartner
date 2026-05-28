import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appswitch.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-delete-model.dart';
import 'package:fudiko/screens/others/individualMenuUpload2.dart';
import 'package:fudiko/screens/others/individuvalMenuUploadEdit.dart';
import 'package:fudiko/services/individual-menu-upload-service.dart';

class MenuCard extends StatefulWidget {
  final String id;
  final String url;
  final String itemName;
  final String itemPrice;
  final String itemDescription;
  final String status;
  final String itemCategory;
  final Function refreshFun;

  const MenuCard({
    super.key,
    required this.id,
    required this.url,
    required this.itemName,
    required this.itemPrice,
    required this.itemDescription,
    required this.status,
    required this.itemCategory,
    required this.refreshFun
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {

  bool isLoading = false;
  IndividualMenuUploadService individualMenuUploadService = IndividualMenuUploadService();
  Future<void> deleteMenu() async{
    setState(() {
      isLoading = true;
    });
    IndividualMenuDeleteModel menu = IndividualMenuDeleteModel(menuId: widget.id);
    IndividualMenuDeleteResponseModel response = await individualMenuUploadService.deleteMenu(menu);
    setState(() {
      isLoading = false;
    });
    if(response.status){
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    }else{
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    }
    widget.refreshFun();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                widget.url,
                height: 100.h,
                width: 100.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100.h,
                  width: 100.w,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, color: Colors.grey[600]),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppText(
                          text: widget.itemName.toUpperCase(),
                          size: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      AppSwitch(
                        initialValue: widget.status == "Active",
                        onToggle: (val) {},
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  AppText(
                    text: "₹ ${widget.itemPrice}",
                    size: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),

                  SizedBox(height: 6.h),

                  AppText(
                    text: widget.itemDescription,
                    size: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[800]!,
                    lineSpacing: 1.3,
                  ),

                  SizedBox(height: 12.h),

                  // Edit & Delete Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 30.h,
                          child: AppButton(
                            text: "Edit",
                            size: 10,
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>IndividualMenuUploadEdit(
                                menuId: widget.id,
                                itemPrice: widget.itemPrice,
                                itemDescription: widget.itemDescription,
                                itemName: widget.itemName,
                                itemCategory: widget.itemCategory,
                                itemImage: widget.url,
                              ))).then((_){
                                widget.refreshFun();
                              });
                            },
                            bgColor1: Colors.blue,
                            bgColor2: Colors.blue,
                            borderRadius: 5,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: SizedBox(
                          height: 30.h,
                          child: AppButton(
                            text: isLoading ? "Deleting..." : "Delete",
                            size: 10,
                            onPressed: () {
                              deleteMenu();
                            },
                            bgColor1: Colors.red,
                            bgColor2: Colors.red,
                            borderRadius: 5,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
