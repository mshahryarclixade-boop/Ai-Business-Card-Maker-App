import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import 'social_link_platforms.dart';

/// Result of a completed pick: the chosen platform's name, its icon
/// asset, and the URL the user typed.
typedef PickedSocialLink = ({String platform, String iconAsset, String url});

/// Runs the platform-picker → URL-entry flow (used by the Custom QR Code
/// screen and the Create Profile screen). Returns null if the user backs
/// out of either step.
Future<PickedSocialLink?> pickSocialLink(BuildContext context) async {
  final chosen = await showModalBottomSheet<(String, String)>(
    context: context,
    backgroundColor: AppColors.white,
    builder: (_) => const _PlatformPickerSheet(),
  );
  if (chosen == null) return null;

  final urlController = TextEditingController();
  final url = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LinkUrlSheet(
      platform: chosen.$1,
      iconAsset: chosen.$2,
      controller: urlController,
    ),
  );
  if (url == null || url.trim().isEmpty) return null;

  return (platform: chosen.$1, iconAsset: chosen.$2, url: url.trim());
}

class _PlatformPickerSheet extends StatelessWidget {
  const _PlatformPickerSheet();

  static const int _itemsPerRow = 4;
  static const double _spacing = 20;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth =
                (constraints.maxWidth - (_spacing * (_itemsPerRow - 1))) /
                    _itemsPerRow;

            return Wrap(
              spacing: _spacing,
              runSpacing: 16,
              children: socialLinkPlatforms
                  .map(
                    (p) => SizedBox(
                  width: itemWidth,
                  child: InkWell(
                    onTap: () => Get.back(result: p),
                    child: Column(
                      children: [
                        Image.asset(
                          p.$2,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.$1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class _LinkUrlSheet extends StatelessWidget {
  final String platform;
  final String iconAsset;
  final TextEditingController controller;

  const _LinkUrlSheet({
    required this.platform,
    required this.iconAsset,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Get.back(),
                ),
                Image.asset(
                  iconAsset,
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  platform,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'Enter link here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Get.back(result: controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}