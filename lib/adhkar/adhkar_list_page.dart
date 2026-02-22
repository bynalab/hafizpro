import 'package:adhkar/adhkar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/widget/star_burst_icon.dart';
import 'package:hafiz_test/adhkar/adhkar_detail_page.dart';

class AdhkarListPage extends StatelessWidget {
  final Adhkar adhkarCategory;

  const AdhkarListPage({super.key, required this.adhkarCategory});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0B0B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    final items = adhkarCategory.adhkars;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          adhkarCategory.title,
          style: GoogleFonts.outfit(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              // Use translation as title, truncated
              String displayTitle = item.translationText;
              if (displayTitle.length > 60) {
                displayTitle = '${displayTitle.substring(0, 60)}...';
              }

              return _AdhkarListTile(
                index: index + 1,
                title: displayTitle,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        return AdhkarDetailPage(
                          title: adhkarCategory.title,
                          item: item,
                          count: index + 1,
                          total: items.length,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),

          // Bottom Play Button
          // Positioned(
          //   bottom: 30,
          //   left: 0,
          //   right: 0,
          //   child: Center(
          //     child: Container(
          //       height: 48,
          //       width: 140,
          //       decoration: BoxDecoration(
          //         color: const Color(0xFF2FA2B1),
          //         borderRadius: BorderRadius.circular(24),
          //         boxShadow: [
          //           BoxShadow(
          //             color: const Color(0xFF2FA2B1).withValues(alpha: 0.3),
          //             blurRadius: 10,
          //             offset: const Offset(0, 4),
          //           ),
          //         ],
          //       ),
          //       child: Material(
          //         color: Colors.transparent,
          //         child: InkWell(
          //           onTap: () {},
          //           borderRadius: BorderRadius.circular(24),
          //           child: Row(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: [
          //               const Icon(Icons.play_arrow_rounded,
          //                   color: Colors.white),
          //               const SizedBox(width: 8),
          //               Text(
          //                 'Play All',
          //                 style: GoogleFonts.inter(
          //                   color: Colors.white,
          //                   fontWeight: FontWeight.w600,
          //                   fontSize: 14,
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _AdhkarListTile extends StatelessWidget {
  final int index;
  final String title;
  final bool isDark;
  final VoidCallback onTap;

  const _AdhkarListTile({
    required this.index,
    required this.title,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final bg = isDark ? const Color(0xFF141414) : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            StarburstIcon(text: '$index'),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15, // Slightly larger
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
