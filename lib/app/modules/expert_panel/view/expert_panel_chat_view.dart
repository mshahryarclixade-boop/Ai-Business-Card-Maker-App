import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/services/speech_input_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../../core/widgets/response_actions.dart';
import '../../../core/widgets/voice_mic_button.dart';
import '../controller/panel_chat_controller.dart';
import '../model/expert_models.dart';
import '../service/panel_ai_service.dart';
import '../service/panel_history_service.dart';
import 'panel_report_view.dart';

TextStyle _t(double size, Color color, {FontWeight? w, double? h}) => TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: size,
  fontWeight: w,
  height: h,
  color: color,
);

const _blue = AppColors.onboardingBtnEnd;

/// Expert panel chat. The server's Director decides who speaks; this screen
/// shows the lines as they arrive.
class ExpertPanelChatView extends StatefulWidget {
  const ExpertPanelChatView({super.key, required this.session});

  final PanelSession session;

  @override
  State<ExpertPanelChatView> createState() => _ExpertPanelChatViewState();
}

class _ExpertPanelChatViewState extends State<ExpertPanelChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final PanelChatController _c = PanelChatController(widget.session);
  late final List<Worker> _follow;

  /// Dictation into the message box (Pitch and Consultation alike).
  final _speech = SpeechInputService();

  PanelSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    // Keep the newest message in view; leave when the session ends.
    _follow = [
      ever(session.messages, (_) => _toBottom()),
      ever(_c.thinking, (_) => _toBottom()),
      ever(_c.over, (over) {
        if (over) _openReportSoon();
      }),
    ];
    _speech.onIssue = (issue) {
      if (mounted) showSpeechIssue(_speech, issue);
    };
    if (session.messages.isEmpty) _welcome();
  }

  @override
  void dispose() {
    for (final w in _follow) {
      w.dispose();
    }
    TtsService.instance.stop();
    _speech.dispose();
    _input.dispose();
    _scroll.dispose();
    _c.onClose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  var _opening = false;

  /// The session is over: give the user a moment to read the last line, then
  /// open the report (Pitch) or the action plan (Consultation).
  void _openReportSoon() {
    if (_opening) return;
    _opening = true;
    Future.delayed(const Duration(milliseconds: 1800), () {
      _opening = false;
      if (!mounted) return;
      PanelHistory.save(session);
      _openReport();
    });
  }

  void _openReport() => Get.to(
    () => PanelReportView(session: session),
    transition: Transition.rightToLeft,
  );

  void _error(Object e) {
    Get.snackbar(
      'career_ai_failed_title'.tr,
      e is GeminiException ? e.message : 'career_ai_error_generic'.tr,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
    );
  }

  Future<void> _welcome() async {
    try {
      await _c.start();
    } catch (e) {
      if (mounted) _error(e);
    }
  }

  /// The whole session as plain text, for Share.
  String _conversationText() {
    final lines = <String>[session.title];
    for (final m in session.messages) {
      final who = m.fromUser ? 'chat_you'.tr : expertById(m.speaker!).name;
      lines.add('$who: ${m.text}');
    }
    return lines.join('\n\n');
  }

  Future<void> _goToDecision() async {
    try {
      await _c.goToDecision();
    } catch (e) {
      if (mounted) _error(e);
    }
  }

  Future<void> _toggleMic() async {
    if (_c.over.value || (_c.thinking.value && !_speech.listening.value))
      return;
    FocusScope.of(context).unfocus();
    final issue = await _speech.toggle(_input);
    if (issue != null && mounted) showSpeechIssue(_speech, issue);
  }

  Future<void> _send() async {
    final t = _input.text.trim();
    if (t.isEmpty || _c.thinking.value || _c.over.value) return;
    await _speech.stop();
    if (!mounted) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    try {
      await _c.send(t);
    } catch (e) {
      // Nothing was answered: give the text back so it can be tried again.
      if (!mounted) return;
      _input.text = t;
      _error(e);
    }
  }

  /// End: says it in the chat. Clixa asks to confirm, and only a "yes" ends it.
  Future<void> _end() async {
    if (_c.thinking.value || _c.over.value) return;
    if (!session.hasUserMessage) {
      Get.snackbar(
        'panel_title'.tr,
        'panel_nothing_to_end'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'panel_end_title'.tr,
          style: _t(16, AppColors.titleDark, w: FontWeight.w800),
        ),
        content: Text(
          'panel_end_message'.tr,
          style: _t(13, AppColors.textGrey, h: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('panel_keep_chatting'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('panel_end_confirm'.tr),
          ),
        ],
      ),
    );
    // Ending needs no model call: the report page opens as soon as it is set.
    if (ok == true && mounted) await _c.endNow();
  }

  @override
  Widget build(BuildContext context) {
    final experts = [for (final i in session.experts) kExperts[i]];
    final who = session.wholePanel
        ? 'panel_whole'.tr
        : experts.map((e) => e.name).join(', ');
    final mode = session.mode.labelKey.tr;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.titleDark,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            for (var i = 0; i < experts.length; i++)
                              Align(
                                widthFactor: 0.62,
                                child: ExpertFace(
                                  expert: experts[i],
                                  size: 24,
                                  ringColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          session.messages.length;
                          return Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _t(
                              14,
                              AppColors.titleDark,
                              w: FontWeight.w800,
                            ),
                          );
                        }),
                        Text(
                          'panel_chat_subtitle'.trParams({
                            'who': who,
                            'mode': mode,
                            'round': session.round,
                          }),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _t(12.5, AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => _c.over.value
                        ? OutlinedButton(
                            onPressed: _openReport,
                            child: Text('panel_report_btn'.tr),
                          )
                        : OutlinedButton(
                            onPressed: _end,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.titleDark,
                              side: const BorderSide(
                                color: AppColors.pillBorder,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              minimumSize: const Size(0, 34),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'panel_end'.tr,
                              style: _t(
                                13,
                                AppColors.titleDark,
                                w: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.pillBorder),
            Expanded(
              child: Obx(() {
                final msgs = session.messages.toList();
                final thinking = _c.thinking.value;
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  // A label for the round, every message, then "thinking".
                  itemCount: 1 + msgs.length + (thinking ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == 0) return _RoundLabel(session: session);
                    final k = i - 1;
                    if (k == msgs.length) return const _Thinking();
                    final m = msgs[k];
                    return Padding(
                      padding: EdgeInsets.only(top: k == 0 ? 14 : 0),
                      child: m.fromUser
                          ? _UserBubble(text: m.text)
                          : _ExpertBubble(
                              expert: expertById(m.speaker!),
                              text: m.text,
                              id: '${session.id}:$k',
                              conversation: _conversationText,
                            ),
                    );
                  },
                );
              }),
            ),
            // Pitch: skip the remaining questions and hear the decisions.
            Obx(() {
              session
                  .messages
                  .length; // rebuild when the stage may have changed
              final show =
                  session.canGoToDecision &&
                  !_c.thinking.value &&
                  !_c.over.value;
              return show
                  ? Container(
                      color: Colors.white,
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: TextButton(
                        onPressed: _goToDecision,
                        child: Text(
                          'panel_go_to_decision'.tr,
                          style: _t(13, _blue, w: FontWeight.w800),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Obx(() {
                final off = _c.over.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: !off,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 1500,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: _t(12.5, AppColors.titleDark),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: off
                              ? 'panel_session_over'.tr
                              : experts.length == 1
                              ? 'panel_message_one'.trParams({
                                  'name': experts.first.name,
                                })
                              : 'panel_message_panel'.tr,
                          hintStyle: _t(12.5, AppColors.textGrey),
                          filled: true,
                          fillColor: AppColors.scaffoldBg,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.pillBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.pillBorder,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: AppColors.pillBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: _blue),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Opacity(
                      opacity: off ? 0.5 : 1,
                      child: VoiceMicButton(
                        speech: _speech,
                        onTap: off ? () {} : _toggleMic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: (_c.thinking.value || off) ? null : _send,
                      child: Opacity(
                        opacity: (_c.thinking.value || off) ? 0.5 : 1,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: _blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundLabel extends StatelessWidget {
  const _RoundLabel({required this.session});

  final PanelSession session;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'panel_session_label'.trParams({
        'mode': session.mode.labelKey.tr.toUpperCase(),
        'round': session.round,
      }),
      style: _t(
        10.5,
        AppColors.textGrey,
        w: FontWeight.w700,
      ).copyWith(letterSpacing: 1.1),
    ),
  );
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text('panel_thinking'.tr, style: _t(12.5, AppColors.textGrey)),
  );
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: _blue,
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(16),
            topEnd: Radius.circular(16),
            bottomStart: Radius.circular(16),
            bottomEnd: Radius.circular(4),
          ),
        ),
        child: Text(text, style: _t(12.5, Colors.white, h: 1.4)),
      ),
    ),
  );
}

class _ExpertBubble extends StatelessWidget {
  const _ExpertBubble({
    required this.expert,
    required this.text,
    required this.id,
    required this.conversation,
  });

  final Expert expert;
  final String text;
  final String id;
  final String Function() conversation;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpertFace(expert: expert, size: 28),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: expert.name,
                  style: _t(12.5, expert.color, w: FontWeight.w800),
                  children: [
                    TextSpan(
                      text: ' · ${expert.shortRoleKey.tr}',
                      style: _t(12.5, AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.66,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(4),
                    topEnd: Radius.circular(16),
                    bottomStart: Radius.circular(16),
                    bottomEnd: Radius.circular(16),
                  ),
                  border: Border.all(color: AppColors.pillBorder),
                ),
                // Long-press to select; the native toolbar has Copy / Select all.
                child: SelectableText(
                  text,
                  style: _t(12.5, AppColors.titleDark, h: 1.4),
                ),
              ),
              ResponseActions(id: id, text: text, conversation: conversation),
            ],
          ),
        ),
      ],
    ),
  );
}
