import 'dart:io';

import 'package:ai_business_card_maker/app/modules/profile_setup/service/first_card_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> events;

  setUp(() {
    events = [];
    FirstCardFlow.showsPaywall = () => true;
    FirstCardFlow.showPaywall = () async => events.add('paywall');
    FirstCardFlow.requestNotifications = () async => events.add('notifications');
  });

  test('action first, then the paywall, then the notification permission', () async {
    FirstCardFlow.begin();
    expect(FirstCardFlow.armed, isTrue); // Home waits: no notification dialog yet
    events.add('action done');
    await FirstCardFlow.afterAction();
    expect(events, ['action done', 'paywall', 'notifications']);
    expect(FirstCardFlow.armed, isFalse);
  });

  test('it runs once: a second return does not show anything again', () async {
    FirstCardFlow.begin();
    await FirstCardFlow.afterAction();
    await FirstCardFlow.afterAction();
    await FirstCardFlow.afterAction();
    expect(events, ['paywall', 'notifications']);
  });

  test('never armed (a normal scan later): nothing happens', () async {
    await FirstCardFlow.afterAction();
    expect(events, isEmpty);
  });

  test('control group / Pro (no paywall): notifications right after the action', () async {
    FirstCardFlow.showsPaywall = () => false;
    FirstCardFlow.begin();
    await FirstCardFlow.afterAction();
    expect(events, ['notifications']);
  });

  test('a failing paywall still ends with the notification permission', () async {
    FirstCardFlow.showPaywall = () async => throw Exception('boom');
    FirstCardFlow.begin();
    await FirstCardFlow.afterAction();
    expect(events, ['notifications']);
  });

  test('wiring: the first-card screen no longer opens the paywall, Home waits '
      'while armed, the action completes before the paywall', () {
    final view = File('lib/app/modules/profile_setup/view/first_card_ready_view.dart').readAsStringSync();
    expect(view.contains('PaywallTriggers'), isFalse);
    expect(view, contains('FirstCardFlow.begin()'));
    final home = File('lib/app/modules/home/controller/home_controller.dart').readAsStringSync();
    expect(home, contains('if (!FirstCardFlow.armed) NotificationService()'));
    final nav = File('lib/app/modules/main_nav/controller/main_nav_controller.dart').readAsStringSync();
    expect(nav.indexOf('await onScanTap()'), lessThan(nav.indexOf('FirstCardFlow.afterAction()')));
    expect(nav.indexOf('await showShareCardSheet('), lessThan(nav.indexOf('FirstCardFlow.afterAction()')));
  });
}
