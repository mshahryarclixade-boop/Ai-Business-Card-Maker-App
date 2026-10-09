import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/add_link_sheet.dart';
import '../../scan card and qr/model/scanned_contact_data.dart';
import '../../scan card and qr/widgets/extracted_data_warning.dart';
import '../../scan card and qr/widgets/scanned_card_preview.dart';
import '../controller/contacts_controller.dart';
import '../model/contact_model.dart';
import '../widgets/custom_link_chip.dart';
import '../widgets/dotted_add_link_button.dart';
import '../widgets/editable_avatar.dart';
import '../widgets/labeled_field.dart';
import '../widgets/section_card.dart';
import '../widgets/section_header.dart';

enum _DuplicateChoice { update, separate }

class AddContactView extends StatefulWidget {
  final ContactModel? existing;

  final ScannedContactData? scannedData;

  const AddContactView({super.key, this.existing, this.scannedData});

  @override
  State<AddContactView> createState() => _AddContactViewState();
}

class _AddContactViewState extends State<AddContactView> {
  late final ContactsController controller;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _companyName;
  late TextEditingController _jobTitle;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _linkedin;
  late TextEditingController _website;
  late TextEditingController _notes;
  late TextEditingController _companyEmail;
  late TextEditingController _companyLinkedin;
  late TextEditingController _companyAddress;

  String? _imagePath;
  List<String> _customLinks = [];
  bool _showMoreFields = false;

  final _firstNameFocus = FocusNode();
  final _companyNameFocus = FocusNode();

  bool get _isEditing => widget.existing != null;
  bool get _isFromScan => !_isEditing && widget.scannedData != null;

  // ----- Dialog button styles (app theme) -----

  ButtonStyle get _dialogOutlinedStyle => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  ButtonStyle get _dialogFilledStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  @override
  void initState() {
    super.initState();
    controller = Get.find<ContactsController>(tag: 'contacts');

    final e = widget.existing;
    final s = widget.scannedData;

    _firstName = TextEditingController(text: e?.firstName ?? s?.firstName ?? '');
    _lastName = TextEditingController(text: e?.lastName ?? s?.lastName ?? '');
    _companyName = TextEditingController(text: e?.companyName ?? s?.companyName ?? '');
    _jobTitle = TextEditingController(text: e?.jobTitle ?? s?.jobTitle ?? '');
    _email = TextEditingController(text: e?.email ?? s?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? s?.phone ?? '');
    _linkedin = TextEditingController(text: e?.linkedin ?? s?.linkedin ?? '');
    _website = TextEditingController(text: e?.website ?? s?.website ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _companyEmail = TextEditingController(text: e?.companyEmail ?? '');
    _companyLinkedin = TextEditingController(text: e?.companyLinkedin ?? '');
    _companyAddress = TextEditingController(text: e?.companyAddress ?? '');

    // When creating a contact from a scanned card, the scanned card image
    // is used as the contact's image right away.
    _imagePath = e?.imagePath ?? s?.imagePath;
    _customLinks = List<String>.from(e?.customLinks ?? []);

    _showMoreFields =
        (e?.companyEmail.isNotEmpty ?? false) ||
            (e?.companyLinkedin.isNotEmpty ?? false) ||
            (e?.companyAddress.isNotEmpty ?? false);

    // Keep the name/company preview under the photo live as the user types.
    _firstName.addListener(_refresh);
    _lastName.addListener(_refresh);
    _companyName.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _companyName,
      _jobTitle,
      _email,
      _phone,
      _linkedin,
      _website,
      _notes,
      _companyEmail,
      _companyLinkedin,
      _companyAddress,
    ]) {
      c.dispose();
    }
    _firstNameFocus.dispose();
    _companyNameFocus.dispose();

    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await controller.pickAndStoreImage(
      source: ImageSource.gallery,
    );

    if (path != null) {
      setState(() => _imagePath = path);
    }
  }

  /// Opens the shared white bottom sheet (4 platform icons per row),
  /// then the URL sheet. Only the URL is stored because
  /// `ContactModel.customLinks` is a `List<String>`.
  Future<void> _addCustomLink() async {
    final added = await showAddLinkSheet(context);
    if (added == null) return;

    setState(() => _customLinks.add(added.url));
  }

  /// New non-empty value wins; otherwise the old one is kept.
  String _pick(String fresh, String old) => fresh.trim().isNotEmpty ? fresh : old;

  /// Merges a freshly entered contact into an already-saved duplicate.
  ContactModel _mergeInto(ContactModel old, ContactModel fresh) {
    final links = <String>{...old.customLinks, ...fresh.customLinks}.toList();
    return old.copyWith(
      firstName: _pick(fresh.firstName, old.firstName),
      lastName: _pick(fresh.lastName, old.lastName),
      companyName: _pick(fresh.companyName, old.companyName),
      jobTitle: _pick(fresh.jobTitle, old.jobTitle),
      email: _pick(fresh.email, old.email),
      phone: _pick(fresh.phone, old.phone),
      linkedin: _pick(fresh.linkedin, old.linkedin),
      website: _pick(fresh.website, old.website),
      notes: _pick(fresh.notes, old.notes),
      customLinks: links,
      companyEmail: _pick(fresh.companyEmail, old.companyEmail),
      companyLinkedin: _pick(fresh.companyLinkedin, old.companyLinkedin),
      companyAddress: _pick(fresh.companyAddress, old.companyAddress),
      imagePath: fresh.imagePath ?? old.imagePath,
    );
  }

  Future<_DuplicateChoice?> _askDuplicateChoice(ContactModel existing) {
    return showDialog<_DuplicateChoice>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.contactsScaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Contact already exists',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.contactsTitleDark,
          ),
        ),
        content: Text(
          '"${existing.fullName}" looks like a contact you already saved. '
              'Update it with the new details, or save this as a separate contact?',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: AppColors.contactsSubtitleGrey,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: _dialogOutlinedStyle,
            onPressed: () => Navigator.pop(context, _DuplicateChoice.separate),
            child: const Text('Save Separate'),
          ),
          ElevatedButton(
            style: _dialogFilledStyle,
            onPressed: () => Navigator.pop(context, _DuplicateChoice.update),
            child: const Text('Update Existing'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        companyName: _companyName.text.trim(),
        jobTitle: _jobTitle.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        linkedin: _linkedin.text.trim(),
        website: _website.text.trim(),
        notes: _notes.text.trim(),
        customLinks: _customLinks,
        companyEmail: _companyEmail.text.trim(),
        companyLinkedin: _companyLinkedin.text.trim(),
        companyAddress: _companyAddress.text.trim(),
        imagePath: _imagePath,
      );

      await controller.updateContact(updated);
    } else {
      // The scanned card image usually sits in a temp folder, so copy it
      // into app storage before saving the contact.
      String? imagePath = _imagePath;
      if (_isFromScan &&
          imagePath != null &&
          imagePath == widget.scannedData?.imagePath) {
        imagePath = await controller.persistImage(imagePath);
      }

      final contact = ContactModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        companyName: _companyName.text.trim(),
        jobTitle: _jobTitle.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        linkedin: _linkedin.text.trim(),
        website: _website.text.trim(),
        notes: _notes.text.trim(),
        customLinks: _customLinks,
        companyEmail: _companyEmail.text.trim(),
        companyLinkedin: _companyLinkedin.text.trim(),
        companyAddress: _companyAddress.text.trim(),
        imagePath: imagePath,
      );

      // Already saved? Let the user choose: update it or keep both.
      final duplicate = controller.findDuplicate(contact);
      if (duplicate != null) {
        final choice = await _askDuplicateChoice(duplicate);
        if (choice == null) return; // dialog dismissed, stay on the form

        if (choice == _DuplicateChoice.update) {
          await controller.updateContact(_mergeInto(duplicate, contact));
          Get.back();
          return;
        }
      }

      await controller.addContact(contact);
    }

    Get.back();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.contactsScaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.delete_outline, color: Colors.red, size: 32),
            SizedBox(height: 8),
            Text(
              'Are you Sure?',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.contactsTitleDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'This contact will be removed from your list',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: AppColors.contactsSubtitleGrey,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: _dialogOutlinedStyle,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: _dialogFilledStyle,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteContact(widget.existing!.id);
      Get.back();
    }
  }

  String get _fullName => (_firstName.text + ' ' + _lastName.text).trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contactsScaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.contactsScaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.contactsTitleDark,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _isEditing ? 'Edit Contact' : (_isFromScan ? 'Create Contact' : 'Add Contact'),
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.contactsTitleDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              if (_isFromScan) ...[
                ScannedCardPreview(data: widget.scannedData!),
                const SizedBox(height: 14),
                _buildReviewExtractedDataHeader(),
                const SizedBox(height: 10),
                if (widget.scannedData!.isMissingName && _firstName.text.trim().isEmpty)
                  ExtractedDataWarning(
                    title: 'Name Not Found',
                    message: "We couldn't find a name for this contact. Click below to add a name.",
                    onTap: () => FocusScope.of(context).requestFocus(_firstNameFocus),
                  ),
                if (widget.scannedData!.isMissingCompany && _companyName.text.trim().isEmpty)
                  ExtractedDataWarning(
                    title: 'Card Missing Company Name',
                    message: 'Company name is required for this contact. Click below to add a name.',
                    onTap: () => FocusScope.of(context).requestFocus(_companyNameFocus),
                  ),
                const SizedBox(height: 4),
              ],
              _buildPhotoHeader(),
              const SizedBox(height: 14),

              // ----- Personal Details -----
              SectionCard(
                header: const SectionHeader(
                  icon: Icons.person_outline,
                  title: 'Personal Details',
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'First Name *',
                          hint: 'First Name',
                          controller: _firstName,
                          focusNode: _firstNameFocus,
                          textCapitalization: TextCapitalization.sentences,
                          forceErrorBorder: _isFromScan &&
                              widget.scannedData!.isMissingName &&
                              _firstName.text.trim().isEmpty,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          label: 'Last Name',
                          hint: 'Last Name',
                          controller: _lastName,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Company Name *',
                    hint: 'Company Name',
                    controller: _companyName,
                    icon: Icons.apartment_outlined,
                    focusNode: _companyNameFocus,
                    textCapitalization: TextCapitalization.sentences,
                    forceErrorBorder: _isFromScan &&
                        widget.scannedData!.isMissingCompany &&
                        _companyName.text.trim().isEmpty,
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Job Title',
                    hint: 'Job Title',
                    controller: _jobTitle,
                    icon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),

              // ----- Contact Details -----
              SectionCard(
                header: const SectionHeader(
                  icon: Icons.call_outlined,
                  title: 'Contact Details',
                ),
                children: [
                  LabeledField(
                    label: 'Email',
                    hint: 'someone@email.com',
                    controller: _email,
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Phone Number',
                    hint: '+92308-6678901',
                    controller: _phone,
                    icon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'LinkedIn',
                    hint: 'Linkedin.com/in/username',
                    controller: _linkedin,
                    icon: Icons.link,
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    label: 'Website',
                    hint: 'Company Website',
                    controller: _website,
                    icon: Icons.language,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),

              // ----- Notes -----
              SectionCard(
                header: SectionHeader(
                  icon: Icons.push_pin_outlined,
                  title: 'Notes',
                  iconBackgroundColor: const Color(0xFFFCE9DA),
                  iconColor: const Color(0xFFE08A3C),
                ),
                children: [
                  LabeledField(
                    controller: _notes,
                    hint: 'Met at Dubai Expo, follow up next week.',
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  if (_customLinks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._customLinks.map(
                          (l) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CustomLinkChip(
                          url: l,
                          onRemove: () =>
                              setState(() => _customLinks.remove(l)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  DottedAddLinkButton(onTap: _addCustomLink),
                ],
              ),

              // ----- More Fields -----
              SectionCard(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        setState(() => _showMoreFields = !_showMoreFields),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showMoreFields
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showMoreFields
                                ? 'Show fewer fields'
                                : 'Show more fields',
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showMoreFields) ...[
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Company Email',
                      hint: 'Contact@companyname.com',
                      controller: _companyEmail,
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Company LinkedIn',
                      hint: 'Linkedin.com/in/username',
                      controller: _companyLinkedin,
                      icon: Icons.link,
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      label: 'Company Address',
                      hint: 'Company location, city',
                      controller: _companyAddress,
                      icon: Icons.location_on_outlined,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ],
              ),

              if (_isEditing) ...[
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: _confirmDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete Contact',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewExtractedDataHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.contactsLavenderBg.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fact_check_outlined, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review Extracted Data',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.contactsTitleDark,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Please review and correct any information',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.contactsSubtitleGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoHeader() {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            EditableAvatar(imagePath: _imagePath, onTap: _pickPhoto),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fullName.isEmpty ? 'Full Name' : _fullName,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.contactsTitleDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _companyName.text.isEmpty ? 'Company' : _companyName.text,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.contactsSubtitleGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap photo to add a picture',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      color: AppColors.contactsSubtitleGrey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}