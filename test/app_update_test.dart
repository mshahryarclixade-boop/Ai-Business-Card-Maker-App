import 'package:ai_business_card_maker/app/core/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int? cmp(String a, String b) => AppUpdateService.compareVersions(a, b);

  group('compareVersions', () {
    test('compares numerically, not as text', () {
      expect(cmp('1.9.0', '1.10.0'), -1);
      expect(cmp('2.0.0', '1.99.99'), 1);
      expect(cmp('1.2.3', '1.2.3'), 0);
    });

    test('missing parts count as zero; build and pre-release are ignored', () {
      expect(cmp('1.0', '1.0.0'), 0);
      expect(cmp('1.0.0+3', '1.0.0'), 0);
      expect(cmp('1.0.1-beta', '1.0.0'), 1);
    });

    test('invalid versions are not comparable', () {
      expect(cmp('1.0.0', ''), isNull);
      expect(cmp('abc', '1.0.0'), isNull);
      expect(cmp('1..0', '1.0.0'), isNull);
    });
  });

  group('VersionConfig', () {
    test('parses the Remote Config JSON', () {
      final c = VersionConfig.fromJsonString(
        '{"min_build_number": 5, "min_version_label": "1.0.1", '
        '"latest_version_label": "1.2.0 (9)"}',
      );
      expect(c.minBuildNumber, 5);
      expect(c.minVersionLabel, '1.0.1');
      expect(c.latest.version, '1.2.0');
      expect(c.latest.build, 9);
    });

    test('latest label without a build number', () {
      final c = VersionConfig.fromJsonString('{"latest_version_label":"2.0"}');
      expect(c.latest.version, '2.0');
      expect(c.latest.build, isNull);
    });

    test('empty, broken or mistyped JSON means no restrictions', () {
      for (final raw in ['', '{oops', '[]', '{"min_build_number":"x"}']) {
        final c = VersionConfig.fromJsonString(raw);
        expect(c.minBuildNumber, 0, reason: raw);
        expect(c.minVersionLabel, '', reason: raw);
        expect(c.latest.version, '', reason: raw);
      }
    });

    test('a numeric string build number is accepted', () {
      expect(
        VersionConfig.fromJsonString('{"min_build_number":"4"}').minBuildNumber,
        4,
      );
    });
  });

  group('evaluate', () {
    UpdateType run(String json, {String version = '1.0.0', int build = 3}) =>
        AppUpdateService.evaluate(
          installedVersion: version,
          installedBuild: build,
          config: VersionConfig.fromJsonString(json),
        );

    test('forced when the build is below min_build_number', () {
      expect(run('{"min_build_number": 4}'), UpdateType.forced);
      expect(run('{"min_build_number": 3}'), UpdateType.none);
    });

    test('min_build_number 0 never forces', () {
      expect(run('{"min_build_number": 0}', build: 1), UpdateType.none);
    });

    test('forced when the version name is below min_version_label', () {
      expect(run('{"min_version_label": "1.0.1"}'), UpdateType.forced);
      expect(run('{"min_version_label": "1.0.0"}'), UpdateType.none);
      expect(run('{"min_version_label": "0.9.9"}'), UpdateType.none);
    });

    test('optional when behind latest_version_label', () {
      expect(run('{"latest_version_label":"1.1.0 (4)"}'), UpdateType.optional);
      expect(run('{"latest_version_label":"1.0.0 (4)"}'), UpdateType.optional);
      expect(run('{"latest_version_label":"1.0.0 (3)"}'), UpdateType.none);
      expect(
        run('{"latest_version_label":"1.0.0 (3)"}', build: 8),
        UpdateType.none,
      );
      expect(run('{"latest_version_label":"0.9.0 (1)"}'), UpdateType.none);
    });

    test('forced wins over optional', () {
      expect(
        run('{"min_build_number":9,"latest_version_label":"2.0.0 (9)"}'),
        UpdateType.forced,
      );
    });

    test('your current Remote Config values do not trigger anything', () {
      expect(
        run(
          '{"min_build_number":0,"min_version_label":"1.0.0",'
          '"latest_version_label":"1.0.0 (3)"}',
        ),
        UpdateType.none,
      );
    });

    test('empty or invalid config never triggers an update', () {
      expect(run(''), UpdateType.none);
      expect(run('{oops'), UpdateType.none);
      expect(run('{"latest_version_label":"soon"}'), UpdateType.none);
    });
  });
}
