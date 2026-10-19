import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:get_storage/get_storage.dart';

import '../../custom_create/view/card_editor_view.dart';
import '../../profile/model/profile_model.dart';
import '../../profile/service/profile_repository.dart';
import '../model/template_item.dart';
import '../../../core/translations/tr_extension.dart';

class TemplateController extends GetxController {
  // 0 = Horizontal, 1 = Vertical, 2 = Saved
  final RxInt tabIndex = 0.obs;

  // 'All' = no category restriction
  final RxString selectedFilter = 'All'.obs;

  final List<String> filters = const [
    'All',
    'Travel',
    'Spa & Care',
    'Sports & Games',
    'Real Estate',
  ];

  final List<String> popularTags = const [
    'Travel',
    'Spa',
    'Events',
    'Sports',
    'Games',
    'Fitness',
    'Care',
    'Real Estate',
  ];

  /// Display label for a category / tag. The English value stays the
  /// identity used for filtering and asset lookup.
  static const Map<String, String> _categoryKeys = {
    'All': 'template_category_all',
    'Travel': 'template_category_travel',
    'Spa & Care': 'template_category_spa_care',
    'Sports & Games': 'template_category_sports_games',
    'Real Estate': 'template_category_real_estate',
    'Spa': 'template_category_spa',
    'Events': 'template_category_events',
    'Sports': 'template_category_sports',
    'Games': 'template_category_games',
    'Fitness': 'template_category_fitness',
    'Care': 'template_category_care',
  };

  String categoryLabel(String category) {
    final key = _categoryKeys[category];
    return key == null ? category : key.tr;
  }

  final TextEditingController searchController = TextEditingController();

  final FocusNode searchFocusNode = FocusNode();

  final RxBool isSearching = false.obs;
  final RxSet<String> savedIds = <String>{}.obs;

  final GetStorage _box = GetStorage();

  static const String _savedIdsStorageKey = 'saved_template_ids';

  // Selected template
  final Rx<TemplateItem?> selectedTemplate = Rx<TemplateItem?>(null);

  final RxBool autoFillProfile = false.obs;
  final Rx<ProfileModel?> autoFillProfileData = Rx<ProfileModel?>(null);

  final RxList<TemplateItem> allTemplates = <TemplateItem>[].obs;

  final RxBool isLoading = true.obs;

  static final RegExp _frontRegex = RegExp(
    r'^assets/images/templates/([^/]+)/(horizontal|vertical)/(.+)_front\.(png|jpe?g|webp)$',
  );

  String _slugOf(String category) =>
      category.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_');

  /// Loads previously saved template IDs from disk.
  void _loadSavedIdsFromDisk() {
    final raw = _box.read<String>(_savedIdsStorageKey);

    if (raw == null) return;

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      savedIds.assignAll(list.map((e) => e as String));
    } catch (e, st) {
      debugPrint('Failed to load saved template IDs: $e');

      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'load saved template ids',
      );
    }
  }

  Future<void> _persistSavedIds() async {
    await _box.write(_savedIdsStorageKey, jsonEncode(savedIds.toList()));
  }

  /// Loads available templates from the asset manifest.
  Future<void> _loadTemplatesFromAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

      final assets = manifest.listAssets().toSet();

      final categories = filters
          .where((category) => category != 'All')
          .toList();

      final slugToCategory = {
        for (final category in categories) _slugOf(category): category,
      };

      final entries = <(TemplateItem, int)>[];

      for (final path in assets) {
        final match = _frontRegex.firstMatch(path);

        if (match == null) continue;

        final slug = match.group(1)!;
        final category = slugToCategory[slug];

        if (category == null) continue;

        final orientationFolder = match.group(2)!;
        final fileId = match.group(3)!;
        final ext = match.group(4)!;

        final number = int.tryParse(fileId.split('_').last) ?? 0;

        final backPath =
            'assets/images/templates/$slug/$orientationFolder/${fileId}_back.$ext';

        entries.add((
          TemplateItem(
            id: '${orientationFolder}_$fileId',
            name: '$category Template $number',
            category: category,
            orientation: orientationFolder == 'vertical'
                ? TemplateOrientation.vertical
                : TemplateOrientation.horizontal,
            frontImagePath: path,
            backImagePath: assets.contains(backPath) ? backPath : path,
            isPremium: number % 3 == 0,
          ),
          number,
        ));
      }

      // Sort by category, orientation, and template number.
      entries.sort((a, b) {
        final categoryComparison = categories
            .indexOf(a.$1.category)
            .compareTo(categories.indexOf(b.$1.category));

        if (categoryComparison != 0) {
          return categoryComparison;
        }

        final orientationComparison = a.$1.orientation.index.compareTo(
          b.$1.orientation.index,
        );

        if (orientationComparison != 0) {
          return orientationComparison;
        }

        return a.$2.compareTo(b.$2);
      });

      allTemplates.assignAll(entries.map((entry) => entry.$1));
    } catch (e, st) {
      debugPrint('Failed to load templates: $e');

      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'load templates from assets',
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<TemplateItem> get _baseListForTab {
    if (tabIndex.value == 2) {
      return allTemplates
          .where((template) => savedIds.contains(template.id))
          .toList();
    }

    final wantVertical = tabIndex.value == 1;

    return allTemplates
        .where(
          (template) =>
              (template.orientation == TemplateOrientation.vertical) ==
              wantVertical,
        )
        .toList();
  }

  /// Applies tab, category, and search filters.
  List<TemplateItem> get currentList {
    var list = _baseListForTab;

    if (selectedFilter.value != 'All') {
      list = list
          .where((template) => template.category == selectedFilter.value)
          .toList();
    }

    final query = searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      list = list.where((template) => template.matchesQuery(query)).toList();
    }

    return list;
  }

  bool get isVerticalGrid => tabIndex.value == 1;

  void changeTab(int index) {
    tabIndex.value = index;
  }

  void selectFilter(String filter) {
    selectedFilter.value = filter;
  }

  void toggleSaved(String id) {
    if (savedIds.contains(id)) {
      savedIds.remove(id);
    } else {
      savedIds.add(id);

      FirebaseAnalytics.instance.logEvent(name: 'template_saved');
    }

    _persistSavedIds();
  }

  void onSearchFocusChanged() {
    isSearching.value = searchFocusNode.hasFocus;
  }

  void exitSearch() {
    searchFocusNode.unfocus();
    searchController.clear();
    isSearching.value = false;
  }

  void onTagTap(String tag) {
    searchController.text = tag;
  }

  void openTemplate(TemplateItem item) {
    selectedTemplate.value = item;

    FirebaseAnalytics.instance.logEvent(
      name: 'template_opened',
      parameters: {
        'category': item.category,
        'orientation': item.orientation.name,
      },
    );
  }

  void closeTemplateDetail() {
    selectedTemplate.value = null;
  }

  void toggleAutoFill(bool value) {
    if (value) {
      final profile = ProfileRepository.getSavedProfile();

      if (profile == null) {
        Get.snackbar(
          'template_no_profile_title'.tr,
          'template_no_profile_message'.tr,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
        );

        return;
      }

      autoFillProfileData.value = profile;
    } else {
      autoFillProfileData.value = null;
    }

    autoFillProfile.value = value;
  }

  void onEditTemplateTap() {
    final item = selectedTemplate.value;

    if (item == null) return;

    FirebaseAnalytics.instance.logEvent(
      name: 'template_edit_started',
      parameters: {'category': item.category},
    );

    Get.to(() => CardEditorView(template: item));
  }

  @override
  void onInit() {
    super.onInit();

    searchFocusNode.addListener(onSearchFocusChanged);

    _loadSavedIdsFromDisk();
    _loadTemplatesFromAssets();
  }

  @override
  void onClose() {
    searchFocusNode.removeListener(onSearchFocusChanged);
    searchFocusNode.dispose();
    searchController.dispose();

    super.onClose();
  }
}
