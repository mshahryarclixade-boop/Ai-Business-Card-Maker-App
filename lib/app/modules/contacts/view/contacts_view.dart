import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../paywall/view/paywall_view.dart';
import '../../scan card and qr/view/scan_card_view.dart';
import '../controller/contacts_controller.dart';
import 'add_contact_view.dart';
import 'contact_detail_view.dart';
import '../widgets/contacts_empty_state.dart';
import '../widgets/contacts_list.dart';
import '../widgets/no_results_state.dart';
import '../widgets/contacts_fab.dart';

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  late final ContactsController controller;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ContactsController(), tag: 'contacts');
  }

  void _exitSearch() {
    FocusManager.instance.primaryFocus?.unfocus();

    _searchCtrl.clear();
    controller.updateSearch('');
    setState(() => _searchFocused = false);
  }

  // Opens the same add-contact options that were previously handled
  // directly inside the ContactsView FAB.
  void _openAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddOptionsSheet(
        onAddManually: () {
          Navigator.pop(context);
          Get.to(
                () => const AddContactView(),
            transition: Transition.rightToLeft,
          );
        },
        onScanCard: () {
          Navigator.pop(context);
          Get.to(() => const ScanCardView(), transition: Transition.rightToLeft);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contactsScaffoldBg,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
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
                    onAddManually: () {
                      Get.to(
                            () => const AddContactView(),
                        transition: Transition.rightToLeft,
                      );
                    },
                    onScanCard: () {
                      Get.to(
                            () => const ScanCardView(),
                        transition: Transition.rightToLeft,
                      );
                    },
                  )
                      : (contacts.isEmpty
                      ? NoResultsState(query: _searchCtrl.text)
                      : ContactsList(
                    contacts: contacts,
                    onTap: (c) async {
                      // Remove focus before navigating.
                      FocusManager.instance.primaryFocus?.unfocus();

                      await Get.to(
                            () => ContactDetailView(contact: c),
                        transition: Transition.rightToLeft,
                      );

                      // Remove focus again after returning to Contacts.
                      if (mounted) {
                        WidgetsBinding.instance
                            .addPostFrameCallback((_) {
                          if (mounted) {
                            FocusManager.instance.primaryFocus
                                ?.unfocus();
                            setState(() {
                              _searchFocused = false;
                            });
                          }
                        });
                      }
                    },
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
            const Center(
              child: Text(
                'Contacts',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.titleDark,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Get.to(
                        () => const PaywallView(),
                    transition: Transition.rightToLeft,
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.cardWhite,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.crown,
                    size: 18,
                    color: AppColors.contactsPremiumIcon,
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
                onTap: () => setState(() => _searchFocused = true),
                onChanged: (v) => controller.updateSearch(v),
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.contactsSubtitleGrey,
                    size: 20,
                  ),
                  hintText: 'Search Contacts...',
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
            onTap: () => Get.to(
                  () => const ScanCardView(),
              transition: Transition.rightToLeft,
            ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add Contact',
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
                  label: 'Scan Card',
                  onTap: onScanCard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PillButton(
                  icon: Icons.edit_outlined,
                  label: 'Add Manually',
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
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}