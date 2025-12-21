import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hafiz_test/data/reciters.dart';
import 'package:hafiz_test/extension/collection.dart';
import 'package:hafiz_test/services/analytics_service.dart';
import 'package:hafiz_test/services/rating_service.dart';
import 'package:hafiz_test/util/app_colors.dart';
import 'package:hafiz_test/settings/settings_controller.dart';
import 'package:hafiz_test/settings/sheets/notifications_sheet.dart';
import 'package:hafiz_test/settings/sheets/reciter_picker_sheet.dart';
import 'package:hafiz_test/settings/widgets/leading_circle.dart';
import 'package:hafiz_test/settings/widgets/settings_tile.dart';
import 'package:hafiz_test/widget/quran_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController controller = SettingsController();

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
        _showErrorSnackBar('Error launching URL: $url. Error: $e');
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

  Future<void> _showInAppRating() async {
    try {
      AnalyticsService.trackEvent('Settings Rating Clicked');
      await RatingService.showRatingDialog(context);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error opening rating dialog: $e');
      }
    }
  }

  String get notificationSubtitle {
    if (controller.notificationsEnabled) {
      return 'Notification time: ${controller.notificationTime.format(context)}';
    }

    return 'Set your Notification preference';
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
          'Settings',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        leadingWidth: 62,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE5E7EB),
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
      body: controller.isLoading
          ? const QuranLoader(
              title: 'Loading Settings...',
              subtitle: 'جارٍ التحميل',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                children: [
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/autoplay.png',
                    ),
                    title: 'Auto Play Verse',
                    subtitle: 'Autoplay the verses as your test begins',
                    trailing: Switch(
                      value: controller.autoPlay,
                      onChanged: controller.setAutoPlay,
                      activeTrackColor: AppColors.green500,
                      activeColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/hand_megaphone.png',
                    ),
                    title: 'Select Reciter',
                    subtitle: reciterName ?? 'Select your favorite reciter',
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () async {
                      final selected = await ReciterPickerSheet(
                        selected: controller.reciter,
                      ).openBottomSheet(context);
                      if (selected == null) return;
                      await controller.setReciter(selected.identifier);
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/notification_bell.png',
                    ),
                    title: 'Notifications',
                    subtitle: notificationSubtitle,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () async {
                      final result = await NotificationsSheet(
                        initialEnabled: controller.notificationsEnabled,
                        initialTime: controller.notificationTime,
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
                          ..showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/bug_report.png',
                    ),
                    title: 'Report Bug or Request Feature',
                    subtitle: 'Talk to us',
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/web_icon.png',
                    ),
                    title: 'Official Website',
                    subtitle: 'Check Out our website',
                    trailing: Icon(
                      Icons.open_in_new,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () {
                      _launchInBrowser(
                        'https://hafizpro.com',
                        'Website',
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle.asset(
                      'assets/icons/community_icon.png',
                    ),
                    title: 'Join our community',
                    subtitle: 'Join discussions and get help',
                    trailing: Icon(
                      Icons.open_in_new,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: () {
                      _launchInBrowser(
                        'https://whatsapp.com/channel/0029Vb7FCqkFHWpx566byH0Y',
                        'WhatsApp Channel',
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SettingsTile(
                    leading: const LeadingCircle(Icons.star_rate_rounded),
                    title: 'Rate Us',
                    subtitle: 'Leave a 5 star review on your app store',
                    trailing: Icon(
                      Icons.open_in_new,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    onTap: _showInAppRating,
                  ),
                ],
              ),
            ),
    );
  }
}
