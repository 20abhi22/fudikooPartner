import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/menucard.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-list-model.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-upload-model.dart';
import 'package:fudiko/models/menuupload/menu-list-model.dart';
import 'package:fudiko/screens/others/individualMenuUpload2.dart';
import 'package:fudiko/services/individual-menu-upload-service.dart';
import 'package:fudiko/services/menu-upload-service.dart';
import 'package:fudiko/utils/constants.dart';

class IndividualMenuUpload extends StatefulWidget {
  const IndividualMenuUpload({super.key});

  @override
  State<IndividualMenuUpload> createState() => _IndividualMenuUploadState();
}

class _IndividualMenuUploadState extends State<IndividualMenuUpload> {
  bool isOpen = false;
  bool _isLoading = true;
  List<IndividualMenuModel> menuList = [];
  List<IndividualMenuModel> filteredMenuList = [];
  String _selectedFilter = 'Both Active & Inactive';
  List<String> menuPdfList = ['Chinese Menu', 'Indian Menu'];
  IndividualMenuUploadService individualMenuUploadService =
      IndividualMenuUploadService();

  @override
  void initState() {
    getAll();
    super.initState();
  }

  Future<void> getAll() async {
    setState(() => _isLoading = true);
    try {
      IndividualMenuListModel menu = await individualMenuUploadService
          .getAllMenus();
      setState(() {
        menuList = menu.menus;
        _applyFilter(_selectedFilter, shouldRebuild: false);
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _isActiveStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'active' || normalized == '1' || normalized == 'true';
  }

  bool _isInactiveStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'inactive' ||
        normalized == '0' ||
        normalized == 'false';
  }

  void _applyFilter(String filterValue, {bool shouldRebuild = true}) {
    final nextList = filterValue == 'Active'
        ? menuList.where((item) => _isActiveStatus(item.status)).toList()
        : filterValue == 'Inactive'
        ? menuList.where((item) => _isInactiveStatus(item.status)).toList()
        : List<IndividualMenuModel>.from(menuList);

    if (shouldRebuild) {
      setState(() {
        _selectedFilter = filterValue;
        filteredMenuList = nextList;
      });
      return;
    }

    _selectedFilter = filterValue;
    filteredMenuList = nextList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 40.h, right: 20.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10.r,
              offset: Offset(0, 4.r),
            ),
          ],
        ),
        // child: IconButton(
        //   onPressed: () {
        //     setState(() {
        //       isOpen = !isOpen;
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => IndividualMenuUpload2(),
        //   ),
        //       );
        //     });
        //   },
        //   icon: Icon(Icons.add, color: appButtonColor, size: 40.w),
        // ),
        child: Positioned(
          bottom: 40.h,
          right: 20.w,
          child: GestureDetector(
            onTap: () {
              setState(() {
                // isOpen = !isOpen;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IndividualMenuUpload2(),
                  ),
                );
              });
            },
            child: Container(
              width: 75.w,
              height: 75.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // uses your appButtonColor (orange) from constants
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withOpacity(0.35),
                    offset: const Offset(0, 0), // X, Y
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Image.asset(
                  plusIcon,
                  width: 10.w,
                  height: 10.h,
                  // fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
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
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Image.asset(backWhite, width: 32.w, height: 32.h),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 35.h),
          SizedBox(
            width: 220.w,
            child: AppFilterDropDown(
              items: ['Active', 'Inactive', 'Both Active & Inactive'],
              hint: 'Both Active and Inactive',
              // icon: Icons.tune,
              onChanged: (value) => _applyFilter(value),
            ),
          ),
    
          if (_isLoading)
            Expanded(child: Center(child: CircularProgressIndicator()))
          else if (filteredMenuList.isEmpty)
            Expanded(child: Center(child: Text("No Items added")))
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 30.h, bottom: 30.h),
                itemCount: filteredMenuList.length,
                itemBuilder: (context, index) {
                  final menu = filteredMenuList[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: MenuCard(
                      id: menu.uuid,
                      url: menu.itemImage,
                      itemName: menu.itemName,
                      itemDescription: menu.itemDescription,
                      itemPrice: menu.itemPrice,
                      status: menu.status,
                      itemCategory: menu.itemCategory,
                      refreshFun: () => getAll(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
