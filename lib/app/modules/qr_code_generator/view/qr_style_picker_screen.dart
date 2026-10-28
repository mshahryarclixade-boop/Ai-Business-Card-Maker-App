import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
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

  void _save() {
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.titleDark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'qr_style_title'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.titleDark,
          ),
        ),
      ),
      body: Column(
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
                              duration: const Duration(milliseconds: 180),
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
                child: Text('qr_style_save'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
              ),
            ),
          ),
        ],
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
      child: Container(
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
    );
  }
}
