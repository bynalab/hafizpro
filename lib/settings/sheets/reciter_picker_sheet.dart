import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/reciters.dart';
import 'package:hafiz_test/model/reciter.model.dart';

class ReciterPickerSheet extends StatefulWidget {
  final String? selected;

  const ReciterPickerSheet({super.key, required this.selected});

  Future<Reciter?> openBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<Reciter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => this,
    );
  }

  @override
  State<ReciterPickerSheet> createState() => _ReciterPickerSheetState();
}

class _ReciterPickerSheetState extends State<ReciterPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final text = _searchController.text;
    if (text == _query) return;
    setState(() => _query = text);
  }

  List<Reciter> searchReciters(String query) {
    final filtered = query.isEmpty
        ? reciters
        : reciters.where((r) {
            final a = r.englishName.toLowerCase();
            final b = r.name.toLowerCase();
            final c = r.identifier.toLowerCase();
            return a.contains(query) || b.contains(query) || c.contains(query);
          }).toList(growable: false);

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final query = _query.trim().toLowerCase();
    final filtered = searchReciters(query);

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Select Reciter',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search reciters...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? const Color(0xFF9CA3AF) : null,
                    ),
                    suffixIcon: _query.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => _searchController.clear(),
                            icon: Icon(
                              Icons.close,
                              color: isDark ? const Color(0xFF9CA3AF) : null,
                            ),
                          ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF2F2F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? const Color(0xFF2A2A2A) : null,
                    ),
                    itemBuilder: (context, index) {
                      final reciter = filtered[index];
                      final isSelected = reciter.identifier == widget.selected;
                      final arabicName = reciter.name != reciter.englishName
                          ? reciter.name
                          : '';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFF2F2F2),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          reciter.englishName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF111827),
                          ),
                        ),
                        subtitle: arabicName.isEmpty
                            ? null
                            : Text(
                                arabicName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF58667B),
                                ),
                              ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF205B5F),
                              )
                            : Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF9CA3AF),
                              ),
                        onTap: () => Navigator.pop(context, reciter),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
