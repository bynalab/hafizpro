import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';
import 'package:hafiz_test/data/reciters.dart';
import 'package:hafiz_test/extension/collection.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/main.dart';
import 'package:hafiz_test/model/reciter.model.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/widget/button.dart';
import 'package:hafiz_test/util/theme_controller.dart';
import 'package:hafiz_test/util/rating_debug.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hafiz_test/services/rating_service.dart';
import 'package:hafiz_test/widget/searchable_dropdown.dart';
import 'package:hafiz_test/widget/link_button.dart';

class SettingDialog extends StatefulWidget {
  const SettingDialog({super.key});

  @override
  State<SettingDialog> createState() => _SettingDialogState();
}

class _SettingDialogState extends State<SettingDialog> {
  final storageServices = getIt<IStorageService>();
  final themeController = getIt<ThemeController>();

  bool autoPlay = true;
  bool isLoading = true;

  String? reciter;
  late ThemeMode themeMode;
  String language = 'en';

  void init() {
    try {
      autoPlay = storageServices.checkAutoPlay();
      reciter = storageServices.getReciter();
      themeMode = ThemeMode.values.byName(themeController.mode);
      language = storageServices.getString('language') ?? 'en';
    } catch (e) {
      debugPrint('Error $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    // Track settings dialog opened
    AnalyticsService.trackScreenView('Settings Dialog');

    init();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.settings,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    child: Icon(
                      Icons.close,
                      size: 30,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                    onTap: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator.adaptive())
              else ...[
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.autoplayVerse,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Switch(
                          value: autoPlay,
                          onChanged: (_) {
                            final oldValue = autoPlay;
                            setState(() => autoPlay = !autoPlay);
                            AnalyticsService.trackSettingsChanged(
                                'autoplay', oldValue, !oldValue);
                          },
                          activeTrackColor:
                              Theme.of(context).colorScheme.primary,
                          activeColor: Colors.white,
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.theme,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: DropdownButton<ThemeMode>(
                            value: themeMode,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text(context.l10n.themeSystem),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text(context.l10n.themeLight),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text(context.l10n.themeDark),
                              ),
                            ],
                            onChanged: (mode) {
                              if (mode == null) return;
                              final oldValue = themeMode;
                              setState(() => themeMode = mode);
                              AnalyticsService.trackSettingsChanged(
                                  'theme', oldValue.name, mode.name);
                            },
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.language,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: DropdownButton<String>(
                            value: language,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: 'en',
                                child: Text(context.l10n.languageEnglish),
                              ),
                              DropdownMenuItem(
                                value: 'ar',
                                child: Text(context.l10n.languageArabic),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              final oldValue = language;
                              setState(() => language = value);
                              AnalyticsService.trackSettingsChanged(
                                  'language', oldValue, value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Text(
                  context.l10n.selectFavoriteReciter,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SearchableDropdown<Reciter>(
                  items: reciters,
                  selectedItem: reciters.firstWhereOrNull(
                    (reciter) => reciter.identifier == this.reciter,
                  ),
                  getDisplayText: (reciter) => reciter.englishName,
                  getSubText: (reciter) =>
                      reciter.name != reciter.englishName ? reciter.name : '',
                  getItemId: (reciter) => reciter.identifier,
                  hintText: context.l10n.selectFavoriteReciter,
                  searchHint: context.l10n.searchReciters,
                  onChanged: (selectedReciter) {
                    final oldValue = reciter;
                    setState(() {
                      reciter = selectedReciter?.identifier;
                    });

                    AnalyticsService.trackSettingsChanged(
                      'reciter',
                      oldValue,
                      selectedReciter?.identifier,
                    );
                  },
                ),
                const SizedBox(height: 20),
                LinkButton(
                  icon: Icons.language,
                  title: context.l10n.visitWebsite,
                  onTap: () {
                    launchInBrowser(context, 'https://hafizpro.com', 'Website');
                  },
                ),
                const SizedBox(height: 12),
                LinkButton(
                  icon: Icons.chat,
                  title: context.l10n.joinWhatsappChannel,
                  onTap: () {
                    launchInBrowser(
                      context,
                      'https://whatsapp.com/channel/0029Vb7FCqkFHWpx566byH0Y',
                      'WhatsApp Channel',
                    );
                  },
                ),
                const SizedBox(height: 12),
                LinkButton(
                  icon: Icons.group,
                  title: context.l10n.whatsappFeedbackGroup,
                  onTap: () {
                    launchInBrowser(
                      context,
                      'https://chat.whatsapp.com/EuF6FS3qL9TElJSNQBHEdp',
                      'WhatsApp Feedback Group',
                    );
                  },
                ),
                const SizedBox(height: 12),
                LinkButton(
                  icon: Icons.star_rate,
                  title: context.l10n.rateThisApp,
                  onTap: () => _showInAppRating(context),
                ),
                const SizedBox(height: 20),
                if (kDebugMode) ...[
                  // Debug button for rating system (remove in production)
                  Button(
                    height: 32,
                    color: Colors.orange,
                    child: Text(
                      context.l10n.debugRatingSystem,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const RatingDebugDialog(),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                Button(
                  height: 36,
                  color: Theme.of(context).colorScheme.primary,
                  child: Text(
                    context.l10n.save,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  onPressed: () {
                    AnalyticsService.trackEvent('Settings Saved', properties: {
                      'autoplay': autoPlay,
                      'theme': themeMode.name,
                      'reciter': reciter ?? 'none',
                      'language': language,
                    });
                    storageServices.setAutoPlay(autoPlay);
                    storageServices.setReciter(reciter ?? '');
                    themeController.setMode(themeMode.name);
                    quranHafizKey.currentState?.setLocale(Locale(language));
                    storageServices.setString('language', language);
                    Navigator.pop(context);
                  },
                )
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> launchInBrowser(
      BuildContext context, String url, String linkName) async {
    try {
      // Track link click
      AnalyticsService.trackEvent('Website Link Clicked', properties: {
        'link_name': linkName,
        'link_url': url,
      });

      final Uri uri = Uri.parse(url);

      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        debugPrint('Failed to launch $url');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          context.l10n.errorLaunchingUrl(url, e.toString()),
        );
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _showInAppRating(BuildContext context) async {
    try {
      // Track rating button click
      AnalyticsService.trackEvent('Settings Rating Clicked');

      // Show the in-app rating dialog
      await RatingService.showRatingDialog(context);
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          context.l10n.errorOpeningRatingDialog(e.toString()),
        );
      }
    }
  }
}
