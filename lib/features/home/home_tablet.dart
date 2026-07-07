import 'package:flutter/material.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/features/home/home_mobile.dart';

class HomeTablet extends StatelessWidget {
  final List<Map<String, Object>> items;
  final Orientation orientation;
  final EdgeInsets systemPadding;

  const HomeTablet({
    super.key,
    required this.items,
    required this.orientation,
    required this.systemPadding,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = AppDimensions.padding(width);
          final gap = AppDimensions.gap(width);
          final columns = AppDimensions.gridColumns(width);
          final aspectRatio = orientation == Orientation.landscape ? 2.45 : 1.8;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(padding, padding, padding, gap),
                sliver: SliverToBoxAdapter(child: _TabletHeader(width: width)),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  0,
                  padding,
                  padding + systemPadding.bottom,
                ),
                sliver: SliverGrid.builder(
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    childAspectRatio: aspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    return HomeMetricCard(item: items[index], width: width);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabletHeader extends StatelessWidget {
  final double width;

  const _TabletHeader({required this.width});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Home',
                style: TextStyle(
                  fontSize: AppDimensions.headline(width),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: AppDimensions.gap(width) * 0.5),
              Text(
                'A balanced dashboard for scanning service activity.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: AppDimensions.body(width),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('New Offer'),
        ),
      ],
    );
  }
}
