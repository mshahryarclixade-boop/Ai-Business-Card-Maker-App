import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart' hide Trans;
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/gemini_card_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../../routes/app_routes.dart';
import '../../custom_create/view/card_editor_view.dart';
import '../../../core/services/remote_config_service.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../../paywall/services/credits_gate.dart';
import '../../paywall/view/paywall_screen.dart';
import '../../profile_setup/controller/first_card_generator.dart';
import '../../profile_setup/service/profile_store.dart';
import '../../template/controller/template_controller.dart';
import '../../template/model/template_item.dart';
import '../../template/model/template_live_data.dart';
import '../../../core/translations/tr_extension.dart';
// import '../../../core/widgets/rate_app_dialog.dart';

class HomeController extends GetxController {
  final TextEditingController promptController = TextEditingController();

  final Rx<TemplateItem?> previewTemplate = Rx<TemplateItem?>(null);

  /// Realtime preview (empty background + user's info). Null when the tapped
  /// template has no empty version / JSON yet -> old AI flow is used.
  final Rx<TemplateData?> previewData = Rx<TemplateData?>(null);

  final RxBool applying = false.obs;

  /// Used to capture the live preview as PNGs when applying.
  final GlobalKey frontCaptureKey = GlobalKey();
  final GlobalKey backCaptureKey = GlobalKey();

  int _tapSeq = 0;
  Worker? _proWorker;

  final FirstCardGenerator _generator = FirstCardGenerator();

  /// Reuses the Template tab's controller (it already scans the assets).
  TemplateController get templates => Get.isRegistered<TemplateController>()
      ? Get.find<TemplateController>()
      : Get.put(TemplateController());

  @override
  void onReady() {
    super.onReady();

    // Home is the first screen where the No Internet dialog is allowed
    Get.find<ConnectivityService>().startMonitoring();

    // Home is the first screen where we ask for notification permission.
    NotificationService().requestPermissionAndSubscribe();

    // Realtime: if the subscription lapses/is refunded while the app is
    // open, send the user back to the paywall.
    _proWorker = ever<bool>(Get.find<SubscriptionController>().isUserPro, (
      pro,
    ) {
      if (!pro && Get.currentRoute == Routes.MAIN) {
        openPaywall(source: 'subscription_lapsed');
      }
    });

    // TEMP: testing only — uncomment to preview the rate dialog on Home.
    // showRateAppDialog(
    //   onYes: (rating) => debugPrint('Rated: $rating stars'),
    //   onNo: () => debugPrint('Pressed No'),
    // );
  }

  Future<void> previewTemplateTap(TemplateItem item) async {
    if (applying.value) return;

    // Tapping the selected template again closes the preview.
    if (previewTemplate.value?.id == item.id) {
      cancelPreview();
      return;
    }

    final seq = ++_tapSeq;

    final base = await TemplateData.load(item);
    TemplateData? live;
    if (base != null) {
      live = base.filled(TemplateData.currentProfileValues());
      await _precache(live);
    }

    // A newer tap / cancel / apply happened while we were loading.
    if (seq != _tapSeq || applying.value) return;

    previewData.value = live;
    previewTemplate.value = item;

    FirebaseAnalytics.instance.logEvent(
      name: 'template_previewed',
      parameters: {'category': item.category},
    );
  }

  void cancelPreview() {
    if (applying.value) return;
    _tapSeq++;
    previewTemplate.value = null;
    previewData.value = null;
  }

  /// Opens the template in the canvas editor, with the user's info filled in.
  Future<void> editTemplate() async {
    final item = previewTemplate.value;
    if (item == null || applying.value) return;

    FirebaseAnalytics.instance.logEvent(
      name: 'template_edit_started',
      parameters: {'category': item.category},
    );

    final service = Get.find<RecentDesignsService>();
    final before = service.designs.isEmpty ? null : service.designs.first.id;

    await Get.to(
      () => CardEditorView(template: item),
      transition: Transition.rightToLeft,
    );

    // If the user saved a card in the editor, the preview is no longer needed.
    final after = service.designs.isEmpty ? null : service.designs.first.id;
    if (after != before) cancelPreview();
  }

  /// Apply: live template (no AI, instant) or the old AI flow when the
  /// template has no empty version yet.
  Future<void> applyTemplate() async {
    final item = previewTemplate.value;
    if (item == null || applying.value) return;

    final live = previewData.value;
    if (live != null) {
      await _applyLive(item, live);
    } else {
      await _applyWithAi(item);
    }
  }

  Future<void> _applyLive(TemplateItem item, TemplateData live) async {
    applying.value = true;
    try {
      // Make sure the latest frame (fonts, images) is painted.
      await WidgetsBinding.instance.endOfFrame;

      final front = await _capture(frontCaptureKey);
      final back = await _capture(backCaptureKey);
      if (front == null || back == null) {
        throw Exception('Could not capture the template');
      }

      await Get.find<RecentDesignsService>().save(
        front,
        backThumbnailBytes: back,
        designData: live.toDesignData(),
        title: item.name,
      );

      _tapSeq++;
      previewTemplate.value = null;
      previewData.value = null;

      FirebaseAnalytics.instance.logEvent(
        name: 'template_applied',
        parameters: {'category': item.category, 'method': 'live'},
      );

      Get.snackbar(
        'home_template_applied_title'.tr,
        'home_template_applied_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'apply live template',
      );
      debugPrint('Apply live template error: $e');
      debugPrintStack(stackTrace: st);
      Get.snackbar(
        'home_template_apply_failed_title'.tr,
        'home_try_again'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } finally {
      applying.value = false;
    }
  }

  /// Old flow: builds a new card from the chosen template using AI.
  Future<void> _applyWithAi(TemplateItem item) async {
    if (!await Get.find<ConnectivityService>().ensureInternet()) return;

    // Plan limit: no-op unless Remote Config `credits_enabled` is on.
    final aiCardCost = RemoteConfigService().creditCosts.aiCard;
    if (!await CreditGate.canUse(cost: aiCardCost, source: 'template_ai')) {
      return;
    }

    applying.value = true;
    try {
      await _generator.generate(
        ProfileStore.to.profile.value,
        templateAssetPath: item.frontImagePath,
        title: item.name,
      );
      // Charged only now that the card was actually generated.
      await CreditGate.spend(cost: aiCardCost, source: 'template_ai');
      previewTemplate.value = null;
      previewData.value = null;

      FirebaseAnalytics.instance.logEvent(
        name: 'template_applied',
        parameters: {'category': item.category, 'method': 'ai'},
      );

      Get.snackbar(
        'home_template_applied_title'.tr,
        'home_template_applied_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } on GeminiException catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'apply template (gemini)',
      );
      debugPrint('Apply template failed: ${e.message}');
      debugPrintStack(stackTrace: st);
      Get.snackbar(
        'home_template_apply_failed_title'.tr,
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st, reason: 'apply template');
      debugPrint('Apply template error: $e');
      debugPrintStack(stackTrace: st);
      Get.snackbar(
        'home_template_apply_failed_title'.tr,
        'home_try_again'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } finally {
      applying.value = false;
    }
  }

  Future<Uint8List?> _capture(GlobalKey key, {double pixelRatio = 3}) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  /// Loads the template's images up front, so the preview appears at once.
  Future<void> _precache(TemplateData data) async {
    final ctx = Get.context;
    if (ctx == null) return;

    final paths = <String>{data.front.background, data.back.background};
    for (final side in [data.front, data.back]) {
      for (final e in side.elements) {
        if (e.imageAsset != null) paths.add(e.imageAsset!);
      }
    }

    for (final p in paths) {
      try {
        await precacheImage(AssetImage(p), ctx);
      } catch (_) {}
    }
  }

  Future<void> onGenerateWithAi() async {
    if (!await Get.find<ConnectivityService>().ensureInternet()) return;

    // TODO: hook up to AI generation service later
  }

  @override
  void onClose() {
    _proWorker?.dispose();
    promptController.dispose();
    super.onClose();
  }
}
