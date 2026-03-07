import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/util.dart';
import 'package:hafiz_test/main_menu/widgets.dart';
import 'package:hafiz_test/widget/star_burst_icon.dart';

class ReadingInsightsPage extends StatefulWidget {
  const ReadingInsightsPage({super.key});

  @override
  State<ReadingInsightsPage> createState() => _ReadingInsightsPageState();
}

class _ReadingInsightsPageState extends State<ReadingInsightsPage> {
  final _storage = getIt<IStorageService>();

  /// Shows a confirmation dialog to clear the total reading progress bitset.
  Future<void> _confirmResetAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Progress?'),
        content: const Text(
            'This will clear all your Quran reading progress. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.clearAllProgress();
      // Refresh the UI to reflect zeroed progress
      if (mounted) setState(() {});
    }
  }

  /// Shows a confirmation dialog and then zeroes out the bits for a specific Surah.
  Future<void> _confirmResetSurah(BuildContext context, Surah surah) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Surah ${surah.englishName}?'),
        content: Text(
            'This will clear all reading progress for Surah ${surah.englishName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.clearSurahProgress(surah.number);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRead = _storage.getTotalReadCount();
    final totalVerses = 6236;
    final remaining = totalVerses - totalRead;
    final completedSurahs = _storage.getCompletedSurahsCount();
    final percentage = _storage.getCompletionPercentage();

    return Scaffold(
      backgroundColor: DashboardPalette.pinnedHeaderBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DashboardPalette.primaryText(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reading Insights',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DashboardPalette.primaryText(context),
          ),
        ),
        centerTitle: true,
        actions: [
          if (totalRead > 0)
            IconButton(
              icon: Icon(
                Icons.delete_sweep_rounded,
                color: DashboardPalette.secondaryText(context),
              ),
              onPressed: () => _confirmResetAll(context),
              tooltip: 'Reset All Progress',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _OverviewStatsCard(
                totalRead: totalRead,
                remaining: remaining,
                completedSurahs: completedSurahs,
                percentage: percentage,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Text(
                'Surah Breakdown',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DashboardPalette.primaryText(context),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final surah = surahList[index];
                final readCount = _storage.getSurahReadCount(surah.number);
                final lastUpdated = _storage.getSurahLastUpdated(surah.number);
                return _SurahProgressTile(
                  surah: surah,
                  readCount: readCount,
                  lastUpdated: lastUpdated,
                  onReset: () => _confirmResetSurah(context, surah),
                );
              },
              childCount: surahList.length,
            ),
          ),
          // Bottom padding for safe area
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatsCard extends StatelessWidget {
  final int totalRead;
  final int remaining;
  final int completedSurahs;
  final double percentage;

  const _OverviewStatsCard({
    required this.totalRead,
    required this.remaining,
    required this.completedSurahs,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? DashboardPalette.segmentedBg(context)
            : DashboardPalette.cardTeal(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? DashboardPalette.listTileBorder(context)
              : Colors.transparent,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: 'Read',
                value: formatNumber(totalRead),
                icon: Icons.check_circle_rounded,
                color: AppColors.green500,
              ),
              _StatItem(
                label: 'Remaining',
                value: formatNumber(remaining),
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFF78B7C6),
              ),
              _StatItem(
                label: 'Completed',
                value: formatNumber(completedSurahs),
                icon: Icons.flag_rounded,
                color: const Color(0xFFFBBF24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DashboardPalette.secondaryText(context),
                    ),
                  ),
                  Text(
                    formatPercentage(percentage),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppColors.green500 : const Color(0xFF205B5F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 10,
                  backgroundColor: isDark
                      ? DashboardPalette.listTileBg(context)
                      : Colors.white.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.green500 : const Color(0xFF205B5F),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: DashboardPalette.primaryText(context),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: DashboardPalette.secondaryText(context),
          ),
        ),
      ],
    );
  }
}

class _SurahProgressTile extends StatelessWidget {
  final Surah surah; // Data/Surah type
  final int readCount;
  final DateTime? lastUpdated;
  final VoidCallback onReset;

  const _SurahProgressTile({
    required this.surah,
    required this.readCount,
    this.lastUpdated,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = readCount / surah.numberOfAyahs;
    final isCompleted = readCount == surah.numberOfAyahs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DashboardPalette.listTileBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DashboardPalette.listTileBorder(context),
          ),
        ),
        child: Row(
          children: [
            StarburstIcon(text: '${surah.number}'),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        surah.englishName,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: DashboardPalette.primaryText(context),
                        ),
                      ),
                      Text(
                        '${formatNumber(readCount)}/${formatNumber(surah.numberOfAyahs)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DashboardPalette.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 5,
                      backgroundColor: isDark
                          ? DashboardPalette.segmentedBg(context)
                          : AppColors.green50,
                      valueColor: AlwaysStoppedAnimation<Color>(isCompleted
                          ? AppColors.green500
                          : const Color(0xFF78B7C6)),
                    ),
                  ),
                  if (lastUpdated != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Last updated: ${formatDateTime(lastUpdated!)}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (readCount > 0) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.restart_alt_rounded,
                  size: 20,
                  color: DashboardPalette.secondaryText(context)
                      .withValues(alpha: 0.5),
                ),
                onPressed: onReset,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Reset Surah Progress',
              ),
            ],
            if (isCompleted) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle,
                  color: AppColors.green500, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
