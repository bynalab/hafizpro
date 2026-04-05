import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wraps any widget that contains a vertically scrolling descendant
/// ([ListView], [ScrollablePositionedList], [SingleChildScrollView], etc.)
/// and paints a non-interactive scrollbar from [ScrollNotification] metrics.
///
/// The child must fill the space you want the scrollbar to span (typically
/// an [Expanded] or [SizedBox.expand] ancestor provides bounds).
class MetricsScrollbar extends StatefulWidget {
  const MetricsScrollbar({
    super.key,
    required this.child,
    this.thickness = 5,

    /// Total width reserved on the [TextDirection.ltr] trailing / [TextDirection.rtl] leading edge.
    this.gutterWidth = 12,
    this.trackVerticalMargin = 4,
  });

  final Widget child;
  final double thickness;
  final double gutterWidth;
  final double trackVerticalMargin;

  @override
  State<MetricsScrollbar> createState() => _MetricsScrollbarState();
}

class _MetricsScrollbarState extends State<MetricsScrollbar> {
  ScrollMetrics? _scrollMetrics;

  /// Scroll notifications can fire during layout (e.g. [ScrollPosition.applyNewDimensions]).
  /// Scheduling [setState] for the next frame avoids "Build scheduled during frame".
  ScrollMetrics? _pendingMetrics;
  bool _metricsFlushScheduled = false;

  void _requestMetricsPaint(ScrollMetrics m) {
    _pendingMetrics = m;
    if (_metricsFlushScheduled) return;
    _metricsFlushScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _metricsFlushScheduled = false;
      if (!mounted) return;
      final next = _pendingMetrics;
      if (next == null) return;

      final prev = _scrollMetrics;
      if (prev != null &&
          prev.pixels == next.pixels &&
          prev.maxScrollExtent == next.maxScrollExtent &&
          prev.minScrollExtent == next.minScrollExtent &&
          prev.viewportDimension == next.viewportDimension) {
        return;
      }
      setState(() => _scrollMetrics = next);
    });
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    _requestMetricsPaint(n.metrics);
    return false;
  }

  bool _onScrollMetricsNotification(ScrollMetricsNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    _requestMetricsPaint(n.metrics);
    return false;
  }

  Widget _buildThumbOverlay() {
    final m = _scrollMetrics;
    if (m == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final min = m.minScrollExtent;
    final max = m.maxScrollExtent;
    final range = max - min;
    final viewport = m.viewportDimension;
    final barWidth = widget.thickness;
    final trackMargin = widget.trackVerticalMargin;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackH = constraints.maxHeight;
        if (trackH <= 0) return const SizedBox.shrink();

        final innerTrack =
            (trackH - 2 * trackMargin).clamp(0.0, double.infinity);

        double thumbH;
        double thumbTop;
        if (range <= 0) {
          thumbH = innerTrack;
          thumbTop = 0;
        } else {
          thumbH = (viewport / (range + viewport)) * innerTrack;
          thumbH = math.max(24.0, thumbH);
          thumbH = math.min(thumbH, innerTrack);
          final scrollable = math.max(0.0, innerTrack - thumbH);
          thumbTop = ((m.pixels - min) / range) * scrollable;
          thumbTop = thumbTop.clamp(0.0, scrollable);
        }

        final trackColor =
            (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10);
        final thumbColor =
            (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35);

        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 2),
            child: SizedBox(
              width: barWidth,
              height: trackH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: trackMargin,
                    bottom: trackMargin,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(barWidth / 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: trackMargin + thumbTop,
                    height: math.max(8.0, thumbH),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: thumbColor,
                        borderRadius: BorderRadius.circular(barWidth / 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onScrollMetricsNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Stack(
          children: [
            widget.child,
            PositionedDirectional(
              top: 0,
              end: 0,
              bottom: 0,
              width: widget.gutterWidth,
              child: IgnorePointer(
                child: _buildThumbOverlay(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
