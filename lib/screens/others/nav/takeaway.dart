import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/models/profile/partner-profile-model.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/tab_back_handler.dart';

class TakeAway extends StatefulWidget {
  final VoidCallback? onDrawerTap;
  final PartnerProfileModel? partnerProfile;
  const TakeAway({super.key, this.onDrawerTap, this.partnerProfile});

  @override
  State<TakeAway> createState() => _TakeAwayState();
}

class _TakeAwayState extends State<TakeAway> implements TabBackHandler {
  String selectedStatus = "All Orders";
  String _previousStatus = "All Orders";
  bool hasData = false;
  bool isDrawerOpen = false;
  bool _isSearchClicked = false;
  static const Duration _searchAnimationDuration = Duration(milliseconds: 460);
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool handleBack() {
    if (_isSearchClicked) {
      _closeSearch();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,

      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 30.h),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      height: MediaQuery.of(context).size.height - 30.h,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: appSecondaryBackgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40.r),
                          topRight: Radius.circular(40.r),
                        ),
                      ),
                      child: const Center(child: Text("Helloo")),
                    ),
                  ),
                  Column(
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
                                  text:
                                      widget.partnerProfile?.name ?? "Loading",
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
                                      text:
                                          widget.partnerProfile?.address ?? "",
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
                              child: Icon(
                                Icons.menu,
                                size: 30.w,
                                color: appTextColor3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: _buildStatusSearchSwitcher(),
                      ),
                      if (hasData)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            children: [
                              // Your orders here
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (!hasData) const Center(child: Text("No orders yet")),
        ],
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
      }
    });
  }

  Widget _buildStatusSearchSwitcher() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double expandedHeight = 60.h;
        final double collapsedHeight = 78.h;
        final double searchButtonWidth = 60.w;

        return AnimatedContainer(
          duration: _searchAnimationDuration,
          curve: Curves.easeInOutCubic,
          height: _isSearchClicked ? expandedHeight : collapsedHeight,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 320),
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
              AnimatedPositioned(
                duration: _searchAnimationDuration,
                curve: Curves.easeInOutCubic,
                right: 0,
                top: _isSearchClicked ? 0 : 39.h,
                child: _AnimatedSearchField(
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
                ),
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
      _previousStatus = "All Orders";
      selectedStatus = "All Orders";
      _searchController.clear();
    });
  }

  Widget _buildAnimatedStatusTabs({
    required double width,
    required double searchButtonWidth,
  }) {
    final tabs = ["All Orders", "Confirmed", "Completed", "Rejected"];
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6.r,
            offset: Offset(2.r, 2.r),
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
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6.r,
                        offset: Offset(2.r, 2.r),
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
      case "All Orders":
      default:
        return Rect.fromLTWH(0, 0, topTabWidth, tabHeight);
    }
  }

  _StatusTabPosition? _statusTabPosition(String text) {
    switch (text) {
      case "All Orders":
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

  const _AnimatedSearchField({
    required this.isExpanded,
    required this.width,
    required this.controller,
    required this.onOpen,
    required this.onClose,
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
              color: Colors.black.withValues(alpha: isExpanded ? 0.22 : 0.2),
              blurRadius: isExpanded ? 15.r : 6.r,
              offset: isExpanded ? Offset.zero : Offset(2.r, 2.r),
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
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search Orders",
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
