// lib/app/core/widgets/offline_gate.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../services/connectivity_service.dart';

/// Wrap the whole app with this (GetMaterialApp.builder).
///
/// While there is no real internet:
///  * every touch on the app is absorbed, so nothing can be opened, tapped or
///    navigated to;
///  * every tap re-opens the existing No Internet dialog (closing it only
///    lifts the dialog, not the lock);
///  * the dialog itself stays usable (Retry / Close).
///
/// When the connection returns, ConnectivityService flips `isOnline` and the
/// app is usable again by itself.
class OfflineGate extends StatelessWidget {
  const OfflineGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // ConnectivityService must be registered before runApp.
    final service = Get.find<ConnectivityService>();

    return Obx(() {
      final blocked = service.isBlocked;
      final dialogUp = service.dialogVisible.value;

      return Listener(
        // Sees every touch, even those the AbsorbPointer below swallows.
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (service.isBlocked) service.showNoInternetDialog();
        },
        child: AbsorbPointer(
          // While the dialog is up its own route handles touches.
          absorbing: blocked && !dialogUp,
          child: child,
        ),
      );
    });
  }
}