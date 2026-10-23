import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../profile_setup/model/user_profile_data.dart';
import '../service/profiles_manager.dart';
import 'profile_editor_view.dart';

const profilesRoute = '/Profiles';

/// Settings → Profile: the user's profiles. Tap one to switch to it; the menu
/// edits or deletes it; + adds another. Each profile keeps its own details,
/// designs, QR codes and signatures.
class ProfilesView extends StatelessWidget {
  const ProfilesView({super.key});

  void _add() => Get.to(
    () => const ProfileEditorView(),
    routeName: profileEditorRoute,
    transition: Transition.rightToLeft,
  );

  void _edit(ProfileEntry e) => Get.to(
    () => ProfileEditorView(editId: e.id),
    routeName: profileEditorRoute,
    transition: Transition.rightToLeft,
  );

  void _switch(ProfileEntry e) {
    if (e.id == ProfilesManager.activeId.value) return;
    ProfilesManager.switchTo(e.id);
    Get.snackbar(
      'profiles_switched_title'.tr,
      'profiles_switched_message'.trParams({'name': ProfilesManager.labelOf(e)}),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _delete(BuildContext context, ProfileEntry e) async {
    if (ProfilesManager.profiles.length <= 1) {
      Get.snackbar(
        'profiles_last_title'.tr,
        'profiles_last_message'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('profiles_delete_title'.tr),
        content: Text('profiles_delete_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('profiles_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'profiles_delete'.tr,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok == true) ProfilesManager.delete(e.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'profiles_add'.tr,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: AppColors.titleDark,
                      ),
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Text(
                    'profiles_title'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final active = ProfilesManager.activeId.value;
                final list = ProfilesManager.profiles.toList();
                // Re-draw when the active profile's details change.
                ProfilesManager.infoOf(active);
                return ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 96),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'profiles_subtitle'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.textSubtitle,
                        ),
                      ),
                    ),
                    for (final e in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProfileRow(
                          entry: e,
                          info: ProfilesManager.infoOf(e.id),
                          label: ProfilesManager.labelOf(e),
                          active: e.id == active,
                          onTap: () => _switch(e),
                          onEdit: () => _edit(e),
                          onDelete: () => _delete(context, e),
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

enum _Action { switchTo, edit, delete }

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.entry,
    required this.info,
    required this.label,
    required this.active,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ProfileEntry entry;
  final UserProfileData info;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      info.designation,
      info.companyName,
    ].where((s) => s.trim().isNotEmpty).join(' · ');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.pillBorder,
              width: active ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              _Avatar(info: info, label: label, active: active),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.titleDark,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                  ],
                ),
              ),
              if (active)
                Container(
                  margin: const EdgeInsetsDirectional.only(end: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'profiles_active'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              PopupMenuButton<_Action>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textGrey,
                ),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (a) => switch (a) {
                  _Action.switchTo => onTap(),
                  _Action.edit => onEdit(),
                  _Action.delete => onDelete(),
                },
                itemBuilder: (_) => [
                  if (!active)
                    PopupMenuItem(
                      value: _Action.switchTo,
                      child: Text('profiles_switch'.tr),
                    ),
                  PopupMenuItem(
                    value: _Action.edit,
                    child: Text('profiles_edit'.tr),
                  ),
                  PopupMenuItem(
                    value: _Action.delete,
                    child: Text(
                      'profiles_delete'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.info, required this.label, required this.active});

  final UserProfileData info;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : AppColors.primarySoft,
        image: info.hasLogo
            ? DecorationImage(
                image: MemoryImage(info.logoBytes!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: info.hasLogo
          ? null
          : Text(
              label.trim().isEmpty
                  ? '?'
                  : label.trim().characters.first.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : AppColors.primary,
              ),
            ),
    );
  }
}
