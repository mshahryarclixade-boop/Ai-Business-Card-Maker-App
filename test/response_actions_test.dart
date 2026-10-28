import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_business_card_maker/app/core/widgets/response_actions.dart';

void main() {
  testWidgets('Copy puts the whole response on the clipboard and confirms', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponseActions(id: 'a', text: 'The full answer.', conversation: () => 'You: hi\n\nClixa: The full answer.'),
        ),
      ),
    );
    expect(find.byIcon(Icons.content_copy_outlined), findsOneWidget);
    expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.content_copy_outlined));
    await tester.pump();
    expect(copied, 'The full answer.');
    expect(find.byIcon(Icons.check_rounded), findsOneWidget, reason: 'the icon confirms the copy');

    await tester.pump(const Duration(seconds: 3));
    expect(find.byIcon(Icons.content_copy_outlined), findsOneWidget, reason: 'and goes back');
  });

  testWidgets('response text can be selected (long-press) in a SelectableText', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SelectableText('Select me'))));
    await tester.longPress(find.text('Select me'));
    await tester.pump();
    expect(find.byType(SelectableText), findsOneWidget);
  });
}
