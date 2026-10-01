import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../paywall/view/paywall_view.dart';

class RemoveBgAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const RemoveBgAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.showCrown = true,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showCrown;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.scaffoldBg,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.titleDark,
        ),
        onPressed: onBack ?? () => Get.back(),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.titleDark,
        ),
      ),
      actions: showCrown
          ? [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Get.to(
                    () => const PaywallView(),
                transition: Transition.rightToLeft,
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.cardWhite,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const FaIcon(
                FontAwesomeIcons.crown,
                size: 18,
                color: Color(0xFFF5A623),
              ),
            ),
          ),
        ),
      ]
          : null,
    );
  }
}