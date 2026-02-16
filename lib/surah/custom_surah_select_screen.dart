import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/main_menu/widgets.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/surah/test_by_surah.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

class CustomSurahSelectScreen extends StatefulWidget {
  const CustomSurahSelectScreen({super.key});

  @override
  State<CustomSurahSelectScreen> createState() =>
      _CustomSurahSelectScreenState();
}

class _CustomSurahSelectScreenState extends State<CustomSurahSelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedSurahs = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSurah(int number) {
    setState(() {
      if (_selectedSurahs.contains(number)) {
        _selectedSurahs.remove(number);
      } else {
        _selectedSurahs.add(number);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displaySurahs =
        _query.trim().isEmpty ? surahList : searchSurah(_query);
    final titleColor =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          context.l10n.customSurahSelectTitle,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: titleColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: SearchField(
              controller: _searchController,
              hintText: context.l10n.searchBySurahHint,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
              itemCount: displaySurahs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final surah = displaySurahs[index];
                final isSelected = _selectedSurahs.contains(surah.number);

                return _SelectionSurahCard(
                  surah: surah,
                  isSelected: isSelected,
                  onTap: () => _toggleSurah(surah.number),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedSurahs.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TestBySurah(
                          surahNumbers: _selectedSurahs.toList()..sort(),
                        ),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF004B40),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  label: Text(
                    context.l10n.customSurahSelectContinue,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _SelectionSurahCard extends StatelessWidget {
  final Surah surah;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionSurahCard({
    required this.surah,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF101010) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final titleColor =
        isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final subtitleColor = const Color(0xFF9CA3AF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF004B40) : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF004B40)
                    : (isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF3F4F6)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        '${surah.number}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.englishName,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    surah.englishNameTranslation,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeColor: const Color(0xFF004B40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }
}
