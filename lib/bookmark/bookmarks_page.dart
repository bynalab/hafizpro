import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/bookmark.model.dart';
import 'package:hafiz_test/quran/quran_view.dart';
import 'package:hafiz_test/juz/juz_quran_view.dart';
import 'package:hafiz_test/data/juz_list.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  final _storage = getIt<IStorageService>();
  List<Bookmark> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarks = _storage.getBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          context.l10n.bookmarksTitle,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor:
            isDark ? const Color(0xFF1D353B) : const Color(0xFF78B7C6),
        foregroundColor: isDark ? Colors.white : const Color(0xFF111827),
        elevation: 0,
        centerTitle: true,
      ),
      body: _bookmarks.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              itemCount: _bookmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bookmark = _bookmarks[index];
                return _BookmarkCard(
                  bookmark: bookmark,
                  onTap: () => _navigateToBookmark(bookmark),
                  onDelete: () => _deleteBookmark(bookmark),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noBookmarksMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBookmark(Bookmark bookmark) {
    if (bookmark.viewContext == BookmarkViewContext.juz &&
        bookmark.juzNumber != null) {
      final juz = findJuzByNumber(bookmark.juzNumber!);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JuzQuranView(
            juz: juz,
            initialSurahNumber: bookmark.surah.number,
            initialAyahNumber: bookmark.ayah.numberInSurah,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuranView(
            surah: bookmark.surah,
            initialAyahNumber: bookmark.ayah.numberInSurah,
          ),
        ),
      );
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n.deleteBookmarkTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          context.l10n.deleteBookmarkMessage,
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.l10n.commonNo,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.commonYes,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.removeBookmark(
          bookmark.surah.number, bookmark.ayah.numberInSurah);
      _loadBookmarks();
    }
  }
}

class _BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkCard({
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surah = bookmark.surah;
    final ayah = bookmark.ayah;
    final isJuzContext = bookmark.viewContext == BookmarkViewContext.juz;

    String subtitle = '';
    if (isJuzContext && bookmark.juzNumber != null) {
      subtitle =
          'Juz ${bookmark.juzNumber}, ${surah.englishName}, Verse ${ayah.numberInSurah}';
    } else {
      subtitle = '${surah.englishName}, Verse ${ayah.numberInSurah}';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    (isDark ? const Color(0xFF78B7C6) : const Color(0xFF78B7C6))
                        .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 20,
                color:
                    isDark ? const Color(0xFF78B7C6) : const Color(0xFF1D353B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isJuzContext && bookmark.juzNumber != null
                        ? 'Juz ${bookmark.juzNumber}'
                        : surah.englishName,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade400,
                size: 22,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
