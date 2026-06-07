import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../l10n/strings_formatters.dart';
import '../l10n/strings_plurals.dart';
import '../models/usage_stats.dart';
import '../services/usage_store.dart';
import '../ui/layout.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.strings,
    required this.usageStore,
  });

  final S strings;
  final UsageStore usageStore;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final metrics = AppMetrics.of(context);
    final scale = metrics.uiScale;
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.sp(24),
        metrics.sp(16),
        metrics.sp(24),
        metrics.sp(20) + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36 * scale,
              height: 4 * scale,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20 * scale),
          Text(
            widget.strings.analytics.toLowerCase(),
            style: TextStyle(
              fontSize: 17 * scale,
              fontWeight: FontWeight.w500,
              color: onSurface.withValues(alpha: 77),
              letterSpacing: 0.5,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20 * scale),
                  FutureBuilder<UsageStats>(
                    future: widget.usageStore.loadStats(),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? UsageStats.empty;
                      final loading =
                          snapshot.connectionState == ConnectionState.waiting;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatsSummary(
                            stats: stats,
                            strings: widget.strings,
                            scale: scale,
                            loading: loading,
                            onSurface: onSurface,
                          ),
                          if (!loading) ...[
                            SizedBox(height: 24 * scale),
                            _TimelineWidget(
                              stats: stats,
                              scale: scale,
                              onSurface: onSurface,
                            ),
                            SizedBox(height: 24 * scale),
                            _DailyBreakdown(
                              stats: stats,
                              strings: widget.strings,
                              scale: scale,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 8 * scale),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({
    required this.stats,
    required this.strings,
    required this.scale,
    required this.loading,
    required this.onSurface,
  });

  final UsageStats stats;
  final S strings;
  final double scale;
  final bool loading;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24 * scale),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (stats.totalCount == 0) {
      return Padding(
        padding: EdgeInsets.only(top: 8 * scale, bottom: 8 * scale),
        child: Text(
          strings.analyticsEmpty,
          style: TextStyle(
            fontSize: 14 * scale,
            color: onSurface.withValues(alpha: 77),
            height: 1.4,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${stats.totalCount}',
              style: TextStyle(
                fontSize: 40 * scale,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF6EE7A0),
                height: 1,
              ),
            ),
            SizedBox(width: 8 * scale),
            Padding(
              padding: EdgeInsets.only(bottom: 6 * scale),
              child: Text(
                strings.sessionsLabel(stats.totalCount).toLowerCase(),
                style: TextStyle(
                  fontSize: 15 * scale,
                  color: onSurface.withValues(alpha: 77),
                ),
              ),
            ),
          ],
        ),
        if (stats.streakDays > 1) ...[
          SizedBox(height: 6 * scale),
          Text(
            strings.streakDays(stats.streakDays).toLowerCase(),
            style: TextStyle(
              fontSize: 13 * scale,
              color: onSurface.withValues(alpha: 77),
            ),
          ),
        ],
        SizedBox(height: 6 * scale),
        Text(
          strings.badgeTitle(stats.badgeKey).toLowerCase(),
          style: TextStyle(
            fontSize: 13 * scale,
            color: onSurface.withValues(alpha: 77),
          ),
        ),
      ],
    );
  }
}

class _TimelineWidget extends StatelessWidget {
  const _TimelineWidget({
    required this.stats,
    required this.scale,
    required this.onSurface,
  });

  final UsageStats stats;
  final double scale;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    if (stats.days.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate median activity for efficiency indicator
    final counts = stats.days.map((d) => d.count).toList();
    counts.sort();
    final median = counts.isEmpty
        ? 0
        : counts[(counts.length / 2).floor()];

    // Generate list of days from today going back (limit to 30 days)
    final now = DateTime.now();
    final timelineSize = 30;
    final daysInRange = <DateTime, int>{};

    for (final day in stats.days) {
      final daysAgo = now.difference(day.date).inDays;
      if (daysAgo >= 0 && daysAgo < timelineSize) {
        daysInRange[day.date] = day.count;
      }
    }

    // Fill in missing days with 0 activity
    for (int i = 0; i < timelineSize; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      daysInRange.putIfAbsent(date, () => 0);
    }

    // Sort by date (newest first)
    final sortedDays = daysInRange.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'activity timeline',
          style: TextStyle(
            fontSize: 13 * scale,
            color: onSurface.withValues(alpha: 77),
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 12 * scale),
        Wrap(
          spacing: 6 * scale,
          runSpacing: 6 * scale,
          children: [
            for (final entry in sortedDays)
              _TimelineDay(
                date: entry.key,
                count: entry.value,
                median: median,
                scale: scale,
              ),
          ],
        ),
      ],
    );
  }
}

class _TimelineDay extends StatelessWidget {
  const _TimelineDay({
    required this.date,
    required this.count,
    required this.median,
    required this.scale,
  });

  final DateTime date;
  final int count;
  final int median;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysAgo = now.difference(date).inDays;

    // Base opacity decay: 1.0 (today) → 0.1 (30 days ago)
    final baseFade = (1.0 - (daysAgo / 30.0)).clamp(0.1, 1.0);

    // Efficiency boost: days above median stay brighter 50% longer
    double opacity = baseFade;
    if (count > median && median > 0) {
      // Extend fade by 50%: instead of 30 days, use 45 days for calculation
      opacity = (1.0 - (daysAgo / 45.0)).clamp(0.1, 1.0);
    }

    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hasActivity = count > 0;
    final color = hasActivity
        ? const Color(0xFF6EE7A0).withValues(alpha: opacity)
        : onSurface.withValues(alpha: (opacity * 0.5).clamp(0.0, 1.0));

    return Tooltip(
      message: '${date.day}/${date.month}: $count sessions',
      child: Container(
        width: 28 * scale,
        height: 28 * scale,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4 * scale),
          border: hasActivity
              ? Border.all(
                  color: const Color(0xFF6EE7A0).withValues(alpha: opacity * 0.6),
                  width: 0.5,
                )
              : null,
        ),
        child: hasActivity
            ? Center(
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9 * scale,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _DailyBreakdown extends StatelessWidget {
  const _DailyBreakdown({
    required this.stats,
    required this.strings,
    required this.scale,
  });

  final UsageStats stats;
  final S strings;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (stats.days.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.byDate.toLowerCase(),
          style: TextStyle(
            fontSize: 13 * scale,
            color: colorScheme.onSurface.withValues(alpha: 0.38),
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 8 * scale),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 300 * scale),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.days.length,
            separatorBuilder: (_, __) => Divider(
              color: colorScheme.onSurface.withValues(alpha: 0.12),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final day = stats.days[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 10 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      strings.formatDay(day.date),
                      style: TextStyle(
                        fontSize: 15 * scale,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * scale,
                        vertical: 4 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6 * scale),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        strings.timesOnDay(day.count),
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
