import 'package:ai_business_card_maker/app/modules/paywall/models/credit_config_model.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/credits_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<int> deducted;
  late int? balance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    deducted = [];
    balance = 5;
    CreditGate.resetCharged();
    CreditGate.enabledProvider = () => true;
    CreditGate.balanceProvider = () async => balance;
    CreditGate.deductProvider = (cost) async => deducted.add(cost);
  });

  group('canUse', () {
    test('passes everything while credits are disabled', () async {
      CreditGate.enabledProvider = () => false;
      balance = 0;
      expect(await CreditGate.canUse(cost: 1, source: 't'), isTrue);
    });

    test(
      'passes when the balance covers the cost, is unlimited or unknown',
      () async {
        expect(await CreditGate.canUse(cost: 1, source: 't'), isTrue);
        balance = -1;
        expect(await CreditGate.canUse(cost: 50, source: 't'), isTrue);
        balance = null;
        expect(await CreditGate.canUse(cost: 1, source: 't'), isTrue);
      },
    );

    test('a zero cost never blocks', () async {
      balance = 0;
      expect(await CreditGate.canUse(cost: 0, source: 't'), isTrue);
    });

    test('blocks a free user who is out of credits', () async {
      balance = 0;
      expect(await CreditGate.canUse(cost: 1, source: 't'), isFalse);
    });

    test('blocks a Pro user whose period pool is used up', () async {
      SharedPreferences.setMockInitialValues({'is_pro': true});
      balance = 0;
      expect(await CreditGate.canUse(cost: 1, source: 't'), isFalse);
    });
  });

  group('spend', () {
    test('charges the cost once', () async {
      await CreditGate.spend(cost: 1, source: 't');
      expect(deducted, [1]);
    });

    test('charges nothing while disabled or for a zero cost', () async {
      await CreditGate.spend(cost: 0, source: 't');
      CreditGate.enabledProvider = () => false;
      await CreditGate.spend(cost: 1, source: 't');
      expect(deducted, isEmpty);
    });

    test('the same dedupe key is charged only once', () async {
      await CreditGate.spend(cost: 2, source: 't', dedupeKey: 'card-1');
      await CreditGate.spend(cost: 2, source: 't', dedupeKey: 'card-1');
      await Future.wait([
        CreditGate.spend(cost: 2, source: 't', dedupeKey: 'card-2'),
        CreditGate.spend(cost: 2, source: 't', dedupeKey: 'card-2'),
      ]);
      expect(deducted, [2, 2]);
    });

    test('an already charged key passes canUse even with no credits', () async {
      await CreditGate.spend(cost: 1, source: 't', dedupeKey: 'card-1');
      balance = 0;
      expect(
        await CreditGate.canUse(cost: 1, source: 't', dedupeKey: 'card-1'),
        isTrue,
      );
    });

    test('a failed charge can be retried', () async {
      var fail = true;
      CreditGate.deductProvider = (cost) async {
        if (fail) throw Exception('offline');
        deducted.add(cost);
      };
      await CreditGate.spend(cost: 1, source: 't', dedupeKey: 'k');
      fail = false;
      await CreditGate.spend(cost: 1, source: 't', dedupeKey: 'k');
      expect(deducted, [1]);
    });
  });

  group('credit config', () {
    test('pools map each plan tier and fall back to free', () {
      const p = CreditPools();
      expect(p.forTier('free'), 5);
      expect(p.forTier('trial'), 50);
      expect(p.forTier('monthly'), 200);
      expect(p.forTier('yearly'), 2000);
      expect(p.forTier('mystery'), 5);
    });

    test('pools and costs parse overrides and survive bad JSON', () {
      expect(CreditPools.fromJsonString('{"monthly":300}').monthly, 300);
      expect(CreditPools.fromJsonString('{oops').yearly, 2000);
      expect(CreditCosts.fromJsonString('{"ai_card":3}').aiCard, 3);
      expect(CreditCosts.fromJsonString('').export, 0);
    });
  });
}
