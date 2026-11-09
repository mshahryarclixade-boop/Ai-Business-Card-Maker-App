import '../../../core/widgets/pro_crown_badge.dart';
import '../../career_studio/widgets/career_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../paywall/services/free_limits.dart';
import '../../paywall/services/paywall_triggers.dart';
import '../model/qr_code_builder.dart';
import '../model/qr_entry.dart';
import '../model/qr_profile_data.dart';
import '../model/qr_style.dart';
import '../service/qr_store.dart';
import '../widgets/styled_qr.dart';
import 'qr_management_screen.dart';

/// After the QR form: preview the code in each style, pick one and save it.
/// [editId] updates an existing QR code instead of adding a new one.
class QrStylePickerScreen extends StatefulWidget {
  const QrStylePickerScreen({
    super.key,
    required this.form,
    required this.profile,
    this.editId,
    this.initialStyleId,
    this.fromManagement = false,
  });

  /// The form as saved (see [QrProfileData.fromForm]) and what it holds.
  final Map<String, dynamic> form;
  final QrProfileData profile;
  final String? editId;
  final String? initialStyleId;

  /// Opened from the saved QR codes: saving goes back to that screen.
  final bool fromManagement;

  @override
  State<QrStylePickerScreen> createState() => _QrStylePickerScreenState();
}

class _QrStylePickerScreenState extends State<QrStylePickerScreen> {
  late QrStyle _style = QrStyles.byId(widget.initialStyleId);

  Future<void> _save() async {
    // Classic is free. Any other style is a Pro style - except one this QR
    // code already has (what the user made is never locked).
    final isProStyle =
        _style.id != QrStyles.classic.id && _style.id != widget.initialStyleId;
    if (!await FreeLimits.ensureTemplate(
      isPremium: isProStyle,
      trigger: PaywallTrigger.proQr,
      screen: 'qr_style_picker',
    )) {
      return; // the paywall was shown; the chosen style stays selected
    }
    final existing = widget.editId == null
        ? null
        : QrStore.entries.firstWhereOrNull((e) => e.id == widget.editId);
    QrStore.put(
      existing?.copyWith(form: widget.form, styleId: _style.id) ??
          QrEntry(
            id: QrStore.newId(),
            form: widget.form,
            styleId: _style.id,
            createdAt: DateTime.now(),
          ),
    );
    // Go back first: Get.back() only closes an open snackbar instead of
    // leaving the screen, so the message is shown after navigating.
    if (widget.fromManagement) {
      Get.back(); // the saved QR codes are right underneath
    } else {
      Get.off(
        () => const QrManagementScreen(),
        routeName: qrManagementRoute,
        transition: Transition.rightToLeft,
      );
    }
    Get.snackbar(
      'qr_saved_title'.tr,
      'qr_saved_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = buildVCard(widget.profile);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CareerAppBar(title: 'qr_style_title'.tr),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3F3D9E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      child: StyledQr(
                                        key: ValueKey(_style.id),
                                        data: data,
                                        style: _style,
                                        size: 200,
                                        padding: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  widget.profile.fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                                if (widget.profile.companyName.isNotEmpty)
                                  Text(
                                    widget.profile.companyName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'qr_style_subtitle'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              color: AppColors.textSubtitle,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final s in QrStyles.all)
                                _StyleTile(
                                  style: s,
                                  data: data,
                                  selected: s.id == _style.id,
                                  onTap: () => setState(() => _style = s),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    // On a tablet the button is lifted clear of the bottom edge (it
                    // was half cut off there); phones keep the original spacing.
                    padding: EdgeInsets.fromLTRB(
                      24,
                      8,
                      24,
                      MediaQuery.sizeOf(context).shortestSide >= 600
                          ? 15 + MediaQuery.paddingOf(context).bottom
                          : 20,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'qr_style_save'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.style,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final QrStyle style;
  final String data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Three per row on a phone.
    final w = (MediaQuery.sizeOf(context).width - 48 - 24) / 3;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: w.clamp(80.0, 140.0),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : const Color(0xFFE1E1EE),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: StyledQr(
                    data: data,
                    style: style,
                    size: (w.clamp(80.0, 140.0)) - 16 - 4,
                    padding: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  style.nameKey.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.titleDark,
                  ),
                ),
              ],
            ),
          ),
          // Every style except Classic is a Pro style: a crown, visual only.
          if (style.id != QrStyles.classic.id)
            const PositionedDirectional(
              top: 4,
              end: 4,
              child: ProCrownBadge(iconSize: 10, padding: 4),
            ),
        ],
      ),
    );
  }
}
