import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/l10n/app_localizations.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';
import 'package:hafiz_test/model/ayah.model.dart';

class VersePickerBottomSheet extends StatelessWidget {
  final List<Ayah> ayahs;
  final int currentAyahNumber;
  final Function(int) onVerseSelected;
  final String title;
  final String subtitle;

  const VersePickerBottomSheet({
    super.key,
    required this.ayahs,
    required this.currentAyahNumber,
    required this.onVerseSelected,
    required this.title,
    required this.subtitle,
  });

  static void show(
    BuildContext context, {
    required List<Ayah> ayahs,
    required int currentAyahNumber,
    required Function(int) onVerseSelected,
    String? title,
    String? subtitle,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VersePickerBottomSheet(
        ayahs: ayahs,
        currentAyahNumber: currentAyahNumber,
        onVerseSelected: onVerseSelected,
        title: title ?? l10n.versePickerTitle,
        subtitle: subtitle ?? l10n.versePickerSubtitleTest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? const Color(0xFF2A6B6F) : const Color(0xFF004B40);
    const accentGold = Color(0xFFD4AF37);
    final onSurface = isDark ? Colors.white : const Color(0xFF0F172A);
    final bgColor = isDark ? const Color(0xFF1E292B) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Islamic Pattern Background
              Positioned.fill(
                child: Opacity(
                  opacity: isDark ? 0.1 : 0.08,
                  child: Image.asset(
                    'assets/islamic_pattern_gold.png',
                    repeat: ImageRepeat.repeat,
                    scale: 2,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),

              // Decorative Accents
              Positioned(
                top: -30,
                right: -30,
                child:
                    _IslamicCircleAccent(color: primary.withValues(alpha: 0.1)),
              ),
              Positioned(
                bottom: -40,
                left: -40,
                child: _IslamicCircleAccent(
                    color: accentGold.withValues(alpha: 0.05)),
              ),

              // Content
              Column(
                children: [
                  const SizedBox(height: 12),
                  // HandleBar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.close_rounded,
                                  size: 20, color: onSurface),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Search and Grid
                  Expanded(
                    child: _PickerContent(
                      ayahs: ayahs,
                      currentAyahNumber: currentAyahNumber,
                      onVerseSelected: onVerseSelected,
                      primary: primary,
                      onSurface: onSurface,
                      accentGold: accentGold,
                      scrollController: scrollController,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PickerContent extends StatefulWidget {
  final List<Ayah> ayahs;
  final int currentAyahNumber;
  final Function(int) onVerseSelected;
  final Color primary;
  final Color onSurface;
  final Color accentGold;
  final ScrollController scrollController;

  const _PickerContent({
    required this.ayahs,
    required this.currentAyahNumber,
    required this.onVerseSelected,
    required this.primary,
    required this.onSurface,
    required this.accentGold,
    required this.scrollController,
  });

  @override
  State<_PickerContent> createState() => _PickerContentState();
}

class _PickerContentState extends State<_PickerContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredIndices = List.generate(widget.ayahs.length, (i) => i)
        .where((i) => (i + 1).toString().contains(_searchQuery))
        .toList();

    return Column(
      children: [
        // Search TextField
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: widget.primary.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.montserrat(
                color: widget.onSurface,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.versePickerSearchVerseHint,
                hintStyle: GoogleFonts.montserrat(
                  color: widget.onSurface.withValues(alpha: 0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _searchQuery.isEmpty
                      ? widget.onSurface.withValues(alpha: 0.3)
                      : widget.primary,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            size: 18,
                            color: widget.onSurface.withValues(alpha: 0.5)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: widget.onSurface.withValues(alpha: 0.04),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: widget.onSurface.withValues(alpha: 0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: widget.primary.withValues(alpha: 0.3), width: 1.5),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Grid
        Expanded(
          child: ClipRRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: filteredIndices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: widget.onSurface.withValues(alpha: 0.1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.verseSearchNoResults,
                            style: GoogleFonts.montserrat(
                              color: widget.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      key: ValueKey(
                          _searchQuery.isEmpty ? 'default' : 'filtered'),
                      controller: widget.scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: filteredIndices.length,
                      itemBuilder: (context, index) {
                        final actualIndex = filteredIndices[index];
                        final verseNumber = actualIndex + 1;
                        final isCurrent =
                            verseNumber == widget.currentAyahNumber;

                        return _VerseGridItem(
                          verseNumber: verseNumber,
                          isCurrent: isCurrent,
                          primary: widget.primary,
                          onSurface: widget.onSurface,
                          accentGold: widget.accentGold,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onVerseSelected(actualIndex);
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VerseGridItem extends StatelessWidget {
  final int verseNumber;
  final bool isCurrent;
  final Color primary;
  final Color onSurface;
  final Color accentGold;
  final VoidCallback onTap;

  const _VerseGridItem({
    required this.verseNumber,
    required this.isCurrent,
    required this.primary,
    required this.onSurface,
    required this.accentGold,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isCurrent ? primary : onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? accentGold.withValues(alpha: 0.5)
                  : onSurface.withValues(alpha: 0.08),
              width: isCurrent ? 2 : 1,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                verseNumber.toString(),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? Colors.white : onSurface,
                ),
              ),
              if (isCurrent)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IslamicCircleAccent extends StatelessWidget {
  final Color color;
  const _IslamicCircleAccent({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
