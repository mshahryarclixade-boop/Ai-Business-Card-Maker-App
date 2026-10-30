import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/card_shadow.dart';
import 'create_first_card_section.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../custom_create/model/card_element_model.dart';
import '../../custom_create/view/card_editor_view.dart';
import '../../email_signature/view/email_signature_intro_view.dart';
import '../../profile_setup/service/profile_store.dart';
import '../../qr_code_generator/model/qr_code_builder.dart';
import '../../qr_code_generator/service/qr_store.dart';
import '../../qr_code_generator/view/qr_management_screen.dart';
import '../../qr_code_generator/widgets/styled_qr.dart';
import '../../template/widget/template_live_preview.dart';
import '../controller/home_controller.dart';
import 'share_card_sheet.dart';
import '../../../core/translations/tr_extension.dart';

double _designAspect(RecentDesign design) {
  final o = design.designData?['orientation'] as String?;
  if (o == null) return 7 / 4; // AI / legacy cards: keep old behavior
  final size = CardOrientation.values.byName(o).canvasSize;
  return size.width / size.height;
}

/// Welcome message, the user's current card and its main actions.
class MyCardSection extends StatelessWidget {
  const MyCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<RecentDesignsService>();
    final home = Get.find<HomeController>();

    return Obx(() {
      if (service.designs.isEmpty) return const CreateFirstCardSection();

      final design = service.designs.first;
      final fullName = ProfileStore.to.profile.value.fullName.trim();
      final firstName = fullName.isEmpty ? '' : fullName.split(' ').first;
      final preview = home.previewTemplate.value;
      final liveData = home.previewData.value;
      final applying = home.applying.value;

      // The live template preview uses the same aspect ratio as the editor.
      final canvas = liveData?.orientation.canvasSize;
      final previewAspect = canvas == null
          ? 7 / 4
          : canvas.width / canvas.height;

      void editCard() => Get.to(
            () => CardEditorView(design: design),
        transition: Transition.rightToLeft,
      );

      final cardTile = GestureDetector(
            onTap: preview == null ? editCard : null,
            // The shadow follows the card itself (as on the live templates),
            // not the padded box around it, and is not clipped.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kCardPreviewRadius),
                  boxShadow: kCardPreviewShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kCardPreviewRadius),
                  child: AspectRatio(
                    aspectRatio: liveData != null
                        ? previewAspect
                        : (preview == null ? _designAspect(design) : 7 / 4),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (preview == null)
                          Image.file(
                            design.file,
                            fit: BoxFit.contain,
                          )
                        else if (liveData != null)
                        // Draw the template at its real canvas size and
                        // scale the complete design down to fit.
                          FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: canvas!.width,
                              height: canvas.height,
                              child: TemplateLivePreview(
                                side: liveData.front,
                                orientation: liveData.orientation,
                                repaintKey: home.frontCaptureKey,
                              ),
                            ),
                          )
                        else
                          Image.asset(
                            preview.frontImagePath,
                            fit: BoxFit.contain,
                          ),
                        if (applying)
                          Container(
                            color: const Color(0x99FFFFFF),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstName.isEmpty ? 'home_welcome'.tr : 'home_welcome_name'.trParams({'name': firstName}),
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          ),
          const SizedBox(height: 8),
          // Swipe left for the QR code of the active profile.
          if (preview == null)
            _SwipeCards(
              aspect: _designAspect(design),
              card: cardTile,
              qr: const _QrPage(),
            )
          else
            cardTile,

          // Back side of the live preview, drawn off-screen only so it can
          // be captured when the user taps Apply Template.
          if (liveData != null)
            SizedBox(
              width: 0,
              height: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -5000,
                    top: 0,
                    width: liveData.orientation.canvasSize.width,
                    height: liveData.orientation.canvasSize.height,
                    child: IgnorePointer(
                      child: TemplateCardCanvas(
                        side: liveData.back,
                        orientation: liveData.orientation,
                        repaintKey: home.backCaptureKey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),
          if (preview == null) ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'home_card_share'.tr,
                    filled: true,
                    onTap: () => showShareCardSheet(design.file),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'home_card_my_qr'.tr,
                    filled: false,
                    onTap: openQrCodes,
                  ),
                ),
                const SizedBox(width: 10),
                _EmailButton(onTap: openEmailSignature),
              ],
            ),
          ] else if (liveData != null)
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'home_card_edit_template'.tr,
                    filled: false,
                    onTap: applying ? null : home.editTemplate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: applying ? 'home_card_applying'.tr : 'home_card_apply_template'.tr,
                    filled: true,
                    onTap: applying ? null : home.applyTemplate,
                  ),
                ),
              ],
            )
          else
          // Template without an empty version yet: old AI flow.
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'home_card_cancel'.tr,
                    filled: false,
                    onTap: applying ? null : home.cancelPreview,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: applying ? 'home_card_applying'.tr : 'home_card_apply_template'.tr,
                    filled: true,
                    onTap: applying ? null : home.applyTemplate,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
      );
    });
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? AppColors.buttonDark : AppColors.cardWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : AppColors.titleDark,
          ),
        ),
      ),
    );
  }
}

/// Icon-only button that opens the Email signature module.
class _EmailButton extends StatelessWidget {
  const _EmailButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'email_sig_open'.tr,
      child: SizedBox(
        width: 48,
        height: 40,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cardWhite,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Image.asset(
            'assets/icons/email_signatures_icon.png',
            width: 22,
            height: 22,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// The card and, one swipe over, the active profile's QR code, with two dots
/// showing which one is open. The card keeps its own size; the QR page is
/// drawn to the same height.
class _SwipeCards extends StatefulWidget {
  const _SwipeCards({
    required this.aspect,
    required this.card,
    required this.qr,
  });

  final double aspect;
  final Widget card;
  final Widget qr;

  @override
  State<_SwipeCards> createState() => _SwipeCardsState();
}

class _SwipeCardsState extends State<_SwipeCards> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            // The card is drawn with 14px at each side and 1px above/below.
            final height = (box.maxWidth - 28) / widget.aspect + 2;
            return SizedBox(
              height: height,
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  widget.card,
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: widget.qr,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 2; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : AppColors.pillBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// The active profile's newest QR code, or a prompt to make one.
class _QrPage extends StatelessWidget {
  const _QrPage();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entry = QrStore.defaultEntry;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GestureDetector(
          onTap: openQrCodes,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              // Square-ish, like the card it sits next to (Home only).
              borderRadius: BorderRadius.circular(2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  offset: Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: entry == null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_2_rounded,
                        size: 44,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'home_card_qr_empty'.tr,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.titleDark,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FittedBox(
                            child: StyledQr(
                              data: buildVCard(entry.profileData),
                              style: entry.style,
                              size: 160,
                              padding: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.titleDark,
                              ),
                            ),
                            if (entry.profileData.companyName.isNotEmpty)
                              Text(
                                entry.profileData.companyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12.5,
                                  color: AppColors.textSubtitle,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              'home_card_qr_hint'.tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 11.5,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}
