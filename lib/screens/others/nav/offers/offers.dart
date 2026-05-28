import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/offercard.dart';
import 'package:fudiko/models/offer/offer-create-model.dart';
import 'package:fudiko/models/offer/offer-delete-model.dart';
import 'package:fudiko/models/offer/offer-list-model.dart';
import 'package:fudiko/models/offer/offer-return-model.dart';
import 'package:fudiko/models/offer/offer-update-model.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/services/offer-service.dart';
import 'package:fudiko/utils/constants.dart';
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

  _StickyFilterBarDelegate({required this.child});

  @override
  double get minExtent => 80.h;

  @override
  double get maxExtent => 80.h;

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
    return oldDelegate.child != child;
  }
}

class _OffersState extends State<Offers> {
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
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      floatingActionButton: isOpen || isEditOpen
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
                  height: 75.h,
                  width: 75.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDeletePressed ? Colors.grey.shade400 : Colors.white,
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
                      child: Image.asset(plusIcon, width: 40.w, height: 40.h),
                    ),
                  ),
                ),
              ),
            ),
      body: !isOpen && !isEditOpen
          ? Stack(
              children: [
                if (isLoading)
                  SizedBox(
                    height: MediaQuery.of(context).size.height.h,
                    width: MediaQuery.of(context).size.width.w,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                CustomScrollView(
                  slivers: [
                    // Banner that scrolls away
                    SliverAppBar(
                      backgroundColor: appSecondaryBackgroundColor,
                      elevation: 0,
                      pinned: false,
                      floating: false,
                      toolbarHeight: 0,
                      collapsedHeight: 0,
                      expandedHeight: 150.h,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Padding(
                          padding: EdgeInsets.only(
                            left: 20.w,
                            right: 20.w,
                            top: 20.h,
                          ),
                          child: _offerBanner(),
                        ),
                      ),
                    ),
                    // Filter bar that becomes sticky
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyFilterBarDelegate(
                        child: Container(
                          color: Colors.transparent,
                          padding: EdgeInsets.only(
                            left: 75.w,
                            right: 75.w,
                            top: 10.h,
                            bottom: 10.h,
                          ),
                          child: SizedBox(
                            width: 250.w,
                            child: AppFilterDropDown(
                              fieldBorderRadius: 6.r,
                              hint: selectedOption,
                              iconImage: "assets/images/filter_icon.png",
                              // icon: Icons.tune,
                              toogleDropdown: () {
                                showModalBottomSheet(
                                  backgroundColor: Colors.white,
                                  context: context,
                                  isScrollControlled: true,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(10.r),
                                    ),
                                  ),
                                  builder: (context) {
                                    return Padding(
                                      padding: EdgeInsets.all(30.w),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 40.w,
                                            height: 5.h,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(10.r),
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          Container(
                                            width: MediaQuery.of(
                                              context,
                                            ).size.width,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                            ),
                                            padding: EdgeInsets.all(16.w),
                                            child: Column(
                                              children: [
                                                Divider(
                                                  color: Colors.grey[200],
                                                ),
                                                SizedBox(height: 10.h),
                                                GestureDetector(
                                                  onTap: () async {
                                                    setState(() {
                                                      selectedOption = "Active";
                                                    });
                                                    Navigator.pop(context);
                                                    await getOffers();
                                                  },
                                                  child: AppText(
                                                    text: "Active",
                                                    size: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 10.h),
                                                Divider(
                                                  color: Colors.grey[200],
                                                ),
                                                SizedBox(height: 10.h),
                                                GestureDetector(
                                                  onTap: () async {
                                                    setState(() {
                                                      selectedOption =
                                                          "InActive";
                                                    });
                                                    Navigator.pop(context);
                                                    await getOffers();
                                                  },
                                                  child: AppText(
                                                    text: "InActive",
                                                    size: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 10.h),
                                                Divider(
                                                  color: Colors.grey[200],
                                                ),
                                                SizedBox(height: 10.h),
                                                GestureDetector(
                                                  onTap: () async {
                                                    setState(() {
                                                      selectedOption =
                                                          "Both Active & InActive";
                                                    });
                                                    Navigator.pop(context);
                                                    await getOffers();
                                                  },
                                                  child: AppText(
                                                    text:
                                                        "Both Active & InActive",
                                                    size: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 10.h),
                                                Divider(
                                                  color: Colors.grey[200],
                                                ),
                                              ],
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
                    // Content list
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(left: 20.w, right: 20.w),
                        child: SizedBox(height: 10.h),
                      ),
                    ),
                    if (hasItem)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(left: 20.w, right: 20.w),
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
                              SizedBox(height: 25.h),
                            ],
                          ),
                        ),
                      ),
                    if (offerList.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final offer = offerList[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              left: 20.w,
                              right: 20.w,
                              bottom: 16.h,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedOffer = offer;
                                });
                                showOfferDetailModal(context, selectedOffer!);
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(left: 20.w, right: 20.w),
                          child: AppText(
                            text: "No Offers in $selectedOption section",
                            size: 15,
                            fontWeight: FontWeight.w600,
                            color: appTextColor2,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: 30.h)),
                  ],
                ),
                if (isDeletePressed) _deleteWidget(),
              ],
            )
          : isOpen
          ? SingleChildScrollView(child: _discountCreatePage())
          : SingleChildScrollView(child: _discountEditPage()),
    );
  }

  void showOfferDetailModal(BuildContext context, OfferModel offer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Offer Details",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _detailItem("Discount", "${offer.discountPercentage}%"),
                  _detailItem("Applies To", offer.applicableFor),
                  _detailItem("Dine Type", offer.dineType),
                  _detailItem("Start Time", offer.startTime),
                  _detailItem("End Time", offer.endTime),
                  _detailItem("Active Days", offer.activeDays),
                  _detailItem("Status", offer.status),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Close", style: TextStyle(fontSize: 16.sp)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailItem(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15.sp),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: widget.partnerProfile?.name ?? "Loading",
              size: 35,
              fontWeight: FontWeight.w600,
              color: appTextColor3,
            ),
            AppText(
              text: widget.partnerProfile?.type ?? "",
              size: 25,
              fontWeight: FontWeight.w600,
              color: appTextColor3,
            ),
            Row(
              children: [
                Icon(Icons.location_on, size: 15.w, color: appTextColor3),
                SizedBox(width: 5.w),
                AppText(
                  text: widget.partnerProfile?.address ?? "",
                  size: 15,
                  fontWeight: FontWeight.w400,
                  color: appTextColor3,
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: widget.onDrawerTap,
          child: Icon(Icons.menu, size: 30.w, color: appTextColor3),
        ),
      ],
    );
  }

  Widget _deleteWidget() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isDeletePressed = false;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height.h,
            width: MediaQuery.of(context).size.width.w,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Container(
                  height: 150.h,
                  width: double.infinity,
                  padding: EdgeInsets.only(left: 40.w, right: 40.w, top: 30.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.r),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AppText(
                        text: "Are you sure you want to delete this offer?",
                        size: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        isCentered: true,
                        maxLines: 2,
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 35.h,
                              child: AppButton(
                                text: "Yes",
                                onPressed: () {
                                  deleteOffer();
                                  setState(() {
                                    isDeletePressed = !isDeletePressed;
                                  });
                                },
                                size: 15.sp,
                                borderRadius: 5.r,
                                bgColor1: Colors.green,
                                bgColor2: Colors.green,
                              ),
                            ),
                          ),
                          SizedBox(width: 20.w),
                          Expanded(
                            child: SizedBox(
                              height: 35.h,
                              child: AppButton(
                                text: "No",
                                onPressed: () {
                                  setState(() {
                                    isDeletePressed = false;
                                  });
                                },
                                size: 15.sp,
                                borderRadius: 5.r,
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
          ),
        ],
      ),
    );
  }

  Widget _discountEditPage() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 40.h),
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
                child: Image.asset(backOrange, width: 30.w, height: 30.h),
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
                      SizedBox(width: 30.w),
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
                      width: 150.w,
                      height: 50.h,
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
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 40.h),
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
                child: Image.asset(backOrange, width: 30.w, height: 30.h),
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
                      SizedBox(width: 30.w),
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
                      width: 150.w,
                      height: 50.h,
                      child: AppButton(
                        text: 'Create',
                        borderRadius: 8,
                        onPressed: () {
                          createOffer();
                          // setState(() {
                          //   isOpen = !isOpen;
                          // });
                        },
                        bgColor1: Colors.blue,
                        bgColor2: Colors.blueAccent,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? appTextColor3 : Colors.transparent,
          border: Border.all(color: appTextColor3, width: 1),
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (text == "Custom" ? Color(0xFFBDB23A) : appTextColor2),
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
          ),
        ),
      ),
    );
  }

  Widget _offerScheduleCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 34.w, vertical: 28.h),
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
          SizedBox(height: 32.h),
          Text(
            "Active Days",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: offerPageTextColor,
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 18.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10.w,
            runSpacing: 8.h,
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
    final int displayHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: offerPageTextColor,
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 9.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
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
                  width: 38.w,
                  height: 30.h,
                  decoration: BoxDecoration(
                    color: time.period == DayPeriod.am
                        ?  const Color.fromARGB(255, 150, 148, 148)
                        : const Color(0xFF53534F) ,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10.r),
                      bottomRight: Radius.circular(10.r),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      time.period == DayPeriod.am ? 'AM' : 'PM',
                      style: TextStyle(
                        fontSize: 13.sp,
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
    return Container(height: 30.h, width: 1.w, color: Colors.white);
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
    final controller = FixedExtentScrollController(initialItem: value - min);
    return SizedBox(
      width: 30.w,
      height: 30.h,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 32.h,
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
                  fontSize: 16.sp,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50.w,
        height: 30.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF53534F) : const Color(0xFFC7C7C7),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : offerPageTextColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _discountApplyBox(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? appTextColor3 : Colors.transparent,
          border: Border.all(color: appTextColor3, width: 1),
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (text == "Custom" ? Color(0xFFBDB23A) : appTextColor2),
            fontWeight: FontWeight.w500,
            fontSize: 15.sp,
          ),
        ),
      ),
    );
  }
}
