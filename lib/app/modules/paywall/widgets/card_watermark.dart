import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../controller/subscription_controller.dart';
import '../services/watermark_service.dart';

/// The grey colour of the watermark (crown and text).
const Color kWatermarkGrey = Color(0xFFA3A3AE);

final _never = false.obs;

/// "Made with Business Card Maker" with a small crown, top-right of a card
/// PREVIEW (Home and My Cards). Shown to free users only; never on the
/// editable canvas. Put it as a child of a `Stack(fit: StackFit.expand)` that
/// holds the card picture - it ignores touches and is sized from the card's
/// width, so it stays small and readable on a thumbnail and on a big preview.
class CardWatermark extends StatelessWidget {
  const CardWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Follows a purchase at once.
      (Get.isRegistered<SubscriptionController>()
              ? Get.find<SubscriptionController>().isUserPro
              : _never)
          .value;
      if (!WatermarkService.applies) return const SizedBox.shrink();
      return IgnorePointer(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth.isFinite ? c.maxWidth : 300.0;
            final font = (w * 0.03).clamp(5.5, 20.0);
            return Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: w * 0.04, end: w * 0.045),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w * 0.46),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.crown, size: font * 1.45, color: kWatermarkGrey),
                      SizedBox(width: font * 0.55),
                      Flexible(
                        child: Text(
                          WatermarkService.lines,
                          maxLines: 2,
                          style: TextStyle(
                            color: kWatermarkGrey,
                            fontSize: font,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
