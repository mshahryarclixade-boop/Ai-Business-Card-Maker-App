// lib/app/core/services/connectivity_service.dart

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../widgets/no_internet_dialog.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounce;

  bool _dialogOpen = false;
  bool _monitoring = false; // stays false on splash, turned on by Home

  /// Reactive flag if any screen wants to react to connectivity.
  final RxBool isOnline = true.obs;

  @override
  void onReady() {
    super.onReady();

    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      // Connectivity events often fire several times in a row.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), _evaluate);
    });
    // No initial check here — Home calls startMonitoring() instead.
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _subscription?.cancel();
    super.onClose();
  }

  /// Call this from the first screen where the dialog should be allowed
  /// (e.g. HomeController.onReady). Runs an initial check right away.
  void startMonitoring() {
    if (_monitoring) return;
    _monitoring = true;
    _evaluate();
  }

  /// True only if the device is on a network AND can actually reach the
  /// internet (Wi-Fi without data would otherwise count as "connected").
  Future<bool> hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) return false;

    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Call before a network action. Shows the dialog and returns `false`
  /// when there is no internet. Works even before `startMonitoring()`.
  ///
  ///   if (!await Get.find<ConnectivityService>().ensureInternet()) return;
  Future<bool> ensureInternet() async {
    final online = await hasInternet();
    isOnline.value = online;
    if (!online) showNoInternetDialog();
    return online;
  }

  /// Used by the dialog's Retry button.
  Future<bool> retry() async {
    final online = await hasInternet();
    isOnline.value = online;
    if (online) dismissDialog();
    return online;
  }

  Future<void> _evaluate() async {
    if (!_monitoring) return; // splash/onboarding: stay silent

    final online = await hasInternet();
    isOnline.value = online;

    if (online) {
      dismissDialog();
    } else {
      showNoInternetDialog();
    }
  }

  Future<void> showNoInternetDialog() async {
    if (_dialogOpen) return;
    _dialogOpen = true; // set first so concurrent calls don't stack dialogs

    // On cold start the navigator may not be ready yet — wait briefly.
    for (var i = 0; i < 20 && Get.overlayContext == null; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (Get.overlayContext == null) {
      _dialogOpen = false;
      return;
    }

    Get.dialog(
      NoInternetDialog(onRetry: retry, onClose: dismissDialog),
      barrierDismissible: false,
      useSafeArea: false, // lets the blur cover the status bar too
    ).then((_) => _dialogOpen = false);
  }

  void dismissDialog() {
    if (!_dialogOpen) return;
    final ctx = Get.overlayContext;
    if (ctx != null) {
      Navigator.of(ctx, rootNavigator: true).pop();
    }
  }
}