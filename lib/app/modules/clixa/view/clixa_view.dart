import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../../core/widgets/crown_upgrade_button.dart';
import '../../career_studio/widgets/career_widgets.dart';
import '../../profile_setup/service/profile_store.dart';
import '../controller/clixa_controller.dart';
import '../model/clixa_models.dart';
import '../widgets/clixa_avatars.dart';
import '../widgets/clixa_sheets.dart';
import 'clixa_chat_view.dart';

const clixaRoute = '/Clixa';

/// The Clixa AI tab: opens Clixa's start screen.
void openClixa() => Get.to(
  () => const ClixaView(),
  routeName: clixaRoute,
  transition: Transition.rightToLeft,
);

/// Opens a chat. [replace] swaps the current chat for it (starting a new chat
/// from inside one), so Back still goes to the start screen.
void openClixaChat(ClixaChat chat, {bool replace = false}) {
  Widget page() => ClixaChatView(chat: chat);
  final name = '/ClixaChat/${chat.id}';
  if (replace) {
    Get.off(page, routeName: name, transition: Transition.rightToLeft);
  } else {
    Get.to(page, routeName: name, transition: Transition.rightToLeft);
  }
}

/// Starts a chat of [mode] and opens it. With no free chats left (Free), the
/// "used today's free chats" sheet opens instead.
void startClixaChat(
  BuildContext context,
  ClixaMode mode, {
  bool replace = false,
}) {
  final c = ClixaController.to;
  if (!c.canStartChat) {
    showDailyLimitSheet(
      context,
      onContinueSaved: () => showSavedChatsSheet(
        context,
        onOpen: (chat) => openClixaChat(chat, replace: replace),
      ),
    );
    return;
  }
  openClixaChat(c.startChat(mode), replace: replace);
}

/// "Start a new chat": the five kinds to pick from.
void pickClixaChat(BuildContext context, {bool replace = false}) {
  final c = ClixaController.to;
  if (!c.canStartChat) {
    startClixaChat(
      context,
      ClixaMode.discuss,
      replace: replace,
    ); // shows the limit
    return;
  }
  showStartChatSheet(
    context,
    onPick: (m) => startClixaChat(context, m, replace: replace),
  );
}

TextStyle _t(double size, Color color, {FontWeight? w, double? h}) => TextStyle(
  fontFamily: AppTextStyles.fontFamily,
  fontSize: size + 1,
  fontWeight: w,
  height: h,
  color: color,
);

/// Clixa, the AI business coach: the empty-chat start screen. UI only; the
/// chats and replies are placeholders.
class ClixaView extends StatelessWidget {
  const ClixaView({super.key, this.embedded = false});

  /// Shown as the Clixa AI tab: no back arrow, and room left for the bottom
  /// navigation.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final c = ClixaController.to;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            CareerAppBar(
              title: 'clixa_title'.tr,
              showLeading: !embedded,
              trailing: Obx(
                () => c.isPro
                    ? const SizedBox.shrink()
                    : CrownUpgradeButton(
                        size: 40,
                        iconSize: 22,
                        borderRadius: 12,
                        onTap: () => showClixaUpgrade(context),
                      ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  20,
                  8,
                  20,
                  embedded ? 110 : 24,
                ),
                children: [
                  _ClixaCard(
                    onTap: () => startClixaChat(context, ClixaMode.discuss),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'clixa_start_chat'.tr,
                          style: _t(
                            14,
                            AppColors.titleDark,
                            w: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Obx(
                          () => Text(
                            c.isPro
                                ? 'clixa_unlimited_chats'.tr
                                : 'clixa_free_left'.trParams({
                                    'left': c.freeChatsLeft,
                                    'total': ClixaController.freeChatsPerDay,
                                  }),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: _t(12, AppColors.textGrey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < 4; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PromptCard(
                              mode: ClixaMode.values[i],
                              onTap: () =>
                                  startClixaChat(context, ClixaMode.values[i]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PromptCard(
                              mode: ClixaMode.values[i + 1],
                              onTap: () => startClixaChat(
                                context,
                                ClixaMode.values[i + 1],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _PromptCard(
                    mode: ClixaMode.talk,
                    onTap: () => startClixaChat(context, ClixaMode.talk),
                  ),
                  Obx(() {
                    final chats = c.chats
                        .where((x) => x.userMessages > 0)
                        .take(5)
                        .toList();
                    if (chats.isEmpty) return const _NoRecentChats();
                    return _RecentChats(
                      chats: chats,
                      onOpen: (chat) => openClixaChat(chat),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The blue Clixa card: avatar, greeting, and the prompt box. The box is for
/// show: it can't be typed in, tapping it (or the arrow) opens "Start a new
/// chat".
class _ClixaCard extends StatelessWidget {
  const _ClixaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const ClixaAvatar(size: 64, radius: 16),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final full = ProfileStore.to.profile.value.fullName
                            .trim();
                        final first = full.isEmpty ? '' : full.split(' ').first;
                        return Text(
                          first.isEmpty
                              ? 'clixa_hi'.tr
                              : 'clixa_hi_name'.trParams({'name': first}),
                          style: _t(
                            20,
                            Colors.white,
                            w: FontWeight.w800,
                            h: 1.2,
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Text(
                        'clixa_card_message'.tr,
                        style: _t(12.5, const Color(0xFFBFC8F2), h: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            IgnorePointer(
              child: Container(
                height: 52,
                padding: const EdgeInsetsDirectional.only(start: 18, end: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'clixa_input_hint'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _t(13, AppColors.textGrey),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.onboardingBtnEnd,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.mode, required this.onTap});

  final ClixaMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.pillBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  mode.icon,
                  size: 20,
                  color: AppColors.onboardingBtnEnd,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mode.titleKey.tr,
                      style: _t(
                        13,
                        AppColors.titleDark,
                        w: FontWeight.w800,
                        h: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.subtitleKey.tr,
                      style: _t(12, AppColors.textGrey, h: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown under the heading while there are no chats yet.
class _NoRecentChats extends StatelessWidget {
  const _NoRecentChats();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'clixa_recent'.tr,
            style: _t(14, AppColors.titleDark, w: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.pillBorder),
            ),
            child: Text(
              'clixa_no_recent'.tr,
              textAlign: TextAlign.center,
              style: _t(13, AppColors.textGrey),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recent chats in one rounded card, rows split by a divider, with the AI
/// disclaimer underneath.
class _RecentChats extends StatelessWidget {
  const _RecentChats({required this.chats, required this.onOpen});

  final List<ClixaChat> chats;
  final void Function(ClixaChat chat) onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'clixa_recent'.tr,
            style: _t(14, AppColors.titleDark, w: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.pillBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < chats.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.pillBorder,
                    ),
                  _RecentRow(
                    chat: chats[i],
                    when: chats[i].whenLabel,
                    onTap: () => onOpen(chats[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'clixa_ai_disclaimer'.tr,
              textAlign: TextAlign.center,
              style: _t(12, AppColors.textGrey, h: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.chat,
    required this.when,
    required this.onTap,
  });

  final ClixaChat chat;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const ClixaAvatar(size: 54),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => Text(
                      chat.title.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _t(17, AppColors.primaryDark, w: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'clixa_recent_subtitle'.trParams({
                      'mode': chat.mode.titleKey.tr,
                      'when': when,
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(13, AppColors.textGrey),
                  ),
                ],
              ),
            ),
            Obx(() {
              chat.messages.length;
              final badge = chat.verdictBadge;
              if (badge == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsetsDirectional.only(start: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: _t(13, AppColors.onboardingBtnEnd, w: FontWeight.w800),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
