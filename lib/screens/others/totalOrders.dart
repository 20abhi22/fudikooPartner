import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/orderDonut.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:fudiko/utils/tokens.dart';

class TotalOrders extends StatefulWidget {
  const TotalOrders({super.key});

  @override
  State<TotalOrders> createState() => _TotalOrdersState();
}

class _TotalOrdersState extends State<TotalOrders> {
  String _selectedFilter = 'Last 7 days';
  DateTimeRange? _customDateRange;
  bool _isLoading = true;
  int _completedOrders = 0;
  int _cancelledOrders = 0;

  bool _isWideShortPhone(BuildContext context) {
    return Breakpoints.isWideShortPhone(MediaQuery.sizeOf(context));
  }

  double _contentMaxWidth(Size size, bool isWideShortPhone) {
    final width = size.width;
    if (Breakpoints.isDesktop(width)) return 680;
    if (Breakpoints.isTabletDevice(size) || isWideShortPhone) return 600;
    return double.infinity;
  }

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTimeRange _currentDateRange() {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'Last 30 days':
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case 'Custom':
        return _customDateRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            );
      case 'Last 7 days':
      default:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
    }
  }

  int _parseCount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await getToken();
      final range = _currentDateRange();
      final response = await DioClient.dio.post(
        '/partner/analytics',
        data: FormData.fromMap({
          'start_date': _formatDate(range.start),
          'end_date': _formatDate(range.end),
        }),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data is Map<String, dynamic>
          ? response.data['data'] as Map<String, dynamic>?
          : null;

      if (!mounted) return;

      setState(() {
        _completedOrders = _parseCount(data?['completed_reservations']);
        _cancelledOrders = _parseCount(data?['cancelled_reservations']);
        _isLoading = false;
      });
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        _completedOrders = 0;
        _cancelledOrders = 0;
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load analytics')));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _completedOrders = 0;
        _cancelledOrders = 0;
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load analytics')));
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange:
          _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF97A0D),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'Custom';
      });
      await _loadAnalytics();
    }
  }

  void _handleFilterChanged(String value) {
    if (value == 'Custom') {
      _pickCustomDateRange();
      return;
    }

    setState(() {
      _selectedFilter = value;
    });
    _loadAnalytics();
  }

  String? _buildCustomRangeText(BuildContext context) {
    if (_selectedFilter != 'Custom' || _customDateRange == null) {
      return null;
    }

    final localizations = MaterialLocalizations.of(context);
    final start = localizations.formatMediumDate(_customDateRange!.start);
    final end = localizations.formatMediumDate(_customDateRange!.end);
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = _isWideShortPhone(context);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final pagePadding = isWideShortPhone
        ? 24.0
        : isMobile
        ? 30.w
        : AppDimensions.padding(width);
    final topPadding = isWideShortPhone
        ? 20.0
        : isMobile
        ? 40.h
        : 28.0;
    final backIconSize = isWideShortPhone
        ? 24.0
        : isMobile
        ? 28.w
        : 28.0;
    final filterWidth = isWideShortPhone
        ? 220.0
        : isMobile
        ? 200.w
        : 220.0;
    final customRangeGap = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.h
        : 10.0;
    final contentTopGap = isWideShortPhone
        ? 28.0
        : isMobile
        ? 45.h
        : 42.0;
    final titleGap = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.h
        : 10.0;
    final sectionGap = isWideShortPhone
        ? 24.0
        : isMobile
        ? 40.h
        : 36.0;
    final chartGap = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.h
        : 10.0;
    final useHorizontalCharts =
        isWideShortPhone || (isTablet && width > size.height);
    final chartSize = isWideShortPhone
        ? 120.0
        : useHorizontalCharts
        ? 150.0
        : isMobile
        ? 200.w
        : 220.0;
    final totalOrders = _completedOrders + _cancelledOrders;
    final completedChart = _orderChartSection(
      chartSize: chartSize,
      chartGap: chartGap,
      label: 'Completed',
      value: _completedOrders.toDouble(),
      total: totalOrders.toDouble(),
      mainColor: const Color(0xFFF7882A),
      secondaryColor: const Color(0xFFFDD3B0),
    );
    final cancelledChart = _orderChartSection(
      chartSize: chartSize,
      chartGap: chartGap,
      label: 'Cancelled',
      value: _cancelledOrders.toDouble(),
      total: totalOrders.toDouble(),
      mainColor: const Color(0xFF577941),
      secondaryColor: const Color(0xFFB9C296),
    );

    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.only(
          top: (isTablet || isWideShortPhone) ? 12.0 : 0.0,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: pagePadding),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          appTextColor3,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          'assets/images/backarrow_icon.png',
                          width: backIconSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _contentMaxWidth(size, isWideShortPhone),
                  ),
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: filterWidth),
                        child: AppFilterDropDown(
                          key: ValueKey(_selectedFilter),
                          hint: _selectedFilter,
                          items: const [
                            'Last 7 days',
                            'Last 30 days',
                            'Custom',
                          ],
                          icon: Icons.tune,
                          onChanged: _handleFilterChanged,
                        ),
                      ),
                      if (_buildCustomRangeText(context) != null) ...[
                        SizedBox(height: customRangeGap),
                        AppText(
                          text: _buildCustomRangeText(context)!,
                          size: 12,
                          fontWeight: FontWeight.w500,
                          color: appTextColor2,
                          isCentered: true,
                        ),
                      ],
                      SizedBox(height: contentTopGap),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        AppText(
                          text: 'TOTAL ORDERS',
                          size: 20,
                          fontWeight: FontWeight.w600,
                          isCentered: true,
                        ),
                        SizedBox(height: titleGap),
                        AppText(
                          text: totalOrders.toString(),
                          size: 40,
                          fontWeight: FontWeight.w600,
                          isCentered: true,
                          color: appTextColor3,
                        ),
                        SizedBox(height: sectionGap),
                        if (useHorizontalCharts)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: completedChart),
                              SizedBox(
                                width: isWideShortPhone ? 20.0 : sectionGap,
                              ),
                              Expanded(child: cancelledChart),
                            ],
                          )
                        else ...[
                          completedChart,
                          SizedBox(height: sectionGap),
                          cancelledChart,
                        ],
                        SizedBox(height: AppDimensions.margin(width)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderChartSection({
    required double chartSize,
    required double chartGap,
    required String label,
    required double value,
    required double total,
    required Color mainColor,
    required Color secondaryColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: chartSize,
          height: chartSize,
          child: OrderDonut(
            done: value,
            total: total,
            mainColor: mainColor,
            secondaryColor: secondaryColor,
          ),
        ),
        SizedBox(height: chartGap),
        AppText(
          text: label,
          size: 20,
          fontWeight: FontWeight.w400,
          isCentered: true,
          color: appTextColor2,
        ),
      ],
    );
  }
}
