import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../../core/services/recent_designs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/recent_design_card.dart';

class AllRecentDesignsView extends StatelessWidget {
  const AllRecentDesignsView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<RecentDesignsService>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: Icon(
                          Icons.arrow_back,
                          size: 23,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Recent Designs',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.titleDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 36), // balances the back button
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final list = service.designs;

                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'No recent designs yet',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        color: AppColors.textSubtitle,
                      ),
                    ),
                  );
                }

                // Staggered (masonry) grid: 2 columns. Every tile takes its
                // own height from its image ratio, so landscape cards stay
                // short and portrait cards stay tall.
                return MasonryGridView.count(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final design = list[index];
                    return _DesignTile(
                      key: ValueKey(design.id),
                      design: design,
                      onLongPress: () => service.delete(design.id),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// One grid tile. Reads the real width/height of the design's thumbnail
/// so landscape and portrait designs each get their own aspect ratio.
class _DesignTile extends StatefulWidget {
  // Same type as the items in RecentDesignsService.designs.
  final dynamic design;
  final VoidCallback onLongPress;

  const _DesignTile({
    super.key,
    required this.design,
    required this.onLongPress,
  });

  @override
  State<_DesignTile> createState() => _DesignTileState();
}

class _DesignTileState extends State<_DesignTile> {
  /// Landscape shown until the image size is known.
  static const double _fallbackRatio = 1.6;

  /// Remembers ratios so tiles don't jump when the list rebuilds.
  static final Map<String, double> _ratioCache = {};

  late double _ratio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  String get _id => widget.design.id.toString();

  @override
  void initState() {
    super.initState();
    _ratio = _ratioCache[_id] ?? _fallbackRatio;
    if (!_ratioCache.containsKey(_id)) _resolveRatio();
  }

  void _resolveRatio() {
    final stream =
    FileImage(widget.design.file).resolve(ImageConfiguration.empty);

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
          (info, _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (w > 0 && h > 0) {
          final ratio = (w / h).clamp(0.5, 2.2);
          _ratioCache[_id] = ratio;
          if (mounted) setState(() => _ratio = ratio);
        }
        stream.removeListener(listener);
      },
      onError: (_, __) => stream.removeListener(listener),
    );

    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: RecentDesignCard(
        thumbnailFile: widget.design.file,
        aspectRatio: _ratio,
        onTap: () {
          // TODO: open in card_editor_view
          // Get.to(() => CardEditorView(design: widget.design));
        },
        onLongPress: widget.onLongPress,
      ),
    );
  }
}