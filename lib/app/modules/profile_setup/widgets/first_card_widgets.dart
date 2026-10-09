import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';

/// Looping, muted loading animation (299 x 263).
class FirstCardLoadingVideo extends StatefulWidget {
  const FirstCardLoadingVideo({super.key});

  @override
  State<FirstCardLoadingVideo> createState() => _FirstCardLoadingVideoState();
}

class _FirstCardLoadingVideoState extends State<FirstCardLoadingVideo> {
  static const _videoAsset = 'assets/videos/ai_loading.mp4';

  late final VideoPlayerController _video;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.asset(_videoAsset);
    _init();
  }

  Future<void> _init() async {
    try {
      await _video.initialize();
      await _video.setLooping(true);
      await _video.setVolume(0);
      await _video.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // Missing or unreadable video: the placeholder spinner stays.
    }
  }

  @override
  void dispose() {
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 299,
      height: 263,
      child: _ready
          ? FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _video.value.size.width,
          height: _video.value.size.height,
          child: VideoPlayer(_video),
        ),
      )
          : const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.firstCardCheck,
          ),
        ),
      ),
    );
  }
}

/// One status row. It has three looks:
///  * [done]            -> check circle
///  * [active] (not done) -> spinner (this row is loading right now)
///  * neither           -> empty circle (waiting for its turn)
class FirstCardStatusRow extends StatelessWidget {
  const FirstCardStatusRow({
    super.key,
    required this.text,
    required this.done,
    this.active = true,
    this.highlight = false,
  });

  final String text;
  final bool done;

  /// True only for the row that is loading right now.
  final bool active;

  /// Purple text, used for the row that is still in progress.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Widget leading;
    if (done) {
      leading = const Icon(
        Icons.check_circle,
        size: 23,
        color: AppColors.firstCardCheck,
      );
    } else if (active) {
      leading = const CircularProgressIndicator(
        strokeWidth: 3,
        color: AppColors.firstCardCheck,
      );
    } else {
      leading = Icon(
        Icons.radio_button_unchecked,
        size: 23,
        color: AppColors.firstCardCheck.withOpacity(0.5),
      );
    }

    return Row(
      children: [
        SizedBox(width: 23, height: 23, child: leading),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 22,
              fontWeight: FontWeight.w400,
              height: 1.2,
              letterSpacing: 0,
              color: highlight && !done
                  ? AppColors.firstCardCheck
                  : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}