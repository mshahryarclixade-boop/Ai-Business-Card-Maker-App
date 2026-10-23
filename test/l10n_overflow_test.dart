import 'dart:convert';
import 'dart:io';

import 'package:ai_business_card_maker/app/core/translations/app_strings.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/career_hub_controller.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/career_score_store.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/profile_report_controller.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_analyzing_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_fix_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_fixes_ready_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_new_score_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/career_studio_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/controller/profile_builder_flow_controller.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/widgets/career_hub_sheets.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/widgets/pdf_help_sheet.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/post_planner_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_builder_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_generated_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_optimizer_view.dart';
import 'package:ai_business_card_maker/app/modules/career_studio/view/profile_report_view.dart';
import 'package:ai_business_card_maker/app/modules/ai_card_generator/view/ai_card_generator_view.dart';
import 'package:ai_business_card_maker/app/modules/contacts/controller/contacts_controller.dart';
import 'package:ai_business_card_maker/app/modules/contacts/view/add_contact_view.dart';
import 'package:ai_business_card_maker/app/modules/contacts/view/contacts_view.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/ai_toolkit_section.dart';
import 'package:ai_business_card_maker/app/modules/onboarding/view/onboarding_view_v2.dart';
import 'package:ai_business_card_maker/app/modules/profile/view/create_profile_view.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/view/first_card_ready_view.dart';
import 'package:ai_business_card_maker/app/modules/qr_code_generator/view/qr_code_screen.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/model/user_profile_data.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/service/profile_store.dart';
import 'package:ai_business_card_maker/app/modules/settings/view/settings_view.dart';
import 'package:ai_business_card_maker/app/core/theme/app_colors.dart';
import 'package:ai_business_card_maker/app/core/translations/tr_extension.dart';
import 'package:ai_business_card_maker/app/core/widgets/app_dialog.dart';
import 'package:ai_business_card_maker/app/core/widgets/force_update_view.dart';
import 'package:ai_business_card_maker/app/core/widgets/no_internet_dialog.dart';
import 'package:ai_business_card_maker/app/core/widgets/rate_app_dialog.dart';
import 'package:ai_business_card_maker/app/modules/contacts/widgets/contacts_empty_state.dart';
import 'package:ai_business_card_maker/app/modules/contacts/widgets/no_results_state.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/create_first_card_section.dart';
import 'package:ai_business_card_maker/app/modules/main_nav/widgets/main_bottom_nav_bar.dart';
import 'package:ai_business_card_maker/app/core/services/recent_designs_service.dart';
import 'package:ai_business_card_maker/app/modules/contacts/model/contact_model.dart';
import 'package:ai_business_card_maker/app/modules/contacts/view/contact_detail_view.dart';
import 'package:ai_business_card_maker/app/modules/contacts/widgets/contact_action_row.dart';
import 'package:ai_business_card_maker/app/modules/contacts/widgets/contact_actions_menu.dart';
import 'package:ai_business_card_maker/app/modules/home/controller/home_controller.dart';
import 'package:ai_business_card_maker/app/modules/home/view/home_view.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/home_templates_section.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/my_card_section.dart';
import 'package:ai_business_card_maker/app/modules/profile/view/profile_view.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/view/business_details_view.dart';
import 'package:ai_business_card_maker/app/modules/profile_setup/view/personal_details_view.dart';
import 'package:ai_business_card_maker/app/modules/recent%20designs/view/my_cards_view.dart';
import 'package:ai_business_card_maker/app/modules/template/view/template_view.dart';
import 'package:ai_business_card_maker/app/modules/template/widget/template_edit_view.dart';
import 'package:ai_business_card_maker/app/core/widgets/add_link_sheet.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/controller/card_editor_controller.dart';
import 'package:ai_business_card_maker/app/modules/custom_create/view/card_editor_view.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/custom_create_card.dart';
import 'package:ai_business_card_maker/app/modules/home/widgets/share_card_sheet.dart';
import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view.dart';
import 'package:ai_business_card_maker/app/modules/paywall/view/paywall_view_2.dart';
import 'package:ai_business_card_maker/app/modules/recent%20designs/view/card_detail_view.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/model/scanned_contact_data.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/view/scan_card_view.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/widgets/scanned_card_preview.dart';
import 'package:ai_business_card_maker/app/modules/contacts/widgets/confirm_delete_contact.dart';
import 'package:ai_business_card_maker/app/modules/profile/controller/profile_controller.dart';
import 'package:ai_business_card_maker/app/modules/recent%20designs/controller/my_cards_controller.dart';
import 'package:ai_business_card_maker/app/modules/template/controller/template_controller.dart';
import 'package:ai_business_card_maker/app/modules/template/model/template_item.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/widgets/extracted_data_warning.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/widgets/scan_frame_overlay.dart';
import 'package:ai_business_card_maker/app/modules/scan%20card%20and%20qr/widgets/scan_segmented_toggle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Trans;
import 'package:get_storage/get_storage.dart';

/// Pumps screens in the longest-text languages and fails on RenderFlex
/// overflows (the yellow/black stripes).
Future<void> _loadFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'];
  if (sdk == null) return;
  final root = '$sdk/bin/cache/artifacts/material_fonts';
  final loader = FontLoader('SFPro');
  for (final f in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    final file = File('$root/$f');
    if (file.existsSync()) {
      loader.addFont(
        Future.value(ByteData.view(file.readAsBytesSync().buffer)),
      );
    }
  }
  await loader.load();
}

Widget _dialog(List<String> keys, List<String> buttons) => Scaffold(
  body: Center(
    child: AppDialogCard(
      children: [
        const AppDialogIcon(Icons.bolt_rounded),
        AppDialogText(title: keys[0].tr, message: keys[1].tr),
        for (final b in buttons)
          AppDialogButton(label: b.tr, color: AppColors.accent, onTap: () {}),
      ],
    ),
  ),
);

class _FakeSub extends SubscriptionController {
  @override
  void onInit() {}
}

/// Opens [open] right after the first frame (for sheets and dialogs).
class _Opener extends StatefulWidget {
  const _Opener(this.open);
  final void Function(BuildContext) open;
  @override
  State<_Opener> createState() => _OpenerState();
}

class _OpenerState extends State<_Opener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.open(context));
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

/// Calls onPressed of the first IconButton showing [icon].
void _pressIcon(IconData icon) {
  bool found = false;
  void visit(Element el) {
    if (found) return;
    final w = el.widget;
    if (w is IconButton && w.icon is Icon && (w.icon as Icon).icon == icon) {
      found = true;
      w.onPressed?.call();
      return;
    }
    el.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement!.visitChildren(visit);
}

class _EditorDiscard extends StatefulWidget {
  const _EditorDiscard();
  @override
  State<_EditorDiscard> createState() => _EditorDiscardState();
}

class _EditorDiscardState extends State<_EditorDiscard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<CardEditorController>().addText();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _pressIcon(Icons.arrow_back_ios_new_rounded),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const CardEditorView();
}

class _EditorWithTool extends StatefulWidget {
  const _EditorWithTool(this.tool, {this.addText = false});
  final String tool;
  final bool addText;
  @override
  State<_EditorWithTool> createState() => _EditorWithToolState();
}

class _EditorWithToolState extends State<_EditorWithTool> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = Get.find<CardEditorController>();
      if (widget.addText) c.addText();
      c.selectTool(widget.tool);
    });
  }

  @override
  Widget build(BuildContext context) => const CardEditorView();
}

/// Runs [setup] once, right before [child] is built.
class _Prep extends StatelessWidget {
  const _Prep(this.setup, this.child);
  final void Function() setup;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    setup();
    return child;
  }
}

class _FakeHome extends HomeController {
  @override
  void onReady() {}
}

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

final _contact = ContactModel(
  id: '1',
  firstName: 'Alexandre',
  lastName: 'Montgomery',
  companyName: 'Entreprise Internationale',
  jobTitle: 'Directeur du developpement',
  email: 'alex@example.com',
  phone: '+33 1 23 45 67 89',
  website: 'example.com',
  linkedin: 'linkedin.com/in/alex',
);

final _screens = <String, Widget Function()>{
  'orientation_sheet': () => _Opener(openOrientationSheet),
  'editor_discard_dialog': () => const _EditorDiscard(),
  'scan_overlay_card': () => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScanSegmentedToggle<int>(
            selected: 0,
            onChanged: (_) {},
            options: [
              ScanToggleOption(
                value: 0,
                label: 'scan_orientation_landscape'.tr,
                icon: Icons.crop_landscape,
              ),
              ScanToggleOption(
                value: 1,
                label: 'scan_orientation_portrait'.tr,
                icon: Icons.crop_portrait,
              ),
            ],
          ),
          ScanFrameOverlay(
            width: 280,
            height: 176,
            statusText: 'scan_status_reading_card'.tr,
            instructionText: 'scan_instruction_card'.tr,
          ),
        ],
      ),
    ),
  ),
  'scan_overlay_qr': () => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: ScanFrameOverlay(
        width: 240,
        height: 240,
        statusText: 'scan_status_qr_found'.tr,
        instructionText: 'scan_instruction_qr'.tr,
        instructionSubtext: 'scan_instruction_qr_subtext'.tr,
      ),
    ),
  ),
  'extracted_warning': () => Scaffold(
    body: ExtractedDataWarning(
      title: 'scan_status_reading_card'.tr,
      message: 'scan_instruction_qr_subtext'.tr,
    ),
  ),
  'my_cards_ai_tab': () => _Prep(
    () => Get.put(MyCardsController()).selectTab(1),
    const MyCardsView(),
  ),
  'my_cards_empty': () => _Prep(
    () => Get.find<RecentDesignsService>().designs.clear(),
    const MyCardsView(),
  ),
  'profile_card_menu': () => _Prep(
    () =>
        Get.put(ProfileController(), permanent: true).showCardMenu.value = true,
    const ProfileView(),
  ),
  'profile_success': () => _Prep(
    () =>
        Get.put(ProfileController(), permanent: true).showSuccess.value = true,
    const ProfileView(),
  ),
  'profile_empty': () => _Prep(
    () => ProfileStore.to.profile.value = const UserProfileData(),
    const ProfileView(),
  ),
  'template_saved_tab': () => _Prep(
    () => Get.put(TemplateController()).tabIndex.value = 2,
    const Scaffold(body: TemplateView()),
  ),
  'template_search': () => _Prep(
    () => Get.put(TemplateController()).isSearching.value = true,
    const Scaffold(body: TemplateView()),
  ),
  'template_detail': () => _Prep(
    () => Get.put(TemplateController()).selectedTemplate.value =
        const TemplateItem(
          id: 'x',
          name: 'x',
          category: 'travel',
          orientation: TemplateOrientation.horizontal,
          frontImagePath:
              'assets/images/templates/travel/horizontal/travel_01_front.png',
          backImagePath:
              'assets/images/templates/travel/horizontal/travel_01_back.png',
        ),
    const Scaffold(body: TemplateView()),
  ),
  'confirm_delete_contact': () => _Opener((c) => confirmDeleteContact(c)),
  'paywall_1': () => const PaywallView(),
  'paywall_2': () => const PaywallView2(),
  'editor': () => const CardEditorView(),
  'editor_text_tool': () => const _EditorWithTool(CardTool.text, addText: true),
  'editor_qr_tool': () => const _EditorWithTool(CardTool.qr),
  'editor_bg_tool': () => const _EditorWithTool(CardTool.background),
  'editor_image_tool': () => const _EditorWithTool(CardTool.image),
  'editor_symbols_tool': () => const _EditorWithTool(CardTool.symbols),
  'card_detail': () =>
      CardDetailView(design: Get.find<RecentDesignsService>().designs.first),
  'share_sheet': () => _Opener(
    (_) =>
        showShareCardSheet(File('${Directory.systemTemp.path}/l10n_card.png')),
  ),
  'add_link_sheet': () => _Opener((c) => showAddLinkSheet(c)),
  'scan_card': () => const ScanCardView(),
  'scanned_preview': () => const Scaffold(
    body: Padding(
      padding: EdgeInsets.all(16),
      child: ScannedCardPreview(
        data: ScannedContactData(
          firstName: 'Alexandre',
          lastName: 'Montgomery',
          companyName: 'Entreprise Internationale',
          jobTitle: 'Directeur du developpement',
          email: 'alexandre@entreprise-internationale.com',
          phone: '+33 1 23 45 67 89',
          website: 'entreprise-internationale.com',
        ),
      ),
    ),
  ),
  'home_view': () => const HomeView(),
  'home_my_card': () =>
      const Scaffold(body: SingleChildScrollView(child: MyCardSection())),
  'home_templates': () => const Scaffold(
    body: SingleChildScrollView(child: HomeTemplatesSection()),
  ),
  'my_cards': () => const MyCardsView(),
  'contact_detail': () => ContactDetailView(contact: _contact),
  'contact_action_row': () =>
      Scaffold(body: ContactActionRow(contact: _contact)),
  'contact_actions_menu': () => Scaffold(
    body: Center(child: ContactActionsMenu(contact: _contact)),
  ),
  'profile_view': () => const ProfileView(),
  'personal_details': () => const PersonalDetailsView(),
  'business_details': () => const BusinessDetailsView(),
  'template_view': () => const Scaffold(body: TemplateView()),
  'template_edit': () => const TemplateEditView(),
  'dlg_out_of_credits': () => _dialog(
    ['credit_gate_out_of_credits_title', 'credit_gate_out_of_credits_message'],
    ['credit_gate_upgrade', 'credit_gate_not_now'],
  ),
  'dlg_limit': () => _dialog(
    ['credit_gate_limit_reached_title', 'credit_gate_limit_reached_message'],
    ['credit_gate_ok'],
  ),
  'dlg_update_forced': () => _dialog(
    ['force_update_title', 'app_update_dialog_message_forced'],
    ['force_update_button'],
  ),
  'dlg_update_optional': () => _dialog(
    ['app_update_dialog_title_optional', 'app_update_dialog_message_optional'],
    ['force_update_button'],
  ),
  'force_update_view': () => const ForceUpdateView(),
  'rate_app': () => const Scaffold(body: Center(child: RateAppDialog())),
  'no_internet': () => Scaffold(
    body: Center(
      child: NoInternetDialog(onRetry: () async => false, onClose: () {}),
    ),
  ),
  'nav_bar': () => Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: MainBottomNavBar(currentIndex: 0, onTabSelected: (_) {}),
    ),
  ),
  'contacts_empty': () => Scaffold(
    body: ContactsEmptyState(onAddManually: () {}, onScanCard: () {}),
  ),
  'contacts_no_results': () =>
      const Scaffold(body: NoResultsState(query: 'abc')),
  'create_first_card': () => const Scaffold(
    body: SingleChildScrollView(child: CreateFirstCardSection()),
  ),
  'career_studio': () => const CareerStudioView(),
  'career_hub_returning': () => const CareerStudioView(
    initial: CareerHubState(hasDraft: true, score: 54, fixesDone: 2),
  ),
  'career_hub_pro': () => const CareerStudioView(initial: CareerHubState.pro()),
  'career_hub_builder_draft': () {
    ProfileBuilderDraftStore.save({'step': 2});
    return const CareerStudioView();
  },
  'career_fix_queue': () => ProfileFixView(
    controller: ProfileReportController(isPro: true),
    fix: kReportFixes[2],
    queue: kReportFixes,
    index: 2,
  ),
  'career_fixes_ready_free': () => ProfileFixesReadyView(
    controller: ProfileReportController(isPro: false, done: {'headline', 'about'}),
  ),
  'career_fixes_ready_pro': () => ProfileFixesReadyView(
    controller: ProfileReportController(
      isPro: true,
      done: {for (final f in kReportFixes) f.id},
    ),
  ),
  'career_new_score': () {
    CareerScoreStore.newScan();
    for (final f in kReportFixes) {
      CareerScoreStore.markDone(f.id);
    }
    return const ProfileNewScoreView(save: false);
  },
  'career_rescan_loading': () =>
      const ProfileAnalyzingView(rescan: true, duration: Duration(minutes: 5)),
  'career_hub_scored': () {
    CareerScoreStore.newScan();
    CareerScoreStore.markDone('headline');
    CareerScoreStore.saveFixes();
    return const CareerStudioView();
  },
  'career_sheet_pdf': () =>
      _Opener((c) => showPdfHelpSheet(c, onChooseFile: () {})),
  'career_sheet_post_planner': () => _Opener(showPostPlannerSoonSheet),
  'career_sheet_upgrade': () => _Opener((c) => showUpgradeSheet(c)),
  'career_sheet_upgrade_feature': () => _Opener(
    (c) => showUpgradeSheet(c, lockedFeature: 'career_fix_featured_name'.tr),
  ),
  'career_dialog_pro': () => _Opener(
    (c) => showYoureProDialog(c, buttonLabel: 'career_pro_continue_fixes'.tr),
  ),
  'career_sheet_build_used': () => _Opener(
    (c) => showBuildUsedSheet(c, resetDate: 'Nov 1'),
  ),
  'career_sheet_scan_used': () => _Opener(
    (c) => showScanUsedSheet(c, resetDate: 'Nov 1'),
  ),
  'profile_builder': () => const ProfileBuilderView(),
  'profile_optimizer': () => const ProfileOptimizerView(),
  'profile_report': () => const ProfileReportView(),
  'profile_generated': () => ProfileGeneratedView(profileData: const {}),
  'post_planner': () => const PostPlannerView(),
  'settings': () => const SettingsView(),
  'home_toolkit': () => const Scaffold(body: AiToolkitSection()),
  'contacts': () => const ContactsView(),
  'add_contact': () => const AddContactView(),
  'create_profile': () => const CreateProfileView(),
  'ai_generator': () => const AiCardGeneratorView(),
  'qr_screen': () => const CustomQrCodeScreen(),
  'onboarding': () => const OnboardingViewV2(),
  'first_card_ready': () => const FirstCardReadyView(),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('gs').path,
        );
    await GetStorage.init();
    await _loadFonts();
  });

  const langs = ['fr', 'de', 'ru'];
  for (final lang in langs) {
    for (final e in _screens.entries) {
      testWidgets('${e.key} has no overflow in $lang', (t) async {
        Get.reset();
        Get.put(ProfileStore());
        Get.put(ContactsController(), tag: 'contacts');
        Get.put<HomeController>(_FakeHome());
        Get.put<SubscriptionController>(_FakeSub());
        final svc = Get.put(RecentDesignsService());
        final png = File('${Directory.systemTemp.path}/l10n_card.png')
          ..writeAsBytesSync(_png);
        for (var i = 0; i < 3; i++) {
          svc.designs.add(
            RecentDesign(
              id: '$i',
              path: png.path,
              savedAt: DateTime(2025, 1, 1 + i),
              isAiGenerated: i == 2,
              title: 'Carte professionnelle',
              designData: const {},
            ),
          );
        }
        ProfileStore.to.savePersonal(
          fullName: 'Alexandre Montgomery-Thompson',
          email: 'alexandre.montgomery@entreprise-internationale.com',
          dialCode: '+33',
          phoneNumber: '123456789',
        );
        ProfileStore.to.saveBusiness(
          companyName: 'Entreprise Internationale de Developpement',
          designation: 'Directeur du developpement commercial',
          website: 'https://www.entreprise-internationale.com',
          logoBytes: null,
          logoName: '',
        );
        await t.runAsync(() => AppStrings.setLanguage(lang));
        addTearDown(() => AppStrings.language = 'en');
        t.view.physicalSize = const Size(360 * 3, 740 * 3);
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);

        final overflows = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) {
          final m = d.exceptionAsString();
          if (m.contains('overflowed')) {
            final loc = RegExp(r'file:///[^ \n]*lib/[^ \n:]*:\d+')
                .allMatches(d.toString())
                .map((x) => x[0]!.split('lib/').last)
                .toSet()
                .take(2)
                .join(', ');
            overflows.add('${m.split('\n').first} @ $loc');
          } else {
            old?.call(d);
          }
        };

        await t.pumpWidget(
          GetMaterialApp(debugShowCheckedModeBanner: false, home: e.value()),
        );
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(seconds: 1));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 1));
        FlutterError.onError = old;
        expect(overflows, isEmpty, reason: '${e.key}/$lang');
      });
    }
  }
}
