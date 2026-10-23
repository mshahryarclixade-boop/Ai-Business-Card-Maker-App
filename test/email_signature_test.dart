import 'dart:io';

import 'package:ai_business_card_maker/app/modules/email_signature/model/email_signature.dart';
import 'package:ai_business_card_maker/app/modules/email_signature/service/email_signature_store.dart';
import 'package:ai_business_card_maker/app/modules/email_signature/view/email_signature_editor_view.dart';
import 'package:ai_business_card_maker/app/modules/email_signature/view/email_signature_intro_view.dart';
import 'package:ai_business_card_maker/app/modules/email_signature/view/email_signature_saved_view.dart';
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

  @override
  Future<bool> buy(
    BuildContext context, {
    required String productId,
    required String plan,
    required String source,
  }) async {
    isUserPro.value = true;
    return true;
  }
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

  late _FakeSub sub;
  String? clipboard;

  /// A home with a button that opens the module, like Home's email icon.
  Future<void> open(WidgetTester t, {bool pro = false}) async {
    Get.reset();
    await GetStorage().erase();
    EmailSignatureStore.clear();
    Get.put(ProfileStore());
    ProfileStore.to.profile.value = const UserProfileData(
      fullName: 'Sara Khan',
      designation: 'Architect',
      companyName: 'Studio K',
      dialCode: '+92',
      phoneNumber: '300 111',
      website: 'studiok.pk',
    );
    sub = _FakeSub()..isUserPro.value = pro;
    Get.put<SubscriptionController>(sub);
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: openEmailSignature,
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  Future<void> flush(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 50));
  }

  Future<void> createFirst(WidgetTester t) async {
    await t.tap(find.text('Create my signature'));
    await t.pumpAndSettle();
  }

  testWidgets('first time: intro with the card details, then New signature', (
    t,
  ) async {
    await open(t);
    expect(find.byType(EmailSignatureIntroView), findsOneWidget);
    expect(find.text('Sign every email with your card'), findsOneWidget);
    expect(find.text('Sara Khan'), findsOneWidget); // from the business card
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Free plan includes 1 signature'), findsOneWidget);

    await createFirst(t);
    expect(find.byType(EmailSignatureEditorView), findsOneWidget);
    expect(find.text('New signature'), findsOneWidget);
    expect(find.text('Great meeting you today'), findsOneWidget); // sample mail
    expect(find.text('Made with AI Business Card Maker'), findsOneWidget);
    await flush(t);
  });

  testWidgets('screens slide in from the right', (t) async {
    await open(t);
    expect(t.getTopLeft(find.byType(EmailSignatureIntroView)).dx, 0);
    await t.tap(find.text('Create my signature'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    expect(
      t.getTopLeft(find.byType(EmailSignatureEditorView)).dx,
      greaterThan(0),
      reason: 'editor slides in',
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Save and add to email'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    expect(
      t.getTopLeft(find.byType(EmailSignatureSavedView)).dx,
      greaterThan(0),
      reason: 'saved screen slides in',
    );
    await t.pumpAndSettle();
    await flush(t);
  });

  testWidgets('Free: QR on, Book-a-call and Banner ask for Pro', (t) async {
    await open(t);
    await createFirst(t);
    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Logo'), findsOneWidget);
    expect(find.text('Tap to choose'), findsNWidgets(2));
    expect(find.byType(Switch), findsOneWidget); // only the QR toggle
    expect(find.text('PRO'), findsNWidgets(2)); // Banner + Book-a-call

    await t.tap(find.byType(Switch)); // QR is free
    await t.pump();
    expect(t.widget<Switch>(find.byType(Switch)).value, isTrue);

    await t.tap(find.text('Book-a-call'));
    await t.pumpAndSettle();
    expect(find.text('Unlock Book-a-call'), findsOneWidget);
    await t.tap(find.text('Not now'));
    await t.pumpAndSettle();
    expect(find.text('Book a 15-min call'), findsNothing);

    await t.tap(find.text('Banner'));
    await t.pumpAndSettle();
    expect(find.text('Unlock the Banner style'), findsOneWidget);
    expect(find.text('Unlimited signatures'), findsOneWidget);
    await flush(t);
  });

  testWidgets('subscribing from Banner: You\'re Pro, then the Banner style', (
    t,
  ) async {
    await open(t);
    await createFirst(t);
    await t.tap(find.text('Banner'));
    await t.pumpAndSettle();
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(find.text('You\'re Pro'), findsOneWidget);
    await t.tap(find.text('Use the Banner style'));
    await t.pumpAndSettle();
    expect(find.text('Made with AI Business Card Maker'), findsNothing);
    expect(find.text('PRO'), findsNothing);
    await t.tap(find.text('Save and add to email'));
    await t.pumpAndSettle();
    expect(EmailSignatureStore.signatures.single.style, SignatureStyle.banner);
    await flush(t);
  });

  testWidgets('edit details: the sheet changes only this signature', (t) async {
    await open(t);
    await createFirst(t);
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    expect(find.text('Your details').evaluate().length, greaterThan(1));
    expect(
      find.text(
        'From your business card. Changes here only affect your signature.',
      ),
      findsOneWidget,
    );
    await t.enterText(find.widgetWithText(TextField, 'Sara Khan'), 'Sara K.');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Sara K.'), findsWidgets);
    expect(
      ProfileStore.to.profile.value.fullName,
      'Sara Khan',
    ); // card untouched
    await flush(t);
  });

  testWidgets('leave without saving: Discard, Keep editing, Save', (t) async {
    await open(t);
    await createFirst(t);
    // Unchanged: leaves straight away? Change something first.
    await t.tap(find.byType(Switch)); // QR on
    await t.pump();
    await t.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await t.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
    await t.tap(find.text('Keep editing'));
    await t.pumpAndSettle();
    expect(find.byType(EmailSignatureEditorView), findsOneWidget);

    await t.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Discard'));
    await t.pumpAndSettle();
    expect(find.byType(EmailSignatureEditorView), findsNothing);
    expect(EmailSignatureStore.signatures, isEmpty);

    await createFirst(t);
    await t.tap(find.byType(Switch));
    await t.pump();
    await t.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Save').last);
    await t.pumpAndSettle();
    expect(EmailSignatureStore.signatures.single.showQr, isTrue);
    expect(find.byType(EmailSignatureSavedView), findsOneWidget);
    await flush(t);
  });

  testWidgets('unchanged signature: back leaves without asking', (t) async {
    await open(t);
    await createFirst(t);
    await t.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await t.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsNothing);
    expect(find.byType(EmailSignatureEditorView), findsNothing);
    await flush(t);
  });

  testWidgets('saved screen: copy, no "Set it up in", your signatures', (
    t,
  ) async {
    await open(t);
    await createFirst(t);
    await t.tap(find.text('Save and add to email'));
    await t.pumpAndSettle();
    expect(find.text('Add to your email'), findsOneWidget);
    expect(find.text('Set it up in'), findsNothing);
    expect(find.text('Gmail'), findsNothing);
    expect(find.text('Your signatures'), findsOneWidget);
    expect(find.textContaining('Classic'), findsWidgets);

    await t.tap(find.text('Copy signature'));
    await t.pumpAndSettle();
    expect(find.text('Copy as'), findsOneWidget); // text or image
    await t.tap(find.text('Text only'));
    await t.pump();
    expect(clipboard, contains('Sara Khan'));
    expect(clipboard, contains('Architect · Studio K'));
    expect(clipboard, contains('Made with AI Business Card Maker'));
    await t.pumpAndSettle(const Duration(seconds: 3));

    // The ⋯ menu replaces the arrow; Edit opens the editor.
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    await t.tap(find.byIcon(Icons.more_horiz_rounded));
    await t.pumpAndSettle();
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    expect(find.text('Edit signature'), findsOneWidget);
    await flush(t);
  });

  testWidgets('Free: one signature only; a second asks for Pro', (t) async {
    await open(t);
    await createFirst(t);
    await t.tap(find.text('Save and add to email'));
    await t.pumpAndSettle();
    expect(find.text('PRO'), findsOneWidget); // on "New signature"
    await t.tap(find.text('New signature'));
    await t.pumpAndSettle();
    expect(find.text('Unlock unlimited signatures'), findsOneWidget);
    expect(EmailSignatureStore.signatures.length, 1);
    await t.tap(find.text('Not now'));
    await t.pumpAndSettle();
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(find.byType(EmailSignatureSavedView), findsNothing);

    // Opening again goes straight to the saved signatures, not the intro.
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.byType(EmailSignatureIntroView), findsNothing);
    expect(find.byType(EmailSignatureSavedView), findsOneWidget);
    await flush(t);
  });

  testWidgets('Pro: more signatures, Book-a-call, no "Made with" line', (
    t,
  ) async {
    await open(t, pro: true);
    await createFirst(t);
    expect(find.text('Made with AI Business Card Maker'), findsNothing);
    expect(find.text('PRO'), findsNothing);
    await t.tap(find.text('Book-a-call'));
    await t.pump();
    expect(find.text('Book a 15-min call'), findsOneWidget);
    await t.tap(find.text('Save and add to email'));
    await t.pumpAndSettle();

    await t.tap(find.text('New signature'));
    await t.pumpAndSettle();
    expect(find.text('New signature'), findsOneWidget); // editor, no upsell
    await t.tap(find.text('Compact'));
    await t.pump();
    await t.tap(find.text('Save and add to email'));
    await t.pumpAndSettle();
    expect(EmailSignatureStore.signatures.length, 2);

    await t.tap(find.text('Copy signature'));
    await t.pumpAndSettle();
    await t.tap(find.text('Text only'));
    await t.pump();
    expect(clipboard, isNot(contains('Made with')));
    await t.pumpAndSettle(const Duration(seconds: 3));
    await flush(t);
  });

  testWidgets('menu: Preview shows that signature, Delete removes it', (
    t,
  ) async {
    await open(t, pro: true);
    await createFirst(t);
    await t.tap(find.text('Save and add to email'));
    await t.pumpAndSettle();
    await t.tap(find.text('New signature'));
    await t.pumpAndSettle();
    await t.tap(find.text('Compact'));
    await t.pump();
    await t.tap(find.text('Save and add to email'));
    await t.pumpAndSettle();
    final all = EmailSignatureStore.signatures.toList();
    expect(all.length, 2);
    expect(EmailSignatureStore.active!.id, all[1].id); // the newest

    Future<void> menu(int row, String action) async {
      await t.tap(find.byIcon(Icons.more_horiz_rounded).at(row));
      await t.pumpAndSettle();
      await t.tap(find.text(action));
      await t.pumpAndSettle();
    }

    await menu(0, 'Preview'); // the first (Classic) goes in the preview area
    expect(EmailSignatureStore.active!.id, all[0].id);

    await menu(1, 'Delete');
    expect(EmailSignatureStore.signatures.map((e) => e.id), [all[0].id]);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    expect(EmailSignatureStore.active!.id, all[0].id);

    await menu(0, 'Delete'); // delete the last one
    expect(EmailSignatureStore.signatures, isEmpty);
    expect(find.text('Copy signature'), findsNothing);
    await flush(t);
  });

  testWidgets('Done looks like Copy signature: a primary button, no card', (
    t,
  ) async {
    await open(t);
    await createFirst(t);
    await t.tap(find.text('Save and add to email'));
    await t.pumpAndSettle();
    ButtonStyleButton button(String label) => t.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    final copy = button('Copy signature');
    final done = button('Done');
    expect(done, isA<ElevatedButton>());
    expect(
      done.style?.backgroundColor?.resolve({}),
      copy.style?.backgroundColor?.resolve({}),
    );
    // Same size, and no white bar behind it.
    expect(
      t.getSize(
        find.ancestor(
          of: find.text('Done'),
          matching: find.byType(ElevatedButton),
        ),
      ),
      t.getSize(
        find.ancestor(
          of: find.text('Copy signature'),
          matching: find.byType(ElevatedButton),
        ),
      ),
    );
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(find.byType(EmailSignatureSavedView), findsNothing);
    await flush(t);
  });

  test('saved signatures survive a restart', () async {
    await GetStorage().erase();
    EmailSignatureStore.clear();
    EmailSignatureStore.put(
      const EmailSignature(
        id: '1',
        fullName: 'A B',
        style: SignatureStyle.compact,
        showQr: true,
      ),
    );
    final json = GetStorage().read<String>('email_signatures');
    expect(json, isNotNull);
    expect(
      EmailSignature.fromJson(
        (EmailSignatureStore.signatures.single.toJson()),
      ).style,
      SignatureStyle.compact,
    );
  });
}
