import 'dart:io';
import 'package:ai_business_card_maker/app/modules/contacts/controller/contacts_controller.dart';
import 'package:ai_business_card_maker/app/modules/contacts/view/add_contact_view.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/model/scanned_contact_data.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/view/scan_card_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _fonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'];
  final l = FontLoader('SFPro');
  for (final f in ['Roboto-Regular.ttf','Roboto-Medium.ttf','Roboto-Bold.ttf']) {
    final file = File('$sdk/bin/cache/artifacts/material_fonts/$f');
    if (file.existsSync()) l.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
  }
  await l.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await _fonts();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (c) async => Directory.systemTemp.createTempSync('gs').path);
    await GetStorage.init();
  });
  const sizes = {'se 375x667': Size(375,667), '320x568': Size(320,568), '393x852': Size(393,852), 'ipad 820x1180': Size(820,1180)};
  for (final s in sizes.entries) {
    testWidgets('scan screen has no overflow on ${s.key}', (t) async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      t.view.physicalSize = s.value*2; t.view.devicePixelRatio = 2; addTearDown(t.view.reset);
      await t.pumpWidget(const GetMaterialApp(home: ScanCardView()));
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
    testWidgets('contact form opened from a scan (long text, warnings) has no overflow on ${s.key}', (t) async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      Get.put(ProfileStore());
      Get.put(ContactsController(), tag: 'contacts');
      t.view.physicalSize = s.value*2; t.view.devicePixelRatio = 2; addTearDown(t.view.reset);
      await t.pumpWidget(GetMaterialApp(home: AddContactView(scannedData: const ScannedContactData(
        firstName: 'Alexandre-Maximilian', lastName: 'Montgomery-Fitzgerald', companyName: 'International Entreprise Solutions Group',
        jobTitle: 'Senior Vice President of Global Business Development', email: 'alexandre.montgomery@internationalentreprise.com',
        phone: '+92 300 1234567', website: 'https://www.internationalentreprise.com/about', warnings: ['name','company']))));
      for (var i=0;i<6;i++) { await t.pump(const Duration(milliseconds: 150)); }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
