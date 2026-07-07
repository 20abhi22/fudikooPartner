import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/menucard.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/individualMenuUpload/individual-menu-list-model.dart';
import 'package:fudiko/routetransitions.dart';
import 'package:fudiko/screens/others/individualMenuUpload2.dart';
import 'package:fudiko/services/individual-menu-upload-service.dart';
import 'package:fudiko/utils/constants.dart';

class IndividualMenuUpload extends StatefulWidget {
  const IndividualMenuUpload({super.key});

  @override
  State<IndividualMenuUpload> createState() => _IndividualMenuUploadState();
}

class _IndividualMenuUploadState extends State<IndividualMenuUpload> {
  bool _isLoading = true;
  List<IndividualMenuModel> menuList = [];
  List<IndividualMenuModel> filteredMenuList = [];
  String _selectedFilter = 'Both Active & Inactive';
  IndividualMenuUploadService individualMenuUploadService =
      IndividualMenuUploadService();

  bool _isWideShortPhone(BuildContext context) {
    return Breakpoints.isWideShortPhone(MediaQuery.sizeOf(context));
  }

  double _contentMaxWidth(Size size, bool isWideShortPhone) {
    final width = size.width;
    if (Breakpoints.isDesktop(width)) return 760;
    if (Breakpoints.isTabletDevice(size) || isWideShortPhone) return 680;
    return double.infinity;
  }

  EdgeInsetsGeometry _contentPadding(Size size, bool isWideShortPhone) {
    final width = size.width;
    if (isWideShortPhone) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    }
    final isMobile = Breakpoints.isMobileDevice(size);
    return EdgeInsets.symmetric(
      horizontal: isMobile ? 20.w : AppDimensions.padding(width),
    );
  }

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
      debugPrint('Error: $e');
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

  Future<void> _showFilterOptions() async {
    final selectedFilter = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Active', 'Inactive', 'Both Active & Inactive']
                .map(
                  (filter) => ListTile(
                    title: Text(filter),
                    onTap: () => Navigator.pop(context, filter),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );

    if (selectedFilter != null) _applyFilter(selectedFilter);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final isTabletLandscape =
        Breakpoints.isTabletDevice(size) && width > height;
    final bannerHeight = isWideShortPhone
        ? 120.0
        : isTabletLandscape
        ? 130.0
        : isMobile
        ? 150.h
        : 160.0;
    final bannerPadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(width);
    final backIconSize = isWideShortPhone
        ? 24.0
        : isMobile
        ? 32.w
        : 32.0;
    final headerGap = isWideShortPhone
        ? 16.0
        : isMobile
        ? 35.h
        : 32.0;
    final listTopPadding = isWideShortPhone
        ? 16.0
        : isMobile
        ? 30.h
        : 30.0;
    final listBottomPadding = isWideShortPhone
        ? 80.0
        : isMobile
        ? 30.h
        : 96.0;
    final cardVerticalPadding = isWideShortPhone
        ? 6.0
        : isMobile
        ? 8.h
        : 8.0;
    final loadingHeight =
        height -
        (isWideShortPhone
            ? 180.0
            : isMobile
            ? 220.h
            : 240.0);
    final fabSize = isWideShortPhone
        ? 60.0
        : isMobile
        ? 75.w
        : 72.0;
    final fabBottom = isWideShortPhone
        ? 24.0
        : isMobile
        ? 40.h
        : 40.0;
    final fabRight = isWideShortPhone
        ? 24.0
        : isMobile
        ? 20.w
        : AppDimensions.padding(width);
    final fabIconSize = isWideShortPhone
        ? 10.0
        : isMobile
        ? 10.w
        : 10.0;
    final shadowBlur = isWideShortPhone
        ? 10.0
        : isMobile
        ? 10.r
        : 10.0;
    final shadowOffset = Offset(
      0,
      isWideShortPhone
          ? 4.0
          : isMobile
          ? 4.r
          : 4.0,
    );
    final filterMaxWidth = isWideShortPhone
        ? width - 48.0
        : isMobile
        ? double.infinity
        : 240.0;
    final filterWidth = (width * 0.42).clamp(240.0, 340.0).toDouble();

    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottom, right: fabRight),
        child: GestureDetector(
          onTap: () async {
            slideRightWidget(
              newPage: const IndividualMenuUpload2(),
              context: context,
            );
            if (mounted) {
              await getAll();
            }
          },
          child: Container(
            width: fabSize,
            height: fabSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.35),
                  offset: shadowOffset,
                  blurRadius: shadowBlur,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Image.asset(
                plusIcon,
                width: fabIconSize,
                height: fabIconSize,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Colors.orange,
        onRefresh: () => getAll(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/banner1.png',
                  height: bannerHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.all(bannerPadding),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Image.asset(
                      backWhite,
                      width: backIconSize,
                      height: backIconSize,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: headerGap),
            Center(
              child: SizedBox(
                width: filterWidth.clamp(0.0, filterMaxWidth).toDouble(),
                child: AppFilterDropDown(
                  key: ValueKey(_selectedFilter),
                  fieldBorderRadius: isWideShortPhone
                      ? 6.0
                      : isMobile
                      ? 6.r
                      : 6.0,
                  hint: _selectedFilter,
                  iconImage: 'assets/images/filter_icon.png',
                  toogleDropdown: _showFilterOptions,
                ),
              ),
            ),

            if (_isLoading)
              SizedBox(
                height: loadingHeight,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (filteredMenuList.isEmpty)
              SizedBox(
                height: loadingHeight,
                child: const Center(child: Text("No Items added")),
              )
            else
              Padding(
                padding: _contentPadding(size, isWideShortPhone),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _contentMaxWidth(size, isWideShortPhone),
                    ),
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        top: listTopPadding,
                        bottom: listBottomPadding,
                      ),
                      itemCount: filteredMenuList.length,
                      itemBuilder: (context, index) {
                        final menu = filteredMenuList[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: cardVerticalPadding,
                          ),
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}
