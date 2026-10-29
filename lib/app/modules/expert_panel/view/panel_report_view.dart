import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../career_studio/widgets/career_widgets.dart';
import '../model/expert_models.dart';
import '../service/panel_ai_service.dart';

TextStyle _t(double size, Color color, {FontWeight? w, double? h}) => TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: size,
  fontWeight: w,
  height: h,
  color: color,
);

/// The end of a session: the scored report (Pitch) or the action plan
/// (Consultation). The server writes it from the transcript and the hidden
/// notebooks / case file; this screen only shows it.
class PanelReportView extends StatefulWidget {
  const PanelReportView({super.key, required this.session});

  final PanelSession session;

  @override
  State<PanelReportView> createState() => _PanelReportViewState();
}

class _PanelReportViewState extends State<PanelReportView> {
  Map<String, dynamic>? _report;
  var _loading = true;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final r = await PanelAi.instance.report(widget.session);
      if (!mounted) return;
      setState(() {
        _report = r;
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('PANEL REPORT ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pitch = widget.session.mode == PanelMode.pitch;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            CareerAppBar(
              title: (pitch ? 'panel_feedback_title' : 'panel_plan_title').tr,
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 14),
                          Text(
                            'panel_report_loading'.tr,
                            style: _t(13, AppColors.textGrey),
                          ),
                        ],
                      ),
                    )
                  : _failed
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'panel_report_failed'.tr,
                              textAlign: TextAlign.center,
                              style: _t(13.5, AppColors.titleDark, h: 1.4),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _load,
                              child: Text('panel_retry'.tr),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _body(_report!, pitch),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(Map<String, dynamic> r, bool pitch) {
    final status = r['status'];
    if (status != 'complete' && status != 'partial') {
      return _Note(text: '${r['message'] ?? ''}');
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: pitch ? _pitch(r) : _plan(r),
    );
  }

  // ---------------------------------------------------------------- pitch

  Widget _pitch(Map<String, dynamic> r) {
    final sub = r['sub_scores'] is Map ? r['sub_scores'] as Map : const {};
    final score = r['overall_score'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          child: Column(
            children: [
              Text(
                'panel_score'.trParams({'score': '$score'}),
                style: _t(22, AppColors.titleDark, w: FontWeight.w900),
              ),
              if ('${r['label'] ?? ''}'.isNotEmpty)
                Text(
                  '${r['label']}',
                  style: _t(14, AppColors.onboardingBtnEnd),
                ),
              if (sub.values.any((v) => v is num)) ...[
                const SizedBox(height: 12),
                _Bar('panel_sub_clarity'.tr, sub['clarity_story']),
                _Bar('panel_sub_market'.tr, sub['market_customer']),
                _Bar('panel_sub_numbers'.tr, sub['model_numbers']),
                _Bar('panel_sub_execution'.tr, sub['execution_readiness']),
              ],
            ],
          ),
        ),
        _Section('panel_summary'.tr, [_Para('${r['summary'] ?? ''}')]),
        _Section('panel_strengths'.tr, [
          for (final s in _list(r['strengths'])) _Bullet('$s'),
        ]),
        _Section('panel_risks'.tr, [
          for (final x in _list(r['risks']))
            if (x is Map)
              _Bullet(
                '${x['risk']}${x['raised_by'] is String ? ' (${expertById(x['raised_by'] as String).name})' : ''}',
              ),
        ]),
        _Section('panel_next_steps'.tr, [
          for (final s in _list(r['next_steps'])) _Bullet('$s'),
        ]),
        _Section('panel_outcome'.tr, [
          for (final o in _list(r['panel_outcome']))
            if (o is Map)
              _Bullet(
                '${expertById('${o['investor']}').name}: '
                '${(o['decision'] == 'in' ? 'panel_decision_in' : 'panel_decision_out').tr}'
                '${o['score'] is num ? ' · ${(o['score'] as num).round()}/100' : ''}'
                '${o['reason'] is String && (o['reason'] as String).isNotEmpty ? ' — ${o['reason']}' : ''}'
                '${o['practice_offer'] is String ? ' · ${o['practice_offer']}' : ''}',
              ),
        ]),
        _Section('panel_quotes'.tr, [
          for (final q in _list(r['quotes']))
            if (q is Map)
              _Para('${expertById('${q['investor']}').name}: “${q['quote']}”'),
        ]),
        _Para('${r['encouragement'] ?? ''}'),
        _Disclaimer('${r['disclaimer'] ?? ''}'),
      ],
    );
  }

  // ----------------------------------------------------------------- plan

  Widget _plan(Map<String, dynamic> r) {
    final cases = _list(r['cases']).whereType<Map>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ('${r['title'] ?? ''}'.isNotEmpty)
          Text(
            '${r['title']}',
            style: _t(20, AppColors.titleDark, w: FontWeight.w900),
          ),
        for (final c in cases) ...[
          if ('${c['business'] ?? ''}'.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${c['business']}',
                style: _t(14, AppColors.onboardingBtnEnd, w: FontWeight.w800),
              ),
            ),
          _Section('panel_plan_situation'.tr, [_Para('${c['situation']}')]),
          _Section('panel_plan_insights'.tr, [
            for (final i in _list(c['key_insights']))
              if (i is Map)
                _Bullet(
                  '${expertById('${i['advisor']}').name}: ${i['insight']}',
                ),
          ]),
          _Section('panel_plan_steps'.tr, [
            for (final s in _list(c['action_plan']))
              if (s is Map)
                _Bullet(
                  '${s['step']} (${s['timeframe']})'
                  '${'${s['why'] ?? ''}'.isEmpty ? '' : ' — ${s['why']}'}',
                ),
          ]),
          _Section('panel_plan_metrics'.tr, [
            for (final m in _list(c['metrics_to_watch'])) _Bullet('$m'),
          ]),
          _Section('panel_plan_open'.tr, [
            for (final q in _list(c['open_questions'])) _Bullet('$q'),
          ]),
        ],
        if (_list(r['professional_help']).isNotEmpty)
          _Section('panel_plan_professional'.tr, [
            for (final p in _list(r['professional_help']))
              if (p is Map) _Bullet('${p['who']}: ${p['why']}'),
          ]),
        _Para('${r['encouragement'] ?? ''}'),
        _Disclaimer('${r['disclaimer'] ?? ''}'),
      ],
    );
  }
}

List<dynamic> _list(Object? v) => v is List ? v : const [];

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: _t(14, AppColors.titleDark, h: 1.45),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.scaffoldBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.pillBorder),
    ),
    child: child,
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _t(15, AppColors.titleDark, w: FontWeight.w800)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _Para extends StatelessWidget {
  const _Para(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => text.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(text, style: _t(13.5, AppColors.titleDark, h: 1.45)),
        );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: _t(13.5, AppColors.titleDark)),
        Expanded(
          child: Text(text, style: _t(13.5, AppColors.titleDark, h: 1.4)),
        ),
      ],
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar(this.label, this.value);
  final String label;
  final Object? value;
  @override
  Widget build(BuildContext context) {
    final v = value is num ? (value as num).toDouble() : null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: _t(12.5, AppColors.textGrey)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v == null ? 0 : v / 25,
                minHeight: 8,
                backgroundColor: AppColors.pillBorder,
                color: AppColors.onboardingBtnEnd,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              v == null ? '—' : '${v.round()}/25',
              textAlign: TextAlign.end,
              style: _t(12, AppColors.titleDark, w: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => text.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Text(text, style: _t(11.5, AppColors.textGrey, h: 1.4)),
        );
}
