import 'dart:developer';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

import '../translations/app_strings.dart';

/// Reads a chat response aloud. One response at a time: starting another (or
/// tapping the same one again) stops the current one.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  var _ready = false;

  /// The id of the response being read, or null.
  final speakingId = RxnString();

  /// Set when speech cannot start or breaks off.
  void Function()? onFailure;

  Future<void> _init() async {
    if (_ready) return;
    _tts.setCompletionHandler(() => speakingId.value = null);
    _tts.setCancelHandler(() => speakingId.value = null);
    _tts.setErrorHandler((message) {
      log('error: $message', name: 'TtsService');
      speakingId.value = null;
      onFailure?.call();
    });
    try {
      await _tts.setSpeechRate(0.5);
      await _tts.setLanguage(AppStrings.locale.toLanguageTag());
    } catch (_) {
      // The device default voice and language are fine.
    }
    _ready = true;
  }

  /// Reads [text] as response [id]; tapping the response being read stops it.
  Future<void> toggle(String id, String text) async {
    if (speakingId.value == id) {
      await stop();
      return;
    }
    final t = text.trim();
    if (t.isEmpty) return;
    try {
      await _init();
      await _tts.stop();
      speakingId.value = id;
      final r = await _tts.speak(t);
      if (r != 1) {
        speakingId.value = null;
        onFailure?.call();
      }
    } catch (e) {
      log('speak failed: $e', name: 'TtsService');
      speakingId.value = null;
      onFailure?.call();
    }
  }

  Future<void> stop() async {
    speakingId.value = null;
    if (!_ready) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
