import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showSnackBar(BuildContext context, String text) {
  final snackBar = SnackBar(
    content: Text(text),
    action: SnackBarAction(
      label: 'Toh',
      onPressed: () {},
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

/// Formats a number with comma separators for better readability (e.g., 6236 -> 6,236).
String formatNumber(num number) {
  return NumberFormat('#,###').format(number);
}

/// Converts a fraction (0.0 - 1.0) into a formatted percentage string (e.g., 0.123 -> 12.3%).
String formatPercentage(double percentage, {int decimalPlaces = 1}) {
  return '${(percentage * 100).toStringAsFixed(decimalPlaces)}%';
}

/// Formats a DateTime into a human-readable string (e.g., Today, 5:45 PM or Feb 23, 2026, 5:45 PM).
String formatDateTime(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));
  final dateToCheck = DateTime(dt.year, dt.month, dt.day);

  String datePart;
  if (dateToCheck == today) {
    datePart = 'Today';
  } else if (dateToCheck == yesterday) {
    datePart = 'Yesterday';
  } else if (dateToCheck == tomorrow) {
    datePart = 'Tomorrow';
  } else {
    datePart = DateFormat('MMM d, yyyy').format(dt);
  }

  return '$datePart, ${DateFormat('h:mm a').format(dt)}';
}

/// Converts English digits (0-9) in a string to Arabic-Indic digits (٠-٩).
String toArabicIndicDigits(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  for (int i = 0; i < english.length; i++) {
    input = input.replaceAll(english[i], arabic[i]);
  }

  return input;
}
