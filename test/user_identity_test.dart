import 'dart:async';
import 'dart:io';

import 'package:ai_business_card_maker/app/core/services/device_identity.dart';
import 'package:ai_business_card_maker/app/core/services/device_usage_store.dart';
import 'package:ai_business_card_maker/app/core/services/user_sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:ai_business_card_maker/app/modules/email_signature/service/email_signature_store.dart';
import 'package:ai_business_card_maker/app/modules/paywall/models/cro_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/usage_service.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/user_credits_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _raw = '9f8e7d6c5b4a3921'; // what ANDROID_ID looks like
const _hash = 'a1a56dd23130d04d237bb17d820b5d98b224b184b3350b29081d273368a06afb';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String? systemId = _raw;
  var systemFails = false;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('uid').path,
        );
    await GetStorage.init();
  });

  setUp(() async {
    systemId = _raw;
    systemFails = false;
    SharedPreferences.setMockInitialValues({});
    DeviceIdentity.resetForTest();
    await GetStorage().erase();
    Get.reset();
    UserSync.available = () => true;
    UserSync.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_udid'), (
          call,
        ) async {
          if (systemFails) throw PlatformException(code: 'UNAVAILABLE');
          return systemId;
        });
  });

  tearDown(() {
    UserSync.available = () => false;
  });

  group('the device id', () {
    test('user_id is the ACTUAL device id, not the SHA-256 hash', () async {
      expect(await DeviceIdentity.userId(), _raw);
      final legacy = await DeviceIdentity.legacyHashId();
      expect(legacy, hasLength(64));
      expect(legacy, isNot(_raw));
      // The old id is exactly the SHA-256 of the actual id.
      expect(legacy, 'a1a56dd23130d04d237bb17d820b5d98b224b184b3350b29081d273368a06afb');
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(legacy), isTrue);
    });

    test('an app reinstall (all app data gone) gives the SAME id - the system '
        'answers again', () async {
      final before = await DeviceIdentity.userId();
      SharedPreferences.setMockInitialValues({}); // uninstall: app storage gone
      await GetStorage().erase();
      DeviceIdentity.resetForTest();
      expect(await DeviceIdentity.userId(), before);
    });

    test('Android: ANDROID_ID and iOS: Keychain UUID formats are both usable',
        () async {
      for (final id in ['8af8770a27cfd182', '7946DA4E-8429-423C-B405-B3FC77914E3E']) {
        systemId = id;
        DeviceIdentity.resetForTest();
        expect(await DeviceIdentity.userId(), id);
      }
    });

    test('if the system cannot answer, the saved copy is used; with neither, '
        'null (nothing is invented)', () async {
      expect(await DeviceIdentity.userId(), _raw);
      DeviceIdentity.resetForTest();
      systemFails = true;
      expect(await DeviceIdentity.userId(), _raw); // saved copy
      SharedPreferences.setMockInitialValues({});
      DeviceIdentity.resetForTest();
      expect(await DeviceIdentity.userIdOrNull(), isNull);
    });

    test('a recovered subscriber continues as their original id, which is '
        'remembered; their own id switches back', () async {
      await DeviceIdentity.adopt('oldphone0123456789');
      expect(await DeviceIdentity.userId(), 'oldphone0123456789');
      DeviceIdentity.resetForTest(); // app restart
      expect(await DeviceIdentity.userId(), 'oldphone0123456789');
      await DeviceIdentity.adopt(_raw);
      DeviceIdentity.resetForTest();
      expect(await DeviceIdentity.userId(), _raw);
    });
  });

  group('credit record migration (users/{id})', () {
    late Map<String, Map<String, dynamic>> db;
    Future<Map<String, dynamic>?> read(String id) async => db[id];
    Future<void> write(String id, Map<String, dynamic> d, {bool merge = false}) async {
      db[id] = merge ? {...?db[id], ...d} : Map.of(d);
    }

    setUp(() => db = {});

    test('moves the old record to the device id, keeps the old one marked',
        () async {
      db[_hash] = {'balance': 42, 'plan_tier': 'yearly', 'is_pro': true};
      final moved = await UserCreditsManager.moveLegacyUserDoc(
        id: _raw, legacy: _hash, read: read, write: write);
      expect(moved, isTrue);
      expect(db[_raw]!['balance'], 42);
      expect(db[_raw]!['plan_tier'], 'yearly');
      expect(db[_raw]!['migratedFrom'], _hash);
      expect(db[_hash]!['migratedTo'], _raw); // kept, never deleted
      expect(db[_hash]!['balance'], 42);
    });

    test('never overwrites an existing new record, and repeating is a no-op',
        () async {
      db[_hash] = {'balance': 42};
      db[_raw] = {'balance': 7};
      expect(await UserCreditsManager.moveLegacyUserDoc(
        id: _raw, legacy: _hash, read: read, write: write), isFalse);
      expect(db[_raw]!['balance'], 7);
      db.remove(_raw);
      await UserCreditsManager.moveLegacyUserDoc(
        id: _raw, legacy: _hash, read: read, write: write);
      expect(await UserCreditsManager.moveLegacyUserDoc(
        id: _raw, legacy: _hash, read: read, write: write), isFalse);
      expect(db.length, 2); // no duplicates
    });
  });

  group('limits survive a reinstall and a profile change', () {
    UsageService fresh({DateTime? now}) => UsageService(
      isPro: () => false,
      limits: () => const CroLimits(),
      clock: () => now ?? DateTime(2026, 11, 12, 9),
    );

    test('after a reinstall the server counters are brought back', () async {
      final u = fresh();
      expect(u.remaining(UsageFeature.scan), 5);
      u.mergeRemote({'scan': {'used': 5}, 'career_build': {'used': 1}});
      expect(u.remaining(UsageFeature.scan), 0);
      expect(u.canUse(UsageFeature.careerBuild), isFalse);
      expect(u.canUse(UsageFeature.careerOptimize), isTrue);
    });

    test('counters only ever go up; a smaller server number changes nothing',
        () async {
      final u = fresh();
      u.consume(UsageFeature.scan, dedupeKey: 'a');
      u.consume(UsageFeature.scan, dedupeKey: 'b');
      u.mergeRemote({'scan': {'used': 1}});
      expect(u.used(UsageFeature.scan), 2);
      u.mergeRemote({'scan': {'used': 4}});
      expect(u.used(UsageFeature.scan), 4);
    });

    test('Clixa chats: the server window counts only while it is still open',
        () async {
      final now = DateTime(2026, 11, 12, 9);
      var u = fresh(now: now);
      u.mergeRemote({
        'clixa_chat': {'used': 3, 'windowStart': now.subtract(const Duration(days: 2)).millisecondsSinceEpoch},
      });
      expect(u.canUse(UsageFeature.clixaChat), isFalse);
      u = fresh(now: now);
      await GetStorage().erase();
      u = fresh(now: now);
      u.mergeRemote({
        'clixa_chat': {'used': 3, 'windowStart': now.subtract(const Duration(days: 9)).millisecondsSinceEpoch},
      });
      expect(u.canUse(UsageFeature.clixaChat), isTrue); // the week is over
    });

    test('limits are device wide: not stored per profile', () {
      final src = File('lib/app/modules/paywall/services/usage_service.dart')
          .readAsStringSync();
      expect(src.contains('ProfileScope'), isFalse);
      expect(UsageService.storageKey, 'cro_usage');
    });
  });

  group('devices/{deviceId} (Firestore, no functions)', () {
    late _FakeStore fake;
    setUp(() {
      fake = _FakeStore();
      UserSync.store = fake;
      Get.put(UsageService(isPro: () => false, limits: () => const CroLimits()));
    });
    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

    test('a fresh device: the document is created as free, every counter 0',
        () async {
      await UserSync.sync(force: true);
      final d = fake.docs[_raw]!;
      expect(d['deviceId'], _raw);
      expect((d['plan'] as Map)['tier'], 'free');
      expect((d['plan'] as Map)['isPro'], false);
      for (final f in UserSync.features) {
        expect(((d['counters'] as Map)[f] as Map)['used'], 0, reason: f);
      }
      expect(fake.log.first, startsWith('read'));
      expect(fake.log[1], startsWith('create'));
    });

    test('an existing document is continued (reinstall = same device id): '
        'counters come back, nothing is created or reset', () async {
      fake.docs[_raw] = {
        'counters': {'scan': {'used': 5}, 'career_build': {'used': 1}},
      };
      await UserSync.sync(force: true);
      expect(fake.log.where((l) => l.startsWith('create')), isEmpty);
      expect(UsageService.to.remaining(UsageFeature.scan), 0);
      expect(UsageService.to.canUse(UsageFeature.careerBuild), isFalse);
      // The profile does not matter: the id is the device's.
      expect(await DeviceIdentity.userId(), _raw);
    });

    test('an action is counted with FieldValue.increment(1) on its counter',
        () async {
      await UserSync.sync(force: true);
      fake.log.clear();
      UserSync.track('template');
      await settle();
      expect(fake.log.single, 'update counters.template.used');
      expect(fake.lastFields!['counters.template.used'], isA<FieldValue>());
    });

    test('spending a scan increments it, Pro included', () async {
      await UserSync.sync(force: true);
      for (final pro in [false, true]) {
        fake.log.clear();
        Get.reset();
        Get.put(UsageService(isPro: () => pro, limits: () => const CroLimits()));
        UsageService.to.consume(UsageFeature.scan, dedupeKey: 'img$pro');
        await settle();
        expect(fake.log, contains('update counters.scan.used'), reason: 'pro=$pro');
      }
    });

    test('Clixa: the first chat of a week opens the week; later ones add 1',
        () async {
      await UserSync.sync(force: true);
      fake.log.clear();
      UsageService.to.consume(UsageFeature.clixaChat, dedupeKey: 'c1');
      UsageService.to.consume(UsageFeature.clixaChat, dedupeKey: 'c2');
      await settle();
      expect(fake.log, ['update counters.clixa_chat', 'update counters.clixa_chat.used']);
    });

    test('offline: a cache miss never creates a document; the last known '
        'counts stay in use', () async {
      fake.offline = true;
      UsageService.to.mergeRemote({'scan': {'used': 4}});
      await UserSync.sync(force: true);
      expect(fake.log.where((l) => l.startsWith('create')), isEmpty);
      expect(UsageService.to.remaining(UsageFeature.scan), 1);
      // The server cannot be read at all: still no crash, counts unchanged.
      fake.failReads = true;
      await UserSync.refresh();
      expect(UsageService.to.remaining(UsageFeature.scan), 1);
    });

    test('uses counted on the phone before the document existed are sent '
        'once it does (one +1 per write)', () async {
      fake.docs[_raw] = {'counters': {'scan': {'used': 1}}};
      UsageService.to.mergeRemote({'scan': {'used': 3}}); // phone is ahead
      await UserSync.sync(force: true);
      expect(fake.log.where((l) => l == 'update counters.scan.used').length, 2);
    });

    test('purchase / restore: the plan and expiry are written to the document',
        () async {
      await UserSync.sync(force: true);
      final meta = fake.metaWrites.last;
      expect((meta['plan'] as Map).keys, containsAll(['tier', 'isPro', 'expiresAt']));
      expect(meta['platform'], isIn(['android', 'ios']));
    });

    test('email signatures: the lifetime created count is the limit (delete '
        'and profile switch do not give it back)', () async {
      expect(EmailSignatureStore.canCreate(isPro: false), isTrue);
      UsageService.to.consume(UsageFeature.emailSignature, dedupeKey: 'sig1');
      EmailSignatureStore.signatures.clear(); // deleted / other profile
      expect(EmailSignatureStore.canCreate(isPro: false), isFalse);
      expect(EmailSignatureStore.canCreate(isPro: true), isTrue);
      await GetStorage().erase(); // a reinstall: the document's count comes back
      UsageService.to.mergeRemote({'email_signature': {'used': 1}});
      expect(EmailSignatureStore.canCreate(isPro: false), isFalse);
    });

    test('a failing server never breaks anything', () async {
      fake.failReads = true;
      await UserSync.sync(force: true);
      UserSync.track('qr');
      await settle();
      expect(await DeviceIdentity.userId(), _raw);
    });

    test('the rules: only devices/{id}, +1 counters, no delete, App Check '
        'is a console switch', () {
      final r = File('firestore.rules').readAsStringSync();
      expect(r, contains('match /devices/{deviceId}'));
      expect(r, contains('allow delete: if false;'));
      expect(r, contains('n.used == o.used + 1'));
      expect(r, contains('allow read, write: if false;')); // the rest denied
      expect(r.contains('match /users/'), isFalse);
      // Every counter the app writes is in the rules.
      for (final f in UserSync.features) {
        expect(r, contains("counterOk('$f')"), reason: f);
        expect(r, contains("zeroCounter('$f')"), reason: f);
      }
    });
  });

}

class _FakeStore implements DeviceStore {
  final docs = <String, Map<String, dynamic>>{};
  final log = <String>[];
  final metaWrites = <Map<String, dynamic>>[];
  Map<String, dynamic>? lastFields;
  bool offline = false;
  bool failReads = false;

  @override
  Future<DeviceRead> read(String id) async {
    log.add('read');
    if (failReads) throw Exception('unavailable');
    if (offline) return DeviceRead(docs[id], fromCache: true);
    return DeviceRead(docs[id]);
  }

  @override
  Future<void> create(String id, Map<String, dynamic> data) async {
    log.add('create');
    docs[id] = data;
  }

  @override
  Future<void> update(String id, Map<String, dynamic> fields) async {
    log.add('update ${fields.keys.join(',')}');
    lastFields = fields;
    if (fields.containsKey('plan')) metaWrites.add(fields);
  }
}
