import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/reciters.dart';
import 'package:hafiz_test/data/surah_list.dart';
import 'package:hafiz_test/extension/collection.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/model/surah.model.dart';
import 'package:hafiz_test/services/audio_download_service.dart';
import 'package:hafiz_test/services/network.services.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/surah_source.dart';
import 'package:hafiz_test/services/tarteel_audio_resolver.dart';
import 'package:hafiz_test/settings/sheets/reciter_picker_sheet.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

class DownloadManagerScreen extends StatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  State<DownloadManagerScreen> createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends State<DownloadManagerScreen> {
  final AudioDownloadService _downloadService = getIt<AudioDownloadService>();
  final IStorageService _storage = getIt<IStorageService>();
  final NetworkServices _networkServices = getIt<NetworkServices>();
  final SurahSource _surahSource = getIt<SurahSource>();

  late String _selectedReciterId;
  TarteelSelection? _currentSelection;
  bool _isLoadingSelection = false;
  final Set<int> _deletingSurahs = {};
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  final Map<int, bool> _downloadedStatus = {};

  @override
  void initState() {
    super.initState();
    _selectedReciterId = _storage.getReciterId();
    _resolveReciterSelection();
    _downloadService.downloadProgress.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    _downloadService.downloadProgress.removeListener(_onProgressChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onProgressChanged() {
    _refreshDownloadStatus();
  }

  Future<void> _refreshDownloadStatus() async {
    if (_currentSelection == null) return;
    
    final tempMap = <int, bool>{};
    final futures = surahList.map((surah) async {
      final isDownloaded = await _downloadService.isSurahDownloaded(
        surah.number,
        _selectedReciterId,
        _currentSelection!,
        surah,
      );
      tempMap[surah.number] = isDownloaded;
    });
    
    await Future.wait(futures);
    
    if (mounted) {
      setState(() {
        _downloadedStatus.clear();
        _downloadedStatus.addAll(tempMap);
      });
    }
  }

  Future<void> _resolveReciterSelection() async {
    setState(() => _isLoadingSelection = true);
    _currentSelection = await TarteelAudioResolver.resolve(
      networkServices: _networkServices,
      reciterId: _selectedReciterId,
      surahNumber: 1, // Just use Fatiha to resolve the base format
      checkNetwork: false,
    );
    if (mounted) {
      setState(() => _isLoadingSelection = false);
      _refreshDownloadStatus();
    }
  }

  Future<void> _pickReciter() async {
    final selected = await ReciterPickerSheet(
      selected: _selectedReciterId,
    ).openBottomSheet(context);

    if (selected != null && selected.identifier != _selectedReciterId) {
      setState(() {
        _selectedReciterId = selected.identifier;
      });
      _resolveReciterSelection();
    }
  }

  Future<void> _downloadSurah(Surah baseSurah) async {
    if (_currentSelection == null) return;

    final fullSurah = await _surahSource.getSurah(baseSurah.number);

    await _downloadService.downloadSurah(
      surahNumber: fullSurah.number,
      reciterId: _selectedReciterId,
      selection: _currentSelection!,
      surah: fullSurah,
    );
    _refreshDownloadStatus();
  }

  Future<void> _deleteSurah(Surah baseSurah) async {
    if (_currentSelection == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161C1A) : const Color(0xFFF4F7F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.deleteDownload,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF003028),
          ),
        ),
        content: Text(
          context.l10n.deleteDownloadConfirm(baseSurah.englishName),
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF556660),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.l10n.commonCancel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white38 : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.l10n.commonYes,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    setState(() {
      _deletingSurahs.add(baseSurah.number);
    });

    try {
      final fullSurah = await _surahSource.getSurah(baseSurah.number);
      await _downloadService.deleteSurah(
          baseSurah.number, _selectedReciterId, _currentSelection!, fullSurah);
      _refreshDownloadStatus();
    } finally {
      if (mounted) {
        setState(() {
          _deletingSurahs.remove(baseSurah.number);
        });
      }
    }
  }

  Widget _buildSurahTile(Surah surah) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = theme.colorScheme.primary;
    const goldAccent = Color(0xFFD4AF37);

    final isDownloaded = _downloadedStatus[surah.number] ?? false;

    return ValueListenableBuilder<Map<String, double>>(
      valueListenable: _downloadService.downloadProgress,
          builder: (context, progressMap, _) {
            final key = '${surah.number}_$_selectedReciterId';
            final progress = progressMap[key];
            final isDownloading = progress != null;
            final isDeleting = _deletingSurahs.contains(surah.number);

            // Card backgrounds and borders optimized for zero drawing-lag
            final cardBg = isDark ? const Color(0xFF131716) : Colors.white;
            final cardBorder = isDark
                ? (isDownloaded
                    ? primaryAccent.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.05))
                : (isDownloaded
                    ? primaryAccent.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.03));

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cardBorder,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Modern 8-Pointed Star (Rub el Hizb ۞) Index Badge
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: 0.785398, // 45 degrees
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDownloaded
                                  ? primaryAccent.withValues(alpha: 0.1)
                                  : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDownloaded
                                    ? goldAccent.withValues(alpha: 0.4)
                                    : (isDark ? Colors.white12 : Colors.black12),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${surah.number}',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDownloaded
                                ? primaryAccent
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Surah Text & Progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            surah.englishName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isDownloading) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: isDark
                                          ? Colors.grey[850]
                                          : Colors.grey[200],
                                      color: primaryAccent,
                                      minHeight: 5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (isDownloaded) ...[
                            // Ready Offline Badge Pill
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 12, color: primaryAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        context.l10n.readyOffline,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: primaryAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              context.l10n.notDownloaded,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Actions Button Trigger
                    if (isDownloading)
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 28),
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: isDark ? const Color(0xFF161C1A) : const Color(0xFFF4F7F6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text(context.l10n.cancelDownloadTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                              content: Text(context.l10n.cancelDownloadConfirm(surah.englishName)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(context.l10n.dialogNo, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[600], fontWeight: FontWeight.bold)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(context.l10n.dialogYesCancel, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          if (_currentSelection == null) return;
                          final fullSurah = await _surahSource.getSurah(surah.number);
                          await _downloadService.cancelDownload(
                            surah.number,
                            _selectedReciterId,
                            _currentSelection!,
                            fullSurah,
                          );
                          if (mounted) setState(() {});
                        },
                      )
                    else if (isDownloaded)
                      (isDeleting
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 26),
                              color: Colors.redAccent.withValues(alpha: 0.8),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _deleteSurah(surah),
                            ))
                    else
                      IconButton(
                        icon: Icon(Icons.arrow_circle_down_rounded, size: 28, color: primaryAccent),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _downloadSurah(surah),
                      ),
                  ],
                ),
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = theme.colorScheme.primary;
    const goldAccent = Color(0xFFD4AF37);

    final reciterName = reciters
            .firstWhereOrNull((r) => r.identifier == _selectedReciterId)
            ?.englishName ??
        'Select Reciter';

    // Premium Islamic themed canvas
    final canvasBgColor = isDark ? const Color(0xFF0E1211) : const Color(0xFFF7FAF9);

    return Scaffold(
      backgroundColor: canvasBgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF131716) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: _isSearching
            ? Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2220) : const Color(0xFFEFF3F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? primaryAccent.withValues(alpha: 0.1) : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      hintText: context.l10n.searchSurahHint,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white30 : Colors.black38,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: isDark ? Colors.white60 : Colors.black54, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              )
            : Text(
                context.l10n.offlineDownloads,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF003028),
                ),
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : Colors.black54),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: Icon(Icons.search_rounded, color: primaryAccent),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          const SizedBox(width: 12),
        ],
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () {
                if (_isSearching) {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2220) : const Color(0xFFEFF3F1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Breathtaking Islamic-styled Reciter Picker Header Panel
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131716) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? primaryAccent.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _pickReciter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Royal 8-pointed star ornament (۞) for selector
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: 0.785398,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: goldAccent.withValues(alpha: 0.4), width: 1.2),
                            ),
                          ),
                        ),
                        Icon(Icons.mic_external_on_rounded, size: 20, color: primaryAccent),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Reciter Profile',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reciterName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.unfold_more_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          
          // Surah List Label with Elegant Geometric Accents
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                Transform.rotate(
                  angle: 0.785398,
                  child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: goldAccent)),
                ),
                const SizedBox(width: 10),
                Text(
                  'QURAN AUDIO PLAYLISTS',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Main List
          Expanded(
            child: _isLoadingSelection
                ? const Center(child: CircularProgressIndicator())
                : (() {
                    final filteredSurahs = surahList.where((surah) {
                      final query = _searchQuery.toLowerCase().trim();
                      if (query.isEmpty) return true;
                      return surah.number.toString() == query ||
                          surah.englishName.toLowerCase().contains(query);
                    }).toList();

                    if (filteredSurahs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Surahs Found',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filteredSurahs.length,
                      itemBuilder: (context, index) {
                        return _buildSurahTile(filteredSurahs[index]);
                      },
                    );
                  }()),
          ),
        ],
      ),
    );
  }
}
