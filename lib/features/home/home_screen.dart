import 'package:flutter/material.dart';
import 'package:fudiko/core/responsive/responsive_builder.dart';
import 'package:fudiko/features/home/home_desktop.dart';
import 'package:fudiko/features/home/home_mobile.dart';
import 'package:fudiko/features/home/home_tablet.dart';

class HomeScreen extends StatelessWidget {
  final double? breakpointWidth;

  const HomeScreen({super.key, this.breakpointWidth});

  static const List<Map<String, Object>> dashboardItems = [
    {
      'title': 'Today Orders',
      'subtitle': 'Orders received across active services',
      'metric': '128',
      'icon': Icons.receipt_long,
      'color': Color(0xFF2F6FED),
    },
    {
      'title': 'Reservations',
      'subtitle': 'Upcoming bookings for the next service window',
      'metric': '34',
      'icon': Icons.event_available,
      'color': Color(0xFF73B256),
    },
    {
      'title': 'Promotions',
      'subtitle': 'Live offers currently available to guests',
      'metric': '12',
      'icon': Icons.local_offer,
      'color': Color(0xFFE28A2F),
    },
    {
      'title': 'Revenue',
      'subtitle': 'Estimated gross revenue for this week',
      'metric': '₹82K',
      'icon': Icons.trending_up,
      'color': Color(0xFF8F5FE8),
    },
    {
      'title': 'Messages',
      'subtitle': 'Customer and support conversations waiting',
      'metric': '9',
      'icon': Icons.forum,
      'color': Color(0xFF0F9F8E),
    },
    {
      'title': 'Menu Health',
      'subtitle': 'Items available and ready to be ordered',
      'metric': '96%',
      'icon': Icons.restaurant_menu,
      'color': Color(0xFFD63F67),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final systemPadding = MediaQuery.paddingOf(context);

    return OrientationBuilder(
      builder: (context, orientation) {
        return ResponsiveBuilder(
          breakpointWidth: breakpointWidth,
          mobile: (context, constraints) => HomeMobile(
            items: dashboardItems,
            orientation: orientation,
            systemPadding: systemPadding,
          ),
          tablet: (context, constraints) => HomeTablet(
            items: dashboardItems,
            orientation: orientation,
            systemPadding: systemPadding,
          ),
          desktop: (context, constraints) => HomeDesktop(
            items: dashboardItems,
            orientation: orientation,
            systemPadding: systemPadding,
          ),
        );
      },
    );
  }
}
