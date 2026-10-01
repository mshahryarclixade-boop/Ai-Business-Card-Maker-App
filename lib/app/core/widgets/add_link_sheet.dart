import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SocialPlatform {
  final String name;
  final String imagePath;

  const SocialPlatform(this.name, this.imagePath);
}

class AddedLink {
  final SocialPlatform platform;
  final String url;

  const AddedLink(this.platform, this.url);
}

const List<SocialPlatform> kSocialPlatforms = [
  SocialPlatform('LinkedIn', 'assets/icons/social/linkedin_qr.png'),
  SocialPlatform('Instagram', 'assets/icons/social/insta_qr.png'),
  SocialPlatform('Tiktok', 'assets/icons/social/tiktok_qr.png'),
  SocialPlatform('Facebook', 'assets/icons/social/fb_qr.png'),
  SocialPlatform('Snapchat', 'assets/icons/social/snapchat_qr.png'),
  SocialPlatform('Threads', 'assets/icons/social/threads_qr.png'),
  SocialPlatform('Telegram', 'assets/icons/social/telegram_qr.png'),
  SocialPlatform('Link', 'assets/icons/social/link_qr.png'),
  SocialPlatform('YouTube', 'assets/icons/social/youtube_qr.png'),
  SocialPlatform('Github', 'assets/icons/social/github_qr.png'),
  SocialPlatform('Twitter', 'assets/icons/social/twitter_qr.png'),
];

/// Best-effort platform guess from a raw URL. Falls back to generic "Link".
SocialPlatform guessPlatform(String url) {
  final lower = url.toLowerCase();
  for (final p in kSocialPlatforms) {
    if (p.name != 'Link' && lower.contains(p.name.toLowerCase())) return p;
  }
  // Common short domains that don't contain the platform name.
  if (lower.contains('instagr.am')) {
    return kSocialPlatforms.firstWhere((p) => p.name == 'Instagram');
  }
  if (lower.contains('fb.com')) {
    return kSocialPlatforms.firstWhere((p) => p.name == 'Facebook');
  }
  if (lower.contains('t.me')) {
    return kSocialPlatforms.firstWhere((p) => p.name == 'Telegram');
  }
  if (lower.contains('x.com')) {
    return kSocialPlatforms.firstWhere((p) => p.name == 'Twitter');
  }
  return kSocialPlatforms.firstWhere((p) => p.name == 'Link');
}

class _BackToPicker {
  const _BackToPicker();
}

/// Runs the full flow. Returns `null` if the user dismisses either sheet.
Future<AddedLink?> showAddLinkSheet(BuildContext context) async {
  while (true) {
    if (!context.mounted) return null;

    final platform = await showModalBottomSheet<SocialPlatform>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PlatformPickerSheet(),
    );
    if (platform == null) return null;
    if (!context.mounted) return null;

    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LinkUrlSheet(platform: platform),
    );

    if (result is String && result.trim().isNotEmpty) {
      return AddedLink(platform, result.trim());
    }
    if (result is _BackToPicker) continue; // reopen the icon sheet
    return null;
  }
}

/// White, rounded-top container shared by both sheets.
class _SheetContainer extends StatelessWidget {
  final Widget child;

  const _SheetContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(child: child),
    );
  }
}

class _PlatformPickerSheet extends StatelessWidget {
  const _PlatformPickerSheet();

  static const int _itemsPerRow = 4;
  static const double _spacing = 20;

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
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
              children: kSocialPlatforms
                  .map(
                    (p) => SizedBox(
                  width: itemWidth,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, p),
                    child: Column(
                      children: [
                        Image.asset(
                          p.imagePath,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.name,
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

class _LinkUrlSheet extends StatefulWidget {
  final SocialPlatform platform;

  const _LinkUrlSheet({required this.platform});

  @override
  State<_LinkUrlSheet> createState() => _LinkUrlSheetState();
}

class _LinkUrlSheetState extends State<_LinkUrlSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
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
                  onPressed: () =>
                      Navigator.pop(context, const _BackToPicker()),
                ),
                Image.asset(
                  widget.platform.imagePath,
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.platform.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => Navigator.pop(context, v),
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
                onPressed: () => Navigator.pop(context, _controller.text),
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