import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../routes/app_routes.dart';
import '../../profile/model/profile_model.dart';
import '../../profile/service/profile_repository.dart';
import '../model/template_item.dart';

class TemplateController extends GetxController {
  // 0 = Horizontal, 1 = Vertical, 2 = Saved
  final RxInt tabIndex = 0.obs;

  // 'All' = no category restriction, otherwise must match TemplateItem.category
  final RxString selectedFilter = 'All'.obs;
  final List<String> filters = const [
    'All',
    'Travel',
    'Spa & Care',
    'Sports & Games',
    'Real Estate',
  ];

  final List<String> popularTags = const [
    'Travel', 'Spa', 'Events', 'Sports',
    'Games', 'Fitness', 'Care', 'Real Estate',
  ];

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final RxBool isSearching = false.obs;

  final RxSet<String> savedIds = <String>{}.obs;

  final GetStorage _box = GetStorage();
  static const String _savedIdsStorageKey = 'saved_template_ids';

  // Tapped template — when set, shows the detail view instead of the grid.
  final Rx<TemplateItem?> selectedTemplate = Rx<TemplateItem?>(null);

  // No-op for now — preview images still have text baked in.
  final RxBool autoFillProfile = false.obs;
  final Rx<ProfileModel?> autoFillProfileData = Rx<ProfileModel?>(null);

  // Filled from the asset manifest (see _loadTemplatesFromAssets).
  final RxList<TemplateItem> allTemplates = <TemplateItem>[].obs;
  final RxBool isLoading = true.obs;

  // Matches e.g.
  // assets/images/templates/travel/horizontal/travel_01_front.png
  static final RegExp _frontRegex = RegExp(
    r'^assets/images/templates/([^/]+)/(horizontal|vertical)/(.+)_front\.(png|jpe?g|webp)$',
  );

  String _slugOf(String category) => category
      .toLowerCase()
      .replaceAll(' & ', '_')
      .replaceAll(' ', '_');

  /// Loads previously-saved (hearted) template ids from disk.
  void _loadSavedIdsFromDisk() {
    final raw = _box.read<String>(_savedIdsStorageKey);
    if (raw == null) return;

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      savedIds.assignAll(list.map((e) => e as String));
    } catch (e) {
      debugPrint('Failed to load saved template ids: $e');
    }
  }

  Future<void> _persistSavedIds() async {
    await _box.write(_savedIdsStorageKey, jsonEncode(savedIds.toList()));
  }

  /// Scans the asset manifest, so only images that actually exist
  /// become cards. No fixed 1..3 range anymore — a category can have
  /// 1 image or 20, and each shows exactly what is on disk.
  Future<void> _loadTemplatesFromAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets().toSet();

      final categories = filters.where((f) => f != 'All').toList();
      final slugToCategory = {for (final c in categories) _slugOf(c): c};

      final entries = <(TemplateItem, int)>[];

      for (final path in assets) {
        final m = _frontRegex.firstMatch(path);
        if (m == null) continue;

        final slug = m.group(1)!;
        final category = slugToCategory[slug];
        if (category == null) continue; // folder not in filters list

        final orientationFolder = m.group(2)!;
        final fileId = m.group(3)!; // e.g. travel_01
        final ext = m.group(4)!;
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
          // if a back image is missing, fall back to the front one
          backImagePath: assets.contains(backPath) ? backPath : path,
          isPremium: number % 3 == 0,
        ),
        number,
        ));
      }

      // stable order: category (as in filters) -> orientation -> number
      entries.sort((a, b) {
        final c = categories
            .indexOf(a.$1.category)
            .compareTo(categories.indexOf(b.$1.category));
        if (c != 0) return c;
        final o = a.$1.orientation.index.compareTo(b.$1.orientation.index);
        if (o != 0) return o;
        return a.$2.compareTo(b.$2);
      });

      allTemplates.assignAll(entries.map((e) => e.$1));
    } catch (e) {
      debugPrint('Failed to load templates: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<TemplateItem> get _baseListForTab {
    if (tabIndex.value == 2) {
      return allTemplates.where((t) => savedIds.contains(t.id)).toList();
    }
    final wantVertical = tabIndex.value == 1;
    return allTemplates
        .where((t) => (t.orientation == TemplateOrientation.vertical) == wantVertical)
        .toList();
  }

  /// Tab + category + search filters applied together on one flat list.
  List<TemplateItem> get currentList {
    var list = _baseListForTab;

    if (selectedFilter.value != 'All') {
      list = list.where((t) => t.category == selectedFilter.value).toList();
    }

    final query = searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) => t.matchesQuery(query)).toList();
    }

    return list;
  }

  bool get isVerticalGrid => tabIndex.value == 1;

  void changeTab(int index) => tabIndex.value = index;

  void selectFilter(String filter) => selectedFilter.value = filter;

  void toggleSaved(String id) {
    if (savedIds.contains(id)) {
      savedIds.remove(id);
    } else {
      savedIds.add(id);
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
  }

  void closeTemplateDetail() {
    selectedTemplate.value = null;
  }

  void toggleAutoFill(bool value) {
    if (value) {
      final profile = ProfileRepository.getSavedProfile();
      if (profile == null) {
        Get.snackbar(
          'No saved profile',
          'Save your profile first to use auto-fill.',
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
    Get.toNamed(Routes.TEMPLATE_EDIT, arguments: item);
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