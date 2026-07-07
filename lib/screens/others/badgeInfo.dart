import 'package:flutter/material.dart';
import 'package:fudiko/components/apptext.dart';
import 'package:fudiko/core/responsive/app_dimensions.dart';
import 'package:fudiko/core/responsive/breakpoints.dart';
// import 'package:fudiko/model/badge/badge_model.dart';
import 'package:fudiko/models/badge/badge_model.dart';
// import 'package:fudiko/service/badge/badge_service.dart';
import 'package:fudiko/services/badge_service.dart';
import 'package:fudiko/utils/constants.dart';

class BadgeInfo extends StatefulWidget {
  const BadgeInfo({super.key});

  static const int _gridColumns = 5;

  @override
  State<BadgeInfo> createState() => _BadgeInfoState();
}

class _BadgeInfoState extends State<BadgeInfo> {
  final BadgesService _badgesService = BadgesService();
  BadgesResponseModel? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBadges();
  }

  Future<void> _fetchBadges() async {
    final result = await _badgesService.getBadges();
    if (!mounted) return;
    setState(() {
      _data = result;
      _isLoading = false;
    });
  }

  /// Returns the progress percentage toward the next badge and its point
  /// target. Mirrors the client-side logic exactly.
  ({double percentage, int target}) _progressToNextBadge(
    int currentPoints,
    List<BadgeItemModel> badges,
  ) {
    final nextBadge = badges
        .where((b) => b.points > currentPoints)
        .fold<BadgeItemModel?>(null, (closest, b) {
          if (closest == null || b.points < closest.points) return b;
          return closest;
        });

    if (nextBadge == null) {
      return (percentage: 100.0, target: currentPoints);
    }

    final percentage = nextBadge.points == 0
        ? 0.0
        : (currentPoints / nextBadge.points * 100).clamp(0.0, 100.0);

    return (percentage: percentage, target: nextBadge.points);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final badges = _data?.badges ?? [];
                final currentPoints = _data?.currentPoints ?? 0;
                final hasCurrentBadge = _data?.currentBadge != null;

                final metrics = _BadgeInfoLayoutMetrics.fromConstraints(
                  constraints: constraints,
                  orientation: orientation,
                  badgeCount: badges.isEmpty ? 1 : badges.length,
                );

                final progress = _progressToNextBadge(currentPoints, badges);

                final content = _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: metrics.isTablet
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Badge title ───────────────────────────────────
                          AppText(
                            text: hasCurrentBadge
                                ? _data!.currentBadge!.name
                                : 'No Badge Yet',
                            size: metrics.titleSize,
                            fontWeight: FontWeight.w600,
                            isCentered: true,
                            color: hasCurrentBadge ? Colors.amber : Colors.grey,
                          ),
                          SizedBox(height: metrics.smallGap),

                          // ── Main badge image ──────────────────────────────
                          // Main badge
                          Center(
                            child: hasCurrentBadge
                                ? SizedBox(
                                    width: metrics.mainBadgeSize,
                                    height: metrics.mainBadgeSize,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        const ColoredBox(color: Colors.white),
                                        Image.network(
                                          _data!.currentBadge!.image,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              _greyscaleBadgePlaceholder(
                                                metrics.mainBadgeSize,
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _greyscaleBadgePlaceholder(
                                    metrics.mainBadgeSize,
                                  ),
                          ),
                          SizedBox(height: metrics.mainBadgeBottomGap),

                          // ── Caption ───────────────────────────────────────
                          AppText(
                            text: hasCurrentBadge
                                ? 'Keep going to earn more badges!'
                                : 'Your next badge is on its way!',
                            size: metrics.captionSize,
                            fontWeight: FontWeight.w400,
                            isCentered: true,
                            color: Colors.black,
                          ),
                          SizedBox(height: metrics.bodyGap),

                          // ── Progress bar ──────────────────────────────────
                          Center(
                            child: SizedBox(
                              width: metrics.progressWidth,
                              child: _GradientProgressBar(
                                percentage: progress.percentage,
                                height: metrics.progressHeight,
                              ),
                            ),
                          ),
                          SizedBox(height: metrics.bodyGap),

                          // ── Points counter ────────────────────────────────
                          AppText(
                            text: '$currentPoints/${progress.target}',
                            size: metrics.bodySize,
                            fontWeight: FontWeight.w500,
                            isCentered: true,
                            color: Colors.black,
                          ),
                          SizedBox(height: metrics.gridTopGap),

                          // ── Badge grid ────────────────────────────────────
                          if (badges.isEmpty)
                            AppText(
                              text: 'No badges available',
                              size: metrics.bodySize,
                              fontWeight: FontWeight.w400,
                              isCentered: true,
                              color: appTextColor2,
                            )
                          else
                            Center(
                              child: SizedBox(
                                width: metrics.gridWidth,
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: metrics.gridGap,
                                  runSpacing: metrics.gridGap,
                                  children: badges.map((badge) {
                                    final isEarned =
                                        badge.points <= currentPoints;
                                    final badgeImage = SizedBox(
                                      width: metrics.gridBadgeSize,
                                      height: metrics.gridBadgeSize,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          const ColoredBox(color: Colors.white),
                                          Image.network(
                                            badge.image,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                _greyscaleBadgePlaceholder(
                                                  metrics.gridBadgeSize,
                                                ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (isEarned) return badgeImage;

                                    return ColorFiltered(
                                      colorFilter:
                                          const ColorFilter.matrix(<double>[
                                            0.2126,
                                            0.7152,
                                            0.0722,
                                            0,
                                            0,
                                            0.2126,
                                            0.7152,
                                            0.0722,
                                            0,
                                            0,
                                            0.2126,
                                            0.7152,
                                            0.0722,
                                            0,
                                            0,
                                            0,
                                            0,
                                            0,
                                            1,
                                            0,
                                          ]),
                                      child: badgeImage,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.pageHorizontalPadding,
                  ),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          top: metrics.contentTopInset,
                          bottom: metrics.bottomPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                (constraints.maxHeight -
                                        metrics.contentTopInset -
                                        metrics.bottomPadding)
                                    .clamp(0.0, double.infinity),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: metrics.contentWidth,
                              child: content,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: metrics.backTop,
                        left: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              appTextColor3,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'assets/images/backarrow_icon.png',
                              width: metrics.backSize,
                              height: metrics.backSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _greyscaleBadgePlaceholder(double size) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: Image.asset(
        'assets/images/verificationgrey.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.percentage, required this.height});

  final double percentage;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clamped = percentage.clamp(0.0, 100.0);
        final radius = height / 2;

        return Stack(
          children: [
            Container(
              height: height,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                height: height,
                width: constraints.maxWidth * (clamped / 100),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.pink],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout metrics
// Partner AppDimensions takes a plain double (width), not a BuildContext.
// Wide-short-phone detection mirrors the original client breakpoint:
//   mobile width (< 600) && width >= 500 && height <= 760
// ─────────────────────────────────────────────────────────────────────────────

class _BadgeInfoLayoutMetrics {
  const _BadgeInfoLayoutMetrics({
    required this.pageHorizontalPadding,
    required this.contentWidth,
    required this.progressWidth,
    required this.gridWidth,
    required this.backTop,
    required this.backSize,
    required this.contentTopInset,
    required this.smallGap,
    required this.bodyGap,
    required this.mainBadgeBottomGap,
    required this.gridTopGap,
    required this.bottomPadding,
    required this.mainBadgeSize,
    required this.gridBadgeSize,
    required this.gridGap,
    required this.progressHeight,
    required this.titleSize,
    required this.bodySize,
    required this.captionSize,
    required this.isTablet,
  });

  final double pageHorizontalPadding;
  final double contentWidth;
  final double progressWidth;
  final double gridWidth;
  final double backTop;
  final double backSize;
  final double contentTopInset;
  final double smallGap;
  final double bodyGap;
  final double mainBadgeBottomGap;
  final double gridTopGap;
  final double bottomPadding;
  final double mainBadgeSize;
  final double gridBadgeSize;
  final double gridGap;
  final double progressHeight;
  final double titleSize;
  final double bodySize;
  final double captionSize;
  final bool isTablet;

  factory _BadgeInfoLayoutMetrics.fromConstraints({
    required BoxConstraints constraints,
    required Orientation orientation,
    required int badgeCount,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    final size = Size(width, height);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isTabletLandscape = isTablet && orientation == Orientation.landscape;

    final isWideShortPhone = Breakpoints.isWideShortPhone(size);

    // Compact phone: very small screen
    final isCompactPhone = !isWideShortPhone && (width < 390 || height < 640);

    final columns = BadgeInfo._gridColumns;
    final rows = (badgeCount / columns).ceil().clamp(1, 1000);

    // ── Grid sizing ──────────────────────────────────────────────────────────
    final gridGap = isTablet
        ? AppDimensions.gap(width) * 0.8
        : isCompactPhone
        ? 8.0
        : 10.0;

    final baseGridBadgeSize = isTablet
        ? ((width * (isTabletLandscape ? 0.48 : 0.56) - (gridGap * 4)) / 5)
              .clamp(56.0, 76.0)
        : isWideShortPhone
        ? 44.0
        : isCompactPhone
        ? 44.0
        : 50.0;

    final shrinkFactor = rows <= 5 ? 1.0 : (5 / rows).clamp(0.45, 1.0);
    final gridBadgeSize = (baseGridBadgeSize * shrinkFactor).clamp(
      28.0,
      baseGridBadgeSize,
    );
    final effectiveGridGap = rows <= 5
        ? gridGap
        : gridGap * shrinkFactor.clamp(0.6, 1.0);

    final gridWidth =
        (gridBadgeSize * columns) + (effectiveGridGap * (columns - 1));

    // ── Horizontal padding / content width ───────────────────────────────────
    final pageHorizontalPadding = isTablet
        ? width * 0.08
        : isWideShortPhone
        ? 24.0
        : isCompactPhone
        ? width * 0.06
        : width * 0.075;

    final contentWidth = isTablet
        ? (gridWidth + width * 0.08).clamp(360.0, width * 0.78)
        : width - (pageHorizontalPadding * 2);

    // ── Back button ───────────────────────────────────────────────────────────
    final backTop = isTablet
        ? 36.0
        : isWideShortPhone
        ? 8.0
        : isCompactPhone
        ? 22.0
        : 40.0;

    final backSize = isTablet
        ? 34.0
        : isWideShortPhone
        ? 24.0
        : isCompactPhone
        ? 28.0
        : 30.0;

    // ── Vertical gaps ─────────────────────────────────────────────────────────
    final titleTopGap = isTablet
        ? AppDimensions.margin(width)
        : isWideShortPhone
        ? 32.0
        : isCompactPhone
        ? 22.0
        : 30.0;

    final smallGap = isTablet
        ? AppDimensions.gap(width) * 0.8
        : isWideShortPhone
        ? 8.0
        : isCompactPhone
        ? 8.0
        : 10.0;

    final bodyGap = isTablet
        ? AppDimensions.gap(width) * 1.1
        : isWideShortPhone
        ? 14.0
        : isCompactPhone
        ? 16.0
        : 20.0;

    final mainBadgeBottomGap = isTablet
        ? AppDimensions.margin(width) * 0.85
        : isWideShortPhone
        ? 18.0
        : isCompactPhone
        ? 22.0
        : 30.0;

    final gridTopGap = isTabletLandscape
        ? AppDimensions.margin(width)
        : isTablet
        ? AppDimensions.margin(width) * 1.35
        : isWideShortPhone
        ? 28.0
        : isCompactPhone
        ? 44.0
        : 60.0;

    // ── Progress bar ──────────────────────────────────────────────────────────
    final progressWidth = isTablet
        ? (contentWidth * 0.78).clamp(260.0, 420.0)
        : isWideShortPhone
        ? contentWidth.clamp(260.0, 420.0)
        : isCompactPhone
        ? width * 0.8
        : width * 0.75;

    // ── Badge sizes ───────────────────────────────────────────────────────────
    final mainBadgeSize = isTablet
        ? 170.0
        : isWideShortPhone
        ? 120.0
        : isCompactPhone
        ? 132.0
        : 150.0;

    return _BadgeInfoLayoutMetrics(
      pageHorizontalPadding: pageHorizontalPadding,
      contentWidth: contentWidth,
      progressWidth: progressWidth,
      gridWidth: gridWidth,
      backTop: backTop,
      backSize: backSize,
      contentTopInset: backTop + backSize + titleTopGap,
      smallGap: smallGap,
      bodyGap: bodyGap,
      mainBadgeBottomGap: mainBadgeBottomGap,
      gridTopGap: gridTopGap,
      bottomPadding: isTablet
          ? AppDimensions.margin(width)
          : isWideShortPhone
          ? 24.0
          : isCompactPhone
          ? 22.0
          : 30.0,
      mainBadgeSize: mainBadgeSize,
      gridBadgeSize: gridBadgeSize,
      gridGap: effectiveGridGap,
      progressHeight: isTablet
          ? 10.0
          : isCompactPhone
          ? 8.0
          : 10.0,
      titleSize: isTablet ? AppDimensions.title(width) : 20.0,
      bodySize: isTablet
          ? AppDimensions.body(width)
          : isCompactPhone
          ? 14.0
          : 15.0,
      captionSize: isTablet
          ? AppDimensions.caption(width)
          : isCompactPhone
          ? 9.5
          : 10.0,
      isTablet: isTablet,
    );
  }
}
