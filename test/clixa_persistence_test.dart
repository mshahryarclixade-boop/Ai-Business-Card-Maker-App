import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:ai_business_card_maker/app/modules/clixa/controller/clixa_controller.dart';
import 'package:ai_business_card_maker/app/modules/clixa/model/clixa_models.dart';
import 'package:ai_business_card_maker/app/modules/clixa/service/clixa_chat_store.dart';

/// A fresh controller, as after an app restart: it loads what was saved.
ClixaController restarted() => ClixaController()..onInit();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('clixa_store').path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir,
        );
    await GetStorage.init();
    ClixaChatStore.enabled = true;
  });

  tearDownAll(() => ClixaChatStore.enabled = false);

  setUp(() async {
    await GetStorage().erase();
  });

  test('a chat and its messages survive a restart', () async {
    final c = ClixaController()..onInit();
    final chat = c.startChat(ClixaMode.discuss);
    await c.send(chat, 'I want to start a small online store');

    final after = restarted();
    expect(after.chats.length, 1);
    final back = after.chats.single;
    expect(back.id, chat.id);
    expect(back.mode, ClixaMode.discuss);
    expect(back.title.value, chat.title.value);
    expect(back.messages.length, chat.messages.length);
    expect(
      [for (final m in back.messages) (m.fromUser, m.text)],
      [for (final m in chat.messages) (m.fromUser, m.text)],
    );
    expect(back.createdAt.millisecondsSinceEpoch, chat.createdAt.millisecondsSinceEpoch);
  });

  test('the free-chat count is kept for today and starts again on a new day', () async {
    final c = ClixaController()..onInit();
    await c.send(c.startChat(ClixaMode.talk), 'How do I find customers?');
    expect(restarted().freeChatsLeft, ClixaController.freeChatsPerDay - 1);

    // The same record, but from yesterday: a new day starts with all free chats.
    await GetStorage().write(
      'clixa_daily',
      jsonEncode({'day': '2000-01-01', 'count': 3}),
    );
    expect(restarted().freeChatsLeft, ClixaController.freeChatsPerDay);
  });

  test('rename and delete are saved', () async {
    final c = ClixaController()..onInit();
    final a = c.startChat(ClixaMode.discuss);
    await c.send(a, 'First idea');
    final b = c.startChat(ClixaMode.plan);
    await c.send(b, 'Second idea');

    c.rename(a, 'My renamed chat');
    await Future<void>.delayed(Duration.zero);
    expect(restarted().chats.map((x) => x.title.value), contains('My renamed chat'));

    c.delete(b);
    await Future<void>.delayed(Duration.zero);
    final after = restarted();
    expect(after.chats.length, 1);
    expect(after.chats.single.id, a.id);
  });

  test('a chat nobody wrote in is not kept', () async {
    final c = ClixaController()..onInit();
    c.startChat(ClixaMode.numbers); // opened and left
    final used = c.startChat(ClixaMode.talk);
    await c.send(used, 'Hello');
    expect(restarted().chats.map((x) => x.id), [used.id]);
  });

  test('a verdict card is stored and restored', () {
    final chat = ClixaChat(id: '1', mode: ClixaMode.validate, title: 'Cakes');
    chat.messages.add(const ClixaMessage(fromUser: true, text: 'cakes'));
    chat.messages.add(
      const ClixaMessage(
        fromUser: false,
        verdict: ClixaVerdict(
          badge: 'Promising',
          headline: 'Worth a test',
          strengths: ['a'],
          risks: ['b'],
          next: ['c'],
        ),
      ),
    );
    final back = ClixaChat.fromJson(
      jsonDecode(jsonEncode(chat.toJson())) as Map<String, dynamic>,
    );
    expect(back.verdictBadge, 'Promising');
    expect(back.messages.last.verdict!.headline, 'Worth a test');
    expect(back.messages.last.verdict!.risks, ['b']);
  });

  test('a damaged entry is skipped, the rest still load', () async {
    final c = ClixaController()..onInit();
    await c.send(c.startChat(ClixaMode.discuss), 'Good chat');
    final good = jsonDecode(GetStorage().read<String>('clixa_chats')!) as List;
    await GetStorage().write(
      'clixa_chats',
      jsonEncode([
        {'id': 'broken', 'mode': 'nope'},
        ...good,
      ]),
    );
    final after = restarted();
    expect(after.chats.length, 1);
    expect(after.chats.single.messages.any((m) => m.text == 'Good chat'), isTrue);
  });

  test('only the newest 10 chats are kept; older ones are dropped on save', () async {
    final c = ClixaController()..onInit();
    final ids = <String>[];
    for (var i = 0; i < 12; i++) {
      final chat = c.startChat(ClixaMode.talk);
      ids.add(chat.id);
      await c.send(chat, 'Question $i');
    }
    final after = restarted();
    expect(after.chats.length, 10);
    // Newest first: the last ten started are kept, the first two are gone.
    expect(after.chats.map((x) => x.id), ids.reversed.take(10).toList());
    expect(after.chats.any((x) => x.id == ids.first), isFalse);
  });
}
