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

  /// Becomes true only when the card is really generated.
  final RxBool creatingDone = false.obs;

  final Rx<FirstCardStatus> status = FirstCardStatus.generating.obs;
  final RxString errorMessage = ''.obs;

  /// How long each tick row stays loading before its tick appears.
  static const Duration _stepDelay = Duration(milliseconds: 1500);

  /// Pause on the last tick before moving to the next screen.
  static const Duration _finishDelay = Duration(milliseconds: 900);

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
    creatingDone.value = false;

    try {
      // Card generation starts right away and runs while the ticks play.
      final cardsFuture = _generateCards(data);
      // Marks the error as handled for now; it is still thrown below
      // when we await the future.
      cardsFuture.ignore();

      // Tick 1, then tick 2, one after the other.
      if (!personalDone.value) {
        await Future.delayed(_stepDelay);
        personalDone.value = true;
      }
      if (hasCompanyDetails && !companyDone.value) {
        await Future.delayed(_stepDelay);
        companyDone.value = true;
      }

      // Tick 3 only when the card is really ready.
      final cards = await cardsFuture;

      if (isClosed) return; // user left the screen while generating
      creatingDone.value = true;

      await Future.delayed(_finishDelay);

      if (isClosed) return;
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