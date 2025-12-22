import 'package:flutter/material.dart';
import 'package:hafiz_test/widget/quran_loader.dart';

class SurahLoader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SurahLoader({
    super.key,
    this.title = 'Loading Surah...',
    this.subtitle = 'جارٍ التحميل',
  });

  @override
  Widget build(BuildContext context) {
    return QuranLoader(
      title: title,
      subtitle: subtitle,
    );
  }
}
