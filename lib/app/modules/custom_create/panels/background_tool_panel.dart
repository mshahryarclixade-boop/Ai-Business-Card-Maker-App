import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controller/card_editor_controller.dart';
import '../widgets/color_palette.dart';
import '../widgets/panel_shared.dart';

class BackgroundToolPanel extends StatefulWidget {
  final CardEditorController controller;
  const BackgroundToolPanel({super.key, required this.controller});

  @override
  State<BackgroundToolPanel> createState() => _BackgroundToolPanelState();
}

class _BackgroundToolPanelState extends State<BackgroundToolPanel> {
  bool _showingTemplates = false;

  // Placeholder templates
  static const List<String> _templateAssets = [
    'assets/images/bg_templates/template1.jpg',
    'assets/images/bg_templates/template2.jpg',
    'assets/images/bg_templates/template3.png',
    'assets/images/bg_templates/template4.jpg',
    'assets/images/bg_templates/gradient_teal.jpg',
    'assets/images/bg_templates/marble.jpg',
    'assets/images/bg_templates/template1.jpg',
    'assets/images/bg_templates/template2.jpg',
    'assets/images/bg_templates/template3.png',
    'assets/images/bg_templates/template4.jpg',
    'assets/images/bg_templates/gradient_teal.jpg',
    'assets/images/bg_templates/marble.jpg',
  ];

  CardEditorController get controller => widget.controller;

  void _openTemplates() {
    controller.openBackgroundTemplates();
    setState(() => _showingTemplates = true);
  }

  void _closeTemplates() {
    setState(() => _showingTemplates = false);
  }

  void _selectTemplate(String assetPath) {
    controller.setBackgroundTemplate(assetPath);
    setState(() => _showingTemplates = false);
  }

  @override
  Widget build(BuildContext context) {
    return PanelContainer(
      child: _showingTemplates ? _buildTemplatesView() : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PanelHeader(title: '', onBack: controller.closeToolPanel),
        const SizedBox(height: 4),
        Obx(
              () => ColorPaletteGrid(
            selected: (controller.backgroundImage.value == null &&
                controller.backgroundTemplate.value == null)
                ? controller.backgroundColor.value
                : null,
            swatchSize: 30,
            spacing: 14,
            onSelect: controller.setBackgroundColor,
            onOpenCustomPicker: () => controller.openColorPicker(
              target: ColorPickerTarget.background,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: controller.pickBackgroundImageFromGallery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Upload from Gallery',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: _openTemplates,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Background Templates',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplatesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PanelHeader(title: '', onBack: _closeTemplates),
        const SizedBox(height: 6),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templateAssets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final assetPath = _templateAssets[index];

              return SizedBox(
                width: 170,
                child: _TemplateThumbnail(
                  assetPath: assetPath,
                  onTap: () => _selectTemplate(assetPath),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TemplateThumbnail extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;

  const _TemplateThumbnail({required this.assetPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.progressTrack,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.dotInactive,
              ),
            ),
          ),
        ),
      ),
    );
  }
}