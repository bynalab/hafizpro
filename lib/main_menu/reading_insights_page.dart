import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/util/util.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalRead = _storage.getTotalReadCount();
    final totalVerses = 6236;
    final remaining = totalVerses - totalRead;
    final completedSurahs = _storage.getCompletedSurahsCount();
    final percentage = _storage.getCompletionPercentage();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0B0B) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF111827),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reading Insights',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
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
                isDark: isDark,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Text(
                'Surah Breakdown',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final surah = surahList[index];
                final readCount = _storage.getSurahReadCount(surah.number);
                return _SurahProgressTile(
                  surah: surah,
                  readCount: readCount,
                  isDark: isDark,
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
  final bool isDark;

  const _OverviewStatsCard({
    required this.totalRead,
    required this.remaining,
    required this.completedSurahs,
    required this.percentage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
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
                isDark: isDark,
              ),
              _StatItem(
                label: 'Remaining',
                value: formatNumber(remaining),
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFF78B7C6),
                isDark: isDark,
              ),
              _StatItem(
                label: 'Completed',
                value: formatNumber(completedSurahs),
                icon: Icons.flag_rounded,
                color: const Color(0xFFFBBF24),
                isDark: isDark,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                  ),
                  Text(
                    formatPercentage(percentage),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF78B7C6),
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
                  backgroundColor:
                      isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF78B7C6)),
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
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _SurahProgressTile extends StatelessWidget {
  final Surah surah; // Data/Surah type
  final int readCount;
  final bool isDark;
  final VoidCallback onReset;

  const _SurahProgressTile({
    required this.surah,
    required this.readCount,
    required this.isDark,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = readCount / surah.numberOfAyahs;
    final isCompleted = readCount == surah.numberOfAyahs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF242424) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.green500.withValues(alpha: 0.1)
                    : const Color(0xFF78B7C6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${surah.number}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? AppColors.green500
                        : const Color(0xFF78B7C6),
                  ),
                ),
              ),
            ),
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
                          color:
                              isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${formatNumber(readCount)}/${formatNumber(surah.numberOfAyahs)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white60 : const Color(0xFF6B7280),
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
                      backgroundColor:
                          isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                      valueColor: AlwaysStoppedAnimation<Color>(isCompleted
                          ? AppColors.green500
                          : const Color(0xFF78B7C6)),
                    ),
                  ),
                ],
              ),
            ),
            if (readCount > 0) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.restart_alt_rounded,
                  size: 20,
                  color: isDark ? Colors.white38 : Colors.grey,
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
