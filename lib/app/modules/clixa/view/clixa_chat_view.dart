import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../controller/clixa_controller.dart';
import '../model/clixa_models.dart';
import '../widgets/clixa_avatars.dart';
import '../widgets/clixa_sheets.dart';
import '../widgets/verdict_card.dart';
import 'clixa_view.dart';

TextStyle _t(double size, Color color, {FontWeight? w, double? h}) => TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: size + 1,
  fontWeight: w,
  height: h,
  color: color,
);

/// One chat with Clixa. UI only: Clixa's replies are scripted placeholders.
class ClixaChatView extends StatefulWidget {
  const ClixaChatView({super.key, required this.chat});

  final ClixaChat chat;

  @override
  State<ClixaChatView> createState() => _ClixaChatViewState();
}

class _ClixaChatViewState extends State<ClixaChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final List<Worker> _follow;

  ClixaChat get chat => widget.chat;
  ClixaController get _c => ClixaController.to;

  @override
  void initState() {
    super.initState();
    // Keep the newest message in view.
    _follow = [
      ever(chat.messages, (_) => _toBottom()),
      ever(chat.thinking, (_) => _toBottom()),
    ];
  }

  @override
  void dispose() {
    for (final w in _follow) {
      w.dispose();
    }
    _input.dispose();
    _scroll.dispose();
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

  void _limitSheet() => showFreeLimitSheet(
    context,
    onNewChat: () => pickClixaChat(context, replace: true),
  );

  Future<void> _send([String? text]) async {
    final t = (text ?? _input.text).trim();
    if (t.isEmpty) return;
    if (_c.limitReached(chat)) {
      _limitSheet();
      return;
    }
    _input.clear();
    FocusScope.of(context).unfocus();
    await _c.send(chat, t);
    // The tenth message was the last free one.
    if (mounted && _c.limitReached(chat)) _limitSheet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              chat: chat,
              onMenu: () => showChatMenuSheet(
                context,
                chat,
                onNewChat: () => pickClixaChat(context, replace: true),
                onDeleted: () => Navigator.of(context).pop(),
              ),
            ),
            const Divider(height: 1, color: AppColors.pillBorder),
            Expanded(
              child: Obx(() {
                final msgs = chat.messages.toList();
                final thinking = chat.thinking.value;
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
                  itemCount: msgs.length + (thinking ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == msgs.length) return const _Typing();
                    return _Bubble(message: msgs[i]);
                  },
                );
              }),
            ),
            _Footer(
              chat: chat,
              input: _input,
              onSend: _send,
              onSuggestion: () => _send(chat.mode.suggestionKey.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.chat, required this.onMenu});

  final ClixaChat chat;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.titleDark),
            padding: const EdgeInsetsDirectional.only(start: 20, end: 8),
            constraints: const BoxConstraints(),
          ),
          const ClixaAvatar(size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    chat.title.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(14, AppColors.titleDark, w: FontWeight.w800),
                  ),
                ),
                Text(
                  'clixa_chat_subtitle'.trParams({'mode': chat.mode.titleKey.tr}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _t(12, AppColors.textGrey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.titleDark),
            padding: const EdgeInsetsDirectional.only(start: 8, end: 14),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ClixaMessage message;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.76;
    if (message.fromUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxW),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.onboardingBtnEnd,
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(16),
                topEnd: Radius.circular(16),
                bottomStart: Radius.circular(16),
                bottomEnd: Radius.circular(4),
              ),
            ),
            child: Text(message.text, style: _t(13, Colors.white, h: 1.4)),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClixaAvatar(size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: message.verdict
                ? const VerdictCard()
                : Container(
                    constraints: BoxConstraints(maxWidth: maxW),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.scaffoldBg,
                      border: Border.fromBorderSide(
                        BorderSide(color: AppColors.pillBorder),
                      ),
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: Radius.circular(4),
                        topEnd: Radius.circular(16),
                        bottomStart: Radius.circular(16),
                        bottomEnd: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: _t(13, AppColors.titleDark, h: 1.4),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        const ClixaAvatar(size: 28),
        const SizedBox(width: 8),
        Text('clixa_typing'.tr, style: _t(12, AppColors.textGrey)),
      ],
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.chat,
    required this.input,
    required this.onSend,
    required this.onSuggestion,
  });

  final ClixaChat chat;
  final TextEditingController input;
  final VoidCallback onSend;
  final VoidCallback onSuggestion;

  @override
  Widget build(BuildContext context) {
    final c = ClixaController.to;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.pillBorder)),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A ready-made answer to start with.
          Obx(() {
            if (chat.userMessages > 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSuggestion,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onboardingBtnEnd,
                    side: const BorderSide(color: AppColors.onboardingBtnEnd),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    chat.mode.suggestionKey.tr,
                    textAlign: TextAlign.center,
                    style: _t(12.5, AppColors.onboardingBtnEnd, w: FontWeight.w600, h: 1.3),
                  ),
                ),
              ),
            );
          }),
          Obx(() {
            final used = chat.messages.where((m) => m.fromUser).length;
            if (c.isPro) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'clixa_messages_used'.trParams({
                  'used': used,
                  'max': ClixaController.freeMessagesPerChat,
                }),
                style: _t(11.5, AppColors.textGrey),
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: _t(13, AppColors.titleDark),
                  decoration: InputDecoration(
                    hintText: 'clixa_message_hint'.tr,
                    hintStyle: _t(13, AppColors.textGrey),
                    filled: true,
                    fillColor: AppColors.scaffoldBg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.pillBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.pillBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.onboardingBtnEnd),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.onboardingBtnEnd,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
