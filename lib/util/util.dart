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
