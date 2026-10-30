import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_business_card_maker/app/core/services/profile_scope.dart';
import 'package:ai_business_card_maker/app/core/services/recent_designs_service.dart';
import 'package:ai_business_card_maker/app/modules/clixa/view/clixa_view.dart';
import 'package:ai_business_card_maker/app/modules/email_signature/model/email_signature.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/email_signature/service/email_signature_store.dart';
import 'package:ai_business_card_maker/app/modules/home/controller/home_controller.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/my_card_section.dart';
import 'package:ai_business_card_maker/app/modules/main_nav/controller/main_nav_controller.dart';
import 'package:ai_business_card_maker/app/modules/main_nav/widgets/main_bottom_nav_bar.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/model/user_profile_data.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/profiles/service/profiles_manager.dart';
import 'package:ai_business_card_maker/app/modules/profiles/view/profile_editor_view.dart';
import 'package:ai_business_card_maker/app/modules/profiles/view/profiles_view.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/model/qr_entry.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/model/qr_profile_data.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/model/qr_style.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/service/qr_store.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/view/qr_code_screen.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/view/qr_management_screen.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/view/qr_style_picker_screen.dart';
import 'package:ai_business_card_maker/app/core/translations/tr_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:get_storage/get_storage.dart';

/// A real 1x1 PNG, so Home's card image decodes.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const _ayesha = UserProfileData(
  fullName: 'Ayesha Raza',
  designation: 'Designer',
  companyName: 'Northwind',
  phoneNumber: '300 1',
);
const _bilal = UserProfileData(
  fullName: 'Bilal Khan',
  designation: 'Engineer',
  companyName: 'Orbit',
  phoneNumber: '300 2',
);

class _NoSub extends SubscriptionController {
  @override
  void onInit() {}
}

/// Home's controller without its connectivity check.
class _FakeHome extends HomeController {
  @override
  void onReady() {}
}

QrEntry _qr(String name, {String style = 'classic'}) => QrEntry(
  id: QrStore.newId() + name,
  form: {'fullName': name, 'company': 'Co'},
  styleId: style,
  createdAt: DateTime.now(),
);

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

  Future<void> fresh() async {
    Get.reset();
    await GetStorage().erase();
    ProfilesManager.clear();
    QrStore.clear();
    EmailSignatureStore.clear();
    Get.put(ProfileStore());
    ProfileStore.to.profile.value = const UserProfileData();
  }

  group('profiles keep their data apart', () {
    test(
      'the first profile owns the data saved before profiles existed',
      () async {
        await fresh();
        expect(ProfilesManager.profiles.single.id, ProfileScope.defaultId);
        expect(ProfileScope.key('recent_designs'), 'recent_designs');
        ProfileStore.to.writeStored(ProfileScope.defaultId, _ayesha);
        expect(GetStorage().read<String>('user_profile_data'), isNotNull);
      },
    );

    test(
      'details, QR codes and signatures follow the active profile',
      () async {
        await fresh();
        final a = ProfilesManager.activeId.value;
        ProfileStore.to.writeStored(a, _ayesha);
        QrStore.put(_qr('Ayesha QR'));
        EmailSignatureStore.put(
          const EmailSignature(id: 's-a', fullName: 'Ayesha Raza'),
        );

        final b = ProfilesManager.create();
        ProfileStore.to.writeStored(b, _bilal);
        ProfilesManager.switchTo(b);

        // Bilal sees only his own: nothing of Ayesha's.
        expect(ProfileStore.to.profile.value.fullName, 'Bilal Khan');
        expect(QrStore.entries, isEmpty);
        expect(EmailSignatureStore.signatures, isEmpty);
        QrStore.put(_qr('Bilal QR', style: 'dots'));
        expect(QrStore.entries.single.title, 'Bilal QR');

        // And back: Ayesha's data is exactly as she left it.
        ProfilesManager.switchTo(a);
        expect(ProfileStore.to.profile.value.fullName, 'Ayesha Raza');
        expect(QrStore.entries.single.title, 'Ayesha QR');
        expect(EmailSignatureStore.signatures.single.id, 's-a');
        ProfilesManager.switchTo(b);
        expect(QrStore.entries.single.style, QrStyles.dots);
      },
    );

    test('the active profile survives a restart', () async {
      await fresh();
      final b = ProfilesManager.create();
      ProfilesManager.switchTo(b);
      // "Restart": read everything back from storage.
      ProfilesManager.clear();
      expect(ProfilesManager.profiles.length, 1);
      // clear() wipes the list on purpose; load from a saved list instead.
      final id = ProfilesManager.create();
      ProfilesManager.switchTo(id);
      final saved = GetStorage().read<String>('profiles_v1');
      expect(saved, contains(id));
    });

    test('deleting a profile removes its data; the last one is kept', () async {
      await fresh();
      final a = ProfilesManager.activeId.value;
      final b = ProfilesManager.create();
      ProfileStore.to.writeStored(b, _bilal);
      ProfilesManager.switchTo(b);
      QrStore.put(_qr('Bilal QR'));
      expect(GetStorage().read<String>('qr_entries__$b'), isNotNull);

      // Deleting the active one switches to the other first.
      expect(ProfilesManager.delete(b), isTrue);
      expect(ProfilesManager.activeId.value, a);
      expect(ProfilesManager.profiles.map((e) => e.id), [a]);
      expect(GetStorage().read<String>('qr_entries__$b'), isNull);
      expect(GetStorage().read<String>('user_profile_data__$b'), isNull);
      expect(QrStore.entries, isEmpty);

      expect(ProfilesManager.delete(a), isFalse); // the last profile stays
      expect(ProfilesManager.profiles.length, 1);
    });
  });

  group('QR codes', () {
    test('every style keeps the dots dark-on-light or light-on-dark', () {
      for (final s in QrStyles.all) {
        final f = s.foreground.computeLuminance();
        final b = s.background.computeLuminance();
        expect((f - b).abs(), greaterThan(0.4), reason: s.id);
      }
      expect(QrStyles.all.length, greaterThanOrEqualTo(5));
      expect(QrStyles.byId('nope'), QrStyles.classic);
    });

    test('a saved QR code keeps its form and style', () async {
      await fresh();
      QrStore.put(_qr('Sara', style: 'midnight'));
      final json = GetStorage().read<String>('qr_entries');
      expect(json, contains('midnight'));
      QrStore.reload();
      expect(QrStore.entries.single.style, QrStyles.midnight);
      expect(QrStore.entries.single.profileData.fullName, 'Sara');
      expect(QrStore.introSeen.value, isTrue);
    });

    testWidgets('first time: the form; afterwards: the saved QR codes', (
      t,
    ) async {
      await fresh();
      await t.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: openQrCodes,
                child: const Text('qr'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('qr'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(find.byType(CustomQrCodeScreen), findsOneWidget);
      expect(find.byType(QrManagementScreen), findsNothing);

      // After a code is saved the button always opens the saved codes.
      Navigator.of(t.element(find.byType(CustomQrCodeScreen))).pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      QrStore.put(_qr('Sara'));
      await t.tap(find.text('qr'));
      await t.pumpAndSettle();
      expect(find.byType(QrManagementScreen), findsOneWidget);
      expect(find.byType(CustomQrCodeScreen), findsNothing);
    });

    testWidgets('pick a style, save, then manage the QR codes', (t) async {
      await fresh();
      t.view.physicalSize = const Size(390 * 3, 844 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      const profile = QrProfileData(
        fullName: 'Sara Khan',
        companyName: 'Studio K',
      );
      await t.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Get.to(
                  () => const QrStylePickerScreen(
                    form: {'fullName': 'Sara Khan', 'company': 'Studio K'},
                    profile: profile,
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(find.text('Choose a style'), findsOneWidget);
      for (final n in ['Classic', 'Rounded', 'Dots', 'Midnight']) {
        expect(find.text(n), findsOneWidget, reason: n);
      }
      await t.tap(find.text('Midnight'));
      await t.pumpAndSettle();
      await t.tap(find.text('Save QR code'));
      await t.pumpAndSettle(const Duration(seconds: 3));

      expect(QrStore.entries.single.style, QrStyles.midnight);
      expect(QrStore.entries.single.title, 'Sara Khan');
      // Straight to the saved QR codes (first time through).
      expect(find.byType(QrManagementScreen), findsOneWidget);
      expect(find.text('Sara Khan'), findsOneWidget);
      expect(find.text('Midnight'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // The ⋯ menu: Edit opens the form with this QR code's details.
      await t.tap(find.byIcon(Icons.more_horiz_rounded));
      await t.pumpAndSettle();
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
      expect(find.text('Edit'), findsOneWidget);
      await t.tap(find.text('Edit'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(find.byType(CustomQrCodeScreen), findsOneWidget);
      expect(find.text('Sara Khan'), findsWidgets);
      Navigator.of(t.element(find.byType(CustomQrCodeScreen))).pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));

      // + makes another one.
      await t.tap(find.byType(FloatingActionButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(find.byType(CustomQrCodeScreen), findsOneWidget);
      Navigator.of(t.element(find.byType(CustomQrCodeScreen))).pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));

      // Delete asks first.
      await t.tap(find.byIcon(Icons.more_horiz_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(find.text('Delete this QR code?'), findsOneWidget);
      await t.tap(find.text('Delete').last);
      await t.pumpAndSettle();
      expect(QrStore.entries, isEmpty);
      expect(find.text('No QR codes yet'), findsOneWidget);
    });
  });

  group('Home', () {
    testWidgets('the card swipes to the active profile\'s QR code', (t) async {
      await fresh();
      t.view.physicalSize = const Size(390 * 3, 844 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      final dir = Directory.systemTemp.createTempSync('cards');
      final file = File('${dir.path}/c.png')..writeAsBytesSync(_png);
      final service = RecentDesignsService();
      service.designs.add(
        RecentDesign(id: '1', path: file.path, savedAt: DateTime.now()),
      );
      Get.put(service);
      Get.put<HomeController>(_FakeHome());
      ProfileStore.to.profile.value = _ayesha;

      await t.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: MyCardSection(),
            ),
          ),
        ),
      );
      await t.pump();
      expect(find.text('QR Code'), findsOneWidget); // the renamed button
      expect(find.text('My QR Code'), findsNothing);
      // No QR code yet: the second page invites you to make one.
      await t.drag(find.byType(PageView), const Offset(-300, 0));
      await t.pumpAndSettle();
      expect(find.text('No QR code yet. Tap to create one.'), findsOneWidget);

      // With one saved, it shows that code.
      QrStore.put(_qr('Ayesha Raza', style: 'rounded'));
      await t.pump();
      expect(find.text('Ayesha Raza'), findsWidgets);
      expect(find.text('Scan to save these contact details.'), findsOneWidget);

      // Swiping back shows the card again.
      await t.drag(find.byType(PageView), const Offset(300, 0));
      await t.pumpAndSettle();
      expect(find.text('Welcome, Ayesha'), findsWidgets);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('Home follows the active profile', (t) async {
      await fresh();
      t.view.physicalSize = const Size(390 * 3, 844 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final dir = Directory.systemTemp.createTempSync('cards');
      final file = File('${dir.path}/c.png')..writeAsBytesSync(_png);
      final service = RecentDesignsService();
      Get.put(service);
      Get.put<HomeController>(_FakeHome());
      final a = ProfilesManager.activeId.value;
      ProfileStore.to.writeStored(a, _ayesha);
      // Ayesha's saved design, stored the way the app stores it.
      await GetStorage().write(
        ProfileScope.key('recent_designs'),
        jsonEncode([
          RecentDesign(
            id: '1',
            path: file.path,
            savedAt: DateTime.now(),
          ).toJson(),
        ]),
      );
      service.reload();

      await t.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: MyCardSection())),
        ),
      );
      await t.pump();
      expect(find.textContaining('Ayesha'), findsWidgets);

      // A second profile has its own (empty) designs: Home shows the
      // "create your first card" state, with that profile's name.
      final b = ProfilesManager.create();
      ProfileStore.to.writeStored(b, _bilal);
      ProfilesManager.switchTo(b);
      await t.pump();
      expect(find.textContaining('Ayesha'), findsNothing);
      expect(find.byType(PageView), findsNothing); // no card yet

      // Back to Ayesha: her card is there again.
      ProfilesManager.switchTo(a);
      await t.pump();
      expect(find.byType(PageView), findsOneWidget);
      expect(find.textContaining('Ayesha'), findsWidgets);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('Profiles screen', () {
    testWidgets('create, switch, edit and delete', (t) async {
      await fresh();
      t.view.physicalSize = const Size(390 * 3, 844 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      ProfileStore.to.writeStored(ProfilesManager.activeId.value, _ayesha);

      await t.pumpWidget(const GetMaterialApp(home: ProfilesView()));
      await t.pump();
      expect(find.text('Profiles'), findsOneWidget);
      expect(find.text('Ayesha Raza'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);

      // Create: the new profile becomes the active one.
      await t.tap(find.byType(FloatingActionButton));
      await t.pumpAndSettle();
      expect(find.byType(ProfileEditorView), findsOneWidget);
      await t.tap(find.text('Save'));
      await t.pump();
      expect(find.text('Enter a full name'), findsOneWidget); // name required
      await t.enterText(find.widgetWithText(TextField, '').first, 'Bilal Khan');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(find.text('Bilal Khan'), findsOneWidget);
      expect(find.text('Ayesha Raza'), findsOneWidget);
      expect(ProfileStore.to.profile.value.fullName, 'Bilal Khan');
      expect(ProfilesManager.profiles.length, 2);

      // Switch back by tapping Ayesha.
      await t.tap(find.text('Ayesha Raza'));
      await t.pumpAndSettle(const Duration(seconds: 3));
      expect(ProfileStore.to.profile.value.fullName, 'Ayesha Raza');

      // Edit Bilal (not the active one): his details change, Ayesha's don't.
      await t.tap(find.byIcon(Icons.more_horiz_rounded).last);
      await t.pumpAndSettle();
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
      await t.enterText(
        find.widgetWithText(TextField, 'Bilal Khan'),
        'Bilal K.',
      );
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(find.text('Bilal K.'), findsOneWidget);
      expect(ProfileStore.to.profile.value.fullName, 'Ayesha Raza');

      // Delete Bilal.
      await t.tap(find.byIcon(Icons.more_horiz_rounded).last);
      await t.pumpAndSettle();
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(find.text('Delete this profile?'), findsOneWidget);
      await t.tap(find.text('Delete').last);
      await t.pumpAndSettle();
      expect(find.text('Bilal K.'), findsNothing);
      expect(ProfilesManager.profiles.length, 1);

      // The only profile left can't be deleted.
      await t.tap(find.byIcon(Icons.more_horiz_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Delete this profile?'), findsNothing);
      expect(ProfilesManager.profiles.length, 1);
    });
  });

  group('navigation and names', () {
    testWidgets('AI Coach is the fourth tab: no back arrow, bar stays', (
      t,
    ) async {
      Get.reset();
      Get.put<SubscriptionController>(_NoSub());
      Get.put(ProfileStore());
      ProfileStore.to.profile.value = const UserProfileData(); // no name yet
      final nav = Get.put(MainNavController());
      t.view.physicalSize = const Size(390 * 3, 844 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Obx(
              () => Stack(
                children: [
                  IndexedStack(
                    index: nav.tabIndex.value,
                    children: const [
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      ClixaView(embedded: true),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 14,
                    child: Center(
                      child: MainBottomNavBar(
                        currentIndex: nav.tabIndex.value,
                        onTabSelected: nav.onNavTap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);
      expect(find.byIcon(Icons.psychology_alt_outlined), findsOneWidget);
      await t.tap(find.byIcon(Icons.psychology_alt_outlined));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(nav.tabIndex.value, 3);
      // The coach screen is on show, with the bottom bar still there and no
      // back arrow on it.
      expect(find.text('Hi, I\'m Clixa'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.byType(MainBottomNavBar), findsOneWidget);
      // Tapping the blue card carries on: "Start a new chat".
      await t.tap(find.text('Hi, I\'m Clixa'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Start a new chat'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });

    test('renamed labels', () {
      expect('home_toolkit_heading'.tr, 'Your Business ToolKit');
      expect('home_toolkit_expert_title'.tr, 'Expert panel');
      expect('home_card_my_qr'.tr, 'QR Code');
    });
  });
}
