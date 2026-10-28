import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:ai_business_card_maker/app/modules/expert_panel/controller/panel_chat_controller.dart';
import 'package:ai_business_card_maker/app/modules/expert_panel/model/expert_models.dart';
import 'package:ai_business_card_maker/app/modules/expert_panel/service/panel_ai_service.dart';

/// Replays scripted server turns and records what the app sent.
class FakePanelAi extends PanelAi {
  FakePanelAi(this.script);

  final List<PanelTurn Function(PanelSession s)> script;
  final sent = <Map<String, dynamic>>[];
  var _i = 0;

  @override
  Future<PanelTurn> turn(PanelSession session) async {
    sent.add(session.toRequest());
    if (_i >= script.length) throw const GeminiException('no more turns');
    return script[_i++](session);
  }
}

PanelTurn line(String speaker, String text, String then, {Map<String, dynamic>? state, String? userText}) =>
    PanelTurn(speaker: speaker, text: text, then: then, state: state ?? {'stage': 'DEEP_DIVE'}, userText: userText);

PanelSession newSession({PanelMode mode = PanelMode.pitch}) =>
    PanelSession(experts: [0, 1, 2, 3, 4], mode: mode, title: 'New idea');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // The history is stored with GetStorage, which needs a directory.
    final dir = Directory.systemTemp.createTempSync('panel_test').path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir,
        );
    await GetStorage.init();
  });

  test('the cast matches the prompts and Clixa hosts', () {
    expect(kExperts.map((e) => e.id).toSet(), {'dave', 'olivia', 'john', 'marcus', 'sara'});
    expect(expertById('clixa').name, 'Clixa');
    expect(expertById('dave').shortRoleKey, 'panel_role_finance');
    expect(newSession().expertIds.length, 5);
  });

  test('a new session opens with Clixa\'s welcome', () async {
    final ai = FakePanelAi([(s) => line('clixa', 'Hi, I am Clixa.', 'user', state: {'stage': 'PITCH'})]);
    PanelAi.instance = ai;
    final s = newSession();
    final c = PanelChatController(s);
    await c.start();
    expect(s.messages.single.speaker, 'clixa');
    expect(s.engine['stage'], 'PITCH');
    expect(ai.sent.single['messages'], isEmpty);
    await c.start(); // not twice
    expect(s.messages.length, 1);
  });

  test('send calls again while the server says continue, and keeps the state', () async {
    final ai = FakePanelAi([
      (s) => line('dave', 'First.', 'continue', state: {'stage': 'DEEP_DIVE', 'n': 1}, userText: 'my pitch'),
      (s) => line('sara', 'Second?', 'user', state: {'stage': 'DEEP_DIVE', 'n': 2}),
    ]);
    PanelAi.instance = ai;
    final s = newSession();
    final c = PanelChatController(s);
    expect(await c.send('  my pitch  '), isTrue);
    expect(s.messages.map((m) => m.speaker), [null, 'dave', 'sara']);
    expect(s.engine['n'], 2);
    // The second call carried the first call's state and the line it produced.
    expect(ai.sent[1]['state'], {'stage': 'DEEP_DIVE', 'n': 1});
    expect((ai.sent[1]['messages'] as List).length, 2);
    expect(c.thinking.value, isFalse);
  });

  test('the server\'s redacted text replaces what the user typed', () async {
    PanelAi.instance = FakePanelAi([
      (s) => line('clixa', 'Please keep numbers private.', 'user', userText: 'card [number removed]'),
    ]);
    final s = newSession();
    await PanelChatController(s).send('card 4111 1111 1111 1111');
    expect(s.messages.first.text, 'card [number removed]');
  });

  test('empty messages are ignored; a failed first call takes the message back out', () async {
    PanelAi.instance = FakePanelAi([]);
    final s = newSession();
    final c = PanelChatController(s);
    expect(await c.send('   '), isFalse);
    await expectLater(c.send('hello'), throwsA(isA<GeminiException>()));
    expect(s.messages, isEmpty, reason: 'nothing was answered, so the message is given back');
    expect(c.thinking.value, isFalse);
  });

  test('a later failure keeps the lines that already arrived', () async {
    PanelAi.instance = FakePanelAi([
      (s) => line('dave', 'One.', 'continue'),
    ]);
    final s = newSession();
    expect(await PanelChatController(s).send('hi'), isTrue);
    expect(s.messages.length, 2);
  });

  test('when the server ends the session the controller is over and sends no more', () async {
    final ai = FakePanelAi([
      (s) => line('clixa', 'I\'m ending this session now.', 'end', state: {'stage': 'DEEP_DIVE', 'ended': 'conduct'}),
    ]);
    PanelAi.instance = ai;
    final s = newSession();
    final c = PanelChatController(s);
    await c.send('you idiots');
    expect(c.over.value, isTrue);
    expect(s.ended, 'conduct');
    expect(await c.send('hello?'), isFalse);
    expect(ai.sent.length, 1);
  });

  test('End says it in the chat; only the server ends the session', () async {
    final ai = FakePanelAi([
      (s) => line('clixa', 'Do you want me to end the session now?', 'user'),
    ]);
    PanelAi.instance = ai;
    final s = newSession();
    final c = PanelChatController(s);
    await c.requestEnd();
    expect(s.messages.first.fromUser, isTrue);
    expect(s.messages.first.text, 'I want to end the session.');
    expect(s.messages.last.speaker, 'clixa');
    expect(c.over.value, isFalse, reason: 'asking to end does not end it');
  });

  test('the request carries mode, the selected experts and the state', () {
    final s = PanelSession(experts: [0, 4], mode: PanelMode.consult, title: 't', engine: {'stage': 'ADVISE'});
    s.messages.add(const PanelMessage(text: 'hi', round: 1));
    final r = s.toRequest(userName: 'Ayesha');
    expect(r['mode'], 'consult');
    expect(r['experts'], ['olivia', 'john']);
    expect(r['state'], {'stage': 'ADVISE'});
    expect(r['userName'], 'Ayesha');
    expect(r.containsKey('endRequest'), isFalse);
  });
}
