import 'package:flutter/material.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';

class HomeMobile extends StatelessWidget {
  final List<Map<String, Object>> items;
  final Orientation orientation;
  final EdgeInsets systemPadding;

  const HomeMobile({
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
          final compactLandscape = orientation == Orientation.landscape;

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              padding,
              compactLandscape ? gap : padding,
              padding,
              padding + systemPadding.bottom,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _HomeHeader(width: width);
              }

              final item = items[index - 1];
              return HomeMetricCard(item: item, width: width);
            },
            separatorBuilder: (context, index) => SizedBox(height: gap),
            itemCount: items.length + 1,
          );
        },
      ),
    );
  }
}

class HomeMetricCard extends StatelessWidget {
  final Map<String, Object> item;
  final double width;

  const HomeMetricCard({super.key, required this.item, required this.width});

  @override
  Widget build(BuildContext context) {
    final color = item['color']! as Color;
    final icon = item['icon']! as IconData;
    final title = item['title']! as String;
    final subtitle = item['subtitle']! as String;
    final metric = item['metric']! as String;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.padding(width)),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withAlpha(31),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.gap(width) * 0.7),
                child: Icon(icon, color: color),
              ),
            ),
            SizedBox(width: AppDimensions.gap(width)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppDimensions.body(width),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppDimensions.gap(width) * 0.35),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: AppDimensions.caption(width),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppDimensions.gap(width)),
            Text(
              metric,
              style: TextStyle(
                color: color,
                fontSize: AppDimensions.title(width),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final double width;

  const _HomeHeader({required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
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
          'A responsive operating view for daily restaurant activity.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: AppDimensions.body(width),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
