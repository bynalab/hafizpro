import 'package:flutter/material.dart';
import 'package:hafiz_test/l10n/app_localizations.dart';

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppMessenger {
  static void showSnackBar(String message) {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Resolves the message using [AppLocalizations] from the scaffold context.
  static void showLocalizedSnackBar(
    String Function(AppLocalizations l10n) message,
  ) {
    final ctx = appScaffoldMessengerKey.currentContext;
    if (ctx == null) return;
    final l10n = AppLocalizations.of(ctx);
    if (l10n == null) return;
    showSnackBar(message(l10n));
  }
}
