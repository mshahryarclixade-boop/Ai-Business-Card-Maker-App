import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../translations/app_strings.dart';

/// Why dictation could not start, or why it stopped.
enum SpeechIssue {
  /// The user refused the microphone / speech permission (can ask again).
  permissionDenied,

  /// Refused for good: only the system settings can turn it back on.
  permissionBlocked,

  /// No speech recognition on this device (or the service is off).
  unavailable,

  /// Listened, but nothing was said or understood.
  noSpeech,

  /// The recogniser needs the network and could not reach it.
  network,

  /// Anything else.
  failed,
}

/// Dictation for a text field: speech in, editable text out. One instance per
/// screen; call [dispose] when the screen goes away.
class SpeechInputService {
  SpeechInputService({SpeechToText? engine})
    : _speech = engine ?? SpeechToText();

  final SpeechToText _speech;

  /// True while the microphone is open.
  final listening = false.obs;

  /// Set when listening ends on its own because of a problem.
  void Function(SpeechIssue issue)? onIssue;

  bool _ready = false;
  String? _localeId;
  var _heardAnything = false;

  /// Starts listening; [onText] gets the recognised words so far (replacing
  /// the previous partial result). Returns null once listening has started,
  /// otherwise the reason it could not.
  Future<SpeechIssue?> start(void Function(String words) onText) async {
    if (listening.value) return null;
    final ready = await _init();
    if (ready != null) return ready;
    _heardAnything = false;
    try {
      await _speech.listen(
        onResult: (r) {
          if (r.recognizedWords.isNotEmpty) _heardAnything = true;
          onText(r.recognizedWords);
        },
        localeId: _localeId,
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      listening.value = true;
      return null;
    } catch (e) {
      log('listen failed: $e', name: 'SpeechInputService');
      listening.value = false;
      return SpeechIssue.failed;
    }
  }

  /// Mic-button behaviour for a text field: stops if listening, otherwise starts
  /// and types the words into [input] after whatever is already there. The text
  /// stays editable. Returns why it could not start, or null.
  Future<SpeechIssue?> toggle(TextEditingController input) async {
    if (listening.value) {
      await stop();
      return null;
    }
    final base = input.text.trimRight();
    return start((words) {
      final text = base.isEmpty ? words : '$base $words';
      input.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  /// Stops listening and keeps what was heard.
  Future<void> stop() async {
    if (!listening.value) return;
    listening.value = false;
    try {
      await _speech.stop();
    } catch (_) {}
  }

  /// Opens the system settings (for a permission refused for good).
  Future<void> openSettings() => openAppSettings();

  Future<void> dispose() async {
    listening.value = false;
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  // -------------------------------------------------------------- internals

  Future<SpeechIssue?> _init() async {
    if (_ready) return null;
    try {
      final ok = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: false,
      );
      if (!ok) return await _whyNot();
      _localeId = await _pickLocale();
      _ready = true;
      return null;
    } catch (e) {
      log('init failed: $e', name: 'SpeechInputService');
      return SpeechIssue.unavailable;
    }
  }

  /// `initialize` returns false both for a refused permission and for a device
  /// without recognition; tell the two apart.
  Future<SpeechIssue> _whyNot() async {
    if (!await _speech.hasPermission) {
      final mic = await Permission.microphone.status;
      return mic.isPermanentlyDenied
          ? SpeechIssue.permissionBlocked
          : SpeechIssue.permissionDenied;
    }
    return SpeechIssue.unavailable;
  }

  /// The app's language if the device can recognise it, else the device default.
  Future<String?> _pickLocale() async {
    try {
      final code = AppStrings.locale.languageCode.toLowerCase();
      final all = await _speech.locales();
      for (final l in all) {
        if (l.localeId
                .toLowerCase()
                .replaceAll('-', '_')
                .startsWith('${code}_') ||
            l.localeId.toLowerCase() == code) {
          return l.localeId;
        }
      }
    } catch (_) {}
    return null;
  }

  void _onStatus(String status) {
    // "done" / "notListening": the engine closed the microphone by itself.
    if (status == 'done' || status == 'notListening') {
      final was = listening.value;
      listening.value = false;
      if (was && !_heardAnything) onIssue?.call(SpeechIssue.noSpeech);
    }
  }

  void _onError(SpeechRecognitionError e) {
    log(
      'error: ${e.errorMsg} permanent=${e.permanent}',
      name: 'SpeechInputService',
    );
    final was = listening.value;
    listening.value = false;
    switch (e.errorMsg) {
      case 'error_no_match':
      case 'error_speech_timeout':
        if (was && !_heardAnything) onIssue?.call(SpeechIssue.noSpeech);
      case 'error_network':
      case 'error_network_timeout':
        onIssue?.call(SpeechIssue.network);
      case 'error_permission':
        _ready = false;
        onIssue?.call(SpeechIssue.permissionDenied);
      case 'error_busy':
      case 'error_client':
        break; // a restart race: not worth telling the user
      default:
        if (was) onIssue?.call(SpeechIssue.failed);
    }
  }
}
