import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../career_studio/widgets/career_hub_sheets.dart';
import '../../paywall/controller/subscription_controller.dart';
import '../../paywall/services/revenue_cat_service.dart';
import '../controller/clixa_controller.dart';
import '../model/clixa_models.dart';
import 'clixa_avatars.dart';

TextStyle _t(double size, Color color, {FontWeight? w, double? h}) =>
    TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: size + 1,
      fontWeight: w,
      height: h,
      color: color,
    );

Future<T?> _sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 16),
            child: child,
          ),
        ),
      ),
    );

Future<bool> _buy(BuildContext context, {required bool yearly}) =>
    Get.find<SubscriptionController>().buy(
      context,
      productId: yearly
          ? RevenueCatHelper.yearlyProductId
          : RevenueCatHelper.monthlyProductId,
      plan: yearly ? 'yearly' : 'monthly',
      source: 'clixa',
    );

/// "Unlock the expert panel": the Go Pro sheet with the five experts.
Future<void> showClixaUpgrade(BuildContext context) => showUpgradeSheet(
  context,
  title: 'clixa_unlock_title'.tr,
  header: const ExpertAvatars(size: 40, overlap: 12),
  perkKeys: const [
    'clixa_perk_1',
    'clixa_perk_2',
    'clixa_perk_3',
    'clixa_perk_4',
  ],
  purchaser: _buy,
);

// ---------------------------------------------------------------- buttons

class _Primary extends StatelessWidget {
  const _Primary(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.onboardingBtnEnd,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1, style: _t(14, Colors.white, w: FontWeight.w700)),
      ),
    ),
  );
}

class _Outline extends StatelessWidget {
  const _Outline(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.titleDark,
        side: const BorderSide(color: AppColors.pillBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1, style: _t(14, AppColors.titleDark, w: FontWeight.w700)),
      ),
    ),
  );
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: _t(14, AppColors.onboardingBtnEnd, w: FontWeight.w700),
      ),
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: _t(20, AppColors.titleDark, w: FontWeight.w800, h: 1.2),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 14),
    child: Text(text, style: _t(12.5, AppColors.textSubtitle, h: 1.4)),
  );
}

// ------------------------------------------------------------- start a chat

/// "Start a new chat": the five kinds. [onPick] runs after the sheet closes.
Future<void> showStartChatSheet(
  BuildContext context, {
  required ValueChanged<ClixaMode> onPick,
}) async {
  final c = ClixaController.to;
  final picked = await _sheet<ClixaMode>(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Title('clixa_start_sheet_title'.tr),
        _Body(
          c.isPro
              ? 'clixa_start_sheet_message_pro'.tr
              : 'clixa_start_sheet_message'.trParams({
                  'left': c.freeChatsLeft,
                  'total': ClixaController.freeChatsPerDay,
                }),
        ),
        for (var i = 0; i < ClixaMode.values.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.pillBorder),
          Builder(
            builder: (ctx) => _ModeRow(
              mode: ClixaMode.values[i],
              onTap: () => Navigator.of(ctx).pop(ClixaMode.values[i]),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Builder(
          builder: (ctx) =>
              _Outline('clixa_cancel'.tr, () => Navigator.of(ctx).pop()),
        ),
      ],
    ),
  );
  if (picked != null) onPick(picked);
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.mode, required this.onTap});
  final ClixaMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(mode.icon, size: 18, color: AppColors.onboardingBtnEnd),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode.titleKey.tr, style: _t(13, AppColors.titleDark, w: FontWeight.w800)),
                  Text(mode.subtitleKey.tr, style: _t(12, AppColors.textGrey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ limits

/// "This chat reached the free limit".
Future<void> showFreeLimitSheet(
  BuildContext context, {
  required VoidCallback onNewChat,
}) {
  final c = ClixaController.to;
  return _sheet<void>(
    context,
    Builder(
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title('clixa_limit_chat_title'.tr),
          _Body('clixa_limit_chat_message'.trParams({'max': ClixaController.freeMessagesPerChat})),
          _Primary('clixa_get_unlimited_messages'.tr, () {
            Navigator.of(ctx).pop();
            showClixaUpgrade(context);
          }),
          const SizedBox(height: 10),
          _Outline(
            'clixa_new_chat_left'.trParams({'left': c.freeChatsLeft}),
            () {
              Navigator.of(ctx).pop();
              onNewChat();
            },
          ),
          _Link('clixa_not_now'.tr, () => Navigator.of(ctx).pop()),
        ],
      ),
    ),
  );
}

/// "You've used today's 3 free chats".
Future<void> showDailyLimitSheet(
  BuildContext context, {
  required VoidCallback onContinueSaved,
}) {
  return _sheet<void>(
    context,
    Builder(
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title('clixa_limit_day_title'.trParams({'total': ClixaController.freeChatsPerDay})),
          _Body('clixa_limit_day_message'.tr),
          _Primary('clixa_get_unlimited_chats'.tr, () {
            Navigator.of(ctx).pop();
            showClixaUpgrade(context);
          }),
          const SizedBox(height: 10),
          _Outline('clixa_continue_saved'.tr, () {
            Navigator.of(ctx).pop();
            onContinueSaved();
          }),
          _Link('clixa_not_now'.tr, () => Navigator.of(ctx).pop()),
        ],
      ),
    ),
  );
}

// -------------------------------------------------------------- chat menu

/// The ⋮ menu of a chat.
Future<void> showChatMenuSheet(
  BuildContext context,
  ClixaChat chat, {
  required VoidCallback onNewChat,
  required VoidCallback onDeleted,
}) {
  return _sheet<void>(
    context,
    Builder(
      builder: (ctx) {
        Widget item(IconData icon, String label, VoidCallback onTap, {Color? color}) =>
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: color ?? AppColors.onboardingBtnEnd),
                    const SizedBox(width: 12),
                    Text(label, style: _t(13, color ?? AppColors.titleDark, w: FontWeight.w600)),
                  ],
                ),
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(chat.title.value, style: _t(16, AppColors.titleDark, w: FontWeight.w800))),
            const SizedBox(height: 6),
            item(Icons.edit_outlined, 'clixa_rename_chat'.tr, () {
              Navigator.of(ctx).pop();
              showRenameChatSheet(context, chat);
            }),
            const Divider(height: 1, color: AppColors.pillBorder),
            item(Icons.add_rounded, 'clixa_menu_new_chat'.tr, () {
              Navigator.of(ctx).pop();
              onNewChat();
            }),
            const Divider(height: 1, color: AppColors.pillBorder),
            item(Icons.delete_outline_rounded, 'clixa_delete_chat'.tr, () {
              Navigator.of(ctx).pop();
              ClixaController.to.delete(chat);
              onDeleted();
            }, color: const Color(0xFFD32F2F)),
            const SizedBox(height: 12),
            _Outline('clixa_close'.tr, () => Navigator.of(ctx).pop()),
          ],
        );
      },
    ),
  );
}

Future<void> showRenameChatSheet(BuildContext context, ClixaChat chat) {
  final field = TextEditingController(text: chat.title.value);
  return _sheet<void>(
    context,
    Builder(
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title('clixa_rename_title'.tr),
          const SizedBox(height: 12),
          Text('clixa_chat_name'.tr, style: _t(12, AppColors.titleDark, w: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: field,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: _t(13, AppColors.titleDark),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.scaffoldBg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.pillBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.pillBorder),
              ),
            ),
            onSubmitted: (v) {
              ClixaController.to.rename(chat, v);
              Navigator.of(ctx).pop();
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Outline('clixa_cancel'.tr, () => Navigator.of(ctx).pop())),
              const SizedBox(width: 10),
              Expanded(
                child: _Primary('clixa_save'.tr, () {
                  ClixaController.to.rename(chat, field.text);
                  Navigator.of(ctx).pop();
                }),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------ saved chats

/// The chats made so far, to pick one up again.
Future<void> showSavedChatsSheet(
  BuildContext context, {
  required ValueChanged<ClixaChat> onOpen,
}) async {
  final picked = await _sheet<ClixaChat>(
    context,
    Builder(
      builder: (ctx) {
        final chats = ClixaController.to.chats.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title('clixa_saved_title'.tr),
            const SizedBox(height: 8),
            if (chats.isEmpty)
              _Body('clixa_saved_empty'.tr)
            else
              for (final chat in chats)
                InkWell(
                  onTap: () => Navigator.of(ctx).pop(chat),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        Icon(chat.mode.icon, size: 18, color: AppColors.onboardingBtnEnd),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(chat.title.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: _t(13, AppColors.titleDark, w: FontWeight.w700)),
                              Text(chat.mode.titleKey.tr, style: _t(12, AppColors.textGrey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            _Outline('clixa_close'.tr, () => Navigator.of(ctx).pop()),
          ],
        );
      },
    ),
  );
  if (picked != null) onOpen(picked);
}
