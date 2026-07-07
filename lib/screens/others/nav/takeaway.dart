import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
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
    return Breakpoints.isMobile(_screenWidth(context)) ? 30.h : 24.0;
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

    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      body: SafeArea(
        minimum: EdgeInsets.only(top: usesTabletLayout ? 12.0 : 0.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: AppDimensions.margin(width)),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: topPadding),
                      child: _buildTopSection(),
                    ),
                    SizedBox(height: _contentGap(context)),
                    _responsiveContent(
                      child: hasData
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const <Widget>[],
                            )
                          : SizedBox(
                              height: usesTabletLayout
                                  ? 360
                                  : Breakpoints.isMobile(width)
                                  ? 280.h
                                  : 360,
                              child: const Center(child: Text("No orders yet")),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    final width = _screenWidth(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final usesTabletLayout = _usesTabletLayout(context);
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

    return _responsiveContent(
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
                : usesTabletLayout
                ? gap
                : Breakpoints.isMobile(width)
                ? 30.h
                : gap,
          ),
          _buildStatusSearchSwitcher(),
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
        final usesTabletLayout = _usesTabletLayout(context);
        final double searchButtonWidth = usesTabletLayout ? 72.0 : 60.w;
        final double tabHeight = usesTabletLayout ? 36.0 : 29.h;
        final double rowGap = usesTabletLayout ? 12.0 : 10.w;
        final double secondRowTop = tabHeight + rowGap;
        final double totalHeight = (tabHeight * 2) + rowGap + 8.0;
        final double searchHeight = usesTabletLayout ? 64.0 : 60.h;

        return Padding(
          padding: EdgeInsets.only(bottom: usesTabletLayout ? 16.0 : 14.h),
          child: SizedBox(
            height: _isSearchClicked ? searchHeight : totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
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
                        tabGap: rowGap,
                        tabHeight: tabHeight,
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: _searchAnimationDuration,
                  curve: Curves.easeInOutCubic,
                  top: _isSearchClicked ? 0 : secondRowTop,
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
      _previousStatus = "All Orders";
      selectedStatus = "All Orders";
      _searchController.clear();
    });
  }

  Widget _buildAnimatedStatusTabs({
    required double width,
    required double searchButtonWidth,
    required double tabGap,
    required double tabHeight,
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
  final double collapsedHeight;
  final double expandedHeight;
  final TextEditingController controller;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  const _AnimatedSearchField({
    required this.isExpanded,
    required this.width,
    required this.collapsedHeight,
    required this.expandedHeight,
    required this.controller,
    required this.onOpen,
    required this.onClose,
  });

  static const Duration _duration = Duration(milliseconds: 460);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWideShortPhone = Breakpoints.isWideShortPhone(size);
    final collapsedIconSize = isWideShortPhone ? 20.0 : 20.w;
    final expandedIconSize = isWideShortPhone ? 22.0 : 22.w;
    final iconSlotWidth = isWideShortPhone ? 24.0 : 24.w;
    final expandedLeftPadding = isWideShortPhone ? 18.0 : 18.w;
    final expandedRightPadding = isWideShortPhone ? 12.0 : 12.w;
    final collapsedHorizontalPadding = isWideShortPhone ? 4.0 : 4.w;
    final fieldGap = isWideShortPhone ? 12.0 : 12.w;
    final fieldTextSize = isWideShortPhone ? 15.0 : 15.sp;
    final fieldVerticalPadding = isWideShortPhone ? 16.0 : 16.h;
    final closeButtonPadding = isWideShortPhone ? 6.0 : 6.w;
    final closeIconSize = isWideShortPhone ? 22.0 : 22.w;
    final expandedRadius = isWideShortPhone ? 20.0 : 20.r;
    final collapsedRadius = isWideShortPhone ? 10.0 : 10.r;
    final expandedShadowBlur = isWideShortPhone ? 15.0 : 15.r;
    final collapsedShadowBlur = isWideShortPhone ? 6.0 : 6.r;

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
                        child: TextField(
                          autofocus: isExpanded,
                          controller: controller,
                          cursorColor: appTextColor,
                          keyboardType: TextInputType.text,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: fieldTextSize,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search Orders",
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
                          isWideShortPhone ? 18.0 : 18.r,
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
