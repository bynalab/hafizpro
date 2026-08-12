import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/translation.model.dart';
import 'package:hafiz_test/services/quran_db.dart';

class TranslationPickerSheet extends StatefulWidget {
  final String? selected;

  const TranslationPickerSheet({
    super.key,
    required this.selected,
  });

  Future<TranslationInfo?> openBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<TranslationInfo>(
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
  State<TranslationPickerSheet> createState() => _TranslationPickerSheetState();
}

class _TranslationPickerSheetState extends State<TranslationPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  List<TranslationInfo> _translations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    try {
      if (!getIt.isRegistered<QuranDb>()) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final db = getIt<QuranDb>();
      final translations = await db.getTranslations();
      if (mounted) {
        setState(() {
          _translations = translations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  List<TranslationInfo> searchTranslations(String query) {
    if (query.isEmpty) return _translations;

    return _translations.where((t) {
      final a = t.name.toLowerCase();
      final b = t.language.toLowerCase();
      return a.contains(query) || b.contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;
    final query = _query.trim().toLowerCase();
    final filtered = searchTranslations(query);

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
                      'Select Translation', // Fallback, will use l10n below if possible
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
                    hintText: 'Search translations',
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark ? const Color(0xFF2A2A2A) : null,
                          ),
                          itemBuilder: (context, index) {
                            final translation = filtered[index];
                            final isSelected =
                                translation.id == widget.selected;

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
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      translation.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2F1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      translation.language.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF00695C),
                                      ),
                                    ),
                                  ),
                                ],
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
                              onTap: () => Navigator.pop(context, translation),
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
