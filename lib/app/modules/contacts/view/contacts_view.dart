import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart' hide Trans;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../scan card and qr/view/scan_card_view.dart';
import '../controller/contacts_controller.dart';
import 'add_contact_view.dart';
import 'contact_detail_view.dart';
import '../widgets/contacts_empty_state.dart';
import '../widgets/contacts_list.dart';
import '../widgets/no_results_state.dart';
import '../widgets/contacts_fab.dart';
import '../../paywall/view/paywall_screen.dart';
import '../../../core/translations/tr_extension.dart';

enum _AddAction { manual, scan }

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  late final ContactsController controller;
  final TextEditingController _searchCtrl = TextEditingController();

  // Own focus node so we can fully control when the search field is focused.
  final FocusNode _searchFocus = FocusNode();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ContactsController(), tag: 'contacts');

    _searchFocus.addListener(() {
      if (!mounted) return;
      if (_searchFocused != _searchFocus.hasFocus) {
        setState(() => _searchFocused = _searchFocus.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Keyboard handling
  // ---------------------------------------------------------------------------

  void _unfocusSearch() {
    _searchFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // ignore: unused_element
  void _exitSearch() {
    _unfocusSearch();
    _searchCtrl.clear();
    controller.updateSearch('');
    if (mounted) setState(() => _searchFocused = false);
  }

  /// Runs [action] (open a screen / sheet) and guarantees the search keyboard
  /// stays closed: before, during and after it.
  ///
  /// Flutter restores focus to the last focused field when a route or bottom
  /// sheet closes. Blocking the search field from taking focus while we are
  /// away, and releasing it on the next frame, prevents the keyboard from
  /// popping back up.
  Future<T?> _keepSearchClosed<T>(Future<T?> Function() action) async {
    _unfocusSearch();
    _searchFocus.canRequestFocus = false;
    try {
      return await action();
    } finally {
      if (mounted) {
        _unfocusSearch();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _unfocusSearch();
          _searchFocus.canRequestFocus = true;
          if (_searchFocused) setState(() => _searchFocused = false);
        });
      }
    }
  }

  /// Opens a page (right-to-left transition) with the keyboard kept closed.
  Future<T?> _openPage<T>(Widget Function() page) {
    return _keepSearchClosed<T>(
          () async => await Get.to<T>(page, transition: Transition.rightToLeft),
    );
  }

  Future<void> _openScan() => _openPage<void>(() => const ScanCardView());

  Future<void> _openAddManually() =>
      _openPage<void>(() => const AddContactView());

  Future<void> _openPaywall() {
    return _keepSearchClosed<void>(
          () => Future<void>.sync(
            () => openPaywall(source: 'contacts', plans: true),
      ),
    );
  }

  // Opens the add-contact options (from the "+" FAB). The sheet only returns
  // the chosen action; navigation happens here so we can keep the keyboard
  // closed once everything is dismissed.
  Future<void> _openAddOptions() async {
    await _keepSearchClosed<void>(() async {
      final action = await showModalBottomSheet<_AddAction>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _AddOptionsSheet(
          onAddManually: () => Navigator.pop(sheetContext, _AddAction.manual),
          onScanCard: () => Navigator.pop(sheetContext, _AddAction.scan),
        ),
      );

      switch (action) {
        case _AddAction.manual:
          await Get.to(
                () => const AddContactView(),
            transition: Transition.rightToLeft,
          );
        case _AddAction.scan:
          await Get.to(
                () => const ScanCardView(),
            transition: Transition.rightToLeft,
          );
        case null:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contactsScaffoldBg,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          // Tapping anywhere outside the search field closes the keyboard.
          onTap: _unfocusSearch,
          child: Obx(() {
            final contacts = controller.filteredContacts;
            final hasAnyContacts = controller.contacts.isNotEmpty;

            return Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 8),
                _buildSearchBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: !hasAnyContacts
                      ? ContactsEmptyState(
                    onAddManually: _openAddManually,
                    onScanCard: _openScan,
                  )
                      : (contacts.isEmpty
                      ? NoResultsState(query: _searchCtrl.text)
                      : ContactsList(
                    contacts: contacts,
                    onTap: (c) =>
                        _openPage<void>(() => ContactDetailView(contact: c)),
                    onDelete: (c) => controller.deleteContact(c.id),
                  )),
                ),
              ],
            );
          }),
        ),
      ),

      // Separate FAB widget.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 108),
        child: ContactsFab(onTap: _openAddOptions),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      // top padding matched to 12 so this header lines up with
      // Templates' and Profile's headers (was 16 before).
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                'contacts_title'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.titleDark,
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: GestureDetector(
                onTap: _openPaywall,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.crown,
                    size: 18,
                    color: AppColors.crownGold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.contactsSearchBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD9D9D9)),
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: (v) => controller.updateSearch(v),
                // Tapping outside the field closes the keyboard.
                onTapOutside: (_) => _searchFocus.unfocus(),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.contactsSubtitleGrey,
                    size: 20,
                  ),
                  hintText: 'contacts_search_hint'.tr,
                  hintStyle: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.contactsSubtitleGrey,
                    fontSize: 14,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Quick access to scanning.
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _openScan,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.contactsLavenderBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.contactsLavenderBorder),
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                size: 22,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet shown from the "+" FAB.
// ---------------------------------------------------------------------------

class _AddOptionsSheet extends StatelessWidget {
  final VoidCallback onAddManually;
  final VoidCallback onScanCard;

  const _AddOptionsSheet({
    required this.onAddManually,
    required this.onScanCard,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Phone: unchanged (32). Tablet: extra space so the sheet clears
    // the bottom nav / system area.
    final bottomPadding = isTablet ? 32.0 + 5 + bottomInset : 32.0;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'contacts_add_contact'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.contactsTitleDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PillButton(
                  icon: Icons.document_scanner_outlined,
                  label: 'contacts_scan_card'.tr,
                  onTap: onScanCard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PillButton(
                  icon: Icons.edit_outlined,
                  label: 'contacts_add_manually'.tr,
                  onTap: onAddManually,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.contactsLavenderBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.contactsLavenderBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}