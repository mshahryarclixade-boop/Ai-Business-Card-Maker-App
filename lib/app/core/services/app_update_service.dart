import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_colors.dart';
import '../widgets/app_dialog.dart';
import 'remote_config_service.dart';
import 'store_links.dart';

enum UpdateType { none, optional, forced }

/// This platform's version policy from Remote Config
/// (`android_version_config` / `ios_version_config`):
/// ```json
/// { "min_build_number": 0, "min_version_label": "1.0.0",
///   "latest_version_label": "1.0.0 (3)" }
/// ```
/// Every field is optional and an invalid value counts as "not set", so a
/// missing or broken config never triggers an update.
class VersionConfig {
  const VersionConfig({
    this.minBuildNumber = 0,
    this.minVersionLabel = '',
    this.latestVersionLabel = '',
  });

  /// Installs with a build number below this are blocked; 0 disables it.
  final int minBuildNumber;

  /// Installs with an older version name are blocked; '' disables it.
  final String minVersionLabel;

  /// Newest release as `1.0.0 (3)` (version name, build number in
  /// brackets); older installs get an optional prompt.
  final String latestVersionLabel;

  factory VersionConfig.fromJsonString(String raw) {
    if (raw.trim().isEmpty) return const VersionConfig();
    try {
      final j = jsonDecode(raw);
      if (j is! Map) return const VersionConfig();
      final build = j['min_build_number'];
      return VersionConfig(
        minBuildNumber: build is num
            ? build.toInt()
            : int.tryParse('${build ?? ''}') ?? 0,
        minVersionLabel: '${j['min_version_label'] ?? ''}'.trim(),
        latestVersionLabel: '${j['latest_version_label'] ?? ''}'.trim(),
      );
    } catch (_) {
      return const VersionConfig();
    }
  }

  /// `1.0.0 (3)` -> (`1.0.0`, 3). The build part may be missing (null).
  ({String version, int? build}) get latest {
    final m = RegExp(
      r'^\s*([^\s(]+)\s*(?:\((\d+)\))?\s*$',
    ).firstMatch(latestVersionLabel);
    if (m == null) return (version: '', build: null);
    return (version: m.group(1)!, build: int.tryParse(m.group(2) ?? ''));
  }
}

abstract final class AppUpdateService {
  static const _dismissedKey = 'dismissed_update_version';

  /// Compares dotted versions numerically (`1.10.0` > `1.9.0`); a build
  /// suffix (`+3`) or pre-release tag (`-beta`) is ignored and missing parts
  /// count as 0. Returns null when either value isn't a valid version.
  static int? compareVersions(String a, String b) {
    final pa = _parse(a);
    final pb = _parse(b);
    if (pa == null || pb == null) return null;
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x < y ? -1 : 1;
    }
    return 0;
  }

  static List<int>? _parse(String v) {
    final core = v.trim().split(RegExp(r'[+-]')).first;
    if (core.isEmpty) return null;
    final parts = <int>[];
    for (final p in core.split('.')) {
      final n = int.tryParse(p);
      if (n == null || n < 0) return null;
      parts.add(n);
    }
    return parts;
  }

  /// Pure decision, separated for tests.
  /// Forced: the build is below `min_build_number`, or the version name is
  /// below `min_version_label`. Optional: behind `latest_version_label`
  /// (older version name, or the same version with a lower build number).
  static UpdateType evaluate({
    required String installedVersion,
    required int installedBuild,
    required VersionConfig config,
  }) {
    if ((config.minBuildNumber > 0 && installedBuild < config.minBuildNumber) ||
        (compareVersions(installedVersion, config.minVersionLabel) ?? 0) < 0) {
      return UpdateType.forced;
    }
    final latest = config.latest;
    final byVersion = compareVersions(installedVersion, latest.version);
    if (byVersion != null &&
        (byVersion < 0 ||
            (byVersion == 0 &&
                latest.build != null &&
                installedBuild < latest.build!))) {
      return UpdateType.optional;
    }
    return UpdateType.none;
  }

  /// Never throws: any failure (Remote Config unavailable, package info
  /// error) means "no update", so launch is never blocked by this check.
  static Future<UpdateType> check() async {
    try {
      final rc = RemoteConfigService();
      // Read fresh values: wait (bounded) for the startup fetch+activate.
      await rc.whenFetched().timeout(const Duration(seconds: 4));
      final info = await PackageInfo.fromPlatform();
      final config = VersionConfig.fromJsonString(rc.versionConfigRaw);
      final result = evaluate(
        installedVersion: info.version,
        installedBuild: int.tryParse(info.buildNumber) ?? 0,
        config: config,
      );
      final summary =
          'installed=${info.version}+${info.buildNumber} '
          'minBuild=${config.minBuildNumber} '
          'minLabel="${config.minVersionLabel}" '
          'latest="${config.latestVersionLabel}" -> ${result.name}';
      log(summary, name: 'AppUpdateService');
      if (kDebugMode) {
        debugPrint('AppUpdateService: $summary | ${rc.versionDebugInfo}');
      }
      return result;
    } catch (e) {
      log('Update check failed: $e', name: 'AppUpdateService');
      return UpdateType.none;
    }
  }

  /// Opens this app's Play Store / App Store listing.
  static Future<void> openStore() => StoreLinks.open();

  /// The update dialog with **Update Now** and **Later** buttons.
  ///
  /// Optional update: dismissible, and "Later" is remembered per
  /// `latest_version_label`, so it isn't shown again until a newer release.
  /// Forced update ([forced]): not dismissible (no barrier tap, no Back) and
  /// without "Later" — the only way on is the store.
  static Future<void> showUpdateDialog({required bool forced}) async {
    final latest = VersionConfig.fromJsonString(
      RemoteConfigService().versionConfigRaw,
    ).latestVersionLabel;
    final box = GetStorage();
    if (!forced) {
      if (box.read<String>(_dismissedKey) == latest) return;
      // Let the first screen settle before covering it.
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    final context = Get.context;
    if (context == null || !context.mounted) return;
    await showBlurredDialog<void>(
      context,
      PopScope(
        canPop: !forced,
        child: AppDialogCard(
          children: [
            const AppDialogIcon(Icons.system_update_rounded),
            const SizedBox(height: 18),
            AppDialogText(
              title: forced ? 'Update required' : 'Update available',
              message: forced
                  ? 'This version of the app is no longer supported. '
                        'Please update to continue.'
                  : 'A newer version of the app is available with '
                        'improvements and fixes.',
            ),
            const SizedBox(height: 22),
            Builder(
              builder: (ctx) => AppDialogButton(
                label: 'Update Now',
                color: AppColors.accent,
                onTap: () {
                  if (!forced) Navigator.of(ctx).pop();
                  openStore();
                },
              ),
            ),
            // if (!forced) ...[
            //   const SizedBox(height: 11),
            //   Builder(
            //     builder: (ctx) => AppDialogButton(
            //       label: 'Later',
            //       color: const Color(0xFF3A3A3C),
            //       onTap: () {
            //         box.write(_dismissedKey, latest);
            //         Navigator.of(ctx).pop();
            //       },
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
      barrierDismissible: !forced,
    );
  }
}
