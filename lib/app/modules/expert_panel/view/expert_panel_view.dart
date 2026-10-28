import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../career_studio/widgets/career_widgets.dart';
import '../model/expert_models.dart';
import '../service/panel_history_service.dart';
import 'expert_panel_chat_view.dart';

/// Opens the Expert panel. Free for now (testing): no Pro check.
void openExpertPanel() =>
    Get.to(() => const ExpertPanelView(), transition: Transition.rightToLeft);

TextStyle _t(double size, Color color, {FontWeight? w, double? h}) => TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: size,
  fontWeight: w,
  height: h,
  color: color,
);

const _blue = AppColors.onboardingBtnEnd;

/// Expert panel, start screen: pick the experts, the kind of session and
/// optionally a recent panel discussion to continue.
class ExpertPanelView extends StatefulWidget {
  const ExpertPanelView({super.key});

  @override
  State<ExpertPanelView> createState() => _ExpertPanelViewState();
}

class _ExpertPanelViewState extends State<ExpertPanelView> {
  final _picked = <int>{0, 3, 4};
  // Nothing is picked by default: the user chooses Consult or Pitch.
  PanelMode? _mode;
  List<SavedPanel> _saved = [];
  SavedPanel? _recent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await PanelHistory.load();
    if (mounted) {
      setState(() {
        _saved = l;
        _recent = null;
      });
    }
  }

  // Tap to continue a discussion (restores experts and mode); tap again to
  // start fresh.
  void _select(SavedPanel d) => setState(() {
    if (_recent == d) {
      _recent = null;
      return;
    }
    _recent = d;
    _picked
      ..clear()
      ..addAll(d.session.experts);
    _mode = d.session.mode;
  });

  /// "Whole panel" or the experts' names.
  String _who(PanelSession s) => s.wholePanel
      ? 'panel_whole'.tr
      : s.experts.map((i) => kExperts[i].name).join(', ');

  String _when(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days <= 0) return 'clixa_today'.tr;
    if (days == 1) return 'clixa_yesterday'.tr;
    return '${d.day}/${d.month}/${d.year}';
  }

  bool get _whole => _picked.length == kExperts.length;

  void _toggle(int i) => setState(() {
    _recent = null;
    if (!_picked.remove(i)) _picked.add(i);
  });

  void _toggleWhole() => setState(() {
    _recent = null;
    if (_whole) {
      _picked.clear();
    } else {
      _picked.addAll(List.generate(kExperts.length, (i) => i));
    }
  });

  bool get _canStart => _picked.isNotEmpty && _mode != null;

  void _start() {
    if (!_canStart) return;
    Get.to(
      () => ExpertPanelChatView(
        session:
            _recent?.session ??
            PanelSession(
              experts: (_picked.toList()..sort()),
              mode: _mode!,
              title: 'panel_new_idea'.tr,
            ),
      ),
      transition: Transition.rightToLeft,
    )?.then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final recent = _saved;
    final count = _picked.length;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            CareerAppBar(title: 'panel_title'.tr),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'panel_who'.tr,
                          style: _t(
                            14,
                            AppColors.titleDark,
                            w: FontWeight.w800,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _toggleWhole,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _blue,
                          side: const BorderSide(color: AppColors.pillBorder),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          'panel_whole'.tr,
                          style: _t(12, _blue, w: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < kExperts.length; i++)
                        Expanded(
                          child: _ExpertTile(
                            expert: kExperts[i],
                            selected: _picked.contains(i),
                            onTap: () => _toggle(i),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    count == 0
                        ? 'panel_picked_none'.tr
                        : count == 1
                        ? 'panel_picked_one'.tr
                        : 'panel_picked'.trParams({'count': count}),
                    style: _t(12.5, AppColors.textGrey),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'panel_what'.tr,
                    style: _t(14, AppColors.titleDark, w: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  for (final m in PanelMode.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ModeCard(
                        title: m.labelKey.tr,
                        hint: m.labelKey.replaceAll('_label', '_hint').tr,
                        selected: _mode == m,
                        onTap: () => setState(() {
                          _recent = null;
                          _mode = m;
                        }),
                      ),
                    ),
                  ...[
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        text: 'panel_recent'.tr,
                        style: _t(14, AppColors.titleDark, w: FontWeight.w800),
                        children: [
                          TextSpan(
                            text: 'panel_optional'.tr,
                            style: _t(12.5, AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'panel_recent_hint'.tr,
                      style: _t(12.5, AppColors.textGrey),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.pillBorder),
                      ),
                      child: recent.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'panel_no_recent'.tr,
                                textAlign: TextAlign.center,
                                style: _t(12.5, AppColors.textGrey),
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < recent.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      indent: 14,
                                      endIndent: 14,
                                      color: AppColors.pillBorder,
                                    ),
                                  InkWell(
                                    onTap: () => _select(recent[i]),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          _Radio(
                                            selected: _recent == recent[i],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  recent[i].session.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: _t(
                                                    14,
                                                    AppColors.titleDark,
                                                    w: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  'panel_recent_subtitle'
                                                      .trParams({
                                                        'who': _who(
                                                          recent[i].session,
                                                        ),
                                                        'mode': recent[i]
                                                            .session
                                                            .mode
                                                            .labelKey
                                                            .tr,
                                                        'when': _when(
                                                          recent[i].updatedAt,
                                                        ),
                                                      }),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: _t(
                                                    12.5,
                                                    AppColors.textGrey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'panel_footnote'.tr,
                    style: _t(12.5, AppColors.textGrey, h: 1.4),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.scaffoldBg,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canStart ? _start : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _blue.withValues(alpha: 0.4),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'panel_start'.tr,
                    style: _t(15, Colors.white, w: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpertTile extends StatelessWidget {
  const _ExpertTile({
    required this.expert,
    required this.selected,
    required this.onTap,
  });

  final Expert expert;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ExpertFace(
                expert: expert,
                size: 50,
                ringColor: selected ? _blue : Colors.transparent,
              ),
              if (selected)
                PositionedDirectional(
                  end: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            expert.name,
            style: _t(12.5, AppColors.titleDark, w: FontWeight.w800),
          ),
          Text(
            expert.longRoleKey.tr,
            textAlign: TextAlign.center,
            style: _t(9.5, expert.color, w: FontWeight.w600, h: 1.2),
          ),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? _blue : Colors.transparent,
      border: Border.all(
        color: selected ? _blue : const Color(0xFFC9C9D6),
        width: 1.5,
      ),
    ),
    child: selected
        ? const Center(
            child: CircleAvatar(radius: 3.5, backgroundColor: Colors.white),
          )
        : null,
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _blue : AppColors.pillBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            _Radio(selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _t(14, AppColors.titleDark, w: FontWeight.w800),
                  ),
                  const SizedBox(height: 1),
                  Text(hint, style: _t(12.5, AppColors.textGrey, h: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
