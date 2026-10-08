import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/services/gemini_card_service.dart';
import '../../../routes/app_routes.dart';
import '../model/user_profile_data.dart';
import '../service/profile_store.dart';
import 'first_card_generator.dart';

enum FirstCardStatus { generating, failed }

class FirstCardController extends GetxController {
  final RxBool personalDone = false.obs;
  final RxBool companyDone = false.obs;
  final Rx<FirstCardStatus> status = FirstCardStatus.generating.obs;
  final RxString errorMessage = ''.obs;

  bool _running = false;

  UserProfileData get data => ProfileStore.to.profile.value;

  /// Company details are optional, so the row is only shown if any were given.
  bool get hasCompanyDetails {
    final d = data;
    return d.companyName.isNotEmpty ||
        d.designation.isNotEmpty ||
        d.website.isNotEmpty ||
        d.hasLogo;
  }

  @override
  void onReady() {
    super.onReady();
    start();
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;
    status.value = FirstCardStatus.generating;
    errorMessage.value = '';

    try {
      // The details are already saved, so these two steps are quick checks.
      if (!personalDone.value) {
        await Future.delayed(const Duration(milliseconds: 700));
        personalDone.value = true;
      }
      if (hasCompanyDetails && !companyDone.value) {
        await Future.delayed(const Duration(milliseconds: 700));
        companyDone.value = true;
      }

      final cards = await _generateCards(data);

      if (isClosed) return; // user left the screen while generating
      Get.offNamed(Routes.FIRST_CARD_READY, arguments: cards);
    } on GeminiException catch (e, st) {
      debugPrint('FirstCard GeminiException: ${e.message}');
      debugPrintStack(stackTrace: st);
      errorMessage.value = e.message;
      status.value = FirstCardStatus.failed;
    } catch (e, st) {
      debugPrint('FirstCard ERROR: $e');
      debugPrintStack(stackTrace: st);
      // Debug builds show the real error on screen. Release builds show
      // the friendly message.
      errorMessage.value = kDebugMode
          ? 'DEBUG: $e'
          : 'Something went wrong while creating your card.';
      status.value = FirstCardStatus.failed;
    } finally {
      _running = false;
    }
  }

  void tryAgain() => start();

  void useFreeTemplate() {
    // TODO: point this at the templates screen if it has its own route.
    Get.offAllNamed(Routes.MAIN);
  }

  final _generator = FirstCardGenerator();

  Future<List<Uint8List>> _generateCards(UserProfileData data) =>
      _generator.generate(data);
}