import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_business_card_maker/app/core/services/card_profile_sync.dart';
import 'package:ai_business_card_maker/app/core/services/recent_designs_service.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/model/card_element_model.dart';
import 'package:ai_business_card_maker/app/core/services/profile_scope.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/model/user_profile_data.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image/image.dart' as img;

const _old = UserProfileData(
  fullName: 'Alex Morgan',
  email: 'alex@old.com',
  dialCode: '+1',
  phoneNumber: '202 555 0147',
  companyName: 'Skyway',
  designation: 'Travel Consultant',
  website: 'www.old.com',
);

const _new = UserProfileData(
  fullName: 'Sam Rivers',
  email: 'sam@new.com',
  dialCode: '+44',
  phoneNumber: '20 7946 0958',
  companyName: 'Orbit',
  designation: 'Guide',
  website: 'www.new.com',
);

CardElement _text(String id, String text, {String? field, double y = 10}) =>
    CardElement(
      id: id,
      type: CardElementType.text,
      position: Offset(20, y),
      text: text,
      fontFamily: 'SF Pro',
      fontSize: 14,
      field: field,
    );

/// A saved card (both sides) as the editor stores it.
Map<String, dynamic> _design({
  String name = 'Alex Morgan',
  String backCompany = 'SKYWAY', // a template that shows it in capitals
}) => {
  'orientation': 'landscape',
  'backgroundColor': 0xFFF4F1E8,
  'backgroundImagePath': null,
  'backgroundTemplate': null,
  'elements': [
    _text('name', name, field: 'name', y: 20).toJson(),
    _text('title', 'Travel Consultant', field: 'title', y: 50).toJson(),
    _text('phone', '+1 202 555 0147', field: 'phone', y: 80).toJson(),
    CardElement(
      id: 'phone_icon',
      type: CardElementType.symbol,
      position: const Offset(5, 80),
      symbol: '☎',
      field: 'phone',
    ).toJson(),
    _text('email', 'alex@old.com', field: 'email', y: 110).toJson(),
    _text('mine', 'My own slogan', y: 140).toJson(), // no field: the user's
  ],
  'back': {
    'backgroundColor': 0xFF2764D5,
    'backgroundImagePath': null,
    'backgroundTemplate': null,
    'elements': [
      _text('b_company', backCompany, field: 'company', y: 60).toJson(),
      _text('b_site', 'www.old.com', field: 'website', y: 150).toJson(),
    ],
  },
};

List<Map<String, dynamic>> _els(Map<String, dynamic> side) =>
    (side['elements'] as List).cast<Map<String, dynamic>>();

String _textOf(Map<String, dynamic> side, String id) =>
    _els(side).firstWhere((e) => e['id'] == id)['text'] as String;

Uint8List _png() => Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('cards').path,
        );
    await GetStorage.init();
  });

  setUp(() async {
    Get.reset();
    await GetStorage().erase();
  });

  group('CardProfileSync (what follows a profile change)', () {
    test('updates the details on both sides', () {
      final out = CardProfileSync.apply(_design(), _old, _new)!;
      expect(_textOf(out, 'name'), 'Sam Rivers');
      expect(_textOf(out, 'title'), 'Guide');
      expect(_textOf(out, 'phone'), '+44 20 7946 0958');
      expect(_textOf(out, 'email'), 'sam@new.com');
      final back = out['back'] as Map<String, dynamic>;
      expect(_textOf(back, 'b_site'), 'www.new.com');
      expect(_textOf(back, 'b_company'), 'ORBIT'); // kept in capitals
    });

    test('a text the user edited by hand is left alone', () {
      final out = CardProfileSync.apply(_design(name: 'Alexander the Great'), _old, _new)!;
      expect(_textOf(out, 'name'), 'Alexander the Great');
      expect(_textOf(out, 'title'), 'Guide'); // the untouched ones still follow
    });

    test('elements the user added, and every style, stay as they are', () {
      final src = _design();
      final out = CardProfileSync.apply(src, _old, _new)!;
      expect(_textOf(out, 'mine'), 'My own slogan');
      final before = _els(src).firstWhere((e) => e['id'] == 'name');
      final after = _els(out).firstWhere((e) => e['id'] == 'name');
      for (final k in ['position', 'fontSize', 'fontFamily', 'color', 'fontWeight']) {
        expect(after[k], before[k], reason: k);
      }
      expect(out['backgroundColor'], src['backgroundColor']);
      expect(out['back']['backgroundColor'], src['back']['backgroundColor']);
    });

    test('the input data is not modified', () {
      final src = _design();
      final snapshot = jsonEncode(src);
      CardProfileSync.apply(src, _old, _new);
      expect(jsonEncode(src), snapshot);
    });

    test('nothing to change -> null', () {
      expect(CardProfileSync.apply(_design(), _old, _old), isNull);
      // a change that nothing on the card shows
      const sameDetails = UserProfileData(fullName: 'Alex Morgan', email: 'alex@old.com', dialCode: '+1', phoneNumber: '202 555 0147', companyName: 'Skyway', designation: 'Travel Consultant', website: 'www.old.com', logoName: 'x');
      expect(CardProfileSync.apply(_design(), _old, sameDetails), isNull);
    });

    test('a removed phone number takes its icon with it', () {
      const noPhone = UserProfileData(fullName: 'Alex Morgan', email: 'alex@old.com', companyName: 'Skyway', designation: 'Travel Consultant', website: 'www.old.com');
      final out = CardProfileSync.apply(_design(), _old, noPhone)!;
      final ids = _els(out).map((e) => e['id']).toList();
      expect(ids, isNot(contains('phone')));
      expect(ids, isNot(contains('phone_icon')));
      expect(ids, contains('name'));
    });

    test('the logo follows the profile: replaced, refitted, or removed', () {
      final withLogo = _design();
      (withLogo['elements'] as List).add(CardElement(
        id: 'logo', type: CardElementType.image, position: const Offset(100, 10),
        imageFile: File('/old/logo.png'), width: 40, height: 40, field: 'logo',
      ).toJson());
      final a = UserProfileData(fullName: _old.fullName, logoBytes: Uint8List.fromList([1, 2, 3]));
      final b = UserProfileData(fullName: _old.fullName, logoBytes: Uint8List.fromList([9, 9, 9, 9]));

      final replaced = CardProfileSync.apply(withLogo, a, b, newLogoPath: '/new/logo.png', newLogoAspect: 2)!;
      final logo = _els(replaced).firstWhere((e) => e['id'] == 'logo');
      expect(logo['imageFilePath'], '/new/logo.png');
      expect((logo['width'] as num) / (logo['height'] as num), closeTo(2, 0.001)); // not stretched

      final removed = CardProfileSync.apply(withLogo, a, const UserProfileData(fullName: 'Alex Morgan'))!;
      expect(_els(removed).where((e) => e['id'] == 'logo'), isEmpty);
    });
  });

  group('saved cards in the service', () {
    late RecentDesignsService service;

    setUp(() async {
      Get.put(ProfileStore());
      ProfileStore.to.profile.value = _old;
      service = RecentDesignsService();
      await service.init();
      Get.put(service);
    });

    tearDown(() => service.onClose());

    test('update keeps the card in place: same id, place, title; one card; old pictures gone', () async {
      final first = await service.save(_png(), backThumbnailBytes: _png(), designData: _design(), title: 'First');
      await service.save(_png(), designData: _design(), title: 'Second');
      final oldPaths = [first.path, first.backPath!];

      final updated = (await service.update(first.id, front: _png(), back: _png(), designData: _design(name: 'Edited')))!;

      expect(service.designs.length, 2, reason: 'no copy');
      expect(service.designs.last.id, first.id, reason: 'same place');
      expect(updated.title, 'First');
      expect(_textOf(updated.designData!, 'name'), 'Edited');
      expect(updated.path, isNot(first.path), reason: 'new file: no stale cached picture');
      for (final p in oldPaths) {
        expect(File(p).existsSync(), isFalse);
      }
      expect(updated.file.existsSync(), isTrue);
    });

    test('deleting a card updates the list and removes its files', () async {
      final d = await service.save(_png(), backThumbnailBytes: _png(), designData: _design());
      await service.delete(d.id);
      expect(service.designs, isEmpty);
      expect(service.savedDesigns, isEmpty);
      expect(d.file.existsSync(), isFalse);
    });

    test('a profile change reaches the saved cards, and survives a restart', () async {
      final d = await service.save(_png(), backThumbnailBytes: _png(), designData: _design(), title: 'Mine');

      ProfileStore.to.savePersonal(
        fullName: _new.fullName, email: _new.email, dialCode: _new.dialCode, phoneNumber: _new.phoneNumber,
      );
      ProfileStore.to.saveBusiness(
        companyName: _new.companyName, designation: _new.designation, website: _new.website,
        logoBytes: null, logoName: '',
      );

      // The refresh runs a moment after the last change.
      RecentDesign? now;
      for (var i = 0; i < 80; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        now = service.byId(d.id);
        if (now != null && _textOf(now.designData!, 'name') == 'Sam Rivers') break;
      }
      expect(now, isNotNull);
      final data = now!.designData!;
      expect(_textOf(data, 'name'), 'Sam Rivers');
      expect(_textOf(data, 'email'), 'sam@new.com');
      expect(_textOf(data, 'mine'), 'My own slogan');
      expect(_textOf(data['back'] as Map<String, dynamic>, 'b_site'), 'www.new.com');
      expect(now.title, 'Mine');
      expect(service.designs.length, 1);
      expect(now.path, isNot(d.path));
      expect(now.file.existsSync(), isTrue);
      expect(now.backFile!.existsSync(), isTrue);
      expect(File(d.path).existsSync(), isFalse, reason: 'the old picture is gone');
      // The new picture really is a card-sized rendering.
      final pic = img.decodePng(now.file.readAsBytesSync())!;
      expect(pic.width, 340 * 3);
      expect(pic.height, 214 * 3);

      // "Restart": a new service reads what was stored.
      final again = RecentDesignsService();
      await again.init();
      final stored = again.byId(d.id)!;
      expect(_textOf(stored.designData!, 'name'), 'Sam Rivers');
      expect(stored.path, now.path);
      again.onClose();
    });

    test('switching profile is not an edit: the cards are left alone', () async {
      final d = await service.save(_png(), designData: _design());
      // What ProfilesManager.switchTo does: the scope changes, then the
      // details of the other profile are loaded.
      final before = ProfileScope.id;
      ProfileScope.id = 'other';
      ProfileStore.to.profile.value = _new;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      ProfileScope.id = before;
      expect(_textOf(service.byId(d.id)!.designData!, 'name'), 'Alex Morgan');
    });
  });
}
