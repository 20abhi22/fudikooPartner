import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/utils/constants.dart';

// Formats a date for range display. When [other] is provided and is in the
// same year, the year is omitted for a cleaner range like "5 Jan - 15 Mar".
String formatDateForRange(DateTime date, [DateTime? other]) {
  final dayMonth = _formatDayMonth(date);
  if (other != null && other.year == date.year) return dayMonth;
  return '$dayMonth ${date.year}';
}

String _formatDayMonth(DateTime date) {
  const shortMonths = [
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
  ];
  return '${date.day} ${shortMonths[date.month - 1]}';
}

class CompletedDateRangeDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const CompletedDateRangeDialog({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<CompletedDateRangeDialog> createState() =>
      _CompletedDateRangeDialogState();
}

class _CompletedDateRangeDialogState extends State<CompletedDateRangeDialog> {
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

  bool get _isLandscape =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  @override
  Widget build(BuildContext context) {
    final canApply = _startDate != null && _endDate != null;
    final monthName = _monthName(_displayMonth.month);
    final isLandscape = _isLandscape;
    final dialogHPad = isLandscape ? 12.0 : 16.w;
    final dialogVPad = isLandscape ? 10.0 : 16.h;
    final gapSmall = isLandscape ? 4.0 : 6.h;
    final gapMed = isLandscape ? 6.0 : 8.h;
    final gapLarge = isLandscape ? 8.0 : 12.h;

    return Dialog(
      backgroundColor: const Color(0xFFF5F5F5),
      insetPadding: isLandscape
          ? EdgeInsets.symmetric(horizontal: 24, vertical: 8.h)
          : EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 300.0 : double.infinity,
          maxHeight: MediaQuery.sizeOf(context).height - (isLandscape ? 16.h : 48),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: dialogHPad,
            vertical: dialogVPad,
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  iconSize: isLandscape ? 20 : 24,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: isLandscape ? 30 : 40,
                    minHeight: isLandscape ? 30 : 40,
                  ),
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
                          fontSize: isLandscape ? 13.sp : 16.sp,
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
                        size: isLandscape ? 18.sp : 20.sp,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  iconSize: isLandscape ? 20 : 24,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: isLandscape ? 30 : 40,
                    minHeight: isLandscape ? 30 : 40,
                  ),
                  onPressed: _showMonthYearPicker ? null : _nextMonth,
                ),
              ],
            ),
            if (_showMonthYearPicker) ...[
              SizedBox(height: gapSmall),
              _buildMonthYearPicker(isLandscape),
            ] else ...[
              SizedBox(height: gapSmall),
              _buildWeekdayLabels(isLandscape),
              SizedBox(height: gapSmall),
              _buildDayGrid(isLandscape),
            ],
            SizedBox(height: gapLarge),
            _buildSelectedRangeLabel(isLandscape),
            SizedBox(height: gapMed),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isLandscape ? 4 : 10.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 8 : 12,
                        vertical: isLandscape ? 4 : 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: isLandscape ? 12.sp : 14.sp,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 8 : 12,
                        vertical: isLandscape ? 4 : 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
                        fontSize: isLandscape ? 12.sp : 14.sp,
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
      ),
    );
  }

  Widget _buildSelectedRangeLabel(bool isLandscape) {
    final label = _startDate == null
        ? 'Select start date'
        : _endDate == null
        ? 'Select end date'
        : '${formatDateForRange(_startDate!, _endDate!)} - ${formatDateForRange(_endDate!, _startDate!)}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: isLandscape ? 6.0 : 9.h,
      ),
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
          fontSize: isLandscape ? 12.sp : 13.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMonthYearPicker(bool isLandscape) {
    final firstYear = widget.firstDate.year;
    final lastYear = widget.lastDate.year;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isLandscape ? 30 : 40,
                minHeight: isLandscape ? 30 : 40,
              ),
              onPressed: _pickerYear > firstYear
                  ? () => setState(() => _pickerYear--)
                  : null,
            ),
            GestureDetector(
              onTap: () => _showYearScrollPicker(context),
              child: Text(
                '$_pickerYear',
                style: TextStyle(
                  fontSize: isLandscape ? 13.sp : 15.sp,
                  fontWeight: FontWeight.w600,
                  color: appButtonColor,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isLandscape ? 30 : 40,
                minHeight: isLandscape ? 30 : 40,
              ),
              onPressed: _pickerYear < lastYear
                  ? () => setState(() => _pickerYear++)
                  : null,
            ),
          ],
        ),
        SizedBox(height: isLandscape ? 4.0 : 8.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: isLandscape ? 5 : 8,
            crossAxisSpacing: isLandscape ? 5 : 8,
            childAspectRatio: isLandscape ? 2.8 : 2.2,
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
                height: isLandscape ? 34.0 : 50.h,
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
                      fontSize: isLandscape ? 11.sp : 12.sp,
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
        SizedBox(height: isLandscape ? 4.0 : 8.h),
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

  Widget _buildWeekdayLabels(bool isLandscape) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
            .map(
              (day) => SizedBox(
                width: isLandscape ? 26.0 : 36.w,
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: isLandscape ? 10.sp : 12.sp,
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

  Widget _buildDayGrid(bool isLandscape) {
    final today = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayMonth.year,
      _displayMonth.month,
    );
    final firstWeekday =
        DateTime(_displayMonth.year, _displayMonth.month, 1).weekday % 7;
    final cellSize = isLandscape ? 22.0 : 34.w;
    final dotGap = isLandscape ? 1.0 : 2.h;
    final dotSize = isLandscape ? 4.0 : 5.w;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: firstWeekday + daysInMonth,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: isLandscape ? 2 : 4,
        crossAxisSpacing: 0,
        childAspectRatio: isLandscape ? 1.3 : 1,
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
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: isSelected
                      ? appButtonColor
                      : isInRange
                      ? appButtonColor.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(isLandscape ? 8.r : 10.r),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: isLandscape ? 11.sp : 13.sp,
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
              SizedBox(height: dotGap),
              isToday
                  ? Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : SizedBox(height: dotSize),
            ],
          ),
        );
      },
    );
  }

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
