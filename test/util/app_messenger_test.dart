import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hafiz_test/util/app_messenger.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  testWidgets('AppMessenger.showLoopToast displays floating snackbar toast',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () =>
                    AppMessenger.showLoopToast(context, LoopMode.all),
                child: const Text('Toast'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Toast'));
    await tester.pump();

    expect(find.text('Repeat entire surah'), findsOneWidget);
  });
}
