import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudiko/api/dio_client.dart';
import 'package:fudiko/components/appbutton.dart';
import 'package:fudiko/components/appswitch.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
import 'package:fudiko/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:fudiko/utils/tokens.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final List<String> distances = [
    'Up to 1 km',
    'Up to 2 km',
    'Up to 3 km',
    'Up to 4 km',
    'Up to 5 km',
    'Up to 6 km',
    'Up to 7 km',
    'Up to 8 km',
    'Up to 9 km',
    'Up to 10 km',
    'More than 10 km',
  ];

  String selectedDistance = 'More than 10 km';

  bool _takeawayEnabled = true;
  bool _deliveryEnabled = true;
  bool _banquetEnabled = true;
  bool _cateringEnabled = true;
  bool _isLoadingServices = true;
  bool _isSavingServices = false;

  bool _isWideShortPhone(BuildContext context) {
    return Breakpoints.isWideShortPhone(MediaQuery.sizeOf(context));
  }

  EdgeInsetsGeometry _pagePadding(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    if (_isWideShortPhone(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    }
    final isMobile = Breakpoints.isMobileDevice(size);
    return EdgeInsets.symmetric(
      horizontal: isMobile ? 20.w : AppDimensions.padding(width),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInitialServices();
  }

  Future<void> _loadInitialServices() async {
    try {
      final token = await getToken();
      final response = await DioClient.dio.get(
        '/partner/services',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = (response.data is Map<String, dynamic>)
          ? response.data['data'] as Map<String, dynamic>?
          : null;

      if (!mounted) return;

      if (data != null) {
        final deliveryArea = (data['delivery_service_area'] ?? '').toString();
        final areaParts = deliveryArea
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && distances.contains(e))
            .toList();

        setState(() {
          _takeawayEnabled = (data['takeaway_service'] ?? 0) == 1;
          _deliveryEnabled = (data['delivery_service'] ?? 0) == 1;
          _banquetEnabled = (data['banquet_service'] ?? 0) == 1;
          _cateringEnabled = (data['catering_service'] ?? 0) == 1;
          selectedDistance = areaParts.isNotEmpty
              ? areaParts.first
              : 'More than 10 km';
          _isLoadingServices = false;
        });
      } else {
        setState(() => _isLoadingServices = false);
      }
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingServices = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load service settings')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingServices = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load service settings')),
      );
    }
  }

  Future<void> _saveServices() async {
    if (_isSavingServices) return;

    setState(() => _isSavingServices = true);

    try {
      final token = await getToken();
      final formData = FormData.fromMap({
        'banquet_service': _banquetEnabled ? 1 : 0,
        'catering_service': _cateringEnabled ? 1 : 0,
        'takeaway_service': _takeawayEnabled ? 1 : 0,
        'delivery_service': _deliveryEnabled ? 1 : 0,
        'delivery_service_area': _deliveryEnabled ? selectedDistance : '',
      });

      final response = await DioClient.dio.post(
        '/partner/update-services',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final body = response.data;
      final isSuccess = body is Map<String, dynamic>
          ? body['status'] == true
          : response.statusCode != null &&
                response.statusCode! >= 200 &&
                response.statusCode! < 300;
      final message = body is Map<String, dynamic>
          ? (body['message']?.toString() ??
                (isSuccess
                    ? 'Service settings updated successfully'
                    : 'Failed to update service settings'))
          : (isSuccess
                ? 'Service settings updated successfully'
                : 'Failed to update service settings');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on DioException catch (e) {
      if (!mounted) return;
      final errorBody = e.response?.data;
      final errorMessage = errorBody is Map<String, dynamic>
          ? (errorBody['message']?.toString() ??
                'Failed to update service settings')
          : 'Failed to update service settings';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update service settings')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingServices = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = _isWideShortPhone(context);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final verticalPadding = isWideShortPhone
        ? 16.0
        : isMobile
        ? 20.h
        : 24.0;
    final backIconSize = isWideShortPhone
        ? 24.0
        : isMobile
        ? 28.w
        : 28.0;
    final headerGap = isWideShortPhone
        ? 28.0
        : isMobile
        ? 40.h
        : 42.0;
    final smallGap = isWideShortPhone
        ? 8.0
        : isMobile
        ? 10.h
        : 10.0;
    final distanceTopGap = isWideShortPhone
        ? 6.0
        : isMobile
        ? 8.h
        : 10.0;
    final distanceBottomGap = isWideShortPhone
        ? 16.0
        : isMobile
        ? 24.h
        : 24.0;
    final bottomGap = isWideShortPhone
        ? 16.0
        : isMobile
        ? 20.h
        : 24.0;

    return Scaffold(
      body: SafeArea(
        minimum: EdgeInsets.only(
          top: (isTablet || isWideShortPhone) ? 12.0 : 0.0,
        ),
        child: _isLoadingServices
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: verticalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back arrow
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWideShortPhone
                                ? 24.0
                                : isMobile
                                ? 20.w
                                : AppDimensions.padding(width),
                          ),
                          child: ColorFiltered(
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
                        ),
                      ),

                      SizedBox(height: headerGap),
                      SizedBox(height: smallGap),

                      // Top divider
                      Divider(color: Colors.deepOrange.shade100, thickness: 1),

                      // Banquet service
                      _buildServiceRow("Banquet service", _banquetEnabled),
                      Divider(color: Colors.deepOrange.shade100, thickness: 1),

                      // Catering service
                      _buildServiceRow("Catering service", _cateringEnabled),
                      Divider(color: Colors.deepOrange.shade100, thickness: 1),

                      // Takeaway service
                      _buildServiceRow("Takeaway service", _takeawayEnabled),
                      Divider(color: Colors.deepOrange.shade100, thickness: 1),

                      // Delivery service
                      _buildServiceRow("Delivery service", _deliveryEnabled),
                      Divider(color: Colors.deepOrange.shade100, thickness: 1),

                      // Distance grid — only shown when delivery is enabled
                      if (_deliveryEnabled) ...[
                        SizedBox(height: distanceTopGap),
                        Padding(
                          padding: _pagePadding(context),
                          child: _buildDistanceGrid(),
                        ),
                        SizedBox(height: distanceBottomGap),
                      ],

                      // Save button
                      Padding(
                        padding: _pagePadding(context),
                        child: Opacity(
                          opacity: _isSavingServices ? 0.7 : 1,
                          child: IgnorePointer(
                            ignoring: _isSavingServices,
                            child: AppButton(
                              text: _isSavingServices
                                  ? 'Saving...'
                                  : 'Save Services',
                              onPressed: () {
                                _saveServices();
                              },
                              size: 16,
                              borderRadius: 14,
                              bgColor1: appButtonColor,
                              bgColor2: appButtonColor,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: bottomGap),
                      Divider(color: Colors.deepOrange.shade100, thickness: 1),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildServiceRow(String label, bool currentValue) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isWideShortPhone
            ? 8.0
            : isMobile
            ? 10.h
            : 14.0,
        horizontal: isWideShortPhone
            ? 24.0
            : isMobile
            ? 20.w
            : AppDimensions.padding(width),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              text: label,
              size: 15,
              fontWeight: FontWeight.w500,
              color: Colors.deepOrange,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: AppDimensions.gap(width)),
          AppSwitch(
            key: ValueKey('$label-$currentValue'),
            initialValue: currentValue,
            onToggle: (val) {
              setState(() {
                if (label == 'Banquet service') {
                  _banquetEnabled = val;
                } else if (label == 'Catering service') {
                  _cateringEnabled = val;
                } else if (label == 'Takeaway service') {
                  _takeawayEnabled = val;
                } else if (label == 'Delivery service') {
                  _deliveryEnabled = val;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceGrid() {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final left = distances.sublist(0, 5); // Up to 1–5 km
    final right = distances.sublist(5, 10); // Up to 6–10 km
    final last = distances[10]; // More than 10 km

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(children: left.map(_buildCheckboxRow).toList()),
            ),
            SizedBox(
              width: isWideShortPhone
                  ? 16.0
                  : isMobile
                  ? 20.w
                  : AppDimensions.gap(width),
            ),
            Expanded(
              child: Column(children: right.map(_buildCheckboxRow).toList()),
            ),
          ],
        ),
        SizedBox(
          height: isWideShortPhone
              ? 10.0
              : isMobile
              ? 12.h
              : 14.0,
        ),
        // "More than 10 km" centred
        Center(child: _buildCheckboxRow(last)),
      ],
    );
  }

  Widget _buildCheckboxRow(String text) {
    final size = MediaQuery.sizeOf(context);
    final isWideShortPhone = _isWideShortPhone(context);
    final isMobile = Breakpoints.isMobileDevice(size) && !isWideShortPhone;
    final boxSize = isWideShortPhone
        ? 22.0
        : isMobile
        ? 24.w
        : 24.0;
    final checkSize = isWideShortPhone
        ? 14.0
        : isMobile
        ? 16.w
        : 16.0;
    final isChecked = selectedDistance == text;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isWideShortPhone
            ? 5.0
            : isMobile
            ? 6.h
            : 7.0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: AppText(
              text: text,
              size: 14,
              fontWeight: FontWeight.w400,
              color: appTextColor2,
              softWrap: true,
            ),
          ),
          SizedBox(
            width: isWideShortPhone
                ? 8.0
                : isMobile
                ? 8.w
                : 8.0,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                selectedDistance = text;
              });
            },
            child: Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: isChecked ? appToggleColor : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  isWideShortPhone
                      ? 6.0
                      : isMobile
                      ? 6.r
                      : 6.0,
                ),
                border: Border.all(color: appToggleColor, width: 2),
              ),
              child: isChecked
                  ? Icon(Icons.check, size: checkSize, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
