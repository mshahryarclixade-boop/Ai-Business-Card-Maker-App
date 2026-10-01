import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../paywall/view/paywall_view.dart';
import '../controller/profile_controller.dart';
import '../model/profile_model.dart';
import 'create_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {

  final GlobalKey _cardKey = GlobalKey();
  late final ProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Obx(
              () => Stack(
            children: [
              controller.hasProfile.value
                  ? _SavedProfile(cardKey: _cardKey)
                  : const _EmptyProfile(),

              if (controller.showCardMenu.value) ...[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: controller.closeCardMenu,
                    child: const SizedBox.expand(),
                  ),
                ),
                _CardMenuPopup(cardKey: _cardKey),
              ],

              if (controller.showSuccess.value) const _SuccessOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  const _EmptyProfile();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Column(
      children: [
        const SizedBox(height: 5),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
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
                        color: Colors.white,
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
              ],
            ),
          ),
        ),

        const SizedBox(height: 135),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 34,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Set up your profile once, use\neverywhere',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E24),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Autofill your cards, QR codes and\nAI generator with one tap',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: Color(0xFF68686A),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(
                            () => const CreateProfileView(),
                        transition: Transition.rightToLeft,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Create Profile',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CardSpec {
  static const double cardWidth = 345;
  static const double cardHeight = 430;
  static const double coverHeight = 112;
  static const double avatarSize = 88;
  static const double avatarTop = 64;
  static const double qrSize = 82;
  static const double menuBtnSize = 40;
}

class _SavedProfile extends StatelessWidget {
  final GlobalKey cardKey;

  const _SavedProfile({required this.cardKey});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Obx(() {
      // profile ke fields plain (non-Rx) hain, is liye profileVersion
      // ko read karna zaroori hai taake save/edit ke baad yeh rebuild ho.
      controller.profileVersion.value;

      return SingleChildScrollView(
        // horizontal/top padding removed from here — the header now
        // carries its own padding (below) so it matches every other
        // screen's header exactly. Only bottom spacing stays global.
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: SizedBox(
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.titleDark,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: SizedBox(
                width: _CardSpec.cardWidth,
                height: _CardSpec.cardHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ⬇️ Only this part is captured for Share / Download.
                    RepaintBoundary(
                      key: cardKey,
                      child: SizedBox(
                        width: _CardSpec.cardWidth,
                        height: _CardSpec.cardHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: _CardSpec.cardWidth,
                              height: _CardSpec.cardHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x40000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),

                            Positioned(
                              top: 0,
                              left: 0,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Obx(
                                      () => Container(
                                    width: _CardSpec.cardWidth,
                                    height: _CardSpec.coverHeight,
                                    color: const Color(0xFFE1E1EE),
                                    child: controller.coverImage.value != null
                                        ? Image.file(
                                      controller.coverImage.value!,
                                      width: _CardSpec.cardWidth,
                                      height: _CardSpec.coverHeight,
                                      fit: BoxFit.cover,
                                    )
                                        : null,
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              top: _CardSpec.avatarTop,
                              left:
                              (_CardSpec.cardWidth - _CardSpec.avatarSize) / 2,
                              child: Obx(
                                    () => Container(
                                  width: _CardSpec.avatarSize,
                                  height: _CardSpec.avatarSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    border:
                                    Border.all(color: Colors.white, width: 3),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1A000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: controller.frontImage.value != null
                                        ? Image.file(
                                      controller.frontImage.value!,
                                      width: _CardSpec.avatarSize,
                                      height: _CardSpec.avatarSize,
                                      fit: BoxFit.cover,
                                    )
                                        : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 42,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              top: _CardSpec.avatarTop + _CardSpec.avatarSize + 12,
                              left: 24,
                              right: 24,
                              bottom: 64,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    controller.profile.fullName,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E1E24),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    controller.profile.companyName,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 12,
                                      color: AppColors.textSubtitle,
                                    ),
                                  ),
                                  Text(
                                    controller.profile.jobTitle,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 12,
                                      color: AppColors.textSubtitle,
                                    ),
                                  ),
                                  Text(
                                    controller.profile.companyWebsite,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 12,
                                      color: AppColors.textSubtitle,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            _ProfileInfoRow(
                                              icon: Icons.email_outlined,
                                              text: controller.profile.email,
                                            ),
                                            _ProfileInfoRow(
                                              icon: Icons.phone_outlined,
                                              text: controller.profile.phone,
                                            ),
                                            if (controller
                                                .profile.socialLinks.isNotEmpty)
                                              _ProfileInfoRow(
                                                icon: Icons.link_rounded,
                                                text: controller
                                                    .profile.socialLinks.first,
                                              )
                                            else
                                              _ProfileInfoRow(
                                                icon: Icons.location_on_outlined,
                                                text: controller.profile.location,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: _CardSpec.qrSize,
                                        height: _CardSpec.qrSize,
                                        padding: const EdgeInsets.all(4),
                                        child: QrImageView(
                                          data: _SavedProfile._vCardData(
                                              controller.profile),
                                          version: QrVersions.auto,
                                          gapless: true,
                                          eyeStyle: const QrEyeStyle(
                                            eyeShape: QrEyeShape.square,
                                            color: Color(0xFF1E1E24),
                                          ),
                                          dataModuleStyle: const QrDataModuleStyle(
                                            dataModuleShape:
                                            QrDataModuleShape.square,
                                            color: Color(0xFF1E1E24),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // "⋮" menu button — overlaps the card visually, but sits
                    // OUTSIDE the RepaintBoundary above, so it's excluded
                    // from the shared/downloaded image.
                    Positioned(
                      top: 1,
                      right: 0,
                      child: GestureDetector(
                        onTap: controller.toggleCardMenu,
                        child: SizedBox(
                          width: _CardSpec.menuBtnSize,
                          height: _CardSpec.menuBtnSize,
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 24,
                            color: Color(0xFF1E1E24),
                          ),
                        ),
                      ),
                    ),

                    // ⬅️ Edit + Create Card buttons — overlapping the
                    // bottom of the card, still OUTSIDE the RepaintBoundary
                    // so the exported image stays clean (no buttons in the
                    // downloaded/shared PNG).
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SizedBox(
                          width: 278,
                          height: 40,
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Get.to(
                                          () => const CreateProfileView(),
                                      transition: Transition.rightToLeft,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Get.to(
                                          () => const CreateProfileView(),
                                      transition: Transition.rightToLeft,
                                      arguments: const {'blank': true},
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Create Card',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Loading overlay while capturing the card image — no
                    // longer extends over the (now overlapping) buttons area.
                    Obx(
                          () => controller.isProcessingCard.value
                          ? Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: _CardSpec.cardHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  static String _vCardData(ProfileModel profile) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCARD')
      ..writeln('VERSION:3.0')
      ..writeln('N:${profile.lastName};${profile.firstName}')
      ..writeln('FN:${profile.fullName}')
      ..writeln('ORG:${profile.companyName}')
      ..writeln('TITLE:${profile.jobTitle}')
      ..writeln('EMAIL:${profile.email}')
      ..writeln('TEL:${profile.phone}')
      ..writeln('URL:${profile.companyWebsite}')
      ..writeln('END:VCARD');
    return buffer.toString();
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProfileInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                color: Color(0xFF55555F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMenuPopup extends StatelessWidget {
  final GlobalKey cardKey;

  const _CardMenuPopup({required this.cardKey});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Positioned(
      top: 56,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13.3),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.6, sigmaY: 16.6),
          child: Container(
            width: 127,
            padding: const EdgeInsets.all(10.6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(13.3),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 0.66,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 27.13,
                  offset: Offset(0, 6.65),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CardMenuItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () {
                    controller.closeCardMenu();
                    Get.to(
                          () => const CreateProfileView(),
                      transition: Transition.rightToLeft,
                    );
                  },
                  highlighted: true,
                ),
                const SizedBox(height: 8),
                _CardMenuItem(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onTap: () {
                    controller.closeCardMenu();
                    controller.shareCard(cardKey);
                  },
                ),
                const SizedBox(height: 8),
                _CardMenuItem(
                  icon: Icons.file_download_outlined,
                  label: 'Download',
                  onTap: () {
                    controller.closeCardMenu();
                    controller.downloadCard(cardKey);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const _CardMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: highlighted ? Colors.white : const Color(0xFF1E1E24),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: highlighted ? Colors.white : const Color(0xFF1E1E24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5,
            sigmaY: 5,
          ),
          child: Container(
            color: Colors.black.withOpacity(0.12),
            child: Center(
              child: Container(
                width: 155,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Profile Saved',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E24),
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Your profile has been saved successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 10,
                        height: 1.4,
                        color: AppColors.textSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}