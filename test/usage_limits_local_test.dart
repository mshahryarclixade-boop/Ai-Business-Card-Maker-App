import 'dart:io';

import 'package:ai_business_card_maker/app/modules/email_signature/service/email_signature_store.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/cro_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/usage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('ul').path,
        );
    await GetStorage.init();
  });

  setUp(() async {
    Get.reset();
    await GetStorage().erase();
    Get.put(UsageService(isPro: () => false, limits: () => const CroLimits()));
  });

  test('email signatures: the lifetime created count is the limit (a delete '
      'does not give it back)', () {
    expect(EmailSignatureStore.canCreate(isPro: false), isTrue);
    UsageService.to.consume(UsageFeature.emailSignature, dedupeKey: 'sig1');
    EmailSignatureStore.signatures.clear();
    expect(EmailSignatureStore.canCreate(isPro: false), isFalse);
    expect(EmailSignatureStore.canCreate(isPro: true), isTrue);
  });

  test('limits are device wide, not per profile', () {
    final src = File('lib/app/modules/paywall/services/usage_service.dart').readAsStringSync();
    expect(src.contains('ProfileScope'), isFalse);
    expect(UsageService.storageKey, 'cro_usage');
  });

  test('no device-id (UDID) dependency or configuration is left', () {
    expect(File('pubspec.yaml').readAsStringSync().toLowerCase().contains('udid'), isFalse);
    final lib = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final f in lib) {
      final t = f.readAsStringSync().toLowerCase();
      expect(t.contains('flutter_udid') || t.contains('deviceidentity') || t.contains("'udid'"), isFalse, reason: f.path);
    }
    expect(File('firestore.rules').existsSync(), isFalse);
    expect(File('lib/app/core/services/device_identity.dart').existsSync(), isFalse);
  });
}
