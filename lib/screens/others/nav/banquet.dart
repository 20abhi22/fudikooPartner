import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/allEnquiryBox.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/banquetCompletedBox.dart';
import 'package:fudiko/components/banquetConfirmedBox.dart';
import 'package:fudiko/components/completedDateRangeDialog.dart';
import 'package:fudiko/components/dateFilterSheet.dart';
import 'package:fudiko/components/deletedBox.dart';
import 'package:fudiko/components/sentBox.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/models/banquet/all-enquiry-model.dart';
import 'package:fudiko/models/banquet/sent-enquiry-model.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/services/banquet-service.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/snackbar.dart';
import 'package:fudiko/utils/tab_back_handler.dart';
import 'package:fudiko/utils/tab_refreshable.dart';
import 'package:fudiko/utils/error_messages.dart';

class Banquet extends StatefulWidget {
  final VoidCallback? onDrawerTap;
  final PartnerProfileModel? partnerProfile;
  const Banquet({super.key, this.onDrawerTap, this.partnerProfile});

  @override
  State<Banquet> createState() => _BanquetState();
}

class _BanquetState extends State<Banquet>
    implements TabBackHandler, TabRefreshable {
  String selectedStatus = "All Enquiries";
  String _previousStatus = "All Enquiries";
  bool isDeleteClicked = false;
  static const Duration _searchAnimationDuration = Duration(milliseconds: 360);
  bool _isLoading = true;
  List<BanquetEnquiryModel> _allEnquiries = [];
  List<BanquetEnquiryModel> _savedEnquiries = [];
  List<BanquetEnquiryModel> _deletedEnquiries = [];
  List<BanquetEnquiryModel> _confirmedEnquiries = [];
  List<BanquetEnquiryModel> _completedEnquiries = [];
  List<SentEnquiryModel> _sentEnquiries = [];

  // Search
  bool _isSearchClicked = false;
  List<BanquetEnquiryModel> _searchResults = [];
  bool _isSearching = false;
  bool _searchDone = false;
  final TextEditingController _searchController = TextEditingController();

  String _selectedDateFilter = "Last 7 days";
  DateTimeRange? _customDateRange;

  // _getDateRange was removed; leave TODO note about wiring completed enquiries fetch if needed.
  // TODO: pass selected date range to completed enquiries fetch when integrating filtering.

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialRange =
        _customDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => CompletedDateRangeDialog(
        initialStartDate: initialRange.start,
        initialEndDate: initialRange.end,
        firstDate: DateTime(now.year - 2),
        lastDate: now,
      ),
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDateFilter = "Custom range";
      });
      // TODO: pass _getDateRange() to your completed enquiries fetch
    }
  }

  final BanquetEnquiryService _enquiryService = BanquetEnquiryService();
  String _selectedEnquiryUuid = '';
  bool _isSentLoading = true;
  bool _isConfirmedLoading = true;
  bool _isCompletedLoading = true;
  bool _isSavedLoading = true;
  bool _isDeletedLoading = true;

  // bool _isExpired = false; // ← new state variable to track expiry status

  // Future<void> _deleteEnquiry() async {
  //   if (_selectedEnquiryUuid.isEmpty) return;
  //   try {
  //     final result = await _enquiryService.deleteEnquiry(_selectedEnquiryUuid);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(result['message'] ?? "Enquiry deleted")),
  //     );
  //     if (result['status'] == true) {
  //       _fetchEnquiries(); // Refresh the list after deletion
  //       setState(() => isDeleteClicked = false); // Close the delete confirmation
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Error deleting enquiry")),
  //     );
  //   }
  // }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchEnquiries();
    _fetchSavedEnquiries();
    _fetchDeletedEnquiries(); // Refresh deleted enquiries
    _fetchSentEnquiries();
    _fetchConfirmedEnquiries();
    _fetchCompletedEnquiries();
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchDone = false;
    });

    try {
      final response = await _enquiryService.searchEnquiries(trimmed);
      if (!mounted) return;
      setState(() {
        _searchResults = response.enquiries;
        _isSearching = false;
        _searchDone = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchDone = true;
        _searchResults = [];
      });
    }
  }

  @override
  bool handleBack() {
    if (_isSearchClicked) {
      _closeSearch();
      return true;
    }

    if (isDeleteClicked) {
      _dismissDeleteConfirm();
      return true;
    }

    return false;
  }

  Future<void> _fetchEnquiries() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await _enquiryService.getAllEnquiries();
      setState(() {
        _allEnquiries = response.enquiries;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching enquiries: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSavedEnquiries() async {
    if (mounted) {
      setState(() => _isSavedLoading = true);
    }
    try {
      final response = await _enquiryService.getSavedEnquiries();
      setState(() {
        _savedEnquiries = response.enquiries;
        _isSavedLoading = false;
      });
    } catch (e) {
      print('Error fetching saved enquiries: $e');
      setState(() => _isSavedLoading = false);
    }
  }

  Future<void> _fetchDeletedEnquiries() async {
    if (mounted) {
      setState(() => _isDeletedLoading = true);
    }
    try {
      final response = await _enquiryService.getDeletedEnquiries();
      setState(() {
        _deletedEnquiries = response.enquiries;
        _isDeletedLoading = false;
      });
    } catch (e) {
      print('Error fetching deleted enquiries: $e');
      setState(() => _isDeletedLoading = false);
    }
  }

  Future<void> _fetchSentEnquiries() async {
    if (mounted) {
      setState(() => _isSentLoading = true);
    }
    try {
      final response = await _enquiryService.getSentEnquiries();
      setState(() {
        _sentEnquiries = response.enquiries;
        _isSentLoading = false;
      });
    } catch (e) {
      print('Error fetching sent enquiries: $e');
      setState(() => _isSentLoading = false);
    }
  }

  Future<void> _fetchConfirmedEnquiries() async {
    if (mounted) {
      setState(() => _isConfirmedLoading = true);
    }
    try {
      final response = await _enquiryService.getConfirmedEnquiries();
      setState(() {
        _confirmedEnquiries = response.enquiries;
        _isConfirmedLoading = false;
      });
    } catch (e) {
      print('Error fetching confirmed enquiries: $e');
      setState(() => _isConfirmedLoading = false);
    }
  }

  Future<void> _fetchCompletedEnquiries() async {
    if (mounted) {
      setState(() => _isCompletedLoading = true);
    }
    try {
      final response = await _enquiryService.getCompletedEnquiries();
      setState(() {
        _completedEnquiries = response.enquiries;
        _isCompletedLoading = false;
      });
    } catch (e) {
      print('Error fetching completed enquiries: $e');
      setState(() => _isCompletedLoading = false);
    }
  }

  /// Set when a refresh arrives while the delete confirmation is up, so the
  /// reload can run once it is dismissed.
  bool _refreshPending = false;

  @override
  Future<void> refresh() async {
    // Reloading under the confirmation would rebuild the list the partner is
    // confirming against, so it waits for the dialog to close instead.
    if (isDeleteClicked) {
      _refreshPending = true;
      return;
    }
    await _refreshEnquiries();
  }

  /// Runs a refresh that was held back while the confirmation was open.
  void _dismissDeleteConfirm() {
    setState(() => isDeleteClicked = false);
    if (!_refreshPending) return;
    _refreshPending = false;
    _refreshEnquiries();
  }

  Future<void> _refreshEnquiries() async {
    await Future.wait([
      _fetchEnquiries(),
      _fetchSavedEnquiries(),
      _fetchDeletedEnquiries(),
      _fetchSentEnquiries(),
      _fetchConfirmedEnquiries(),
      _fetchCompletedEnquiries(),
    ]);
  }

  Future<void> _showConfirmedEnquiryDetails(String uuid) async {
    try {
      final detail = await _enquiryService.showEnquiry(uuid);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: detail.enquiryId,
                  size: 18,
                  fontWeight: FontWeight.bold,
                  color: appTextColor3,
                ),
                SizedBox(height: 12.h),
                _detailRow("Date", detail.date),
                _detailRow("Time", detail.time),
                _detailRow("People", detail.people.toString()),
                _detailRow("Menu", detail.menuItems),
                _detailRow("Estimated", detail.estimatedAmount),
                _detailRow("Status", detail.status),
                _detailRow(
                  "Expires",
                  "${detail.expirationDate} ${detail.expirationTime}",
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: AppText(
                      text: "Close",
                      size: 14,
                      fontWeight: FontWeight.w400,
                      color: appButtonColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(
        context,
        friendlyErrorMessage(e, fallback: 'Error loading enquiry details'),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: "$label: ",
            size: 12,
            fontWeight: FontWeight.w600,
            color: appTextColor2,
          ),
          Expanded(
            child: AppText(
              text: value,
              size: 12,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTabRefresh() async {
    if (selectedStatus == "Search") {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        await _performSearch(query);
        return;
      }
    }
    await _refreshEnquiries();
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
    if (_isWideShortPhone(context)) return 24.0;
    return AppDimensions.padding(_screenWidth(context));
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
    final isWideShortPhone = _isWideShortPhone(context);
    final usesTabletLayout = _usesTabletLayout(context);
    final topPadding = isWideShortPhone
        ? 8.0
        : usesTabletLayout
        ? 24.0
        : Breakpoints.isMobile(width)
        ? 30.h
        : 24.0;
    final gap = isWideShortPhone ? 8.0 : AppDimensions.gap(width);
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
                              size: isWideShortPhone ? 11.0 : 15,
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
            ),
            SizedBox(
              height: isWideShortPhone
                  ? 10.0
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

  Widget _responsiveListContent({
    required bool isLoading,
    required bool isEmpty,
    required String emptyText,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return _responsiveContent(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEmpty
          ? Center(
              child: AppText(
                text: emptyText,
                size: 15,
                fontWeight: FontWeight.w500,
                color: appTextColor2,
                isCentered: true,
              ),
            )
          : ListView.builder(
              itemCount: itemCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: itemBuilder,
            ),
    );
  }

  Widget _buildSelectedTabContent() {
    if (selectedStatus == "All Enquiries") {
      return _responsiveListContent(
        isLoading: _isLoading,
        isEmpty: _allEnquiries.isEmpty,
        emptyText: "No Enquiries Found",
        itemCount: _allEnquiries.length,
        itemBuilder: (context, index) {
          return AllEnquiryBox(
            enquiry: _allEnquiries[index],
            onPressed: () {},
            onActionCompleted: _refreshEnquiries,
          );
        },
      );
    }

    if (selectedStatus == "Sent") {
      return _responsiveContent(
        child: _isSentLoading
            ? const Center(child: CircularProgressIndicator())
            : _sentEnquiries.isEmpty
            ? Center(
                child: AppText(
                  text: "No Sent Enquiries",
                  size: 15,
                  fontWeight: FontWeight.w500,
                  color: appTextColor2,
                  isCentered: true,
                ),
              )
            : ListView.builder(
                itemCount: _sentEnquiries.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return SentBox(
                    enquiry: _sentEnquiries[index],
                    onAccept: () async {
                      try {
                        final result = await _enquiryService
                            .confirmPartyResponse(_sentEnquiries[index].uuid);
                        if (!mounted) return;
                        showStatusSnack(
                          context,
                          result['status'] == true,
                          result['message'] ?? "Confirmed",
                        );
                        if (result['status'] == true) {
                          await _refreshEnquiries();
                        }
                      } catch (e) {
                        if (!mounted) return;
                        showErrorSnack(
        context,
        friendlyErrorMessage(e, fallback: 'Error confirming party response'),
      );
                      }
                    },
                    onDelete: () async {
                      try {
                        final result = await _enquiryService.deleteSentEnquiry(
                          _sentEnquiries[index].uuid,
                        );
                        if (!mounted) return;
                        showStatusSnack(
                          context,
                          result['status'] == true,
                          result['message'] ?? "Deleted",
                        );
                        if (result['status'] == true) {
                          await _refreshEnquiries();
                        }
                      } catch (e) {
                        if (!mounted) return;
                        showErrorSnack(
        context,
        friendlyErrorMessage(e, fallback: 'Error deleting sent enquiry'),
      );
                      }
                    },
                  );
                },
              ),
      );
    }

    if (selectedStatus == "Confirmed") {
      return _responsiveContent(
        child: _isConfirmedLoading
            ? const Center(child: CircularProgressIndicator())
            : _confirmedEnquiries.isEmpty
            ? Center(
                child: AppText(
                  text: "No Confirmed Enquiries",
                  size: 15,
                  fontWeight: FontWeight.w500,
                  color: appTextColor2,
                  isCentered: true,
                ),
              )
            : ListView.builder(
                itemCount: _confirmedEnquiries.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final enquiry = _confirmedEnquiries[index];
                  return BanquetConfirmedBox(
                    enquiry: enquiry,
                    onDetailsTap: () {
                      _showConfirmedEnquiryDetails(enquiry.uuid);
                    },
                    onRemindTap: () async {
                      final response = await _enquiryService.remindReservation(
                        enquiry.uuid,
                      );
                      if (!mounted) return;

                      showStatusSnack(
                        context,
                        response['status'] == true,
                        response['message']?.toString() ??
                            'Reminder sent successfully',
                      );
                    },
                  );
                },
              ),
      );
    }

    if (selectedStatus == "Completed") {
      final isWideShortPhone = _isWideShortPhone(context);

      return _responsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 130,
                    maxWidth: 230,
                  ),
                  child: IntrinsicWidth(
                    child: AppFilterDropDown(
                      fieldBorderRadius: 6,
                      height: isWideShortPhone ? 35.0 : 35.h,
                      hint:
                          _selectedDateFilter == "Custom range" &&
                              _customDateRange != null
                          ? "${formatDateForRange(_customDateRange!.start, _customDateRange!.end)} - ${formatDateForRange(_customDateRange!.end, _customDateRange!.start)}"
                          : _selectedDateFilter,
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
                          selectedValue: _selectedDateFilter,
                          customValue: "Custom range",
                          onOptionSelected: (option) {
                            setState(() {
                              _selectedDateFilter = option;
                              _customDateRange = null;
                            });
                          },
                          onCustomTap: _pickCustomDateRange,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedDateFilter == "Custom range" &&
                _customDateRange != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h, left: 2.w),
                child: AppText(
                  text:
                      "Showing: ${formatDateForRange(_customDateRange!.start, _customDateRange!.end)} -> ${formatDateForRange(_customDateRange!.end, _customDateRange!.start)}",
                  size: 11,
                  fontWeight: FontWeight.w400,
                  color: appTextColor2,
                ),
              ),
            SizedBox(height: 20.h),
            _isCompletedLoading
                ? const Center(child: CircularProgressIndicator())
                : _completedEnquiries.isEmpty
                ? Center(
                    child: AppText(
                      text: "No Completed Enquiries",
                      size: 15,
                      fontWeight: FontWeight.w500,
                      color: appTextColor2,
                      isCentered: true,
                    ),
                  )
                : ListView.builder(
                    itemCount: _completedEnquiries.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return BanquetCompletedBox(
                        enquiryId: _completedEnquiries[index].enquiryId,
                        estimatedAmount:
                            _completedEnquiries[index].estimatedAmount,
                        amount: _completedEnquiries[index].amount ?? '',
                        extraOffer: _completedEnquiries[index].extraOffer ?? '',
                        comments: _completedEnquiries[index].comments ?? '',
                        menuItems: _completedEnquiries[index].menuItems,
                        people: _completedEnquiries[index].people,
                        date: _completedEnquiries[index].date,
                        time: _completedEnquiries[index].time,
                      );
                    },
                  ),
          ],
        ),
      );
    }

    if (selectedStatus == "Saved") {
      return _responsiveListContent(
        isLoading: _isSavedLoading,
        isEmpty: _savedEnquiries.isEmpty,
        emptyText: "No Saved Enquiries",
        itemCount: _savedEnquiries.length,
        itemBuilder: (context, index) {
          return AllEnquiryBox(
            enquiry: _savedEnquiries[index],
            onPressed: () {},
            showSaveIcon: false,
            onActionCompleted: _refreshEnquiries,
          );
        },
      );
    }

    if (selectedStatus == "Deleted") {
      return _responsiveContent(
        child: _isDeletedLoading
            ? const Center(child: CircularProgressIndicator())
            : _deletedEnquiries.isEmpty
            ? Center(
                child: AppText(
                  text: "No Deleted Enquiries",
                  size: 15,
                  fontWeight: FontWeight.w500,
                  color: appTextColor2,
                  isCentered: true,
                ),
              )
            : ListView.builder(
                itemCount: _deletedEnquiries.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return DeletedBox(
                    enquiry: _deletedEnquiries[index],
                    onCallBackPressed: () async {
                      final enquiry = _deletedEnquiries[index];
                      final response = await _enquiryService
                          .callbackReservation(enquiry.uuid);
                      if (!mounted) return;

                      showStatusSnack(
                        context,
                        response['status'] == true,
                        response['message']?.toString() ??
                            'Reservation recalled successfully',
                      );

                      if (response['status'] == true) {
                        await _refreshEnquiries();
                      }
                    },
                    onActionCompleted: _refreshEnquiries,
                  );
                },
              ),
      );
    }

    if (selectedStatus == "Search") {
      return _responsiveContent(
        padding: EdgeInsets.only(
          left: _pagePadding(context),
          right: _pagePadding(context) + 4,
          bottom: 20.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_searchDone && _searchResults.isEmpty)
              Center(
                child: AppText(
                  text:
                      "No enquiries found for \"${_searchController.text.trim()}\"",
                  size: 14,
                  fontWeight: FontWeight.w400,
                  color: appTextColor2,
                  isCentered: true,
                ),
              )
            else if (_searchResults.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return AllEnquiryBox(
                    enquiry: _searchResults[index],
                    onPressed: () {},
                    onActionCompleted: () {
                      _performSearch(_searchController.text);
                    },
                  );
                },
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
        child: Stack(
          children: [
            RefreshIndicator(
              color: const Color(0xFFF97A0D),
              onRefresh: _onTabRefresh,
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
                          _buildSelectedTabContent(),
                          if (_isLandscape) SizedBox(height: _keyboardInset),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isDeleteClicked)
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Container(
                        height: 150.h,
                        width: double.infinity,
                        padding: EdgeInsets.only(
                          left: 40.w,
                          right: 40.w,
                          top: 30.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            AppText(
                              text:
                                  "Are you sure you want to delete this offer?",
                              size: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              isCentered: true,
                              lineSpacing: 1.2,
                            ),
                            SizedBox(height: 20.h),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 35.h,
                                    child: AppButton(
                                      text: "Yes",
                                      // onPressed: () {
                                      //   setState(() {
                                      //     isDeleteClicked = !isDeleteClicked;
                                      //   });
                                      // },
                                      onPressed: () async {
                                        Navigator.pop(
                                          context,
                                        ); // close dialog isn't needed since it's Stack, just:
                                        _dismissDeleteConfirm();
                                        try {
                                          final result = await _enquiryService
                                              .deleteEnquiry(
                                                _selectedEnquiryUuid,
                                              );
                                          showStatusSnack(
                                            context,
                                            result['status'] == true,
                                            result['message'] ?? "Deleted",
                                          );
                                          _fetchEnquiries(); // refresh list
                                        } catch (e) {
                                          showErrorSnack(
        context,
        friendlyErrorMessage(e, fallback: 'Error deleting'),
      );
                                        }
                                      },
                                      size: 12,
                                      borderRadius: 5,
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
                                      onPressed: _dismissDeleteConfirm,
                                      size: 12,
                                      borderRadius: 5,
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
              ),
          ],
        ),
      ),
    );
  }

  Widget buildStatusButton(String text) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectStatus(text),
        child: Container(
          height: 29.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              const BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 10,
                spreadRadius: 1,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: AppText(
            text: text,
            size: 13,
            fontWeight: FontWeight.w500,
            color: appTextColor3,
          ),
        ),
      ),
    );
  }

  void _selectStatus(String text) {
    if (selectedStatus == text) return;

    setState(() {
      _previousStatus = selectedStatus;
      selectedStatus = text;
      if (_isSearchClicked) {
        _isSearchClicked = false;
        _searchController.clear();
        _searchResults = [];
        _searchDone = false;
      }
    });

    if (text == "Sent") _fetchSentEnquiries();
    if (text == "Confirmed") _fetchConfirmedEnquiries();
    if (text == "Completed") _fetchCompletedEnquiries();
    if (text == "All Enquiries" || text == "Saved" || text == "Deleted") {
      _fetchEnquiries();
      if (text == "Saved") _fetchSavedEnquiries();
      if (text == "Deleted") _fetchDeletedEnquiries();
    }
  }

  Widget _buildAnimatedStatusTabs({
    required double width,
    required double searchButtonWidth,
    required double tabGap,
    required double tabHeight,
  }) {
    final tabs = [
      "All Enquiries",
      "Sent",
      "Confirmed",
      "Completed",
      "Saved",
      "Deleted",
    ];
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
        if (selectedPosition != null)
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 10,
            spreadRadius: 1,
            offset: Offset(0, 0),
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
                  : const [
                      BoxShadow(
                        color: Color(0x2E000000),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(0, 0),
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
    final double rowTwoTop = tabHeight + tabGap;
    final double rowThreeTop = (tabHeight + tabGap) * 2;
    final double fullTabWidth = (width - tabGap) / 2;
    final double bottomTabWidth =
        (width - searchButtonWidth - (tabGap * 2)) / 2;

    switch (text) {
      case "Sent":
        return Rect.fromLTWH(fullTabWidth + tabGap, 0, fullTabWidth, tabHeight);
      case "Confirmed":
        return Rect.fromLTWH(0, rowTwoTop, fullTabWidth, tabHeight);
      case "Completed":
        return Rect.fromLTWH(
          fullTabWidth + tabGap,
          rowTwoTop,
          fullTabWidth,
          tabHeight,
        );
      case "Saved":
        return Rect.fromLTWH(0, rowThreeTop, bottomTabWidth, tabHeight);
      case "Deleted":
        return Rect.fromLTWH(
          bottomTabWidth + tabGap,
          rowThreeTop,
          bottomTabWidth,
          tabHeight,
        );
      case "All Enquiries":
      default:
        return Rect.fromLTWH(0, 0, fullTabWidth, tabHeight);
    }
  }

  _StatusTabPosition? _statusTabPosition(String text) {
    switch (text) {
      case "All Enquiries":
        return const _StatusTabPosition(row: 0, column: 0);
      case "Sent":
        return const _StatusTabPosition(row: 0, column: 1);
      case "Confirmed":
        return const _StatusTabPosition(row: 1, column: 0);
      case "Completed":
        return const _StatusTabPosition(row: 1, column: 1);
      case "Saved":
        return const _StatusTabPosition(row: 2, column: 0);
      case "Deleted":
        return const _StatusTabPosition(row: 2, column: 1);
      default:
        return null;
    }
  }

  // Widget _buildStatusSearchSwitcher() {
  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       final double collapsedHeight = 107.h;
  //       final double expandedHeight = 60.h;
  //       final double searchButtonWidth = 60.w;

  //       return AnimatedContainer(
  //         duration: _searchAnimationDuration,
  //         curve: Curves.easeInOutCubic,
  //         height: _isSearchClicked ? expandedHeight : collapsedHeight,
  //         child: Stack(
  //           alignment: Alignment.bottomRight,
  //           children: [
  //             AnimatedOpacity(
  //               duration: const Duration(milliseconds: 220),
  //               curve: Curves.easeOut,
  //               opacity: _isSearchClicked ? 0 : 1,
  //               child: AnimatedSlide(
  //                 duration: _searchAnimationDuration,
  //                 curve: Curves.easeInOutCubic,
  //                 offset: _isSearchClicked
  //                     ? const Offset(-0.05, 0)
  //                     : Offset.zero,
  //                 child: IgnorePointer(
  //                   ignoring: _isSearchClicked,
  //                   child: _buildAnimatedStatusTabs(
  //                     width: constraints.maxWidth,
  //                     searchButtonWidth: searchButtonWidth,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             _AnimatedSearchField(
  //               isExpanded: _isSearchClicked,
  //               width: _isSearchClicked
  //                   ? constraints.maxWidth
  //                   : searchButtonWidth,
  //               controller: _searchController,
  //               onOpen: () {
  //                 setState(() {
  //                   _isSearchClicked = true;
  //                   _previousStatus = selectedStatus;
  //                   selectedStatus = "Search";
  //                 });
  //               },
  //               onClose: _closeSearch,
  //               onChanged: _onSearchChanged,
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }
  Widget _buildStatusSearchSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideShortPhone = _isWideShortPhone(context);
        final double searchButtonWidth = isWideShortPhone ? 60.0 : 60.w;
        final double tabHeight = isWideShortPhone ? 30.0 : 29.h;
        final double rowGap = isWideShortPhone ? 8.0 : 10.w;
        final double threeRowsHeight = (tabHeight * 3) + (rowGap * 2) + 8.0;
        // final double secondRowTop = tabHeight + rowGap; // unused in this layout
        final double thirdRowTop = (tabHeight + rowGap) * 2;
        final double searchHeight = isWideShortPhone ? 56.0 : 60.h;

        return Padding(
          padding: EdgeInsets.only(bottom: isWideShortPhone ? 12.0 : 14.h),
          child: SizedBox(
            height: _isSearchClicked ? searchHeight : threeRowsHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  opacity: _isSearchClicked ? 0 : 1,
                  child: AnimatedSlide(
                    duration: _searchAnimationDuration,
                    curve: Curves.easeInOutCubic,
                    offset: _isSearchClicked
                        ? const Offset(-0.05, 0)
                        : Offset.zero,
                    child: IgnorePointer(
                      ignoring: _isSearchClicked,
                      child: _buildAnimatedStatusTabs(
                        width: constraints.maxWidth,
                        searchButtonWidth: searchButtonWidth,
                        tabGap: rowGap,
                        tabHeight: tabHeight,
                      ),
                    ),
                  ),
                ),

                // Search button — pinned to row 3, right side when collapsed
                AnimatedPositioned(
                  duration: _searchAnimationDuration,
                  curve: Curves.easeInOutCubic,
                  top: _isSearchClicked ? 0 : thirdRowTop,
                  right: 0,
                  child: _AnimatedSearchField(
                    isExpanded: _isSearchClicked,
                    width: _isSearchClicked
                        ? constraints.maxWidth
                        : searchButtonWidth,
                    collapsedHeight: tabHeight,
                    expandedHeight: searchHeight,
                    controller: _searchController,
                    onOpen: () {
                      setState(() {
                        _isSearchClicked = true;
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
      _isSearchClicked = false;
      _previousStatus = "All Enquiries";
      selectedStatus = "All Enquiries";
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

  static const Duration _duration = Duration(milliseconds: 360);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final useMobileScale = screenWidth < 550 && !isWideShortPhone;
    final collapsedIconSize = isWideShortPhone
        ? 18.0
        : useMobileScale
        ? 20.w
        : 16.w;
    final expandedIconSize = isWideShortPhone
        ? 20.0
        : useMobileScale
        ? 22.w
        : 14.w;
    final iconSlotWidth = isWideShortPhone
        ? 22.0
        : useMobileScale
        ? 24.w
        : 18.w;
    final fieldGap = isWideShortPhone ? 10.0 : 12.w;
    final fieldTextSize = isWideShortPhone ? 14.0 : 15.sp;
    final verticalPadding = isWideShortPhone ? 14.0 : 16.h;

    return GestureDetector(
      onTap: isExpanded ? null : onOpen,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeInOutCubic,
        width: width,
        height: isExpanded ? expandedHeight : collapsedHeight,
        padding: EdgeInsets.only(
          left: isExpanded
              ? (isWideShortPhone ? 16.0 : 18.w)
              : (isWideShortPhone ? 4.0 : 4.w),
          right: isExpanded
              ? (isWideShortPhone ? 10.0 : 12.w)
              : (isWideShortPhone ? 4.0 : 4.w),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            isExpanded
                ? (isWideShortPhone ? 18.0 : 20.r)
                : (isWideShortPhone ? 9.0 : 10.r),
          ),
          boxShadow: [
            BoxShadow(
              color: isExpanded
                  ? Colors.black.withOpacity(0.22)
                  : const Color(0x2E000000),
              blurRadius: isExpanded
                  ? (isWideShortPhone ? 12.0 : 15.r)
                  : (isWideShortPhone ? 8.0 : 10.r),
              spreadRadius: isExpanded ? 0 : 1,
              offset: Offset.zero,
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
                      duration: const Duration(milliseconds: 220),
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
                                vertical: verticalPadding,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 190),
                    curve: Curves.easeOutBack,
                    scale: isExpanded ? 1 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: isExpanded ? 1 : 0,
                      child: InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(
                          isWideShortPhone ? 16.0 : 18.r,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isWideShortPhone ? 5.0 : 6.w),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: isWideShortPhone ? 20.0 : 22.w,
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
