// lib/app/core/services/connectivity_service.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart' hide Trans;

import '../translations/tr_extension.dart';
import '../widgets/no_internet_dialog.dart';
import 'internet_connectivity_service.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _debounce;
  Timer? _poll;

  bool _dialogOpen = false;
  bool _monitoring = false;
  bool _evaluating = false;
  bool _recheck = false;

  /// The "you are offline" notice has been shown for this offline period (it is
  /// shown once on the way offline; after that the OfflineGate re-opens it on
  /// every tap).
  bool _offlineNoticeShown = false;

  /// How reachability is decided; replaceable in tests.
  @visibleForTesting
  Future<bool> Function()? probe;

  /// How long to wait before confirming a failed check (tests shorten it).
  @visibleForTesting
  Duration confirmDelay = const Duration(seconds: 1);

  /// Reactive flag if any screen wants to react to connectivity.
  final RxBool isOnline = true.obs;

  /// The No Internet dialog is on screen. The OfflineGate lets touches through
  /// to it only while this is true.
  final RxBool dialogVisible = false.obs;

  /// The app is locked: monitoring is on and there is no real internet.
  bool get isBlocked => _monitoring && !isOnline.value;

  @override
  void onReady() {
    super.onReady();

    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      // Connectivity events often fire several times in a row.
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), _evaluate);
    });

    // Global from the start (splash and onboarding included). Home's own
    // startMonitoring() call is now a harmless no-op.
    startMonitoring();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _poll?.cancel();
    _subscription?.cancel();
    super.onClose();
  }

  /// Starts watching the connection. Safe to call more than once.
  void startMonitoring() {
    if (_monitoring) return;
    _monitoring = true;
    _evaluate();
  }

  /// True only if the device is on a network AND a real request to the
  /// internet succeeds. A DNS lookup is not enough: Wi-Fi without data and
  /// captive portals can still resolve names.
  Future<bool> hasInternet() async {
    final custom = probe;
    if (custom != null) return custom();

    final results = await _connectivity.checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) return false;

    return InternetConnectivityService.hasInternetAccess();
  }

  /// Call before an action that NEEDS the network (AI generation, a purchase).
  /// Shows the dialog and returns `false` when there is no internet. Works even
  /// before `startMonitoring()`.
  ///
  ///   if (!await Get.find<ConnectivityService>().ensureInternet()) return;
  Future<bool> ensureInternet() async {
    final online = await hasInternet();
    isOnline.value = online;
    if (online) {
      _offlineNoticeShown = false;
    } else {
      showNoInternetDialog();
    }
    return online;
  }

  /// Used by the dialog's Retry button.
  Future<bool> retry() async {
    final online = await hasInternet();
    isOnline.value = online;
    if (online) {
      _offlineNoticeShown = false;
      dismissDialog();
    }
    return online;
  }

  /// Re-checks now (also what the timer and connectivity events call).
  @visibleForTesting
  Future<void> evaluateNow() => _evaluate();

  Future<void> _evaluate() async {
    if (!_monitoring) return;
    if (_evaluating) {
      // An event arrived mid-check: run once more when this one finishes.
      _recheck = true;
      return;
    }
    _evaluating = true;
    try {
      var online = await hasInternet();

      // One failed probe must not lock the whole app: confirm before going
      // offline.
      if (!online && isOnline.value) {
        await Future.delayed(confirmDelay);
        online = await hasInternet();
      }

      isOnline.value = online;

      if (online) {
        _offlineNoticeShown = false;
        dismissDialog();
      } else {
        // A keyboard left open would keep accepting input behind the lock.
        FocusManager.instance.primaryFocus?.unfocus();
        _showOfflineNotice();
      }
    } finally {
      _evaluating = false;
      if (_recheck) {
        _recheck = false;
        unawaited(_evaluate());
      } else {
        _scheduleNextCheck();
      }
    }
  }

  /// The connection can drop (or return) without any connectivity event, e.g.
  /// Wi-Fi that loses its upstream. Check again soon while offline so the app
  /// unlocks by itself, and now and then while online.
  void _scheduleNextCheck() {
    _poll?.cancel();
    _poll = Timer(
      isOnline.value ? const Duration(seconds: 20) : const Duration(seconds: 3),
      _evaluate,
    );
  }

  /// Going offline: the "No Internet" dialog opens once straight away. After
  /// it is closed it comes back on every tap (OfflineGate) until the
  /// connection is really back.
  void _showOfflineNotice() {
    if (_offlineNoticeShown) return;
    _offlineNoticeShown = true;
    showNoInternetDialog();
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

    dialogVisible.value = true;
    Get.dialog(
      NoInternetDialog(onRetry: retry, onClose: dismissDialog),
      // Any way of closing it (Close, a tap outside) is temporary: the gate
      // opens it again on the next tap while offline.
      barrierDismissible: true,
      useSafeArea: false, // lets the blur cover the status bar too
    ).then((_) {
      _dialogOpen = false;
      dialogVisible.value = false;
    });
  }

  void dismissDialog() {
    if (!_dialogOpen) return;
    final ctx = Get.overlayContext;
    if (ctx != null) {
      Navigator.of(ctx, rootNavigator: true).pop();
    }
  }
}