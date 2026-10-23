import 'dart:io';

import 'package:ai_business_card_maker/app/core/widgets/crown_upgrade_button.dart';
import 'package:ai_business_card_maker/app/modules/clixa/controller/clixa_controller.dart';
import 'package:ai_business_card_maker/app/modules/clixa/model/clixa_models.dart';
import 'package:ai_business_card_maker/app/modules/clixa/view/clixa_chat_view.dart';
import 'package:ai_business_card_maker/app/modules/clixa/view/clixa_view.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/ai_toolkit_section.dart';
import 'package:ai_business_card_maker/app/modules/main_nav/controller/main_nav_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/model/user_profile_data.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class _FakeSub extends SubscriptionController {
  @override
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('gs').path,
        );
    await GetStorage.init();
  });

  late ClixaController c;
  late _FakeSub sub;

  Future<void> boot(WidgetTester t, {bool pro = false, Widget? home}) async {
    Get.reset();
    sub = _FakeSub()..isUserPro.value = pro;
    Get.put<SubscriptionController>(sub);
    Get.put(ProfileStore());
    ProfileStore.to.profile.value = const UserProfileData(
      fullName: 'Ayesha Raza',
    );
    c = Get.put(ClixaController(), permanent: true)
      ..replyDelay = const Duration(milliseconds: 10);
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(GetMaterialApp(home: home ?? const ClixaView()));
    await t.pump(const Duration(milliseconds: 300));
  }

  /// The crown on these screens never stops moving: pump a fixed time.
  Future<void> settle(WidgetTester t, [int ms = 600]) async {
    await t.pump();
    await t.pump(Duration(milliseconds: ms));
  }

  Future<void> flush(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 50));
  }

  group('start screen', () {
    testWidgets('greeting card, prompts and the free-chats counter', (t) async {
      await boot(t);
      expect(find.text('AI Coach'), findsOneWidget);
      expect(find.text('Hi Ayesha, I\'m Clixa'), findsOneWidget);
      expect(
        find.text('Your AI business coach. What shall we work on today?'),
        findsOneWidget,
      );
      expect(find.text('Type an idea or a question…'), findsOneWidget);
      expect(find.text('Start a chat'), findsOneWidget);
      expect(find.text('3 of 3 free chats left today'), findsOneWidget);
      for (final m in ClixaMode.values) {
        expect(find.text(_en[m.titleKey]!), findsOneWidget, reason: m.id);
      }
      expect(find.text('Discuss an idea'), findsOneWidget);
      expect(find.text('Just talk business'), findsOneWidget);
      // The prompt box is for show: nothing on this screen can be typed in.
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      await flush(t);
    });

    testWidgets('the prompt box opens "Start a new chat"', (t) async {
      await boot(t);
      await t.tap(find.text('Type an idea or a question…'));
      await settle(t);
      expect(find.text('Start a new chat'), findsOneWidget);
      expect(find.textContaining('A new chat starts fresh'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(5));
      // Picking one opens that chat.
      await t.tap(find.text('Numbers and pricing').last);
      await settle(t);
      expect(find.byType(ClixaChatView), findsOneWidget);
      expect(find.text('New chat · Numbers and pricing'), findsOneWidget);
      expect(c.freeChatsLeft, 2);
      await flush(t);
    });

    testWidgets('Pro: no crown, no counter', (t) async {
      await boot(t, pro: true);
      expect(find.text('Unlimited chats'), findsOneWidget);
      expect(find.textContaining('free chats left'), findsNothing);
      await flush(t);
    });

    testWidgets('the crown opens "Unlock the expert panel"', (t) async {
      await boot(t);
      await t.tap(find.byType(CrownUpgradeButton));
      await settle(t);
      expect(find.text('Unlock the expert panel'), findsOneWidget);
      expect(
        find.text('Consult or pitch to the 5-expert panel'),
        findsOneWidget,
      );
      await flush(t);
    });
  });

  group('chat', () {
    testWidgets('a quick prompt opens a chat with Clixa\'s first message', (
      t,
    ) async {
      await boot(t);
      await t.tap(find.text('Validate my idea'));
      await settle(t);
      expect(find.byType(ClixaChatView), findsOneWidget);
      expect(find.text('New chat · Validate my idea'), findsOneWidget);
      expect(find.text('Clixa · Validate my idea'), findsOneWidget);
      expect(
        find.text(
          'Great, let\'s check your idea. What do you want to sell, and to whom?',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Custom birthday cakes from home, sold on Instagram in Lahore',
        ),
        findsOneWidget, // the ready-made answer
      );
      expect(
        find.text('0 of 10 free messages used in this chat'),
        findsOneWidget,
      );
      expect(find.text('Message Clixa'), findsOneWidget);
      await flush(t);
    });

    testWidgets('sending gets a placeholder reply and names the chat', (
      t,
    ) async {
      await boot(t);
      await t.tap(find.text('Validate my idea'));
      await settle(t);
      await t.tap(
        find.text(
          'Custom birthday cakes from home, sold on Instagram in Lahore',
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 400));
      expect(
        find.text('1 of 10 free messages used in this chat'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Nice. Who usually buys, and what would they pay for a 2 lb custom cake?',
        ),
        findsOneWidget,
      );
      // Named after what it is about.
      expect(
        find.textContaining('Custom birthday cakes from home'),
        findsWidgets,
      );
      expect(find.text('New chat · Validate my idea'), findsNothing);
      await flush(t);
    });

    testWidgets('typing a message works too', (t) async {
      await boot(t);
      await t.tap(find.text('Just talk business'));
      await settle(t);
      await t.enterText(find.byType(TextField), 'How do I price my work?');
      await t.tap(find.byIcon(Icons.arrow_upward_rounded));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('How do I price my work?'), findsWidgets);
      expect(
        find.text('Got it. Tell me a bit more about who this is for.'),
        findsOneWidget,
      );
      await flush(t);
    });

    testWidgets('Validate ends with the idea verdict; pitching asks for Pro', (
      t,
    ) async {
      await boot(t);
      final chat = c.startChat(ClixaMode.validate);
      for (final m in ['a', 'b', 'c', 'd']) {
        await t.runAsync(() => c.send(chat, m));
      }
      await t.pumpWidget(GetMaterialApp(home: ClixaChatView(chat: chat)));
      await settle(t);
      await t.scrollUntilVisible(
        find.text('IDEA VERDICT'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('IDEA VERDICT'), findsOneWidget);
      expect(find.text('Promising'), findsOneWidget);
      expect(find.text('Strengths'), findsOneWidget);
      expect(find.text('Risks'), findsOneWidget);
      expect(find.text('Next steps'), findsOneWidget);
      expect(
        find.text('Practice feedback from an AI coach, not financial advice.'),
        findsOneWidget,
      );
      // To the very end of the chat, clear of the message box.
      await t.drag(find.byType(ListView), const Offset(0, -2000));
      await t.pump();
      await t.tap(find.text('Pitch it to the expert panel'));
      await settle(t);
      expect(find.text('Unlock the expert panel'), findsOneWidget);
      expect(
        find.text('Unlimited chats and messages with Clixa'),
        findsOneWidget,
      );
      await flush(t);
    });

    testWidgets('the ⋮ menu: rename, start new, delete', (t) async {
      await boot(t);
      await t.tap(find.text('Discuss an idea'));
      await settle(t);
      await t.tap(find.byIcon(Icons.more_vert_rounded));
      await settle(t);
      expect(find.text('Rename chat'), findsOneWidget);
      expect(find.text('Start a new chat'), findsOneWidget);
      expect(find.text('Delete chat'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await t.tap(find.text('Rename chat'));
      await settle(t);
      expect(find.text('Chat name'), findsOneWidget);
      await t.enterText(
        find.byType(TextField).last,
        'Home bakery on Instagram',
      );
      await t.tap(find.text('Save'));
      await settle(t);
      expect(find.text('Home bakery on Instagram'), findsOneWidget);
      expect(c.chats.first.title.value, 'Home bakery on Instagram');

      await t.tap(find.byIcon(Icons.more_vert_rounded));
      await settle(t);
      await t.tap(find.text('Delete chat'));
      await settle(t);
      expect(c.chats, isEmpty);
      expect(find.byType(ClixaChatView), findsNothing);
      expect(find.byType(ClixaView), findsOneWidget);
      await flush(t);
    });
  });

  group('free limits', () {
    testWidgets('after three chats a fourth asks for Pro', (t) async {
      await boot(t);
      for (final m in [ClixaMode.discuss, ClixaMode.plan, ClixaMode.numbers]) {
        c.startChat(m);
      }
      await t.pump();
      expect(find.text('0 of 3 free chats left today'), findsOneWidget);
      await t.tap(find.text('Just talk business'));
      await settle(t);
      expect(find.text('You\'ve used today\'s 3 free chats'), findsOneWidget);
      expect(find.text('Get unlimited chats'), findsOneWidget);
      expect(find.text('Continue a saved chat'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(find.byType(ClixaChatView), findsNothing);

      await t.tap(find.text('Continue a saved chat'));
      await settle(t);
      expect(find.text('Saved chats'), findsOneWidget);
      await t.tap(find.textContaining('New chat · Discuss an idea').last);
      await settle(t);
      expect(find.byType(ClixaChatView), findsOneWidget);
      await flush(t);
    });

    testWidgets('a free chat stops at 10 messages', (t) async {
      await boot(t);
      final chat = c.startChat(ClixaMode.talk);
      for (var i = 0; i < 9; i++) {
        await t.runAsync(() => c.send(chat, 'm$i'));
      }
      await t.pumpWidget(GetMaterialApp(home: ClixaChatView(chat: chat)));
      await settle(t);
      expect(
        find.text('9 of 10 free messages used in this chat'),
        findsOneWidget,
      );
      await t.enterText(find.byType(TextField), 'the tenth');
      await t.tap(find.byIcon(Icons.arrow_upward_rounded));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('This chat reached the free limit'), findsOneWidget);
      expect(find.text('Get unlimited messages'), findsOneWidget);
      expect(
        find.text('Start a new chat (3 left today)'),
        findsNothing,
      ); // 2 left
      expect(find.textContaining('left today)'), findsOneWidget);

      // Another message is not sent.
      await t.tap(find.text('Not now'));
      await settle(t);
      await t.enterText(find.byType(TextField), 'one more');
      await t.tap(find.byIcon(Icons.arrow_upward_rounded));
      await settle(t);
      expect(chat.userMessages, 10);
      expect(find.text('This chat reached the free limit'), findsOneWidget);
      await flush(t);
    });

    testWidgets('Pro: no limits', (t) async {
      await boot(t, pro: true);
      final chat = c.startChat(ClixaMode.talk);
      for (var i = 0; i < 12; i++) {
        await t.runAsync(() => c.send(chat, 'm$i'));
      }
      expect(chat.userMessages, 12);
      expect(c.limitReached(chat), isFalse);
      for (var i = 0; i < 5; i++) {
        c.startChat(ClixaMode.talk);
      }
      expect(c.canStartChat, isTrue);
      await flush(t);
    });
  });

  group('Home and navigation', () {
    testWidgets('Your Business ToolKit: Career Studio and the Expert Panel', (
      t,
    ) async {
      await boot(
        t,
        home: const Scaffold(
          body: SingleChildScrollView(child: AiToolkitSection()),
        ),
      );
      expect(find.text('Your Business ToolKit'), findsOneWidget);
      expect(find.text('Your AI toolkit'), findsNothing);
      expect(find.text('Career Studio'), findsOneWidget);
      expect(find.text('Expert panel'), findsOneWidget);
      expect(find.text('Business Panel'), findsNothing);
      expect(
        find.text('Consult or pitch your idea to 5 AI experts'),
        findsOneWidget,
      );
      // One PRO badge: the Expert Panel's. The bar beside the heading is gone.
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('3 free'), findsNothing);

      await t.tap(find.text('Expert panel'));
      await settle(t);
      expect(find.text('Unlock the expert panel'), findsOneWidget);
      await flush(t);
    });

    testWidgets('the AI Coach tab is the fourth tab', (t) async {
      await boot(t, home: const Scaffold(body: SizedBox()));
      final nav = Get.put(MainNavController());
      nav.onNavTap(3);
      expect(nav.tabIndex.value, 3);
      nav.onNavTap(0);
      expect(nav.tabIndex.value, 0);
      await flush(t);
    });
  });
}

const _en = {
  'clixa_mode_discuss_title': 'Discuss an idea',
  'clixa_mode_validate_title': 'Validate my idea',
  'clixa_mode_plan_title': 'Create a business plan',
  'clixa_mode_numbers_title': 'Numbers and pricing',
  'clixa_mode_talk_title': 'Just talk business',
};
