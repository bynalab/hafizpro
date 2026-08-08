import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/reciters.dart';
import 'package:hafiz_test/extension/collection.dart';
import 'package:hafiz_test/locator.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/services/rating_service.dart';
import 'package:hafiz_test/services/storage/abstract_storage_service.dart';
import 'package:hafiz_test/settings/settings_controller.dart';
import 'package:hafiz_test/settings/sheets/notifications_sheet.dart';
import 'package:hafiz_test/settings/sheets/progress_tracking_sheet.dart';
import 'package:hafiz_test/settings/sheets/reciter_picker_sheet.dart';
import 'package:hafiz_test/settings/widgets/leading_circle.dart';
import 'package:hafiz_test/settings/widgets/settings_tile.dart';
import 'package:hafiz_test/settings/sheets/translation_picker_sheet.dart';
import 'package:hafiz_test/model/translation.model.dart';
import 'package:hafiz_test/services/quran_db.dart';
import 'package:hafiz_test/main_menu/download_manager_screen.dart';
import 'package:hafiz_test/l10n/app_localizations.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';
import 'package:hafiz_test/util/locale_notifier.dart';
import 'package:hafiz_test/widget/app_switch.dart';
import 'package:hafiz_test/widget/quran_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController controller = SettingsController();

  static const String _whatsAppFeedbackGroupUrl =
      'https://chat.whatsapp.com/EuF6FS3qL9TElJSNQBHEdp';
  static const String _whatsAppReciterPromptShownKey =
      'whatsapp_reciter_prompt_shown';

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    AnalyticsService.trackScreenView('Settings');
    controller.addListener(_onControllerChanged);
    controller.load();
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }

  Future<void> _launchInBrowser(String url, String linkName) async {
    try {
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
      if (mounted) {
        _showErrorSnackBar(
          context.l10n.errorLaunchingUrl(url, e.toString()),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _maybeShowReciterWhatsAppPrompt({
    required String? previousReciterId,
    required String selectedReciterId,
  }) async {
    final storage = getIt<IStorageService>();
    final alreadyShown =
        (storage.getString(_whatsAppReciterPromptShownKey) ?? 'false') ==
            'true';
    if (alreadyShown) return;

    if (selectedReciterId == 'ar.alafasy') return;
    if (previousReciterId != null && previousReciterId != 'ar.alafasy') {
      return;
    }

    if (!mounted) return;

    AnalyticsService.trackEvent('Reciter WhatsApp Prompt Shown', properties: {
      'previous_reciter_id': previousReciterId,
      'selected_reciter_id': selectedReciterId,
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.reciterWhatsAppPromptTitle),
          content: Text(context.l10n.reciterWhatsAppPromptBody),
          actions: [
            TextButton(
              onPressed: () {
                AnalyticsService.trackEvent(
                  'Reciter WhatsApp Prompt Dismissed',
                );
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.reciterWhatsAppNotNow),
            ),
            ElevatedButton(
              onPressed: () {
                AnalyticsService.trackEvent(
                  'Reciter WhatsApp Prompt Join Clicked',
                );
                Navigator.of(context).pop();
                _launchInBrowser(
                  _whatsAppFeedbackGroupUrl,
                  context.l10n.whatsappFeedbackGroup,
                );
              },
              child: Text(context.l10n.reciterWhatsAppJoinGroup),
            ),
          ],
        );
      },
    );

    await storage.setString(_whatsAppReciterPromptShownKey, 'true');
  }

  Future<void> _showInAppRating() async {
    try {
      AnalyticsService.trackEvent('Settings Rating Clicked');
      await RatingService.showRatingDialog(context);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.errorOpeningRatingDialog(e.toString()));
      }
    }
  }

  String get notificationSubtitle {
    if (controller.notificationsEnabled) {
      return context.l10n.notificationSubtitleEnabled(
          controller.notificationTime.format(context));
    }

    return context.l10n.notificationSubtitleDisabled;
  }

  String _progressTrackingModeLabel(String mode) {
    final l = context.l10n;
    switch (mode) {
      case 'smart':
        return l.progressTrackingSmartTitle;
      case 'manual':
        return l.progressTrackingManualTitle;
      case 'off':
        return l.progressTrackingOffTitle;
      default:
        return mode;
    }
  }

  String _languageSubtitleForCode(AppLocalizations l10n, String code) {
    switch (code) {
      case 'ar':
        return l10n.languageArabic;
      case 'ru':
        return l10n.languageRussian;
      case 'de':
        return l10n.languageGerman;
      default:
        return l10n.languageEnglish;
    }
  }

  Future<void> _pickLanguage() async {
    final storage = getIt<IStorageService>();
    final current = Localizations.localeOf(context).languageCode;

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: Text(
                  context.l10n.languageSelectTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                title: Text(context.l10n.languageEnglish),
                trailing: current == 'en' ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop('en'),
              ),
              ListTile(
                title: Text(context.l10n.languageArabic),
                trailing: current == 'ar' ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop('ar'),
              ),
              ListTile(
                title: Text(context.l10n.languageRussian),
                trailing: current == 'ru' ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop('ru'),
              ),
              ListTile(
                title: Text(context.l10n.languageGerman),
                trailing: current == 'de' ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop('de'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    await storage.setString('language', selected);
    appLocale.value = Locale(selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reciterName = reciters
        .firstWhereOrNull((r) => r.identifier == controller.reciter)
        ?.englishName;

    return Scaffold(
      backgroundColor:
          isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F2),
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.l10n.settings,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        leadingWidth: 62,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: controller.isLoading
          ? QuranLoader(
              title: context.l10n.settingsLoadingTitle,
              subtitle: context.l10n.commonLoadingSubtitle,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                children: [
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/autoplay.png',
                    ),
                    title: context.l10n.settingsAutoPlayTitle,
                    subtitle: context.l10n.settingsAutoPlaySubtitle,
                    trailing: AppSwitch(
                      value: controller.autoPlay,
                      onChanged: controller.setAutoPlay,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/hand_megaphone.png',
                    ),
                    title: context.l10n.settingsSelectReciterTitle,
                    subtitle: reciterName ?? context.l10n.selectFavoriteReciter,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () async {
                      final previous = controller.reciter;
                      final selected = await ReciterPickerSheet(
                        selected: controller.reciter,
                      ).openBottomSheet(context);
                      if (selected == null) return;
                      await controller.setReciter(selected.identifier);

                      await _maybeShowReciterWhatsAppPrompt(
                        previousReciterId: previous,
                        selectedReciterId: selected.identifier,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading:
                        const LeadingCircle(Icons.download_for_offline_rounded),
                    title: context.l10n.audioDownloadsTitle,
                    subtitle: context.l10n.audioDownloadsSubtitle,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DownloadManagerScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle(Icons.language_rounded),
                    title: context.l10n.language,
                    subtitle: _languageSubtitleForCode(
                      context.l10n,
                      Localizations.localeOf(context).languageCode,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: _pickLanguage,
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<TranslationInfo?>(
                    future: getIt.isRegistered<QuranDb>()
                        ? getIt<QuranDb>().getTranslation(controller.translationId)
                        : Future.value(null),
                    builder: (context, snapshot) {
                      final subtitleName = snapshot.data?.name ?? controller.translationId;

                      return SettingsTile(
                        leading: const LeadingCircle(Icons.translate_rounded),
                        title: 'Translation',
                        subtitle: subtitleName,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        onTap: () async {
                          final selected = await TranslationPickerSheet(
                            selected: controller.translationId,
                          ).openBottomSheet(context);
                          if (selected != null) {
                            await controller.setTranslationId(selected.id);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle(Icons.track_changes_rounded),
                    title: context.l10n.progressTrackingTitle,
                    subtitle: _progressTrackingModeLabel(
                        controller.progressTrackingMode),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () async {
                      final selected = await ProgressTrackingSheet(
                        initialMode: controller.progressTrackingMode,
                        isDark: isDark,
                      ).openBottomSheet(context);
                      if (selected != null) {
                        await controller.setProgressTrackingMode(selected);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/notification_bell.png',
                    ),
                    title: context.l10n.notifications,
                    subtitle: notificationSubtitle,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () async {
                      final result = await NotificationsSheet(
                        initialEnabled: controller.notificationsEnabled,
                        initialTime: controller.notificationTime,
                        onTestNotification: controller.testNotification,
                      ).openBottomSheet(context);
                      if (result == null) return;
                      try {
                        await controller.setNotifications(
                          enabled: result.enabled,
                          time: result.time,
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.notificationsUpdateError(
                                  e.toString(),
                                ),
                              ),
                            ),
                          );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/bug_report.png',
                    ),
                    title: context.l10n.settingsReportBugTitle,
                    subtitle: context.l10n.settingsReportBugSubtitle,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () {
                      _launchInBrowser(
                        _whatsAppFeedbackGroupUrl,
                        context.l10n.whatsappFeedbackGroup,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/web_icon.png',
                    ),
                    title: context.l10n.settingsOfficialWebsiteTitle,
                    subtitle: context.l10n.settingsOfficialWebsiteSubtitle,
                    trailing: Icon(
                      Icons.open_in_new,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () {
                      _launchInBrowser(
                        'https://hafizpro.com',
                        context.l10n.settingsLinkWebsite,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/community_icon.png',
                    ),
                    title: context.l10n.settingsJoinCommunityTitle,
                    subtitle: context.l10n.settingsJoinCommunitySubtitle,
                    trailing: Icon(
                      Icons.open_in_new,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () {
                      _launchInBrowser(
                        'https://whatsapp.com/channel/0029Vb7FCqkFHWpx566byH0Y',
                        context.l10n.settingsLinkWhatsAppChannel,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle(Icons.star_rate_rounded),
                    title: context.l10n.settingsRateUsTitle,
                    subtitle: context.l10n.settingsRateUsSubtitle,
                    trailing: Icon(
                      Icons.open_in_new,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: _showInAppRating,
                  ),
                  const SizedBox(height: 10),
                  if (controller.appVersion.isNotEmpty) ...[
                    Text(
                      'v${controller.appVersion}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
