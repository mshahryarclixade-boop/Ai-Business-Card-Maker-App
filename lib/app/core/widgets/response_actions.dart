import 'tap_target.dart';
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:share_plus/share_plus.dart';

import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../translations/tr_extension.dart';
import '../utils/share_origin.dart';

/// The row under an AI response, as in ChatGPT: Copy (this response), Share (the
/// whole conversation as plain text) and Read aloud (tap again to stop).
class ResponseActions extends StatefulWidget {
  const ResponseActions({
    super.key,
    required this.id,
    required this.text,
    required this.conversation,
  });

  /// Identifies this response for read-aloud (only one plays at a time).
  final String id;

  /// The response itself: what Copy copies and Read aloud reads.
  final String text;

  /// The whole conversation as plain text, built when Share is tapped.
  final String Function() conversation;

  @override
  State<ResponseActions> createState() => _ResponseActionsState();
}

class _ResponseActionsState extends State<ResponseActions> {
  var _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _share() async {
    // Measured before any await, while the context is still valid.
    final origin = shareOrigin(context);
    try {
      await SharePlus.instance.share(
        ShareParams(text: widget.conversation(), sharePositionOrigin: origin),
      );
    } catch (e) {
      log('share failed: $e', name: 'ResponseActions');
      Get.snackbar(
        'chat_share_failed_title'.tr,
        'chat_share_failed_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  void _read() {
    TtsService.instance.onFailure ??= () => Get.snackbar(
      'chat_tts_failed_title'.tr,
      'chat_tts_failed_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
    );
    TtsService.instance.toggle(widget.id, widget.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionIcon(
            icon: _copied ? Icons.check_rounded : Icons.content_copy_outlined,
            label: 'chat_copy'.tr,
            onTap: _copy,
          ),
          _ActionIcon(
            icon: Icons.ios_share_rounded,
            label: 'chat_share'.tr,
            onTap: _share,
          ),
          Obx(() {
            final on = TtsService.instance.speakingId.value == widget.id;
            return _ActionIcon(
              icon: on ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
              label: (on ? 'chat_stop_reading' : 'chat_read_aloud').tr,
              onTap: _read,
              active: on,
            );
          }),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: TapTarget(child: InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppColors.onboardingBtnEnd : AppColors.textGrey,
        ),
      ),
    )),
  );
}
