import '../../../core/widgets/tap_target.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/translations/tr_extension.dart';
import '../../profile_setup/model/user_profile_data.dart';
import '../../profile_setup/service/profile_store.dart';
import '../service/profiles_manager.dart';

const profileEditorRoute = '/ProfileEditor';

/// New / Edit profile. [editId] edits that profile (active or not); null
/// creates a new one and switches to it.
class ProfileEditorView extends StatefulWidget {
  const ProfileEditorView({super.key, this.editId});

  final String? editId;

  @override
  State<ProfileEditorView> createState() => _ProfileEditorViewState();
}

class _ProfileEditorViewState extends State<ProfileEditorView> {
  late final UserProfileData _initial = widget.editId == null
      ? const UserProfileData(dialCode: '')
      : ProfilesManager.infoOf(widget.editId!);

  late final _name = TextEditingController(text: _initial.fullName);
  late final _job = TextEditingController(text: _initial.designation);
  late final _company = TextEditingController(text: _initial.companyName);
  late final _code = TextEditingController(text: _initial.dialCode);
  late final _phone = TextEditingController(text: _initial.phoneNumber);
  late final _email = TextEditingController(text: _initial.email);
  late final _website = TextEditingController(text: _initial.website);

  Uint8List? _logo;
  String _logoName = '';
  bool _nameMissing = false;

  @override
  void initState() {
    super.initState();
    _logo = _initial.logoBytes;
    _logoName = _initial.logoName;
  }

  @override
  void dispose() {
    for (final c in [_name, _job, _company, _code, _phone, _email, _website]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _logo = bytes;
      _logoName = file.name;
    });
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameMissing = true);
      return;
    }
    final data = UserProfileData(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      dialCode: _code.text.trim().isEmpty ? '+92' : _code.text.trim(),
      phoneNumber: _phone.text.trim(),
      companyName: _company.text.trim(),
      designation: _job.text.trim(),
      website: _website.text.trim(),
      logoBytes: _logo,
      logoName: _logoName,
    );
    final store = ProfileStore.to;
    final editing = widget.editId;
    if (editing != null) {
      store.writeStored(editing, data);
      // A profile that isn't active has no live value to notify the list.
      ProfilesManager.profiles.refresh();
    } else {
      final id = ProfilesManager.create(name: data.fullName);
      store.writeStored(id, data);
      ProfilesManager.switchTo(id); // the new profile is the one in use
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
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
                      child: TapTarget(child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: AppColors.titleDark,
                        ),
                        padding: const EdgeInsetsDirectional.only(start: 12),
                        constraints: const BoxConstraints(),
                      )),
                    ),
                    Text(
                      (widget.editId == null
                              ? 'profiles_new_title'
                              : 'profiles_edit_title')
                          .tr,
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
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                  children: [
                    _LogoTile(
                      bytes: _logo,
                      onPick: _pickLogo,
                      onRemove: () => setState(() {
                        _logo = null;
                        _logoName = '';
                      }),
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'profiles_field_name'.tr,
                      controller: _name,
                      error: _nameMissing ? 'profiles_name_required'.tr : null,
                      onChanged: (_) {
                        if (_nameMissing) setState(() => _nameMissing = false);
                      },
                    ),
                    _Field(label: 'profiles_field_job'.tr, controller: _job),
                    _Field(
                      label: 'profiles_field_company'.tr,
                      controller: _company,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 84,
                          child: _Field(
                            label: 'profiles_field_code'.tr,
                            controller: _code,
                            type: TextInputType.phone,
                            hint: '+92',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(
                            label: 'profiles_field_phone'.tr,
                            controller: _phone,
                            type: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    _Field(
                      label: 'profiles_field_email'.tr,
                      controller: _email,
                      type: TextInputType.emailAddress,
                    ),
                    _Field(
                      label: 'profiles_field_website'.tr,
                      controller: _website,
                      type: TextInputType.url,
                      last: true,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'profiles_save'.tr,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({
    required this.bytes,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.pillBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primarySoft,
                image: bytes == null
                    ? null
                    : DecorationImage(
                        image: MemoryImage(bytes!),
                        fit: BoxFit.cover,
                      ),
              ),
              child: bytes == null
                  ? const Icon(Icons.add_a_photo_outlined,
                      color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'profiles_logo'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.titleDark,
                ),
              ),
            ),
            if (bytes != null)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textGrey,
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.type,
    this.error,
    this.hint,
    this.onChanged,
    this.last = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? type;
  final String? error;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: type,
            onChanged: onChanged,
            textInputAction: last ? TextInputAction.done : TextInputAction.next,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15.5,
              color: AppColors.titleDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              errorText: error,
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsetsDirectional.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.pillBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.pillBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
