import '../../profile_setup/service/first_card_flow.dart';
import '../../../core/services/user_sync_service.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import '../../../core/services/ai_frame_card_builder.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart' hide Trans;
import 'package:get_storage/get_storage.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/gemini_card_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../../routes/app_routes.dart';
import '../../custom_create/view/card_editor_view.dart';
import '../../../core/services/remote_config_service.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../../paywall/services/credits_gate.dart';
import '../../paywall/services/free_limits.dart';
import '../../paywall/services/usage_service.dart';
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

  /// Ids of the templates the user applied, the latest first. They lead the
  /// Free Templates list; the AI card is first until something else is applied.
  final RxList<String> templateOrder = <String>[].obs;
  static const _orderKey = 'home_template_order';
  final _box = GetStorage();

  /// [items] in the order Home shows them: the AI card, then the rest, with
  /// the applied templates moved to the front (latest applied first).
  List<TemplateItem> orderedTemplates(List<TemplateItem> items) {
    final all = [kAiCardTemplate, ...items];
    final rank = {
      for (var i = 0; i < templateOrder.length; i++) templateOrder[i]: i,
    };
    final applied = all.where((t) => rank.containsKey(t.id)).toList()
      ..sort((a, b) => rank[a.id]!.compareTo(rank[b.id]!));
    return [...applied, ...all.where((t) => !rank.containsKey(t.id))];
  }

  /// A template was applied: it becomes the first in the list.
  void _promote(String id) {
    templateOrder.remove(id);
    templateOrder.insert(0, id);
    _box.write(_orderKey, templateOrder.toList());
  }

  int _tapSeq = 0;
  Worker? _proWorker;

  final FirstCardGenerator _generator = FirstCardGenerator();

  /// Reuses the Template tab's controller (it already scans the assets).
  TemplateController get templates => Get.isRegistered<TemplateController>()
      ? Get.find<TemplateController>()
      : Get.put(TemplateController());

  @override
  void onInit() {
    super.onInit();
    final saved = _box.read<List<dynamic>>(_orderKey);
    if (saved != null) templateOrder.assignAll(saved.whereType<String>());
  }

  @override
  void onReady() {
    super.onReady();

    // Home is the first screen where the No Internet dialog is allowed
    Get.find<ConnectivityService>().startMonitoring();

    // Home is the first screen where we ask for notification permission.
    // (After the first card the permission is asked once the first action and
    // its paywall are done - see FirstCardFlow.)
    if (!FirstCardFlow.armed) NotificationService().requestPermissionAndSubscribe();

    // Realtime: if the subscription lapses/is refunded while the app is
    // open, send the user back to the paywall.
    _proWorker = ever<bool>(Get.find<SubscriptionController>().isUserPro, (
      pro,
    ) {
      if (!pro && Get.currentRoute == Routes.MAIN) {
        openPaywall(
          source: 'subscription_lapsed',
          plans: true,
          screen: 'home',
        );
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

    TemplateData? base;
    Map<String, String>? values;
    TemplateData? live;
    try {
      base = await TemplateData.load(item);
      if (base != null) {
        // The preview shows AT ONCE with the fonts that are ready (a template
        // whose Google font is not downloaded yet must not make the tap look
        // dead); the real fonts are fetched in the background below.
        values = await TemplateData.currentProfileValuesWithLogo();
        live = base.filled(values).fitted();
        await _precache(live);
      }
    } catch (e, st) {
      // Whatever goes wrong while preparing the live preview, the tap still
      // selects the template (its picture is shown instead).
      debugPrint('template preview fell back to the picture: $e\n$st');
      base = null;
      live = null;
    }

    // A newer tap / cancel / apply happened while we were loading.
    if (seq != _tapSeq || applying.value) return;

    previewData.value = live;
    previewTemplate.value = item;

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'template_previewed',
        parameters: {'category': item.category},
      );
    } catch (_) {}

    if (base != null && values != null) {
      _fontRefine = _refineWithFonts(base, values, item, seq);
      unawaited(_fontRefine);
    }
  }

  /// Applying waits for this, so the saved card is drawn with the real fonts.
  Future<void>? _fontRefine;

  /// Downloads the template's fonts (bounded), then measures the texts again
  /// with them - if that template is still the one being previewed.
  Future<void> _refineWithFonts(
    TemplateData base,
    Map<String, String> values,
    TemplateItem item,
    int seq,
  ) async {
    try {
      await AiFrameCardBuilder.loadFonts([
        ...base.front.elements,
        ...base.back.elements,
      ]).timeout(const Duration(seconds: 8));
    } catch (_) {}
    if (seq != _tapSeq || applying.value || previewTemplate.value?.id != item.id) return;
    previewData.value = base.filled(values).fitted();
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
    if (!await FreeLimits.ensureTemplate(isPremium: item.isPremium, screen: 'home')) return;

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
    if (!await FreeLimits.ensureTemplate(isPremium: item.isPremium, screen: 'home')) return;

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
      // The template's fonts finish loading first (bounded), then the latest
      // frame (fonts, images) is painted.
      try {
        await _fontRefine?.timeout(const Duration(seconds: 8));
      } catch (_) {}
      await WidgetsBinding.instance.endOfFrame;
      // The preview may have been re-measured with the real fonts meanwhile.
      final data = previewData.value ?? live;

      final front = await _capture(frontCaptureKey);
      final back = await _capture(backCaptureKey);
      if (front == null || back == null) {
        throw Exception('Could not capture the template');
      }

      await Get.find<RecentDesignsService>().save(
        front,
        backThumbnailBytes: back,
        designData: data.toDesignData(),
        title: item.name,
      );

      _tapSeq++;
      previewTemplate.value = null;
      previewData.value = null;
      _promote(item.id);

      FirebaseAnalytics.instance.logEvent(
        name: 'template_applied',
        parameters: {'category': item.category, 'method': 'live'},
      );
      UserSync.track('template', detail: 'applied:live:${item.category}');

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
    // The free plan's AI cards (CRO plan): out of them, the paywall opens and
    // the previewed template stays as it is.
    if (!await FreeLimits.ensure(UsageFeature.aiCard, screen: 'home')) return;
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
      final usage = UsageService.to;
      final wasLast = !usage.isPro && usage.remaining(UsageFeature.aiCard) == 1;
      usage.consume(
        UsageFeature.aiCard,
        dedupeKey: 'ai_${DateTime.now().microsecondsSinceEpoch}',
        source: 'template_ai',
      );
      if (wasLast) unawaited(FreeLimits.promptAiLimit(screen: 'home'));
      previewTemplate.value = null;
      previewData.value = null;
      _promote(item.id);

      FirebaseAnalytics.instance.logEvent(
        name: 'template_applied',
        parameters: {'category': item.category, 'method': 'ai'},
      );
      UserSync.track('template', detail: 'applied:ai:${item.category}');

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

    final paths = <String>{
      if (data.front.hasBackgroundImage) data.front.background,
      if (data.back.hasBackgroundImage) data.back.background,
    };
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

    // The user's logo (a file), so it is there with the first paint.
    for (final side in [data.front, data.back]) {
      for (final e in side.elements) {
        final file = e.imageFile;
        if (file == null) continue;
        try {
          if (!ctx.mounted) return;
          await precacheImage(FileImage(file), ctx);
        } catch (_) {}
      }
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
