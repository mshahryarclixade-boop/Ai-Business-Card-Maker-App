import 'package:ai_business_card_maker/app/core/services/permission_gate.dart';
import 'package:ai_business_card_maker/app/core/utils/input_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('email', () {
    test('accepts normal addresses', () {
      for (final e in ['a@b.co', 'first.last@company.com', 'x+tag@mail.example.org', ' me@site.io ']) {
        expect(InputValidators.isValidEmail(e), isTrue, reason: e);
      }
    });
    test('rejects bad addresses', () {
      for (final e in ['', 'abc', 'a@b', 'a@@b.com', '@b.com', 'a@.com', 'a b@c.com', 'a..b@c.com', 'a@b..com', 'a@b.c', '.a@b.com', 'a.@b.com', 'a@-b.com']) {
        expect(InputValidators.isValidEmail(e), isFalse, reason: e);
      }
      expect(InputValidators.isValidEmail('${'a' * 250}@b.com'), isFalse);
    });
    test('rejects obvious domain typos', () {
      for (final e in [
        'a@gmail.con', 'a@company.con', 'a@site.cmo', 'a@site.comm', 'a@site.ocm',
        'a@gmial.com', 'a@gmai.com', 'a@yaho.com', 'a@hotmial.com', 'a@outlok.com',
        'a@gmail.co', 'a@site.vom', 'a@site.xom', 'A@GMAIL.CON',
      ]) {
        expect(InputValidators.isValidEmail(e), isFalse, reason: e);
      }
      for (final e in ['a@gmail.com', 'a@company.co', 'a@site.org', 'a@x.co.uk', 'a@site.io', 'a@site.net', 'a@yahoo.com', 'a@outlook.com', 'a@site.pk', 'a@site.com.pk']) {
        expect(InputValidators.isValidEmail(e), isTrue, reason: e);
      }
    });
    test('emailError: empty is fine, bad gives the message', () {
      expect(InputValidators.emailError(''), isNull);
      expect(InputValidators.emailError('a@b.com'), isNull);
      expect(InputValidators.emailError('nope'), isNotNull);
    });
  });

  group('phone', () {
    test('accepts common formats', () {
      for (final p in ['+92 300 1234567', '0300-1234567', '(555) 123-4567', '+1 555 123 4567', '3001234567']) {
        expect(InputValidators.isValidPhone(p), isTrue, reason: p);
      }
      expect(InputValidators.isValidPhone('3001234567', dialCode: '+92'), isTrue);
      expect(InputValidators.isValidPhone('1234', dialCode: '+971'), isTrue);
    });
    test('rejects bad numbers', () {
      for (final p in ['abc', '12', '123456', '+', '1234567890123456', '300-abc-1234', '300 123 4567 890 123 456', '++92 300 1234567']) {
        expect(InputValidators.isValidPhone(p), isFalse, reason: p);
      }
      expect(InputValidators.isValidPhone('12', dialCode: '+92'), isFalse);
      expect(InputValidators.isValidPhone('1234567890123456', dialCode: '+92'), isFalse);
    });
    test('formatters drop letters and cap the length', () {
      final f = InputValidators.phoneFormatters;
      var v = const TextEditingValue(text: '+92 abc 300');
      for (final x in f) {
        v = x.formatEditUpdate(TextEditingValue.empty, v);
      }
      expect(v.text, '+92  300');
      v = TextEditingValue(text: '1' * 40);
      for (final x in f) {
        v = x.formatEditUpdate(TextEditingValue.empty, v);
      }
      expect(v.text.length, InputValidators.maxPhoneDigits);
    });
    test('the 16th digit cannot be typed; separators do not count', () {
      final f = InputValidators.phoneFormatters;
      TextEditingValue run(String old, String next) {
        var v = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
        for (final x in f) {
          v = x.formatEditUpdate(TextEditingValue(text: old), v);
        }
        return v;
      }
      expect(run('123456789012345', '1234567890123456').text, '123456789012345');
      expect(run('+92 300 12345678', '+92 300 123456789').text, '+92 300 123456789'); // 14 digits + ...
      expect(run('', '+92 300 1234567 8901234').text.replaceAll(RegExp(r'\D'), '').length, 15);
    });
    test('email formatter drops spaces', () {
      var v = const TextEditingValue(text: 'a b@c.com');
      for (final x in InputValidators.emailFormatters) {
        v = x.formatEditUpdate(TextEditingValue.empty, v);
      }
      expect(v.text, 'ab@c.com');
    });
  });

  group('PermissionGate', () {
    late Map<Permission, PermissionStatus> status;
    late int requests;
    late int settingsOpened;

    setUp(() {
      Get.testMode = true;
      status = {};
      requests = 0;
      settingsOpened = 0;
      PermissionGate.statusOf = (p) async => status[p] ?? PermissionStatus.denied;
      PermissionGate.requestOf = (p) async {
        requests++;
        return status[p] = _grant[p] ?? status[p] ?? PermissionStatus.denied;
      };
      PermissionGate.openSettings = () async {
        settingsOpened++;
        return true;
      };
    });
    tearDown(() {
      _grant.clear();
      PermissionGate.statusOf = (_) async => PermissionStatus.granted;
      PermissionGate.requestOf = (_) async => PermissionStatus.granted;
      PermissionGate.openSettings = openAppSettings;
    });

    Future<void> host(WidgetTester t) => t.pumpWidget(
      GetMaterialApp(home: Scaffold(body: Builder(builder: (c) => TextButton(onPressed: () {}, child: const Text('x'))))),
    );

    testWidgets('granted: no dialog', (t) async {
      status[Permission.camera] = PermissionStatus.granted;
      await host(t);
      var ok = false;
      await t.runAsync(() async => ok = await PermissionGate.ensure(AppPermission.camera));
      expect(ok, isTrue);
      expect(requests, 0);
      expect(find.text('Open Settings'), findsNothing);
    });

    testWidgets('denied then allowed in the system prompt: goes ahead', (t) async {
      _grant[Permission.camera] = PermissionStatus.granted;
      await host(t);
      var ok = false;
      await t.runAsync(() async => ok = await PermissionGate.ensure(AppPermission.camera));
      expect(ok, isTrue);
      expect(requests, 1);
    });

    testWidgets('refused but can be asked again: no dialog, asked again next time', (t) async {
      await host(t);
      for (var round = 1; round <= 2; round++) {
        var ok = true;
        await t.runAsync(() async => ok = await PermissionGate.ensure(AppPermission.microphone));
        expect(ok, isFalse);
        expect(requests, round); // the system prompt each time
        expect(find.text('Open Settings'), findsNothing);
      }
    });

    testWidgets('refused and now blocked (e.g. iOS): Open Settings / Later, every try', (t) async {
      await host(t);
      _grant[Permission.microphone] = PermissionStatus.permanentlyDenied;
      bool? ok;
      final f = PermissionGate.ensure(AppPermission.microphone).then((v) => ok = v);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      await t.tap(find.text('Later'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await f;
      expect(ok, isFalse);
      expect(settingsOpened, 0);
      expect(requests, 1);
      // Next try: no system prompt (blocked), the dialog again.
      final f2 = PermissionGate.ensure(AppPermission.microphone);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Open Settings'), findsOneWidget);
      await t.tap(find.text('Later'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await f2;
      expect(requests, 1);
    });

    testWidgets('allowed in Settings afterwards: status is re-read and it works', (t) async {
      status[Permission.camera] = PermissionStatus.permanentlyDenied;
      await host(t);
      expect(await t.runAsync(() => PermissionGate.isGranted(AppPermission.camera)), isFalse);
      status[Permission.camera] = PermissionStatus.granted; // user flips it in Settings
      expect(await t.runAsync(() => PermissionGate.isGranted(AppPermission.camera)), isTrue);
      var ok = false;
      await t.runAsync(() async => ok = await PermissionGate.ensure(AppPermission.camera));
      expect(ok, isTrue);
      expect(requests, 0);
    });

    testWidgets('permanently denied: no system prompt, Open Settings opens settings', (t) async {
      status[Permission.camera] = PermissionStatus.permanentlyDenied;
      await host(t);
      final f = PermissionGate.ensure(AppPermission.camera);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('Open Settings'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(await f, isFalse);
      expect(requests, 0);
      expect(settingsOpened, 1);
    });
  });
}

final _grant = <Permission, PermissionStatus>{};
