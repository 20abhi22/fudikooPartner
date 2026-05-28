import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/completedBox.dart';
import 'package:fudiko/components/confirmedBox.dart';
import 'package:fudiko/components/processingbox.dart';
import 'package:fudiko/components/rejectedBox.dart';
import 'package:fudiko/components/searchResultBox.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/models/rerservation/reservation-cancelled-model.dart';
import 'package:fudiko/models/rerservation/reservation-comfirmed-model.dart';
import 'package:fudiko/models/rerservation/reservation-completed-model.dart';
import 'package:fudiko/models/rerservation/reservation-processing-model.dart';
import 'package:fudiko/models/rerservation/reservation-search-model.dart';
import 'package:fudiko/models/rerservation/reservation-status-change.dart';
import 'package:fudiko/services/profile-service.dart';
import 'package:fudiko/services/reservation-service.dart';
import 'package:fudiko/services/offer-service.dart';
import 'package:fudiko/models/offer/offer-list-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/tab_back_handler.dart';

class Reservation extends StatefulWidget {
  final VoidCallback? onDrawerTap;
  final PartnerProfileModel? partnerProfile;
  const Reservation({super.key, this.onDrawerTap, this.partnerProfile});

  @override
  State<Reservation> createState() => _ReservationState();
}

class _ReservationState extends State<Reservation>
    with WidgetsBindingObserver
    implements TabBackHandler {
  String selectedStatus = "Processing";
  String _previousStatus = "Processing";
  String selectedStatusReason = "Date or Time is not available";
  bool isOpen = false;
  bool isSearchClicked = false;
  static const Duration _searchAnimationDuration = Duration(milliseconds: 460);
  static const Duration _pollingInterval = Duration(seconds: 15);

  Timer? _pollingTimer;
  bool _isFetchingReservations = false;
  bool _isInForeground = true;
  bool _isRefreshing = false;
  late Future<void> _fetchFuture;

  final TextEditingController _searchController = TextEditingController();
  List<ReservationSearchModel> _searchResults = [];
  bool _isSearching = false;
  bool _searchDone = false;

  ReservationService reservationService = ReservationService();
  OfferService offerService = OfferService();
  Map<String, OfferModel> _offerMap = {};
  List<ReservationProcessingModel> processingreservations = [];
  List<ReservationConfirmedModel> confirmedreservations = [];
  List<ReservationCancelledModel> _cancelledReservations = [];
  List<ReservationCompletedModel> _completedReservations = [];
  String _completedFilter = "Last 7 days";
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  PartnerProfileModel? partnerProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchFuture = fetchReservations();
    _startPolling();
  }

  @override
  @override
  void dispose() {
    _searchController.dispose();
    _pollingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isInForeground = true;
      _startPolling();
      fetchReservations(force: true);
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _isInForeground = false;
      _stopPolling();
    }
  }

  @override
  bool handleBack() {
    if (isSearchClicked) {
      _closeSearch();
      return true;
    }

    if (isOpen) {
      setState(() {
        isOpen = false;
      });
      return true;
    }

    return false;
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (!_isInForeground) return;
      // _refreshData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await fetchReservations();
    if (mounted) {
      setState(() {
        _fetchFuture = Future.value();
        _isRefreshing = false;
      });
    }
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> refresh() async {
    // await fetchReservations(force: true);
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchDone = false;
    });

    final response = await reservationService.searchReservations(trimmed);

    if (mounted) {
      setState(() {
        _searchResults = response.reservations;
        _isSearching = false;
        _searchDone = true;
      });
    }
  }

  Future<void> fetchReservations({bool force = false}) async {
    if (_isFetchingReservations && !force) return;

    _isFetchingReservations = true;
    try {
      String? startDate;
      String? endDate;
      final now = DateTime.now();

      switch (_completedFilter) {
        case "Last 7 days":
          startDate = _formatDate(now.subtract(const Duration(days: 7)));
          endDate = _formatDate(now);
          break;
        case "Last 30 days":
          startDate = _formatDate(now.subtract(const Duration(days: 30)));
          endDate = _formatDate(now);
          break;
        case "Last 3 months":
          startDate = _formatDate(now.subtract(const Duration(days: 90)));
          endDate = _formatDate(now);
          break;
        case "Custom":
          if (_customStartDate != null && _customEndDate != null) {
            startDate = _formatDate(_customStartDate!);
            endDate = _formatDate(_customEndDate!);
          }
          break;
      }

      final results = await Future.wait([
        reservationService.getprocessingreservations(),
        reservationService.getconfirmedreservations(),
        reservationService.getcancelledreservations(),
        reservationService.getcompletedreservations(
          startDate: startDate,
          endDate: endDate,
        ),
      ]);

      final processingResponse =
          results[0] as ReservationProcessingModelResponse;
      final confirmedResponse = results[1] as ReservationConfirmedModelResponse;
      final cancelledResponse = results[2] as ReservationCancelledModelResponse;
      final completedResponse = results[3] as ReservationCompletedModelResponse;

      if (!mounted) return;

      setState(() {
        processingreservations = processingResponse.reservations;
        confirmedreservations = confirmedResponse.reservations;
        _cancelledReservations = cancelledResponse.reservations;
        _completedReservations = completedResponse.reservations;

        print('=========== Processing Reservations ===========');
        print(processingreservations);
        print('=========== Confirmed Reservations ============');
        print(confirmedreservations);
      });
      await _fetchOfferDetails();
      // mark the fetch future as completed so FutureBuilder stops showing loader
      if (mounted) {
        setState(() {
          _fetchFuture = Future.value();
        });
      }
    } catch (e) {
      print('Error fetching reservations: $e');
    } finally {
      _isFetchingReservations = false;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _fetchOfferDetails() async {
    final ids = <String>{};
    for (var r in processingreservations) {
      if (r.offerId.isNotEmpty) ids.add(r.offerId);
    }
    for (var r in confirmedreservations) {
      if (r.offerId.isNotEmpty) ids.add(r.offerId);
    }
    for (var r in _cancelledReservations) {
      if (r.offerId.isNotEmpty) ids.add(r.offerId);
    }
    for (var r in _completedReservations) {
      if (r.offerId.isNotEmpty) ids.add(r.offerId);
    }

    final futures = ids.map((id) async {
      final offer = await offerService.getOfferById(id);
      return MapEntry(id, offer);
    }).toList();

    try {
      final results = await Future.wait(futures);
      final map = <String, OfferModel>{};
      for (var entry in results) {
        if (entry.value != null) map[entry.key] = entry.value!;
      }
      if (mounted) {
        setState(() {
          _offerMap = map;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> changeStatus(String uuid, String status) async {
    try {
      ReservationStatusChangeResponseModel response = await reservationService
          .changeStatus(
            ReservationStatusChangeModel(reservationId: uuid, status: status),
          );
      if (response.status) {
        SnackBar snackBar = SnackBar(content: Text(response.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        await fetchReservations();
      } else {
        SnackBar snackBar = SnackBar(content: Text(response.message));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchCancelled() async {
    await fetchReservations();
  }

  bool _canCallBack(ReservationCancelledModel reservation) {
    final eventDate = DateTime.tryParse(reservation.date);
    if (eventDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    return today.isBefore(eventDay);
  }

  Future<void> _onCallBackPressed(ReservationCancelledModel reservation) async {
    if (!_canCallBack(reservation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Call back is available only before the event date'),
        ),
      );
      return;
    }

    await changeStatus(reservation.uuid, 'Pending');
  }

  List<ReservationCompletedModel> get _filteredCompleted {
    final now = DateTime.now();
    return _completedReservations.where((r) {
      final date = DateTime.tryParse(r.date);
      if (date == null) return true;
      switch (_completedFilter) {
        case "Last 7 days":
          return now.difference(date).inDays <= 7;
        case "Last 30 days":
          return now.difference(date).inDays <= 30;
        case "Last 3 months":
          return now.difference(date).inDays <= 90;
        case "Custom":
          if (_customStartDate == null || _customEndDate == null) return true;
          return date.isAfter(
                _customStartDate!.subtract(const Duration(days: 1)),
              ) &&
              date.isBefore(_customEndDate!.add(const Duration(days: 1)));
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _selectCompletedDateRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _CompletedDateRangeDialog(
        initialStartDate: _customStartDate,
        initialEndDate: _customEndDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      ),
    );

    if (picked == null) return;

    setState(() {
      _completedFilter = "Custom";
      _customStartDate = picked.start;
      _customEndDate = picked.end;
    });
    fetchReservations(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: FutureBuilder<void>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildFixedHeader(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: const CircularProgressIndicator(),
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildFixedHeader(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.w, color: Colors.red),
                    SizedBox(height: 16.h),
                    AppText(
                      text: 'Error loading reservations',
                      size: 16,
                      fontWeight: FontWeight.w500,
                      color: appTextColor3,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildTopSection(),
              SizedBox(height: 30.h),
              Expanded(
                child: RefreshIndicator(
                  color: Color(0XFFF97A0D),
                  onRefresh: () async {
                    setState(() {
                      _isRefreshing = true;
                    });
                    _fetchFuture = fetchReservations(force: true);
                    await _fetchFuture;
                    if (mounted) {
                      setState(() {
                        _isRefreshing = false;
                      });
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Column(
                      children: [
                        if (_isRefreshing)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: const CircularProgressIndicator(
                              color: Color(0XFFC95F05),
                            ),
                          ),
                        _buildSelectedTabContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: EdgeInsets.only(top: 30.h),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
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
                        Icon(
                          Icons.location_on,
                          size: 15.w,
                          color: appTextColor3,
                        ),
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
            ),
          ),
          SizedBox(height: 30.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildStatusSearchSwitcher(),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader({required Widget child}) {
    return Column(
      children: [
        _buildTopSection(),
        SizedBox(height: 30.h),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildSelectedTabContent() {
    if (selectedStatus == "Processing") {
      return processingreservations.isNotEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: ListView.builder(
                itemCount: processingreservations.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return ProcessingBox(
                    id: processingreservations[index].id,
                    uuid: processingreservations[index].uuid,
                    reservationId: processingreservations[index].reservationId,
                    userId: processingreservations[index].userId,
                    people: processingreservations[index].people,
                    restaurantId: processingreservations[index].restaurantId,
                    time: processingreservations[index].time,
                    date: processingreservations[index].date,
                    offerCode: processingreservations[index].offerCode,
                    offerCodeStatus:
                        processingreservations[index].offerCodeStatus,
                    discountPercentage:
                        processingreservations[index].offerId.isNotEmpty &&
                            _offerMap.containsKey(
                              processingreservations[index].offerId,
                            )
                        ? _offerMap[processingreservations[index].offerId]!
                              .discountPercentage
                        : null,
                    applicableFor:
                        processingreservations[index].offerId.isNotEmpty &&
                            _offerMap.containsKey(
                              processingreservations[index].offerId,
                            )
                        ? _offerMap[processingreservations[index].offerId]!
                              .applicableFor
                        : null,
                    dineType:
                        processingreservations[index].offerId.isNotEmpty &&
                            _offerMap.containsKey(
                              processingreservations[index].offerId,
                            )
                        ? _offerMap[processingreservations[index].offerId]!
                              .dineType
                        : null,
                    // startTime: processingreservations[index].offerId.isNotEmpty && _offerMap.containsKey(processingreservations[index].offerId)
                    //   ? _offerMap[processingreservations[index].offerId]!.startTime
                    //   : null,
                    // endTime: processingreservations[index].offerId.isNotEmpty && _offerMap.containsKey(processingreservations[index].offerId)
                    //   ? _offerMap[processingreservations[index].offerId]!.endTime
                    //   : null,
                    // activeDays: processingreservations[index].offerId.isNotEmpty && _offerMap.containsKey(processingreservations[index].offerId)
                    //   ? _offerMap[processingreservations[index].offerId]!.activeDays
                    //   : null,
                    status: processingreservations[index].status,
                    createdAt: processingreservations[index].createdAt,
                    updatedAt: processingreservations[index].updatedAt,
                    deleteOnPressed: () {
                      showReasonDialog(context, () async {
                        await changeStatus(
                          processingreservations[index].uuid,
                          "Cancelled",
                        );
                      });
                    },
                    onAcceptPressed: () async {
                      await changeStatus(
                        processingreservations[index].uuid,
                        "Confirmed",
                      );
                    },
                  );
                },
              ),
            )
          : const Center(child: Text("No Reservations Found"));
    }

    if (selectedStatus == "Confirmed") {
      return confirmedreservations.isNotEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: ListView.builder(
                itemCount: confirmedreservations.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return ConfirmedBox(
                    id: confirmedreservations[index].id,
                    uuid: confirmedreservations[index].uuid,
                    reservationId: confirmedreservations[index].reservationId,
                    userId: confirmedreservations[index].userId,
                    people: confirmedreservations[index].people,
                    restaurantId: confirmedreservations[index].restaurantId,
                    time: confirmedreservations[index].time,
                    date: confirmedreservations[index].date,
                    offerCode: confirmedreservations[index].offerCode,
                    offerCodeStatus:
                        confirmedreservations[index].offerCodeStatus,
                    discountPercentage:
                        confirmedreservations[index].offerId.isNotEmpty &&
                            _offerMap.containsKey(
                              confirmedreservations[index].offerId,
                            )
                        ? _offerMap[confirmedreservations[index].offerId]!
                              .discountPercentage
                        : null,
                    applicableFor:
                        confirmedreservations[index].offerId.isNotEmpty &&
                            _offerMap.containsKey(
                              confirmedreservations[index].offerId,
                            )
                        ? _offerMap[confirmedreservations[index].offerId]!
                              .applicableFor
                        : null,
                    dineType:
                        confirmedreservations[index].offerId.isNotEmpty &&
                            _offerMap.containsKey(
                              confirmedreservations[index].offerId,
                            )
                        ? _offerMap[confirmedreservations[index].offerId]!
                              .dineType
                        : null,
                    // startTime: confirmedreservations[index].offerId.isNotEmpty && _offerMap.containsKey(confirmedreservations[index].offerId)
                    //   ? _offerMap[confirmedreservations[index].offerId]!.startTime
                    //   : null,
                    // endTime: confirmedreservations[index].offerId.isNotEmpty && _offerMap.containsKey(confirmedreservations[index].offerId)
                    //   ? _offerMap[confirmedreservations[index].offerId]!.endTime
                    //   : null,
                    // activeDays: confirmedreservations[index].offerId.isNotEmpty && _offerMap.containsKey(confirmedreservations[index].offerId)
                    //   ? _offerMap[confirmedreservations[index].offerId]!.activeDays
                    //   : null,
                    status: confirmedreservations[index].status,
                    createdAt: confirmedreservations[index].createdAt,
                    updatedAt: confirmedreservations[index].updatedAt,
                    onAcceptPressed: () async {
                      await changeStatus(
                        confirmedreservations[index].uuid,
                        "Confirmed",
                      );
                    },
                  );
                },
              ),
            )
          : const Center(child: Text("No Reservations Found"));
    }

    if (selectedStatus == "Completed") {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: AppFilterDropDown(
                    hint:
                        _completedFilter == "Custom" &&
                            _customStartDate != null &&
                            _customEndDate != null
                        ? "${_customStartDate!.day}/${_customStartDate!.month} - ${_customEndDate!.day}/${_customEndDate!.month}"
                        : _completedFilter,
                    iconImage: "assets/images/filter_icon.png",
                    icon: Icons.tune,
                    toogleDropdown: () {
                      showModalBottomSheet(
                        backgroundColor: Colors.white,
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(25.r),
                          ),
                        ),
                        builder: (context) => Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40.w,
                                height: 5.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              for (final option in [
                                "Last 7 days",
                                "Last 30 days",
                                "Last 3 months",
                              ])
                                ListTile(
                                  title: Text(option),
                                  trailing: _completedFilter == option
                                      ? Icon(Icons.check, color: appButtonColor)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _completedFilter = option;
                                      _customStartDate = null;
                                      _customEndDate = null;
                                    });
                                    Navigator.pop(context);
                                    fetchReservations(force: true);
                                  },
                                ),
                              ListTile(
                                title: const Text("Custom date range"),
                                trailing: _completedFilter == "Custom"
                                    ? Icon(Icons.check, color: appButtonColor)
                                    : null,
                                onTap: () async {
                                  Navigator.pop(context);
                                  await _selectCompletedDateRange();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          _filteredCompleted.isNotEmpty
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: ListView.builder(
                    itemCount: _filteredCompleted.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),

                    itemBuilder: (context, index) {
                      final r = _filteredCompleted[index];
                      return CompletedBox(
                        reservation: r,
                        discountPercentage: r.discountPercentage,
                        applicableFor: r.applicableFor,
                        dineType: r.dineType,
                      );
                    },
                  ),
                )
              : const Center(child: Text("No Completed Reservations")),
        ],
      );
    }

    if (selectedStatus == "Rejected") {
      return _cancelledReservations.isNotEmpty
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: ListView.builder(
                itemCount: _cancelledReservations.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final reservation = _cancelledReservations[index];
                  final offer = _offerMap[reservation.offerId];
                  return RejectedBox(
                    reservation: reservation,
                    isCallBackEnabled: _canCallBack(reservation),
                    onCallBackPressed: () => _onCallBackPressed(reservation),
                    discountPercentage: offer?.discountPercentage,
                    applicableFor: offer?.applicableFor,
                    dineType: offer?.dineType,
                  );
                },
              ),
            )
          : const Center(child: Text("No Rejected Reservations"));
    }

    if (selectedStatus == "Search") {
      if (_isSearching) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_searchDone && _searchResults.isEmpty) {
        return const Center(child: Text("No results found"));
      }
      if (_searchResults.isNotEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) =>
                SearchResultBox(reservation: _searchResults[index]),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }

  Future<void> showReasonDialog(
    BuildContext context,
    Future<void> Function()? onConfirm,
  ) async {
    final reasons = [
      'Date or Time is not available',
      'Offer Expired',
      'Not Valid',
      'Maximum Redemptions Reached',
      'Technical Issue',
      'Not Opened',
    ];
    String selectedReason = selectedStatusReason.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 40.h,
              ),
              child: Container(
                height: 316.h,
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 20.w,
                  right: 20.w,
                  top: 30.h,
                  bottom: 30.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17.r),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black.withOpacity(0.1),
                  //     blurRadius: 10,
                  //     offset: const Offset(0, 4),
                  //   ),
                  // ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 20.h,
                    bottom: 10.h,
                    left: 30.w,
                    right: 30.w,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        text: 'Reason',
                        size: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: reasonTextColor,
                        isCentered: true,
                      ),
                      SizedBox(height: 15.h),

                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Row 1: "Date or Time is not available" - full width
                            _buildChip(
                              'Date or Time is not available',
                              selectedReason,
                              setDialogState,
                              (r) {
                                selectedReason = r;
                              },
                            ),
                            SizedBox(height: 5.h),
                            // Row 2: "Offer Expired" + "Not Valid" - equal width
                            Row(
                              children: [
                                Expanded(
                                  child: _buildChip(
                                    'Offer Expired',
                                    selectedReason,
                                    setDialogState,
                                    (r) {
                                      selectedReason = r;
                                    },
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: _buildChip(
                                    'Not Valid',
                                    selectedReason,
                                    setDialogState,
                                    (r) {
                                      selectedReason = r;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            // Row 3: "Maximum Redemptions Reached" - full width
                            _buildChip(
                              'Maximum Redemptions Reached',
                              selectedReason,
                              setDialogState,
                              (r) {
                                selectedReason = r;
                              },
                            ),
                            SizedBox(height: 5.h),
                            // Row 4: "Technical Issue" + "Not Opened" - equal width
                            Row(
                              children: [
                                Expanded(
                                  child: _buildChip(
                                    'Technical Issue',
                                    selectedReason,
                                    setDialogState,
                                    (r) {
                                      selectedReason = r;
                                    },
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Expanded(
                                  child: _buildChip(
                                    'Not Opened',
                                    selectedReason,
                                    setDialogState,
                                    (r) {
                                      selectedReason = r;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 27.h,
                            width: 79.w,
                            child: AppButton(
                              fontWeight: FontWeight.w400,
                              text: 'Cancel',
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              bgColor1: reasonCancelButtonColor,
                              bgColor2: reasonCancelButtonColor,
                              size: 12.sp,
                              borderRadius: 5,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          SizedBox(
                            height: 27.h,
                            width: 133.w,
                            child: AppButton(
                              fontWeight: FontWeight.w400,
                              text: 'Confirm Rejection',
                              onPressed: () async {
                                setState(() {
                                  selectedStatusReason = selectedReason;
                                });
                                Navigator.of(context).pop();
                                if (onConfirm != null) await onConfirm();
                              },
                              bgColor1: reasonConfirmButtonColor,
                              bgColor2: reasonConfirmButtonColor,
                              size: 12.sp,
                              borderRadius: 5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _selectStatus(String text) {
    if (selectedStatus == text) return;

    setState(() {
      _previousStatus = selectedStatus;
      selectedStatus = text;
    });
  }

  Widget _buildAnimatedStatusTabs({
    required double width,
    required double searchButtonWidth,
  }) {
    final tabs = ["Processing", "Confirmed", "Completed", "Rejected"];
    final previousPosition = _statusTabPosition(_previousStatus);
    final selectedPosition = _statusTabPosition(selectedStatus);
    final isAdjacent =
        previousPosition != null &&
        selectedPosition != null &&
        (previousPosition.row - selectedPosition.row).abs() +
                (previousPosition.column - selectedPosition.column).abs() ==
            1;

    return Stack(
      children: [
        _buildStatusIndicator(
          width: width,
          searchButtonWidth: searchButtonWidth,
          isAdjacent: isAdjacent,
        ),
        ...tabs.map(
          (tab) => _buildPositionedStatusButton(
            tab,
            width: width,
            searchButtonWidth: searchButtonWidth,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator({
    required double width,
    required double searchButtonWidth,
    required bool isAdjacent,
  }) {
    final rect = _statusTabRect(
      selectedStatus,
      width: width,
      searchButtonWidth: searchButtonWidth,
    );
    final indicator = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC95F05), Color(0xFFF97A0D)],
        ),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );

    if (!isAdjacent) {
      return Positioned.fromRect(
        rect: rect,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(selectedStatus),
          tween: Tween(begin: 0.84, end: 1),
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Opacity(
              opacity: scale.clamp(0.0, 1.0),
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: indicator,
        ),
      );
    }

    return AnimatedPositioned.fromRect(
      rect: rect,
      duration: const Duration(milliseconds: 430),
      curve: Curves.easeInOutCubic,
      child: indicator,
    );
  }

  Widget _buildPositionedStatusButton(
    String text, {
    required double width,
    required double searchButtonWidth,
  }) {
    final isSelected = selectedStatus == text;
    return Positioned.fromRect(
      rect: _statusTabRect(
        text,
        width: width,
        searchButtonWidth: searchButtonWidth,
      ),
      child: GestureDetector(
        onTap: () => _selectStatus(text),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          scale: isSelected ? 1.02 : 1,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
            ),
            child: AppText(
              text: text,
              size: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor3,
            ),
          ),
        ),
      ),
    );
  }

  Rect _statusTabRect(
    String text, {
    required double width,
    required double searchButtonWidth,
  }) {
    final double gap = 10.w;
    final double tabHeight = 29.h;
    final double secondRowTop = tabHeight + gap;
    final double topTabWidth = (width - gap) / 2;
    final double bottomTabWidth = (width - searchButtonWidth - (gap * 2)) / 2;

    switch (text) {
      case "Confirmed":
        return Rect.fromLTWH(topTabWidth + gap, 0, topTabWidth, tabHeight);
      case "Completed":
        return Rect.fromLTWH(0, secondRowTop, bottomTabWidth, tabHeight);
      case "Rejected":
        return Rect.fromLTWH(
          bottomTabWidth + gap,
          secondRowTop,
          bottomTabWidth,
          tabHeight,
        );
      case "Processing":
      default:
        return Rect.fromLTWH(0, 0, topTabWidth, tabHeight);
    }
  }

  _StatusTabPosition? _statusTabPosition(String text) {
    switch (text) {
      case "Processing":
        return const _StatusTabPosition(row: 0, column: 0);
      case "Confirmed":
        return const _StatusTabPosition(row: 0, column: 1);
      case "Completed":
        return const _StatusTabPosition(row: 1, column: 0);
      case "Rejected":
        return const _StatusTabPosition(row: 1, column: 1);
      default:
        return null;
    }
  }

  Widget _buildStatusSearchSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double expandedHeight = 60.h;
        final double collapsedHeight = 68.h;
        final double searchButtonWidth = 60.w;

        return AnimatedContainer(
          duration: _searchAnimationDuration,
          curve: Curves.easeInOutCubic,
          height: isSearchClicked ? expandedHeight : collapsedHeight,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOut,
                opacity: isSearchClicked ? 0 : 1,
                child: AnimatedSlide(
                  duration: _searchAnimationDuration,
                  curve: Curves.easeInOutCubic,
                  offset: isSearchClicked
                      ? const Offset(-0.05, 0)
                      : Offset.zero,
                  child: IgnorePointer(
                    ignoring: isSearchClicked,
                    child: _buildAnimatedStatusTabs(
                      width: constraints.maxWidth,
                      searchButtonWidth: searchButtonWidth,
                    ),
                  ),
                ),
              ),
              _AnimatedSearchField(
                isExpanded: isSearchClicked,
                width: isSearchClicked
                    ? constraints.maxWidth
                    : searchButtonWidth,
                controller: _searchController,
                onOpen: () {
                  setState(() {
                    isSearchClicked = true;
                    _previousStatus = selectedStatus;
                    selectedStatus = "Search";
                  });
                },
                onClose: _closeSearch,
                onChanged: _onSearchChanged,
              ),
            ],
          ),
        );
      },
    );
  }

  void _closeSearch() {
    setState(() {
      isSearchClicked = false;
      _previousStatus = "Processing";
      selectedStatus = "Processing";
      _searchController.clear();
      _searchResults = [];
      _searchDone = false;
    });
  }

  void _onSearchChanged(String val) {
    setState(() {});
    if (val.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchDone = false;
      });
      return;
    }

    _performSearch(val);
  }

  Widget _buildChip(
    String reason,
    String selectedReason,
    StateSetter setDialogState,
    void Function(String) onSelect,
  ) {
    final isSelected = selectedReason == reason;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          onSelect(reason);
        });
      },
      child: Container(
        width: double.infinity, // ← stretches to parent width
        height: 30.h,
        // padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? reasonSelectColor : reasonUnselectColor,
          borderRadius: BorderRadius.all(Radius.circular(15.r)),
        ),
        alignment: Alignment.center,

        child: Text(
          reason,
          textAlign: TextAlign.center, // ← center the text inside
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _CompletedDateRangeDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CompletedDateRangeDialog({
    required this.initialStartDate,
    required this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CompletedDateRangeDialog> createState() =>
      _CompletedDateRangeDialogState();
}

class _CompletedDateRangeDialogState extends State<_CompletedDateRangeDialog> {
  late DateTime _displayMonth;
  late int _pickerYear;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showMonthYearPicker = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    final seedDate = _startDate ?? widget.lastDate;
    _displayMonth = DateTime(seedDate.year, seedDate.month);
    _pickerYear = _displayMonth.year;
  }

  void _prevMonth() {
    final previous = DateTime(_displayMonth.year, _displayMonth.month - 1);
    if (previous.isBefore(
      DateTime(widget.firstDate.year, widget.firstDate.month),
    )) {
      return;
    }
    setState(() => _displayMonth = previous);
  }

  void _nextMonth() {
    final next = DateTime(_displayMonth.year, _displayMonth.month + 1);
    if (next.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month))) {
      return;
    }
    setState(() => _displayMonth = next);
  }

  void _togglePicker() {
    setState(() {
      _showMonthYearPicker = !_showMonthYearPicker;
      _pickerYear = _displayMonth.year;
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
        return;
      }

      if (date.isBefore(_startDate!)) {
        _endDate = _startDate;
        _startDate = date;
      } else {
        _endDate = date;
      }
    });
  }

  void _selectMonthYear(int month, int year) {
    setState(() {
      _displayMonth = DateTime(year, month);
      _showMonthYearPicker = false;
    });
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isDateDisabled(DateTime date) {
    final first = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final last = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );
    return date.isBefore(first) || date.isAfter(last);
  }

  @override
  Widget build(BuildContext context) {
    final canApply = _startDate != null && _endDate != null;
    final monthName = _monthName(_displayMonth.month);

    return Dialog(
      backgroundColor: const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _showMonthYearPicker ? null : _prevMonth,
                ),
                GestureDetector(
                  onTap: _togglePicker,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$monthName  ${_displayMonth.year}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        _showMonthYearPicker
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Colors.black54,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _showMonthYearPicker ? null : _nextMonth,
                ),
              ],
            ),
            if (_showMonthYearPicker) ...[
              SizedBox(height: 6.h),
              _buildMonthYearPicker(),
            ] else ...[
              SizedBox(height: 6.h),
              _buildWeekdayLabels(),
              SizedBox(height: 6.h),
              _buildDayGrid(),
            ],
            SizedBox(height: 12.h),
            _buildSelectedRangeLabel(),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black54, fontSize: 14.sp),
                    ),
                  ),
                  TextButton(
                    onPressed: canApply
                        ? () => Navigator.pop(
                            context,
                            DateTimeRange(start: _startDate!, end: _endDate!),
                          )
                        : null,
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        color: canApply ? appButtonColor : Colors.black26,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
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

  Widget _buildSelectedRangeLabel() {
    final label = _startDate == null
        ? 'Select start date'
        : _endDate == null
        ? 'Select end date'
        : '${_shortDate(_startDate!)} - ${_shortDate(_endDate!)}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMonthYearPicker() {
    final firstYear = widget.firstDate.year;
    final lastYear = widget.lastDate.year;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              onPressed: _pickerYear > firstYear
                  ? () => setState(() => _pickerYear--)
                  : null,
            ),
            GestureDetector(
              onTap: () => _showYearScrollPicker(context),
              child: Text(
                '$_pickerYear',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: appButtonColor,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: _pickerYear < lastYear
                  ? () => setState(() => _pickerYear++)
                  : null,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            final month = index + 1;
            final monthDate = DateTime(_pickerYear, month);
            final isSelected = _isSameMonth(monthDate, _displayMonth);
            final isDisabled =
                monthDate.isBefore(
                  DateTime(widget.firstDate.year, widget.firstDate.month),
                ) ||
                monthDate.isAfter(
                  DateTime(widget.lastDate.year, widget.lastDate.month),
                );

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () => _selectMonthYear(month, _pickerYear),
              child: Container(
                height: 50.h,
                decoration: BoxDecoration(
                  color: isSelected ? appButtonColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected ? appButtonColor : Colors.black12,
                  ),
                ),
                child: Center(
                  child: Text(
                    _shortMonth(month),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isDisabled
                          ? Colors.black26
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  void _showYearScrollPicker(BuildContext context) {
    final years = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (index) => widget.firstDate.year + index,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => SizedBox(
        height: 250.h,
        child: ListView.builder(
          itemCount: years.length,
          itemBuilder: (context, index) {
            final year = years[index];
            final isSelected = year == _pickerYear;
            return ListTile(
              onTap: () {
                setState(() => _pickerYear = year);
                Navigator.pop(context);
              },
              title: Center(
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? appButtonColor : Colors.black87,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
            .map(
              (day) => SizedBox(
                width: 36.w,
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDayGrid() {
    final today = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayMonth.year,
      _displayMonth.month,
    );
    final firstWeekday =
        DateTime(_displayMonth.year, _displayMonth.month, 1).weekday % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: firstWeekday + daysInMonth,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 0,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        if (index < firstWeekday) return const SizedBox();

        final day = index - firstWeekday + 1;
        final date = DateTime(_displayMonth.year, _displayMonth.month, day);
        final isDisabled = _isDateDisabled(date);
        final isStart =
            _startDate != null && DateUtils.isSameDay(date, _startDate);
        final isEnd = _endDate != null && DateUtils.isSameDay(date, _endDate);
        final isSelected = isStart || isEnd;
        final isToday = DateUtils.isSameDay(date, today);
        final isInRange =
            _startDate != null &&
            _endDate != null &&
            date.isAfter(_startDate!) &&
            date.isBefore(_endDate!);

        return GestureDetector(
          onTap: isDisabled ? null : () => _selectDate(date),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? appButtonColor
                      : isInRange
                      ? appButtonColor.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : isDisabled
                          ? Colors.black26
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              isToday
                  ? Container(
                      width: 5.w,
                      height: 5.w,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : SizedBox(height: 5.w),
            ],
          ),
        );
      },
    );
  }

  String _shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  String _shortMonth(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _StatusTabPosition {
  final int row;
  final int column;

  const _StatusTabPosition({required this.row, required this.column});
}

class _AnimatedSearchField extends StatelessWidget {
  final bool isExpanded;
  final double width;
  final TextEditingController controller;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;

  const _AnimatedSearchField({
    required this.isExpanded,
    required this.width,
    required this.controller,
    required this.onOpen,
    required this.onClose,
    required this.onChanged,
  });

  static const Duration _duration = Duration(milliseconds: 460);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isExpanded ? null : onOpen,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeInOutCubic,
        width: width,
        height: isExpanded ? 60.h : 29.h,
        padding: EdgeInsets.only(
          left: isExpanded ? 18.w : 4.w,
          right: isExpanded ? 12.w : 4.w,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isExpanded ? 20.r : 10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isExpanded ? 0.22 : 0.18),
              blurRadius: isExpanded ? 15.r : 6.r,
              offset: isExpanded ? Offset.zero : const Offset(2, 2),
            ),
          ],
        ),
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool hasFieldRoom = constraints.maxWidth > 120.w;

              if (!hasFieldRoom) {
                return Center(
                  child: Image.asset(
                    "assets/images/search_icon.png",
                    width: 20.w,
                    height: 20.w,
                    fit: BoxFit.contain,
                  ),
                );
              }

              return Row(
                children: [
                  AnimatedContainer(
                    duration: _duration,
                    curve: Curves.easeInOutCubic,
                    width: 24.w,
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      "assets/images/search_icon.png",
                      width: 22.w,
                      height: 22.w,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut,
                      opacity: isExpanded ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !isExpanded,
                        child: TextField(
                          autofocus: isExpanded,
                          controller: controller,
                          cursorColor: appTextColor,
                          keyboardType: TextInputType.text,
                          onChanged: onChanged,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: "Coupon Number",
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 16.h,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    scale: isExpanded ? 1 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 240),
                      opacity: isExpanded ? 1 : 0,
                      child: InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(18.r),
                        child: Padding(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 22.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
