import 'package:flutter/material.dart';

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
}
