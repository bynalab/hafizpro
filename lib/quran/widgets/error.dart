import 'package:flutter/material.dart';
import 'package:hafiz_test/widget/button.dart';
import 'package:hafiz_test/util/l10n_extensions.dart';

class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData icon;
  final Color color;
  final String title;

  const CustomErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.icon = Icons.error_outline_rounded,
    this.color = const Color(0xFFDC3545),
    this.title = 'Oops!',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Button(
              onPressed: onRetry,
              child: Text(
                context.l10n.errorRetryButton,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              Button(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryActionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
