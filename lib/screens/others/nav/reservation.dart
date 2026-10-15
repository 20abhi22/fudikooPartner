import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/completedDateRangeDialog.dart';
import 'package:fudiko/components/completedBox.dart';
import 'package:fudiko/components/dateFilterSheet.dart';
import 'package:fudiko/components/confirmedBox.dart';
import 'package:fudiko/components/processingbox.dart';
import 'package:fudiko/components/rejectedBox.dart';
import 'package:fudiko/components/searchResultBox.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/models/rerservation/reservation-cancelled-model.dart';
import 'package:fudiko/models/rerservation/reservation-comfirmed-model.dart';
import 'package:fudiko/models/rerservation/reservation-completed-model.dart';
import 'package:fudiko/models/rerservation/reservation-processing-model.dart';
import 'package:fudiko/models/rerservation/reservation-search-model.dart';
import 'package:fudiko/models/rerservation/reservation-status-change.dart';
import 'package:fudiko/services/reservation-service.dart';
import 'package:fudiko/services/offer-service.dart';
import 'package:fudiko/services/badge_controller.dart';
import 'package:fudiko/models/offer/offer-list-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/snackbar.dart';
import 'package:fudiko/utils/tab_back_handler.dart';
import 'package:fudiko/utils/tab_refreshable.dart';

class Reservation extends StatefulWidget {
  final VoidCallback? onDrawerTap;
  final PartnerProfileModel? partnerProfile;
  const Reservation({super.key, this.onDrawerTap, this.partnerProfile});

  @override
  State<Reservation> createState() => _ReservationState();
}

class _ReservationState extends State<Reservation>
    with WidgetsBindingObserver
    implements TabBackHandler, TabRefreshable {
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
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> refresh() async {
    await fetchReservations(force: true);
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
      });
      await _fetchOfferDetails();
      // mark the fetch future as completed so FutureBuilder stops showing loader
      if (mounted) {
        setState(() {
          _fetchFuture = Future.value();
        });
      }
    } catch (_) {
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
      if (!mounted) return;

      showStatusSnack(context, response.status, response.message);

      if (response.status) {
        await fetchReservations();
        // refresh global badges after a successful status change
        BadgeController.instance.refresh();
      }
    } catch (_) {}
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
      showInfoSnack(
        context,
        'Call back is available only before the event date',
      );
      return;
    }

    final response = await reservationService.callbackReservation(
      reservation.uuid,
    );
    if (!mounted) return;

    showStatusSnack(context, response.status, response.message);

    if (response.status) {
      await fetchReservations(force: true);
      BadgeController.instance.refresh();
    }
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
      builder: (context) => CompletedDateRangeDialog(
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

  bool get _isLandscape =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  double get _keyboardInset => MediaQuery.viewInsetsOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      resizeToAvoidBottomInset: !_isLandscape,
      body: SafeArea(
        minimum: EdgeInsets.only(top: _usesTabletLayout(context) ? 12.0 : 0.0),
        child: FutureBuilder<void>(
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

            return RefreshIndicator(
              color: const Color(0XFFF97A0D),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          _buildTopSection(),
                          SizedBox(height: _contentGap(context)),
                          if (_isRefreshing)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: const CircularProgressIndicator(
                                color: Color(0XFFC95F05),
                              ),
                            ),
                          _buildSelectedTabContent(),
                          if (_isLandscape) SizedBox(height: _keyboardInset),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  double _screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

  bool _isWideShortPhone(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Breakpoints.isWideShortPhone(size);
  }

  bool _usesTabletLayout(BuildContext context) =>
      Breakpoints.isTabletDevice(MediaQuery.sizeOf(context)) ||
      _isWideShortPhone(context);

  double _pagePadding(BuildContext context) {
    return _usesTabletLayout(context)
        ? 24.0
        : AppDimensions.padding(_screenWidth(context));
  }

  double _contentMaxWidth(BuildContext context) {
    final width = _screenWidth(context);
    if (Breakpoints.isDesktop(width)) return 860;
    if (_usesTabletLayout(context)) return 720;
    return double.infinity;
  }

  double _contentGap(BuildContext context) {
    if (_isWideShortPhone(context)) return 12.0;
    if (_usesTabletLayout(context)) return 24.0;
    return 30.h;
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

  Widget _buildTopSection() {
    final width = _screenWidth(context);
    final usesTabletLayout = _usesTabletLayout(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final topPadding = isWideShortPhone
        ? 8.0
        : usesTabletLayout
        ? 24.0
        : Breakpoints.isMobile(width)
        ? 30.h
        : 24.0;
    final gap = isWideShortPhone
        ? 8.0
        : usesTabletLayout
        ? 20.0
        : AppDimensions.gap(width);
    final nameSize = isWideShortPhone
        ? 24.0
        : usesTabletLayout
        ? 42.0
        : Breakpoints.isDesktop(width)
        ? 38.0
        : 35.0;
    final typeSize = isWideShortPhone
        ? 15.0
        : usesTabletLayout
        ? 28.0
        : Breakpoints.isDesktop(width)
        ? 24.0
        : 25.0;
    final addressSize = isWideShortPhone ? 11.0 : 15.0;
    final locationIconSize = isWideShortPhone
        ? 13.0
        : usesTabletLayout
        ? 16.0
        : Breakpoints.isMobile(width)
        ? 15.w
        : 16.0;
    final menuIconSize = isWideShortPhone
        ? 22.0
        : usesTabletLayout
        ? 30.0
        : Breakpoints.isMobile(width)
        ? 30.w
        : 30.0;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: _responsiveContent(
        child: Column(
          children: [
            Row(
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
                        maxLines: 2,
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
                            size: locationIconSize,
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
                              size: addressSize,
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
                    size: menuIconSize,
                    color: appTextColor3,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: usesTabletLayout
                  ? isWideShortPhone
                        ? 10.0
                        : gap
                  : Breakpoints.isMobile(width)
                  ? 30.h
                  : gap,
            ),
            _buildStatusSearchSwitcher(),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedHeader({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                _buildTopSection(),
                SizedBox(height: _contentGap(context)),
                child,
                if (_isLandscape) SizedBox(height: _keyboardInset),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedTabContent() {
    if (selectedStatus == "Processing") {
      return processingreservations.isNotEmpty
          ? _responsiveContent(
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
                          "Rejected",
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
          : Center(
              child: AppText(
                text: "No Reservations Found",
                size: 15,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
                isCentered: true,
              ),
            );
    }

    if (selectedStatus == "Confirmed") {
      return confirmedreservations.isNotEmpty
          ? _responsiveContent(
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
                    customerId: confirmedreservations[index].customerId,
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
                    onRemindPressed: (reservationId) async {
                      final response = await reservationService
                          .remindReservation(reservationId);
                      if (!mounted) return;

                      showStatusSnack(
                        context,
                        response.status,
                        response.message,
                      );
                    },
                  );
                },
              ),
            )
          : Center(
              child: AppText(
                text: "No Reservations Found",
                size: 15,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
                isCentered: true,
              ),
            );
    }

    if (selectedStatus == "Completed") {
      final width = _screenWidth(context);
      final usesTabletLayout = _usesTabletLayout(context);
      final filterWidth = usesTabletLayout
          ? 260.0
          : (width * 0.42).clamp(190.0, 320.0);

      return Column(
        children: [
          _responsiveContent(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: filterWidth,
                  child: AppFilterDropDown(
                    fieldBorderRadius: 6,
                    height: usesTabletLayout ? 42.0 : 35.h,
                    hint:
                        _completedFilter == "Custom" &&
                            _customStartDate != null &&
                            _customEndDate != null
                        ? "${formatDateForRange(_customStartDate!, _customEndDate!)} - ${formatDateForRange(_customEndDate!, _customStartDate!)}"
                        : _completedFilter,
                    iconImage: "assets/images/filter_icon.png",
                    icon: Icons.tune,
                    toogleDropdown: () async {
                      await showDateFilterSheet(
                        context: context,
                        options: const [
                          "Last 7 days",
                          "Last 30 days",
                          "Last 3 months",
                        ],
                        selectedValue: _completedFilter,
                        customValue: "Custom",
                        onOptionSelected: (option) {
                          setState(() {
                            _completedFilter = option;
                            _customStartDate = null;
                            _customEndDate = null;
                          });
                          fetchReservations(force: true);
                        },
                        onCustomTap: _selectCompletedDateRange,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          _filteredCompleted.isNotEmpty
              ? _responsiveContent(
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
              : Center(
                  child: AppText(
                    text: "No Completed Reservations",
                    size: 15,
                    fontWeight: FontWeight.w500,
                    color: appTextColor2,
                    isCentered: true,
                  ),
                ),
        ],
      );
    }

    if (selectedStatus == "Rejected") {
      return _cancelledReservations.isNotEmpty
          ? _responsiveContent(
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
          : Center(
              child: AppText(
                text: "No Rejected Reservations",
                size: 15,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
                isCentered: true,
              ),
            );
    }

    if (selectedStatus == "Search") {
      if (_isSearching) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_searchDone && _searchResults.isEmpty) {
        return Center(
          child: AppText(
            text: "No results found",
            size: 15,
            fontWeight: FontWeight.w500,
            color: appTextColor2,
            isCentered: true,
          ),
        );
      }
      if (_searchResults.isNotEmpty) {
        return _responsiveContent(
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

  // Future<void> showReasonDialog(
  //   BuildContext context,
  //   Future<void> Function()? onConfirm,
  // ) async {
  //   String selectedReason = selectedStatusReason.trim();

  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setDialogState) {
  //           return Dialog(
  //             backgroundColor: Colors.transparent,
  //             insetPadding: EdgeInsets.symmetric(
  //               horizontal: 20.w,
  //               vertical: 40.h,
  //             ),
  //             child: Container(
  //               height: 316.h,
  //               width: double.infinity,
  //               padding: EdgeInsets.only(
  //                 left: 20.w,
  //                 right: 20.w,
  //                 top: 30.h,
  //                 bottom: 30.h,
  //               ),
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.circular(17.r),
  //                 // boxShadow: [
  //                 //   BoxShadow(
  //                 //     color: Colors.black.withOpacity(0.1),
  //                 //     blurRadius: 10,
  //                 //     offset: const Offset(0, 4),
  //                 //   ),
  //                 // ],
  //               ),
  //               child: Padding(
  //                 padding: EdgeInsets.only(
  //                   top: 20.h,
  //                   bottom: 10.h,
  //                   left: 30.w,
  //                   right: 30.w,
  //                 ),
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     AppText(
  //                       text: 'Reason',
  //                       size: 15.sp,
  //                       fontWeight: FontWeight.w700,
  //                       color: reasonTextColor,
  //                       isCentered: true,
  //                     ),
  //                     SizedBox(height: 15.h),

  //                     SizedBox(
  //                       width: double.infinity,
  //                       child: Column(
  //                         mainAxisSize: MainAxisSize.min,
  //                         crossAxisAlignment: CrossAxisAlignment.stretch,
  //                         children: [
  //                           // Row 1: "Date or Time is not available" - full width
  //                           _buildChip(
  //                             'Date or Time is not available',
  //                             selectedReason,
  //                             setDialogState,
  //                             (r) {
  //                               selectedReason = r;
  //                             },
  //                           ),
  //                           SizedBox(height: 5.h),
  //                           // Row 2: "Offer Expired" + "Not Valid" - equal width
  //                           Row(
  //                             children: [
  //                               Expanded(
  //                                 child: _buildChip(
  //                                   'Offer Expired',
  //                                   selectedReason,
  //                                   setDialogState,
  //                                   (r) {
  //                                     selectedReason = r;
  //                                   },
  //                                 ),
  //                               ),
  //                               SizedBox(width: 5.w),
  //                               Expanded(
  //                                 child: _buildChip(
  //                                   'Not Valid',
  //                                   selectedReason,
  //                                   setDialogState,
  //                                   (r) {
  //                                     selectedReason = r;
  //                                   },
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                           SizedBox(height: 5.h),
  //                           // Row 3: "Maximum Redemptions Reached" - full width
  //                           _buildChip(
  //                             'Maximum Redemptions Reached',
  //                             selectedReason,
  //                             setDialogState,
  //                             (r) {
  //                               selectedReason = r;
  //                             },
  //                           ),
  //                           SizedBox(height: 5.h),
  //                           // Row 4: "Technical Issue" + "Not Opened" - equal width
  //                           Row(
  //                             children: [
  //                               Expanded(
  //                                 child: _buildChip(
  //                                   'Technical Issue',
  //                                   selectedReason,
  //                                   setDialogState,
  //                                   (r) {
  //                                     selectedReason = r;
  //                                   },
  //                                 ),
  //                               ),
  //                               SizedBox(width: 5.w),
  //                               Expanded(
  //                                 child: _buildChip(
  //                                   'Not Opened',
  //                                   selectedReason,
  //                                   setDialogState,
  //                                   (r) {
  //                                     selectedReason = r;
  //                                   },
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     SizedBox(height: 30.h),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         SizedBox(
  //                           height: 27.h,
  //                           width: 79.w,
  //                           child: AppButton(
  //                             fontWeight: FontWeight.w400,
  //                             text: 'Cancel',
  //                             onPressed: () {
  //                               Navigator.of(context).pop();
  //                             },
  //                             bgColor1: reasonCancelButtonColor,
  //                             bgColor2: reasonCancelButtonColor,
  //                             size: 12.sp,
  //                             borderRadius: 5,
  //                           ),
  //                         ),
  //                         SizedBox(width: 10.w),
  //                         SizedBox(
  //                           height: 27.h,
  //                           width: 133.w,
  //                           child: AppButton(
  //                             fontWeight: FontWeight.w400,
  //                             text: 'Confirm Rejection',
  //                             onPressed: () async {
  //                               setState(() {
  //                                 selectedStatusReason = selectedReason;
  //                               });
  //                               Navigator.of(context).pop();
  //                               if (onConfirm != null) await onConfirm();
  //                             },
  //                             bgColor1: reasonConfirmButtonColor,
  //                             bgColor2: reasonConfirmButtonColor,
  //                             size: 12.sp,
  //                             borderRadius: 5,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Future<void> showReasonDialog(
    BuildContext context,
    Future<void> Function()? onConfirm,
  ) async {
    String selectedReason = selectedStatusReason.trim();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile =
        Breakpoints.isMobileDevice(MediaQuery.sizeOf(context)) &&
        !_isWideShortPhone(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20.w : screenWidth * 0.2,
                vertical: isMobile ? 40.h : 60,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20.w : 28,
                  vertical: isMobile ? 30.h : 28,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isMobile ? 17.r : 16),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10.w : 16,
                    vertical: isMobile ? 10.h : 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        text: 'Reason',
                        size: isMobile ? 15.sp : 15,
                        fontWeight: FontWeight.w700,
                        color: reasonTextColor,
                        isCentered: true,
                      ),
                      SizedBox(height: isMobile ? 15.h : 14),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildChip(
                            'Date or Time is not available',
                            selectedReason,
                            setDialogState,
                            (r) => selectedReason = r,
                            isMobile: isMobile,
                          ),
                          SizedBox(height: isMobile ? 5.h : 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildChip(
                                  'Offer Expired',
                                  selectedReason,
                                  setDialogState,
                                  (r) => selectedReason = r,
                                  isMobile: isMobile,
                                ),
                              ),
                              SizedBox(width: isMobile ? 5.w : 8),
                              Expanded(
                                child: _buildChip(
                                  'Not Valid',
                                  selectedReason,
                                  setDialogState,
                                  (r) => selectedReason = r,
                                  isMobile: isMobile,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 5.h : 6),
                          _buildChip(
                            'Maximum Redemptions Reached',
                            selectedReason,
                            setDialogState,
                            (r) => selectedReason = r,
                            isMobile: isMobile,
                          ),
                          SizedBox(height: isMobile ? 5.h : 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildChip(
                                  'Technical Issue',
                                  selectedReason,
                                  setDialogState,
                                  (r) => selectedReason = r,
                                  isMobile: isMobile,
                                ),
                              ),
                              SizedBox(width: isMobile ? 5.w : 8),
                              Expanded(
                                child: _buildChip(
                                  'Not Opened',
                                  selectedReason,
                                  setDialogState,
                                  (r) => selectedReason = r,
                                  isMobile: isMobile,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 24.h : 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: isMobile ? 27.h : 36,
                            width: isMobile ? 79.w : 100,
                            child: AppButton(
                              fontWeight: FontWeight.w400,
                              text: 'Cancel',
                              onPressed: () => Navigator.of(context).pop(),
                              bgColor1: reasonCancelButtonColor,
                              bgColor2: reasonCancelButtonColor,
                              size: isMobile ? 12.sp : 13,
                              borderRadius: 5,
                            ),
                          ),
                          SizedBox(width: isMobile ? 10.w : 12),
                          SizedBox(
                            height: isMobile ? 27.h : 36,
                            width: isMobile ? 133.w : 160,
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
                              size: isMobile ? 12.sp : 13,
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
    required double tabGap,
    required double tabHeight,
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
          tabGap: tabGap,
          tabHeight: tabHeight,
          isAdjacent: isAdjacent,
        ),
        ...tabs.map(
          (tab) => _buildPositionedStatusButton(
            tab,
            width: width,
            searchButtonWidth: searchButtonWidth,
            tabGap: tabGap,
            tabHeight: tabHeight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator({
    required double width,
    required double searchButtonWidth,
    required bool isAdjacent,
    required double tabGap,
    required double tabHeight,
  }) {
    final rect = _statusTabRect(
      selectedStatus,
      width: width,
      searchButtonWidth: searchButtonWidth,
      tabGap: tabGap,
      tabHeight: tabHeight,
    );
    final indicator = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC95F05), Color(0xFFF97A0D)],
        ),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
    required double tabGap,
    required double tabHeight,
  }) {
    final isSelected = selectedStatus == text;
    return Positioned.fromRect(
      rect: _statusTabRect(
        text,
        width: width,
        searchButtonWidth: searchButtonWidth,
        tabGap: tabGap,
        tabHeight: tabHeight,
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
                        color: Colors.black.withValues(alpha: 0.2),
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
    required double tabGap,
    required double tabHeight,
  }) {
    final double secondRowTop = tabHeight + tabGap;
    final double topTabWidth = (width - tabGap) / 2;
    final double bottomTabWidth =
        (width - searchButtonWidth - (tabGap * 2)) / 2;

    switch (text) {
      case "Confirmed":
        return Rect.fromLTWH(topTabWidth + tabGap, 0, topTabWidth, tabHeight);
      case "Completed":
        return Rect.fromLTWH(0, secondRowTop, bottomTabWidth, tabHeight);
      case "Rejected":
        return Rect.fromLTWH(
          bottomTabWidth + tabGap,
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

  // Widget _buildStatusSearchSwitcher() {
  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       // final double bottomInset = 10.h;
  //       // final double expandedHeight = 60.h + bottomInset;
  //       // final double collapsedHeight = 68.h + bottomInset;
  //       final double searchButtonWidth = 60.w;

  //       return Padding(
  //         padding:  EdgeInsets.only(bottom: 16.h),
  //         child: AnimatedContainer(
  //           duration: _searchAnimationDuration,
  //           curve: Curves.easeInOutCubic,
  //           // height: isSearchClicked ? expandedHeight : collapsedHeight,
  //           height: isSearchClicked ? 60.h : 78.h,
  //           child: OverflowBox(
  //               maxHeight: double.infinity,   // lets children paint beyond the container
  //               alignment: Alignment.topLeft,
  //             child: Stack(
  //               clipBehavior: Clip.none,
  //               alignment: Alignment.bottomRight,
  //               children: [
  //                 AnimatedOpacity(
  //                   duration: const Duration(milliseconds: 320),
  //                   curve: Curves.easeOut,
  //                   opacity: isSearchClicked ? 0 : 1,
  //                   child: AnimatedSlide(
  //                     duration: _searchAnimationDuration,
  //                     curve: Curves.easeInOutCubic,
  //                     offset: isSearchClicked
  //                         ? const Offset(-0.05, 0)
  //                         : Offset.zero,
  //                     child: IgnorePointer(
  //                       ignoring: isSearchClicked,
  //                       child: _buildAnimatedStatusTabs(
  //                         width: constraints.maxWidth,
  //                         searchButtonWidth: searchButtonWidth,
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //                 _AnimatedSearchField(
  //                   isExpanded: isSearchClicked,
  //                   width: isSearchClicked
  //                       ? constraints.maxWidth
  //                       : searchButtonWidth,
  //                   controller: _searchController,
  //                   onOpen: () {
  //                     setState(() {
  //                       isSearchClicked = true;
  //                       _previousStatus = selectedStatus;
  //                       selectedStatus = "Search";
  //                     });
  //                   },
  //                   onClose: _closeSearch,
  //                   onChanged: _onSearchChanged,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildStatusSearchSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usesTabletLayout = _usesTabletLayout(context);
        final isTablet = Breakpoints.isTabletDevice(MediaQuery.sizeOf(context));
        final double searchButtonWidth = isTablet
            ? 60.0
            : usesTabletLayout
            ? 72.0
            : 60.w;
        final double tabHeight = usesTabletLayout ? 36.0 : 29.h;
        final double rowGap = usesTabletLayout ? 12.0 : 10.w;
        final double secondRowTop = tabHeight + rowGap;
        final double totalHeight = (tabHeight * 2) + rowGap + 8.0;
        final double collapsedSearchHeight = isTablet ? 29.0 : tabHeight;
        final double searchHeight = isTablet
            ? 60.0
            : usesTabletLayout
            ? 64.0
            : 60.h;
        final double collapsedSearchTop =
            secondRowTop + ((tabHeight - collapsedSearchHeight) / 2);

        return Padding(
          padding: EdgeInsets.only(bottom: usesTabletLayout ? 16.0 : 14.h),
          child: SizedBox(
            height: isSearchClicked ? searchHeight : totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              // Remove alignment: Alignment.bottomRight — no longer needed
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
                        tabGap: rowGap,
                        tabHeight: tabHeight,
                      ),
                    ),
                  ),
                ),

                // Search field — explicitly placed on row 2, right side
                AnimatedPositioned(
                  duration: _searchAnimationDuration,
                  curve: Curves.easeInOutCubic,
                  top: isSearchClicked ? 0 : collapsedSearchTop,
                  right: 0,
                  child: _AnimatedSearchField(
                    isExpanded: isSearchClicked,
                    width: isSearchClicked
                        ? constraints.maxWidth
                        : searchButtonWidth,
                    collapsedHeight: collapsedSearchHeight,
                    expandedHeight: searchHeight,
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
                ),
              ],
            ),
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

  // Widget _buildChip(
  //   String reason,
  //   String selectedReason,
  //   StateSetter setDialogState,
  //   void Function(String) onSelect,
  // ) {
  //   final isSelected = selectedReason == reason;
  //   return GestureDetector(
  //     onTap: () {
  //       setDialogState(() {
  //         onSelect(reason);
  //       });
  //     },
  //     child: Container(
  //       width: double.infinity, // ← stretches to parent width
  //       height: 30.h,
  //       // padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
  //       decoration: BoxDecoration(
  //         color: isSelected ? reasonSelectColor : reasonUnselectColor,
  //         borderRadius: BorderRadius.all(Radius.circular(15.r)),
  //       ),
  //       alignment: Alignment.center,

  //       child: Text(
  //         reason,
  //         textAlign: TextAlign.center, // ← center the text inside
  //         style: TextStyle(
  //           fontSize: 12.sp,
  //           fontWeight: FontWeight.w500,
  //           color: isSelected ? Colors.white : Colors.black,
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildChip(
    String reason,
    String selectedReason,
    StateSetter setDialogState,
    void Function(String) onSelect, {
    bool isMobile = true,
  }) {
    final isSelected = selectedReason == reason;
    return GestureDetector(
      onTap: () => setDialogState(() => onSelect(reason)),
      child: Container(
        width: double.infinity,
        height: isMobile ? 30.h : 36,
        decoration: BoxDecoration(
          color: isSelected ? reasonSelectColor : reasonUnselectColor,
          borderRadius: BorderRadius.all(Radius.circular(isMobile ? 15.r : 12)),
        ),
        alignment: Alignment.center,
        child: AppText(
          text: reason,
          size: isMobile ? 12 : 13,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black,
          isCentered: true,
        ),
      ),
    );
  }
}


class _StatusTabPosition {
  final int row;
  final int column;

  const _StatusTabPosition({required this.row, required this.column});
}

class _AnimatedSearchField extends StatelessWidget {
  final bool isExpanded;
  final double width;
  final double collapsedHeight;
  final double expandedHeight;
  final TextEditingController controller;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;

  const _AnimatedSearchField({
    required this.isExpanded,
    required this.width,
    required this.collapsedHeight,
    required this.expandedHeight,
    required this.controller,
    required this.onOpen,
    required this.onClose,
    required this.onChanged,
  });

  static const Duration _duration = Duration(milliseconds: 460);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final isTablet = Breakpoints.isTabletDevice(size);
    final useMobileScale = screenWidth < 550 && !isWideShortPhone;
    final collapsedIconSize = isTablet
        ? 20.0
        : useMobileScale
        ? 20.w
        : 16.w;
    final expandedIconSize = isTablet
        ? 22.0
        : useMobileScale
        ? 22.w
        : 14.w;
    final iconSlotWidth = isTablet
        ? 24.0
        : useMobileScale
        ? 24.w
        : 18.w;
    final expandedLeftPadding = isTablet ? 18.0 : 18.w;
    final expandedRightPadding = isTablet ? 12.0 : 12.w;
    final collapsedHorizontalPadding = isTablet ? 4.0 : 4.w;
    final fieldGap = isTablet ? 12.0 : 12.w;
    final fieldTextSize = isTablet ? 15.0 : 15.sp;
    final fieldVerticalPadding = isTablet ? 16.0 : 16.h;
    final closeButtonPadding = isTablet ? 6.0 : 6.w;
    final closeIconSize = isTablet ? 22.0 : 22.w;
    final expandedRadius = isTablet ? 20.0 : 20.r;
    final collapsedRadius = isTablet ? 10.0 : 10.r;
    final expandedShadowBlur = isTablet ? 15.0 : 15.r;
    final collapsedShadowBlur = isTablet ? 6.0 : 6.r;

    return GestureDetector(
      onTap: isExpanded ? null : onOpen,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeInOutCubic,
        width: width,
        height: isExpanded ? expandedHeight : collapsedHeight,
        padding: EdgeInsets.only(
          left: isExpanded ? expandedLeftPadding : collapsedHorizontalPadding,
          right: isExpanded ? expandedRightPadding : collapsedHorizontalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            isExpanded ? expandedRadius : collapsedRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isExpanded ? 0.22 : 0.18),
              blurRadius: isExpanded ? expandedShadowBlur : collapsedShadowBlur,
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
                    width: collapsedIconSize,
                    height: collapsedIconSize,
                    fit: BoxFit.contain,
                  ),
                );
              }

              return Row(
                children: [
                  AnimatedContainer(
                    duration: _duration,
                    curve: Curves.easeInOutCubic,
                    width: iconSlotWidth,
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      "assets/images/search_icon.png",
                      width: expandedIconSize,
                      height: expandedIconSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(width: fieldGap),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut,
                      opacity: isExpanded ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !isExpanded,
                        child: TranslatedBuilder(
                          text: "Coupon Number",
                          builder: (context, hintText) => TextField(
                            autofocus: isExpanded,
                            controller: controller,
                            cursorColor: appTextColor,
                            keyboardType: TextInputType.text,
                            onChanged: onChanged,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: fieldTextSize,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: hintText,
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: fieldTextSize,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: fieldVerticalPadding,
                              ),
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
                        borderRadius: BorderRadius.circular(
                          isTablet ? 18.0 : 18.r,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(closeButtonPadding),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: closeIconSize,
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
