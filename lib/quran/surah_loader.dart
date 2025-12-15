import 'package:flutter/material.dart';
import 'package:hafiz_test/widget/quran_loader.dart';

class SurahLoader extends StatelessWidget {
  const SurahLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuranLoader(
      title: 'Loading Surah...',
      subtitle: 'جارٍ التحميل',
    );
  }
}
