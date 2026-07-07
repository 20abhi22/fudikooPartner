import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/offercard.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/offer/offer-create-model.dart';
import 'package:fudiko/models/offer/offer-delete-model.dart';
import 'package:fudiko/models/offer/offer-list-model.dart';
import 'package:fudiko/models/offer/offer-return-model.dart';
import 'package:fudiko/models/offer/offer-update-model.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/services/offer-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/tab_back_handler.dart';
import 'package:fudiko/utils/tokens.dart';

class Offers extends StatefulWidget {
  final VoidCallback? onDrawerTap;
  final PartnerProfileModel? partnerProfile; // ← add
  const Offers({super.key, this.onDrawerTap, this.partnerProfile});

  @override
  State<Offers> createState() => _OffersState();
}

class _StickyFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyFilterBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyFilterBarDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _OffsetFabLocation extends FloatingActionButtonLocation {
  final double right;
  final double bottom;

  const _OffsetFabLocation({required this.right, required this.bottom});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return Offset(
      scaffoldGeometry.scaffoldSize.width -
          scaffoldGeometry.floatingActionButtonSize.width -
          right,
      scaffoldGeometry.scaffoldSize.height -
          scaffoldGeometry.floatingActionButtonSize.height -
          bottom,
    );
  }
}

class _OffersState extends State<Offers> implements TabBackHandler {
  final bool hasItem = true;
  bool isOpen = false;
  bool isEditOpen = false;
  int? selectedPercentageIndex;
  int? selectedMenuIndex;
  String selecteduuid = '';
  bool isEditingPressed = false;
  List<int> selectedWeekIndices = [];
  bool isDineInChecked = false;
  bool isTakeAwayChecked = false;
  List<OfferModel> offerList = [];
  OfferModel? selectedOffer;
  bool isDeletePressed = false;
  bool isLoading = false;
  TimeOfDay startTime = TimeOfDay(hour: 8, minute: 30);
  TimeOfDay endTime = TimeOfDay(hour: 14, minute: 0);
  String selectedOption = "Both Active & InActive";
  TextEditingController customPercentageController = TextEditingController();
  OfferService offerService = OfferService();
  List<String> percentageList = [
    "10%",
    "15%",
    "20%",
    "25%",
    "30%",
    "35%",
    "40%",
    "45%",
    "50%",
    "55%",
    "60%",
    "Custom",
  ];

  double _screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

  bool _isWideShortPhone(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Breakpoints.isWideShortPhone(size);
  }

  bool _isNarrowShortPhone(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Breakpoints.isMobileDevice(size) &&
        size.width < 500 &&
        size.height <= 720;
  }

  bool _usesTabletLayout(BuildContext context) =>
      Breakpoints.isTabletDevice(MediaQuery.sizeOf(context)) ||
      _isWideShortPhone(context);

  bool _usesMobileScale(BuildContext context) =>
      Breakpoints.isMobileDevice(MediaQuery.sizeOf(context)) &&
      !_isWideShortPhone(context);

  double _pagePadding(BuildContext context) {
    if (_isWideShortPhone(context)) return 24.0;
    return AppDimensions.padding(_screenWidth(context));
  }

  double _contentMaxWidth(BuildContext context) {
    final width = _screenWidth(context);
    if (Breakpoints.isDesktop(width)) return 860;
    if (_usesTabletLayout(context)) return 720;
    return double.infinity;
  }

  Widget _responsiveContent({
    required Widget child,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
    Alignment alignment = Alignment.topCenter,
  }) {
    return Padding(
      padding:
          padding ??
          EdgeInsets.only(
            left: _pagePadding(context),
            right: _pagePadding(context) + 4,
          ),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? _contentMaxWidth(context),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _responsiveSliverContent({
    required Widget child,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
  }) {
    return SliverToBoxAdapter(
      child: _responsiveContent(
        maxWidth: maxWidth,
        padding: padding,
        child: child,
      ),
    );
  }

  (double, double) _offerFabOffset(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    if (_isWideShortPhone(context)) return (28.0, 16.0);
    if (Breakpoints.isMobileDevice(size)) {
      if (_isCompactMobile(width)) {
        return (14.w, 8.h);
      }

      return ((width * 0.055).clamp(20.0, 28.0), 12.h);
    }

    if (Breakpoints.isTabletDevice(size)) {
      final right = (width * 0.055).clamp(32.0, 56.0);
      return (right, 18.0);
    }

    return (40.0, 16.0);
  }

  bool _isCompactMobile(double width) => width < 390;

  @override
  void initState() {
    getOffers();
    test();
    super.initState();
  }

  Future<void> test() async {
    print(await getToken());
  }

  Future<void> deleteOffer() async {
    if (isDeletePressed) {
      OfferDeleteModel offer = OfferDeleteModel(offerId: selecteduuid);
      OfferDeleteResponseModel response = await offerService.deleteOffer(offer);
      if (response.status) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
      setState(() {
        isLoading = true;
        selectedOption = "Both Active & InActive";
        offerList = [];
      });
      OfferListResponse allresponse = await offerService.getAllOffers();
      setState(() {
        offerList = allresponse.offers;
        isLoading = false;
      });
    }
  }

  Future<void> getOffers() async {
    setState(() {
      isLoading = true;
      offerList = [];
    });

    print("Selectd Option: $selectedOption");
    if (selectedOption == "Active") {
      OfferListResponse response = await offerService.getActiveOffers();
      setState(() {
        offerList = response.offers;
        isLoading = false;
      });
    } else if (selectedOption == "InActive") {
      OfferListResponse response = await offerService.getInActiveOffers();
      setState(() {
        offerList = response.offers;
        isLoading = false;
      });
    } else {
      OfferListResponse response = await offerService.getAllOffers();
      setState(() {
        offerList = response.offers;
        isLoading = false;
      });
    }

    print(offerList);
  }

  Future<void> createOffer() async {
    String? discountPercentage;
    if (selectedPercentageIndex == percentageList.length - 1) {
      discountPercentage = customPercentageController.text;
      if (double.parse(discountPercentage) > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Select a percentage less than 100")),
        );
        return;
      }
    } else {
      discountPercentage = percentageList[selectedPercentageIndex!].substring(
        0,
        2,
      );
    }

    //Get items
    List<Map<String, dynamic>> menuOptions = [
      {"selected": "Entire Menu", "value": "entire_menu"},
      {"selected": "Foods", "value": "foods"},
      {"selected": "Drinks", "value": "drinks"},
    ];
    String? applicableFor;
    for (var item in menuOptions) {
      if (item['selected'] == menuList[selectedMenuIndex!]) {
        applicableFor = item['value'];
      }
    }

    //select dine type
    List? dineTypeArr;
    String? dineType;
    if (isDineInChecked && isTakeAwayChecked) {
      dineTypeArr = ["Dine In", "Take Away"];
    } else if (isDineInChecked) {
      dineTypeArr = ["Dine In"];
    } else if (isTakeAwayChecked) {
      dineTypeArr = ["Take Away"];
    }

    if (dineTypeArr != null) {
      dineType = dineTypeArr.join(",");
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Select dine type")));
      return;
    }

    //Get start time
    String startTimeString = formatTimeOfDay(startTime);

    //Get end time
    String endTimeString = formatTimeOfDay(endTime);

    //Get Active days
    List<String> activeDays = selectedWeekIndices
        .map((i) => weekList[i])
        .toList();
    String activeDaysString = activeDays.join(',');

    if (discountPercentage.isNotEmpty &&
        applicableFor!.isNotEmpty &&
        dineType.isNotEmpty &&
        startTimeString.isNotEmpty &&
        endTimeString.isNotEmpty &&
        activeDaysString.isNotEmpty) {
      CreateOfferModel offerModel = CreateOfferModel(
        discountPercentage: discountPercentage,
        applicableFor: applicableFor,
        dineType: dineType,
        startTime: startTimeString,
        endTime: endTimeString,
        activeDays: activeDaysString,
      );
      OfferReturnModel response = await offerService.createOffer(offerModel);
      if (response.status) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        setState(() {
          isOpen = !isOpen;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fill all the fields")));
    }

    setState(() {
      isLoading = true;
      offerList = [];
      selectedOption = "Both Active & InActive";
    });

    OfferListResponse response = await offerService.getAllOffers();
    setState(() {
      offerList = response.offers;
      isLoading = false;
    });
  }

  Future<void> updateOffer() async {
    String? discountPercentage;
    if (selectedPercentageIndex == percentageList.length - 1) {
      discountPercentage = customPercentageController.text;
      if (double.parse(discountPercentage) > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Select a percentage less than 100")),
        );
        return;
      }
    } else {
      discountPercentage = percentageList[selectedPercentageIndex!].substring(
        0,
        2,
      );
    }

    //Get items
    List<Map<String, dynamic>> menuOptions = [
      {"selected": "Entire Menu", "value": "entire_menu"},
      {"selected": "Foods", "value": "foods"},
      {"selected": "Drinks", "value": "drinks"},
    ];
    String? applicableFor;
    for (var item in menuOptions) {
      if (item['selected'] == menuList[selectedMenuIndex!]) {
        applicableFor = item['value'];
      }
    }

    //select dine type
    List? dineTypeArr;
    String? dineType;
    if (isDineInChecked && isTakeAwayChecked) {
      dineTypeArr = ["Dine In", "Take Away"];
    } else if (isDineInChecked) {
      dineTypeArr = ["Dine In"];
    } else if (isTakeAwayChecked) {
      dineTypeArr = ["Take Away"];
    }

    if (dineTypeArr != null) {
      dineType = dineTypeArr.join(",");
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Select dine type")));
      return;
    }

    //Get start time
    String startTimeString = formatTimeOfDay(startTime);

    //Get end time
    String endTimeString = formatTimeOfDay(endTime);

    //Get Active days
    List<String> activeDays = selectedWeekIndices
        .map((i) => weekList[i])
        .toList();
    String activeDaysString = activeDays.join(',');

    //also add offer id
    if (discountPercentage.isNotEmpty &&
        applicableFor!.isNotEmpty &&
        dineType.isNotEmpty &&
        startTimeString.isNotEmpty &&
        endTimeString.isNotEmpty &&
        activeDaysString.isNotEmpty &&
        selectedOffer!.uuid.isNotEmpty) {
      EditOfferModel offerModel = EditOfferModel(
        discountPercentage: discountPercentage,
        applicableFor: applicableFor,
        dineType: dineType,
        startTime: startTimeString,
        endTime: endTimeString,
        activeDays: activeDaysString,
        uuid: selectedOffer!.uuid,
      );
      OfferEditReturnModel response = await offerService.editOffer(offerModel);
      if (response.status) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        setState(() {
          isEditOpen = !isEditOpen;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fill all the fields")));
    }

    setState(() {
      isLoading = true;
      offerList = [];
      selectedOption = "Both Active & InActive";
    });

    OfferListResponse response = await offerService.getAllOffers();
    setState(() {
      offerList = response.offers;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    customPercentageController.dispose();
    super.dispose();
  }

  @override
  bool handleBack() {
    if (isOpen || isEditOpen || isDeletePressed) {
      setState(() {
        isOpen = false;
        isEditOpen = false;
        isDeletePressed = false;
      });
      return true;
    }
    return false;
  }

  String formatTimeOfDay(TimeOfDay time) {
    final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String paddedHour = hour.toString().padLeft(2, '0');
    final String paddedMinute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? "AM" : "PM";
    return '$paddedHour:$paddedMinute $period';
  }

  Future<void> _showCustomPercentageDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Custom Percentage'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Enter your custom discount percentage:'),
                SizedBox(height: 10.h),
                TextField(
                  controller: customPercentageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g., 25',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  selectedPercentageIndex = null;
                });
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                if (customPercentageController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                } else {
                  // Show error if empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a percentage value')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<String> menuList = ["Entire Menu", "Foods", "Drinks"];
  List<String> weekList = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = _isWideShortPhone(context);
    final isNarrowShortPhone = _isNarrowShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final compactPhone = _isCompactMobile(width);
    final fabOffset = _offerFabOffset(context);
    final fabSize = isWideShortPhone
        ? 52.0
        : isMobile
        ? (compactPhone ? 56.w : 66.w)
        : Breakpoints.isTabletDevice(size)
        ? width * 0.075
        : width * 0.05;
    final fabIconSize = fabSize * 0.65;
    final bannerTopPadding = isWideShortPhone
        ? 8.0
        : isNarrowShortPhone
        ? 16.0
        : isMobile
        ? 30.h
        : 24.0;
    final bannerHeight = isWideShortPhone
        ? 130.0
        : isNarrowShortPhone
        ? 150.0
        : isMobile
        ? 160.h
        : Breakpoints.isTabletDevice(size)
        ? 190.0
        : 180.0;
    final stickyFilterHeight = isWideShortPhone
        ? 62.0
        : isMobile
        ? 80.h
        : 72.0;
    final filterWidth = (width * 0.42).clamp(240.0, 340.0);

    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      floatingActionButtonLocation: _OffsetFabLocation(
        right: fabOffset.$1,
        bottom: fabOffset.$2,
      ),
      floatingActionButton: isOpen || isEditOpen || isDeletePressed
          ? null
          : IgnorePointer(
              ignoring: isDeletePressed,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isOpen = !isOpen;
                  });
                },
                child: Container(
                  height: fabSize,
                  width: fabSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDeletePressed
                        ? Colors.grey.shade400
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDeletePressed ? 0.1 : 0.2,
                        ),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Opacity(
                    opacity: isDeletePressed ? 0.6 : 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        plusIcon,
                        width: fabIconSize,
                        height: fabIconSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      body: !isOpen
          ? Stack(
              children: [
                SafeArea(
                  minimum: EdgeInsets.only(
                    top: _usesTabletLayout(context) ? 12.0 : 0.0,
                  ),
                  child: Stack(
                    children: [
                      if (isLoading)
                        const Positioned.fill(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: bannerHeight,
                              child: _responsiveContent(
                                padding: EdgeInsets.only(
                                  left: _pagePadding(context),
                                  right: _pagePadding(context) + 4,
                                  top: bannerTopPadding,
                                ),
                                child: _offerBanner(),
                              ),
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: false,
                            delegate: _StickyFilterBarDelegate(
                              height: stickyFilterHeight,
                              child: Container(
                                color: appSecondaryBackgroundColor,
                                child: _responsiveContent(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isWideShortPhone
                                          ? 8.0
                                          : isMobile
                                          ? 10.h
                                          : 10.0,
                                    ),
                                    child: SizedBox(
                                      width: filterWidth,
                                      child: AppFilterDropDown(
                                        fieldBorderRadius: isWideShortPhone
                                            ? 6.0
                                            : 6.r,
                                        hint: selectedOption,
                                        iconImage:
                                            "assets/images/filter_icon.png",
                                        toogleDropdown: () async {
                                          await showModalBottomSheet(
                                            backgroundColor: Colors.white,
                                            context: context,
                                            isScrollControlled: true,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(10.r),
                                                  ),
                                            ),
                                            builder: (context) {
                                              return Padding(
                                                padding: EdgeInsets.all(
                                                  isMobile ? 30.w : 28.0,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: isMobile
                                                          ? 40.w
                                                          : 40,
                                                      height: isMobile
                                                          ? 5.h
                                                          : 5,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[300],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10.r,
                                                            ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: isMobile
                                                          ? 16.h
                                                          : 16,
                                                    ),
                                                    ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                            maxWidth: 520,
                                                          ),
                                                      child: Container(
                                                        width: double.infinity,
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20.r,
                                                              ),
                                                        ),
                                                        padding: EdgeInsets.all(
                                                          isMobile ? 16.w : 16,
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Divider(
                                                              color: Colors
                                                                  .grey[200],
                                                            ),
                                                            SizedBox(
                                                              height: isMobile
                                                                  ? 10.h
                                                                  : 10,
                                                            ),
                                                            GestureDetector(
                                                              onTap: () async {
                                                                setState(() {
                                                                  selectedOption =
                                                                      "Active";
                                                                });
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                                await getOffers();
                                                              },
                                                              child: AppText(
                                                                text: "Active",
                                                                size: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: isMobile
                                                                  ? 10.h
                                                                  : 10,
                                                            ),
                                                            Divider(
                                                              color: Colors
                                                                  .grey[200],
                                                            ),
                                                            SizedBox(
                                                              height: isMobile
                                                                  ? 10.h
                                                                  : 10,
                                                            ),
                                                            GestureDetector(
                                                              onTap: () async {
                                                                setState(() {
                                                                  selectedOption =
                                                                      "InActive";
                                                                });
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                                await getOffers();
                                                              },
                                                              child: AppText(
                                                                text:
                                                                    "InActive",
                                                                size: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: isMobile
                                                                  ? 10.h
                                                                  : 10,
                                                            ),
                                                            Divider(
                                                              color: Colors
                                                                  .grey[200],
                                                            ),
                                                            SizedBox(
                                                              height: isMobile
                                                                  ? 10.h
                                                                  : 10,
                                                            ),
                                                            GestureDetector(
                                                              onTap: () async {
                                                                setState(() {
                                                                  selectedOption =
                                                                      "Both Active & InActive";
                                                                });
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                                await getOffers();
                                                              },
                                                              child: AppText(
                                                                text:
                                                                    "Both Active & InActive",
                                                                size: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                              height: isMobile
                                                                  ? 10.h
                                                                  : 10,
                                                            ),
                                                            Divider(
                                                              color: Colors
                                                                  .grey[200],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Content list
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: isWideShortPhone ? 10.0 : 10.h,
                            ),
                          ),
                          if (hasItem)
                            _responsiveSliverContent(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppText(
                                        text: "Total",
                                        size: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF9C7777),
                                      ),
                                      AppText(
                                        text: " ${offerList.length}",
                                        size: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFC91919),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: isWideShortPhone ? 20.0 : 25.h,
                                  ),
                                ],
                              ),
                            ),
                          if (offerList.isNotEmpty)
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final offer = offerList[index];
                                return _responsiveContent(
                                  padding: EdgeInsets.only(
                                    left: _pagePadding(context),
                                    right: _pagePadding(context) + 4,
                                    bottom: isMobile ? 16.h : 16.0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedOffer = offer;
                                      });
                                      showOfferDetailModal(
                                        context,
                                        selectedOffer!,
                                      );
                                    },
                                    child: OfferCard(
                                      percentage: offer.discountPercentage,
                                      applicableFor: offer.applicableFor,
                                      dineType: offer.dineType,
                                      startTime: offer.startTime,
                                      endTime: offer.endTime,
                                      activeDays: offer.activeDays,
                                      status: offer.status,
                                      uuid: offer.uuid,
                                      onStatusChanged: (status) {
                                        setState(() {
                                          final updatedOffer = offer.copyWith(
                                            status: status,
                                          );
                                          offerList[index] = updatedOffer;
                                          if (selectedOffer?.uuid ==
                                              offer.uuid) {
                                            selectedOffer = updatedOffer;
                                          }
                                        });
                                      },
                                      url: 'assets/images/discountbanner2.png',
                                      deleteOnTap: () {
                                        setState(() {
                                          isDeletePressed = !isDeletePressed;
                                          selecteduuid = offer.uuid;
                                        });
                                      },
                                      editOnTap: () {
                                        setState(() {
                                          isEditingPressed = !isEditingPressed;
                                          selectedOffer = offer;
                                          selecteduuid = offer.uuid;
                                          isEditOpen = !isEditOpen;
                                        });
                                        _setDefaultsFromOffer();
                                      },
                                    ),
                                  ),
                                );
                              }, childCount: offerList.length),
                            )
                          else if (!isLoading)
                            _responsiveSliverContent(
                              child: Center(
                                child: AppText(
                                  text: "No Offers in $selectedOption section",
                                  size: 15,
                                  fontWeight: FontWeight.w600,
                                  color: appTextColor2,
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: isWideShortPhone ? 20.0 : 30.h,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isEditOpen) Positioned.fill(child: _editOfferOverlay()),
                if (isDeletePressed) Positioned.fill(child: _deleteWidget()),
              ],
            )
          : SingleChildScrollView(child: _discountCreatePage()),
    );
  }

  void showOfferDetailModal(BuildContext context, OfferModel offer) {
    final isMobile = _usesMobileScale(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 20.w : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Offer Details",
                      style: TextStyle(
                        fontSize: isMobile ? 20.sp : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 16.h : 16),
                    _detailItem("Discount", "${offer.discountPercentage}%"),
                    _detailItem("Applies To", offer.applicableFor),
                    _detailItem("Dine Type", offer.dineType),
                    _detailItem("Start Time", offer.startTime),
                    _detailItem("End Time", offer.endTime),
                    _detailItem("Active Days", offer.activeDays),
                    _detailItem("Status", offer.status),
                    SizedBox(height: isMobile ? 20.h : 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Close",
                          style: TextStyle(fontSize: isMobile ? 16.sp : 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailItem(String title, String value) {
    final isMobile = _usesMobileScale(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 6.h : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 15.sp : 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: isMobile ? 15.sp : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setDefaultsFromOffer() {
    if (selectedOffer == null) return;

    final offerDiscount = selectedOffer!.discountPercentage.replaceAll('%', '');
    int index = percentageList.indexWhere(
      (e) => e.replaceAll('%', '') == offerDiscount,
    );
    if (index != -1) {
      selectedPercentageIndex = index;
    } else {
      customPercentageController.text = offerDiscount;
      selectedPercentageIndex = percentageList.indexOf("Custom");
    }

    String offerAppliedFor = '';
    switch (selectedOffer!.applicableFor) {
      case 'entire_menu':
        setState(() {
          offerAppliedFor = "Entire Menu";
        });
        break;
      case 'foods':
        setState(() {
          offerAppliedFor = "Foods";
        });
        break;
      case 'drinks':
        setState(() {
          offerAppliedFor = "Drinks";
        });
        break;
    }
    selectedMenuIndex = menuList.indexOf(offerAppliedFor);

    isDineInChecked = selectedOffer!.dineType.contains("Dine In");
    isTakeAwayChecked = selectedOffer!.dineType.contains("Take Away");

    startTime = _parseTime(selectedOffer!.startTime);
    endTime = _parseTime(selectedOffer!.endTime);

    selectedWeekIndices = [];
    List<String> activeDays = selectedOffer!.activeDays.split(',');
    for (int i = 0; i < weekList.length; i++) {
      if (activeDays.contains(weekList[i])) {
        selectedWeekIndices.add(i);
      }
    }

    setState(() {});
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final meridian = parts.length > 1 ? parts[1].toUpperCase() : '';

      if (meridian == 'PM' && hour != 12) {
        hour += 12;
      } else if (meridian == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print('Time parsing error: $e');
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  Widget _offerBanner() {
    final width = _screenWidth(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final isNarrowShortPhone = _isNarrowShortPhone(context);
    final usesTabletLayout = _usesTabletLayout(context);
    final gap = isWideShortPhone
        ? 8.0
        : isNarrowShortPhone
        ? 8.0
        : AppDimensions.gap(width);
    final nameSize = isWideShortPhone
        ? 24.0
        : isNarrowShortPhone
        ? 30.0
        : usesTabletLayout
        ? 42.0
        : Breakpoints.isDesktop(width)
        ? 38.0
        : 35.0;
    final typeSize = isWideShortPhone
        ? 15.0
        : isNarrowShortPhone
        ? 20.0
        : usesTabletLayout
        ? 28.0
        : Breakpoints.isDesktop(width)
        ? 24.0
        : 25.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: widget.partnerProfile?.name ?? "Loading",
                size: nameSize,
                fontWeight: FontWeight.w600,
                color: appTextColor3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AppText(
                text: widget.partnerProfile?.type ?? "",
                size: typeSize,
                fontWeight: FontWeight.w600,
                color: appTextColor3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    size: isWideShortPhone
                        ? 13.0
                        : usesTabletLayout
                        ? 16
                        : Breakpoints.isMobile(width)
                        ? 15.w
                        : 16,
                    color: appTextColor3,
                  ),
                  SizedBox(
                    width: isWideShortPhone
                        ? 4.0
                        : usesTabletLayout
                        ? 6
                        : Breakpoints.isMobile(width)
                        ? 5.w
                        : 6,
                  ),
                  Expanded(
                    child: AppText(
                      text: widget.partnerProfile?.address ?? "",
                      size: isWideShortPhone
                          ? 11.0
                          : isNarrowShortPhone
                          ? 12.0
                          : 15,
                      fontWeight: FontWeight.w400,
                      color: appTextColor3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: gap),
        GestureDetector(
          onTap: widget.onDrawerTap,
          child: Icon(
            Icons.menu,
            size: isWideShortPhone
                ? 22.0
                : usesTabletLayout
                ? 30
                : Breakpoints.isMobile(width)
                ? 30.w
                : 30,
            color: appTextColor3,
          ),
        ),
      ],
    );
  }

  Widget _deleteWidget() {
    final isMobile = _usesMobileScale(context);
    final modalRadius = isMobile ? 15.r : 15.0;
    final modalHorizontalPadding = isMobile ? 40.w : 36.0;
    final modalVerticalPadding = isMobile ? 28.h : 26.0;
    final modalShadowBlur = isMobile ? 10.r : 10.0;
    final modalShadowOffset = Offset(0, isMobile ? 4.r : 4.0);
    final buttonHeight = isMobile ? 35.h : 36.0;
    final buttonRadius = isMobile ? 5.r : 5.0;
    final buttonTextSize = isMobile ? 15.sp : 14.0;
    final buttonGap = isMobile ? 20.w : 18.0;
    final contentGap = isMobile ? 20.h : 18.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => isDeletePressed = false),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        Center(
          child: _responsiveContent(
            maxWidth: 420,
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: modalHorizontalPadding,
                vertical: modalVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(modalRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: modalShadowBlur,
                    offset: modalShadowOffset,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    text: "Are you sure you want to delete this offer?",
                    size: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    isCentered: true,
                    maxLines: 2,
                  ),
                  SizedBox(height: contentGap),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: buttonHeight,
                          child: AppButton(
                            text: "Yes",
                            onPressed: () {
                              deleteOffer();
                              setState(() {
                                isDeletePressed = !isDeletePressed;
                              });
                            },
                            size: buttonTextSize,
                            borderRadius: buttonRadius,
                            bgColor1: Colors.green,
                            bgColor2: Colors.green,
                          ),
                        ),
                      ),
                      SizedBox(width: buttonGap),
                      Expanded(
                        child: SizedBox(
                          height: buttonHeight,
                          child: AppButton(
                            text: "No",
                            onPressed: () {
                              setState(() {
                                isDeletePressed = false;
                              });
                            },
                            size: buttonTextSize,
                            borderRadius: buttonRadius,
                            bgColor1: Colors.red,
                            bgColor2: Colors.red,
                          ),
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
    );
  }

  Widget _editOfferOverlay() {
    final isMobile = _usesMobileScale(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => isEditOpen = false),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16.w : 24,
              vertical: isMobile ? 24.h : 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 620,
                maxHeight: screenHeight * 0.76,
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 20.r : 16),
                clipBehavior: Clip.antiAlias,
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(0.88)),
                  child: SingleChildScrollView(
                    child: _discountEditPage(compact: true),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _discountEditPage({bool compact = false}) {
    final isMobile = _usesMobileScale(context);
    final horizontalPadding = compact
        ? (isMobile ? 20.w : 24.0)
        : _pagePadding(context);
    final verticalPadding = compact
        ? (isMobile ? 20.h : 20.0)
        : (isMobile ? 40.h : 36.0);

    return SizedBox(
      width: double.infinity,
      child: _responsiveContent(
        maxWidth: 720,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                setState(() {
                  isEditOpen = !isEditOpen;
                  isLoading = true;
                  offerList = [];
                  selectedOption = "Both Active & InActive";
                });
                OfferListResponse response = await offerService.getAllOffers();
                setState(() {
                  offerList = response.offers;
                  isLoading = false;
                });
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  backOrange,
                  width: isMobile ? 30.w : 30,
                  height: isMobile ? 30.h : 30,
                ),
                // child: Icon(
                //   Icons.arrow_back_ios,
                //   size: 30.w,
                //   color: appTextColor3,
                // ),
              ),
            ),
            AppText(
              text: "Edit Promotion!",
              size: 25,
              fontWeight: FontWeight.w600,
              color: appTextColor3,
              isCentered: true,
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: "Discount Percentage",
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      percentageList.length,
                      (index) => _discountBox(
                        percentageList[index] == "Custom" &&
                                selectedPercentageIndex == index &&
                                customPercentageController.text.isNotEmpty
                            ? "${customPercentageController.text}%"
                            : percentageList[index],
                        selectedPercentageIndex == index,
                        () async {
                          if (percentageList[index] == "Custom") {
                            setState(() {
                              selectedPercentageIndex = index;
                            });
                            await _showCustomPercentageDialog();
                          } else {
                            setState(() {
                              selectedPercentageIndex = index;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Which items does this offer apply to?",
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
                  ),
                  SizedBox(height: 20.h),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      menuList.length,
                      (index) => _discountApplyBox(
                        menuList[index],
                        selectedMenuIndex == index,
                        () {
                          setState(() {
                            selectedMenuIndex = index;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          AppText(
                            text: "Dine in",
                            size: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          Checkbox(
                            value: isDineInChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isDineInChecked = value ?? false;
                              });
                            },
                            fillColor: MaterialStateColor.resolveWith(
                              (states) => isDineInChecked
                                  ? appToggleColor
                                  : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            side: BorderSide(color: appToggleColor, width: 2.w),
                            checkColor: Colors.white,
                            activeColor: appToggleColor,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      SizedBox(width: isMobile ? 30.w : 28),
                      Row(
                        children: [
                          AppText(
                            text: "Take away",
                            size: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          Checkbox(
                            value: isTakeAwayChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isTakeAwayChecked = value ?? false;
                              });
                            },
                            fillColor: MaterialStateColor.resolveWith(
                              (states) => isTakeAwayChecked
                                  ? appToggleColor
                                  : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(color: appToggleColor, width: 2),
                            checkColor: Colors.white,
                            activeColor: appToggleColor,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _offerScheduleCard(),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: isMobile ? 150.w : 150,
                      height: isMobile ? 50.h : 48,
                      child: AppButton(
                        borderRadius: 8,
                        text: 'Update',
                        onPressed: () {
                          updateOffer();
                          // setState(() {
                          //   isOpen = !isOpen;
                          // });
                        },
                        bgColor1: Color(0xFF73B256),
                        bgColor2: Color(0xFF73B256),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _discountCreatePage() {
    final isMobile = _usesMobileScale(context);

    return SizedBox(
      width: double.infinity,
      child: _responsiveContent(
        maxWidth: 720,
        padding: EdgeInsets.symmetric(
          horizontal: _pagePadding(context),
          vertical: isMobile ? 40.h : 36,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                setState(() {
                  isOpen = !isOpen;
                  isLoading = true;
                  offerList = [];
                  selectedOption = "Both Active & InActive";
                });
                OfferListResponse response = await offerService.getAllOffers();
                setState(() {
                  offerList = response.offers;
                  isLoading = false;
                });
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  backOrange,
                  width: isMobile ? 30.w : 30,
                  height: isMobile ? 30.h : 30,
                ),
                // child: Icon(
                //   Icons.arrow_back_ios,
                //   size: 30.w,
                //   color: appTextColor3,
                // ),
              ),
            ),
            AppText(
              text: "Add Promotions!",
              size: 25,
              fontWeight: FontWeight.w600,
              color: offerTextColor,
              isCentered: true,
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: "Discount Percentage",
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      percentageList.length,
                      (index) => _discountBox(
                        percentageList[index] == "Custom" &&
                                selectedPercentageIndex == index &&
                                customPercentageController.text.isNotEmpty
                            ? "${customPercentageController.text}%"
                            : percentageList[index],
                        selectedPercentageIndex == index,
                        () async {
                          if (percentageList[index] == "Custom") {
                            setState(() {
                              selectedPercentageIndex = index;
                            });
                            await _showCustomPercentageDialog();
                          } else {
                            setState(() {
                              selectedPercentageIndex = index;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  AppText(
                    text: "Which items does this offer apply to?",
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor3,
                  ),
                  SizedBox(height: 20.h),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(
                      menuList.length,
                      (index) => _discountApplyBox(
                        menuList[index],
                        selectedMenuIndex == index,
                        () {
                          setState(() {
                            selectedMenuIndex = index;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          AppText(
                            text: "Dine in",
                            size: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          Checkbox(
                            value: isDineInChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isDineInChecked = value ?? false;
                              });
                            },
                            fillColor: MaterialStateColor.resolveWith(
                              (states) => isDineInChecked
                                  ? appToggleColor
                                  : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            side: BorderSide(color: appToggleColor, width: 2.w),
                            checkColor: Colors.white,
                            activeColor: appToggleColor,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      SizedBox(width: isMobile ? 30.w : 28),
                      Row(
                        children: [
                          AppText(
                            text: "Take away",
                            size: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          Checkbox(
                            value: isTakeAwayChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                isTakeAwayChecked = value ?? false;
                              });
                            },
                            fillColor: MaterialStateColor.resolveWith(
                              (states) => isTakeAwayChecked
                                  ? appToggleColor
                                  : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(color: appToggleColor, width: 2),
                            checkColor: Colors.white,
                            activeColor: appToggleColor,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _offerScheduleCard(),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: isMobile ? 150.w : 150,
                      height: isMobile ? 50.h : 48,
                      child: AppButton(
                        text: 'Create',
                        borderRadius: 8,
                        onPressed: () {
                          createOffer();
                          // setState(() {
                          //   isOpen = !isOpen;
                          // });
                        },
                        bgColor1: Color(0xFF3F7DCE),
                        bgColor2: Color(0xFF3F7DCE),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _discountBox(String text, bool isSelected, VoidCallback onTap) {
    final isMobile = _usesMobileScale(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10.w : 10,
          vertical: isMobile ? 6.h : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? appTextColor3 : Colors.transparent,
          border: Border.all(color: appTextColor3, width: 1),
          borderRadius: BorderRadius.circular(isMobile ? 5.r : 5),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (text == "Custom" ? Color(0xFFBDB23A) : appTextColor2),
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 15.sp : 15,
          ),
        ),
      ),
    );
  }

  Widget _offerScheduleCard() {
    final isMobile = _usesMobileScale(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 34.r : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: isMobile ? 24.r : 22,
            offset: Offset(0, isMobile ? 10.h : 8),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 34.w : 30,
        vertical: isMobile ? 28.h : 26,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _timeSelector(
                title: "Start Time",
                time: startTime,
                onChanged: (time) {
                  setState(() {
                    startTime = time;
                  });
                },
              ),
              _timeSelector(
                title: "End Time",
                time: endTime,
                onChanged: (time) {
                  setState(() {
                    endTime = time;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: isMobile ? 32.h : 28),
          Text(
            "Active Days",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: offerPageTextColor,
              fontSize: isMobile ? 17.sp : 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isMobile ? 18.h : 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isMobile ? 10.w : 10,
            runSpacing: isMobile ? 8.h : 8,
            children: List.generate(
              weekList.length,
              (index) => _dayPill(
                weekList[index],
                selectedWeekIndices.contains(index),
                () {
                  setState(() {
                    if (selectedWeekIndices.contains(index)) {
                      selectedWeekIndices.remove(index);
                    } else {
                      selectedWeekIndices.add(index);
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeSelector({
    required String title,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    final isMobile = _usesMobileScale(context);
    final int displayHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: offerPageTextColor,
            fontSize: isMobile ? 17.sp : 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isMobile ? 9.h : 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 8.r : 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: const Color(0xFFC7C7C7),
                child: _timeScroller(
                  value: displayHour,
                  min: 1,
                  max: 12,
                  onChanged: (hour) {
                    onChanged(
                      TimeOfDay(
                        hour: _toTwentyFourHour(hour, time.period),
                        minute: time.minute,
                      ),
                    );
                  },
                ),
              ),
              _timeDivider(),
              Container(
                color: const Color(0xFFC7C7C7),
                child: _timeScroller(
                  value: time.minute,
                  min: 0,
                  max: 59,
                  onChanged: (minute) {
                    onChanged(TimeOfDay(hour: time.hour, minute: minute));
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  final newHour = time.period == DayPeriod.am
                      ? time.hour + 12
                      : time.hour - 12;
                  onChanged(TimeOfDay(hour: newHour, minute: time.minute));
                },
                child: Container(
                  width: isMobile ? 38.w : 38,
                  height: isMobile ? 30.h : 30,
                  decoration: BoxDecoration(
                    color: time.period == DayPeriod.am
                        ? const Color.fromARGB(255, 150, 148, 148)
                        : const Color(0xFF53534F),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10.r),
                      bottomRight: Radius.circular(10.r),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      time.period == DayPeriod.am ? 'AM' : 'PM',
                      style: TextStyle(
                        fontSize: isMobile ? 13.sp : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeDivider() {
    final isMobile = _usesMobileScale(context);
    return Container(
      height: isMobile ? 30.h : 30,
      width: isMobile ? 1.w : 1,
      color: Colors.white,
    );
  }

  int _toTwentyFourHour(int hour, DayPeriod period) {
    if (period == DayPeriod.am) {
      return hour == 12 ? 0 : hour;
    }
    return hour == 12 ? 12 : hour + 12;
  }

  // Scroll-wheel helper
  Widget _timeScroller({
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final isMobile = _usesMobileScale(context);
    final controller = FixedExtentScrollController(initialItem: value - min);
    return SizedBox(
      width: isMobile ? 30.w : 30,
      height: isMobile ? 30.h : 30,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: isMobile ? 32.h : 32,
        perspective: 0.003,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) => onChanged(index + min),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: max - min + 1,
          builder: (context, index) {
            final val = index + min;
            return Center(
              child: Text(
                val.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: isMobile ? 16.sp : 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _dayPill(String text, bool isSelected, VoidCallback onTap) {
    final isMobile = _usesMobileScale(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isMobile ? 50.w : 50,
        height: isMobile ? 30.h : 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF53534F) : const Color(0xFFC7C7C7),
          borderRadius: BorderRadius.circular(isMobile ? 8.r : 8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : offerPageTextColor,
            fontSize: isMobile ? 14.sp : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _discountApplyBox(String text, bool isSelected, VoidCallback onTap) {
    final isMobile = _usesMobileScale(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10.w : 10,
          vertical: isMobile ? 6.h : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? appTextColor3 : Colors.transparent,
          border: Border.all(color: appTextColor3, width: 1),
          borderRadius: BorderRadius.circular(isMobile ? 5.r : 5),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (text == "Custom" ? Color(0xFFBDB23A) : appTextColor2),
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 15.sp : 15,
          ),
        ),
      ),
    );
  }
}
