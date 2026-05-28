import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/allEnquiryBox.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/banquetCompletedBox.dart';
import 'package:fudiko/components/banquetConfirmedBox.dart';
import 'package:fudiko/components/deletedBox.dart';
import 'package:fudiko/components/sentBox.dart';
import 'package:fudiko/models/banquet/all-enquiry-model.dart';
import 'package:fudiko/models/banquet/sent-enquiry-model.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/services/banquet-service.dart';
import 'package:fudiko/utils/constants.dart';

class Banquet extends StatefulWidget {
  final VoidCallback? onDrawerTap;
  final PartnerProfileModel? partnerProfile;
  const Banquet({super.key, this.onDrawerTap, this.partnerProfile});

  @override
  State<Banquet> createState() => _BanquetState();
}

class _BanquetState extends State<Banquet> {
  String selectedStatus = "All Enquiries";
  String _previousStatus = "All Enquiries";
  bool isDeleteClicked = false;
  static const Duration _searchAnimationDuration = Duration(milliseconds: 360);
  bool _isLoading = true;
  List<BanquetEnquiryModel> _allEnquiries = [];
  List<BanquetEnquiryModel> _savedEnquiries = [];
  List<BanquetEnquiryModel> _deletedEnquiries = [];
  List<BanquetEnquiryModel> _confirmedEnquiries = [];
  List<SentEnquiryModel> _sentEnquiries = [];

  // Search
  bool _isSearchClicked = false;
  List<BanquetEnquiryModel> _searchResults = [];
  bool _isSearching = false;
  bool _searchDone = false;
  final TextEditingController _searchController = TextEditingController();

  String _selectedDateFilter = "Last 7 days";
  DateTimeRange? _customDateRange;

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedDateFilter) {
      case "Last 7 days":
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case "Last 30 days":
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case "Last 3 months":
        return DateTimeRange(
          start: DateTime(now.year, now.month - 3, now.day),
          end: now,
        );
      case "Custom range":
        return _customDateRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            );
      default:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialRange =
        _customDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _BanquetDateRangeDialog(
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

  Future<void> _refreshEnquiries() async {
    await Future.wait([
      _fetchEnquiries(),
      _fetchSavedEnquiries(),
      _fetchDeletedEnquiries(),
      _fetchSentEnquiries(),
      _fetchConfirmedEnquiries(),
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
                    child: Text(
                      "Close",
                      style: TextStyle(color: appButtonColor),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error loading enquiry details")),
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

  Widget _buildTopSection() {
    return Padding(
      padding: EdgeInsets.only(top: 30.h),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20.w, right: 20.w),
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
            padding: EdgeInsets.only(left: 20.w, right: 20.w),
            child: _buildStatusSearchSwitcher(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    if (selectedStatus == "All Enquiries") {
      return Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _allEnquiries.isEmpty
            ? const Center(child: Text("No Enquiries Found"))
            : ListView.builder(
                itemCount: _allEnquiries.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return AllEnquiryBox(
                    enquiry: _allEnquiries[index],
                    onPressed: () {},
                    onActionCompleted: _refreshEnquiries,
                  );
                },
              ),
      );
    }

    if (selectedStatus == "Sent") {
      return Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w),
        child: _isSentLoading
            ? const Center(child: CircularProgressIndicator())
            : _sentEnquiries.isEmpty
            ? const Center(child: Text("No Sent Enquiries"))
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: AppText(
                              text: result['message'] ?? "Confirmed",
                              size: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                        if (result['status'] == true) {
                          await _refreshEnquiries();
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: AppText(
                              text: "Error confirming party response",
                              size: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      }
                    },
                    onDelete: () async {
                      try {
                        final result = await _enquiryService.deleteSentEnquiry(
                          _sentEnquiries[index].uuid,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: AppText(
                              text: result['message'] ?? "Deleted",
                              size: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                        if (result['status'] == true) {
                          await _refreshEnquiries();
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: AppText(
                              text: "Error deleting sent enquiry",
                              size: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
      );
    }

    if (selectedStatus == "Confirmed") {
      return Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w),
        child: _isConfirmedLoading
            ? const Center(child: CircularProgressIndicator())
            : _confirmedEnquiries.isEmpty
            ? const Center(child: Text("No Confirmed Enquiries"))
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
                    onRemindTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Reminder feature coming soon"),
                        ),
                      );
                    },
                  );
                },
              ),
      );
    }

    if (selectedStatus == "Completed") {
      return Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: AppFilterDropDown(
                    hint:
                        _selectedDateFilter == "Custom range" &&
                            _customDateRange != null
                        ? "${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}"
                        : _selectedDateFilter,
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
                                  trailing: _selectedDateFilter == option
                                      ? Icon(Icons.check, color: appButtonColor)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedDateFilter = option;
                                      _customDateRange = null;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ListTile(
                                title: const Text("Custom date range"),
                                trailing: _selectedDateFilter == "Custom range"
                                    ? Icon(Icons.check, color: appButtonColor)
                                    : null,
                                onTap: () async {
                                  Navigator.pop(context);
                                  await _pickCustomDateRange();
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
            if (_selectedDateFilter == "Custom range" &&
                _customDateRange != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h, left: 2.w),
                child: AppText(
                  text:
                      "Showing: ${_customDateRange!.start.day}/${_customDateRange!.start.month}/${_customDateRange!.start.year}"
                      " -> "
                      "${_customDateRange!.end.day}/${_customDateRange!.end.month}/${_customDateRange!.end.year}",
                  size: 11,
                  fontWeight: FontWeight.w400,
                  color: appTextColor2,
                ),
              ),
            SizedBox(height: 20.h),
            ListView.builder(
              itemCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return BanquetCompletedBox();
              },
            ),
          ],
        ),
      );
    }

    if (selectedStatus == "Saved") {
      return Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w),
        child: _isSavedLoading
            ? const Center(child: CircularProgressIndicator())
            : _savedEnquiries.isEmpty
            ? const Center(child: Text("No Saved Enquiries"))
            : ListView.builder(
                itemCount: _savedEnquiries.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return AllEnquiryBox(
                    enquiry: _savedEnquiries[index],
                    onPressed: () {},
                    showSaveIcon: false,
                    onActionCompleted: _refreshEnquiries,
                  );
                },
              ),
      );
    }

    if (selectedStatus == "Deleted") {
      return Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w),
        child: _isDeletedLoading
            ? const Center(child: CircularProgressIndicator())
            : _deletedEnquiries.isEmpty
            ? const Center(child: Text("No Deleted Enquiries"))
            : ListView.builder(
                itemCount: _deletedEnquiries.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return DeletedBox(
                    enquiry: _deletedEnquiries[index],
                    onCallBackPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Callback feature coming soon"),
                        ),
                      );
                    },
                    onActionCompleted: _refreshEnquiries,
                  );
                },
              ),
      );
    }

    if (selectedStatus == "Search") {
      return Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,

      body: Stack(
        children: [
          Column(
            children: [
              _buildTopSection(),
              SizedBox(height: 30.h),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFF97A0D),
                  onRefresh: _onTabRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: _buildSelectedTabContent(),
                  ),
                ),
              ),
            ],
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
                            text: "Are you sure you want to delete this offer?",
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
                                      setState(() => isDeleteClicked = false);
                                      try {
                                        final result = await _enquiryService
                                            .deleteEnquiry(
                                              _selectedEnquiryUuid,
                                            );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['message'] ?? "Deleted",
                                            ),
                                          ),
                                        );
                                        _fetchEnquiries(); // refresh list
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Error deleting"),
                                          ),
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
                                    onPressed: () {
                                      setState(() => isDeleteClicked = false);
                                    },
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
    if (text == "All Enquiries" || text == "Deleted") _fetchEnquiries();
    if (text == "Saved") _fetchSavedEnquiries();
  }

  Widget _buildAnimatedStatusTabs({
    required double width,
    required double searchButtonWidth,
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
  }) {
    final double gap = 10.w;
    final double tabHeight = 29.h;
    final double rowTwoTop = tabHeight + gap;
    final double rowThreeTop = (tabHeight + gap) * 2;
    final double fullTabWidth = (width - gap) / 2;
    final double bottomTabWidth = (width - searchButtonWidth - (gap * 2)) / 2;

    switch (text) {
      case "Sent":
        return Rect.fromLTWH(fullTabWidth + gap, 0, fullTabWidth, tabHeight);
      case "Confirmed":
        return Rect.fromLTWH(0, rowTwoTop, fullTabWidth, tabHeight);
      case "Completed":
        return Rect.fromLTWH(
          fullTabWidth + gap,
          rowTwoTop,
          fullTabWidth,
          tabHeight,
        );
      case "Saved":
        return Rect.fromLTWH(0, rowThreeTop, bottomTabWidth, tabHeight);
      case "Deleted":
        return Rect.fromLTWH(
          bottomTabWidth + gap,
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

  Widget _buildStatusSearchSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double collapsedHeight = 107.h;
        final double expandedHeight = 60.h;
        final double searchButtonWidth = 53.w;

        return AnimatedContainer(
          duration: _searchAnimationDuration,
          curve: Curves.easeInOutCubic,
          height: _isSearchClicked ? expandedHeight : collapsedHeight,
          child: Stack(
            alignment: Alignment.bottomRight,
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
                    ),
                  ),
                ),
              ),
              _AnimatedSearchField(
                isExpanded: _isSearchClicked,
                width: _isSearchClicked
                    ? constraints.maxWidth
                    : searchButtonWidth,
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
            ],
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

  static const Duration _duration = Duration(milliseconds: 360);

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
              color: isExpanded
                  ? Colors.black.withOpacity(0.22)
                  : const Color(0x2E000000),
              blurRadius: isExpanded ? 15.r : 10.r,
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
                    width: 24.w,
                    height: 24.w,
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
                      duration: const Duration(milliseconds: 220),
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
                    duration: const Duration(milliseconds: 190),
                    curve: Curves.easeOutBack,
                    scale: isExpanded ? 1 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
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

class _BanquetDateRangeDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _BanquetDateRangeDialog({
    required this.initialStartDate,
    required this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_BanquetDateRangeDialog> createState() =>
      _BanquetDateRangeDialogState();
}

class _BanquetDateRangeDialogState extends State<_BanquetDateRangeDialog> {
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
