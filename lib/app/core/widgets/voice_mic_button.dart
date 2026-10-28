import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../services/speech_input_service.dart';
import '../theme/app_colors.dart';
import '../translations/tr_extension.dart';

const _recording = Color(0xFFD32F2F);

/// The microphone next to a message box: tap to dictate, tap again to stop.
/// Drawn with vector shapes only (a [CircleBorder] with an anti-aliased edge,
/// on its own repaint layer), so it stays sharp at every size and density.
class VoiceMicButton extends StatelessWidget {
  const VoiceMicButton({
    super.key,
    required this.speech,
    required this.onTap,
    this.size = 48,
  });

  final SpeechInputService speech;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final on = speech.listening.value;
      return Tooltip(
        message: (on ? 'clixa_mic_stop' : 'clixa_mic_start').tr,
        child: RepaintBoundary(
          child: GestureDetector(
            onTap: onTap,
            child: SizedBox.square(
              dimension: size,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: on ? _recording : AppColors.scaffoldBg,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: on ? _recording : AppColors.pillBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Icon(
                  on ? Icons.stop_rounded : Icons.mic_none_rounded,
                  color: on ? Colors.white : AppColors.onboardingBtnEnd,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Tells the user why dictation could not start or stopped.
void showSpeechIssue(SpeechInputService speech, SpeechIssue issue) {
  final blocked = issue == SpeechIssue.permissionBlocked;
  final (title, message) = switch (issue) {
    SpeechIssue.permissionDenied => (
      'clixa_mic_denied_title',
      'clixa_mic_denied_message',
    ),
    SpeechIssue.permissionBlocked => (
      'clixa_mic_denied_title',
      'clixa_mic_blocked_message',
    ),
    SpeechIssue.unavailable => (
      'clixa_mic_unavailable_title',
      'clixa_mic_unavailable_message',
    ),
    SpeechIssue.noSpeech => (
      'clixa_mic_no_speech_title',
      'clixa_mic_no_speech_message',
    ),
    SpeechIssue.network => (
      'clixa_mic_unavailable_title',
      'clixa_mic_network_message',
    ),
    SpeechIssue.failed => (
      'clixa_mic_unavailable_title',
      'clixa_mic_failed_message',
    ),
  };
  Get.snackbar(
    title.tr,
    message.tr,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(15),
    mainButton: blocked
        ? TextButton(
            onPressed: speech.openSettings,
            child: Text(
              'clixa_mic_settings'.tr,
              style: const TextStyle(color: Colors.white),
            ),
          )
        : null,
  );
}
