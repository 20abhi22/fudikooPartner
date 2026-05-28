import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/components/appfilterdropdown.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/components/orderDonut.dart';
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
    final totalOrders = _completedOrders + _cancelledOrders;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: EdgeInsets.only(top: 40.h),
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
                          width: 28.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 200.w),
                child: AppFilterDropDown(
                  key: ValueKey(_selectedFilter),
                  hint: _selectedFilter,
                  items: const ['Last 7 days', 'Last 30 days', 'Custom'],
                  icon: Icons.tune,
                  onChanged: _handleFilterChanged,
                ),
              ),
              if (_buildCustomRangeText(context) != null) ...[
                SizedBox(height: 10.h),
                AppText(
                  text: _buildCustomRangeText(context)!,
                  size: 12,
                  fontWeight: FontWeight.w500,
                  color: appTextColor2,
                  isCentered: true,
                ),
              ],
              SizedBox(height: 45.h),
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
                SizedBox(height: 10.h),
                AppText(
                  text: totalOrders.toString(),
                  size: 40,
                  fontWeight: FontWeight.w600,
                  isCentered: true,
                  color: appTextColor3,
                ),
                SizedBox(height: 40.h),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: OrderDonut(
                    done: _completedOrders.toDouble(),
                    total: totalOrders.toDouble(),
                    mainColor: const Color(0xFFF7882A),
                    secondaryColor: const Color(0xFFFDD3B0),
                  ),
                ),
                SizedBox(height: 10.h),
                AppText(
                  text: 'Completed',
                  size: 20,
                  fontWeight: FontWeight.w400,
                  isCentered: true,
                  color: appTextColor2,
                ),
                SizedBox(height: 40.h),
                SizedBox(
                  width: 200.w,
                  height: 200.h,
                  child: OrderDonut(
                    done: _cancelledOrders.toDouble(),
                    total: totalOrders.toDouble(),
                    mainColor: const Color(0xFF577941),
                    secondaryColor: const Color(0xFFB9C296),
                  ),
                ),
                SizedBox(height: 10.h),
                AppText(
                  text: 'Cancelled',
                  size: 20,
                  fontWeight: FontWeight.w400,
                  isCentered: true,
                  color: appTextColor2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
