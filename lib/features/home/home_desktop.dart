import 'package:flutter/material.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/features/home/home_mobile.dart';

class HomeDesktop extends StatelessWidget {
  final List<Map<String, Object>> items;
  final Orientation orientation;
  final EdgeInsets systemPadding;

  const HomeDesktop({
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

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 280,
                child: _DesktopSidePanel(width: width, items: items),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        padding,
                        padding,
                        padding,
                        gap,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _DesktopHeader(width: width),
                      ),
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
                          crossAxisCount: AppDimensions.gridColumns(
                            constraints.maxWidth - 280 - (padding * 2),
                          ),
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                          childAspectRatio: orientation == Orientation.landscape
                              ? 2.3
                              : 2.0,
                        ),
                        itemBuilder: (context, index) {
                          return HomeMetricCard(
                            item: items[index],
                            width: width,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopSidePanel extends StatelessWidget {
  final double width;
  final List<Map<String, Object>> items;

  const _DesktopSidePanel({required this.width, required this.items});

  @override
  Widget build(BuildContext context) {
    final gap = AppDimensions.gap(width);
    final padding = AppDimensions.padding(width);
    final activeItem = items.first;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: TextStyle(
                fontSize: AppDimensions.title(width),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: gap),
            Text(
              'Focus area',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: AppDimensions.caption(width),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: gap * 0.5),
            Text(
              activeItem['title']! as String,
              style: TextStyle(
                fontSize: AppDimensions.body(width),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: gap * 0.5),
            Text(
              activeItem['subtitle']! as String,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: AppDimensions.caption(width),
                height: 1.4,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.tune),
              label: const Text('Configure'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  final double width;

  const _DesktopHeader({required this.width});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                'Master-detail dashboard with persistent context and scalable content.',
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
