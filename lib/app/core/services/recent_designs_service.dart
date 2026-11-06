import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../modules/custom_create/model/card_element_model.dart';
import '../../modules/profile_setup/model/user_profile_data.dart';
import '../../modules/profile_setup/service/profile_logo_file.dart';
import '../../modules/profile_setup/service/profile_store.dart';
import '../../modules/template/model/template_live_data.dart';
import '../../modules/template/widget/template_live_preview.dart';
import '../utils/app_fonts.dart';
import '../utils/widget_image_renderer.dart';
import 'card_profile_sync.dart';
import 'profile_scope.dart';

class RecentDesign {
  final String id;
  final String path; // front/thumbnail PNG path on disk
  final String? backPath; // back-side PNG
  final DateTime savedAt;
  bool isFavorite;
  final bool isPremium;
  final String title;
  final bool isAiGenerated;

  /// Full editable design state, so the card can be reopened in
  /// CardEditorController
  final Map<String, dynamic>? designData;

  RecentDesign({
    required this.id,
    required this.path,
    this.backPath,
    required this.savedAt,
    this.isFavorite = false,
    this.isPremium = false,
    this.title = '',
    this.isAiGenerated = false,
    this.designData,
  });

  File get file => File(path);
  File? get backFile => backPath != null ? File(backPath!) : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'backPath': backPath,
    'savedAt': savedAt.toIso8601String(),
    'isFavorite': isFavorite,
    'isPremium': isPremium,
    'title': title,
    'isAiGenerated': isAiGenerated,
    'designData': designData,
  };

  factory RecentDesign.fromJson(Map<String, dynamic> json) => RecentDesign(
    id: json['id'] as String,
    path: json['path'] as String,
    backPath: json['backPath'] as String?,
    savedAt: DateTime.parse(json['savedAt'] as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
    isPremium: json['isPremium'] as bool? ?? false,
    title: json['title'] as String? ?? '',
    isAiGenerated: json['isAiGenerated'] as bool? ?? false,
    designData: json['designData'] as Map<String, dynamic>?,
  );
}

class RecentDesignsService extends GetxService {
  static const _baseKey = 'recent_designs';

  /// The active profile's designs.
  static String get _storageKey => ProfileScope.key(_baseKey);

  /// Source of truth for both tabs. My Cards / Ai Cards are filtered views.
  final RxList<RecentDesign> designs = <RecentDesign>[].obs;

  final _box = GetStorage();

  Future<RecentDesignsService> init() async {
    await GetStorage.init();
    _loadFromDisk();
    _watchProfile();
    return this;
  }

  @override
  void onClose() {
    _profileWorker?.dispose();
    _syncTimer?.cancel();
    super.onClose();
  }

  List<RecentDesign> get savedDesigns =>
      designs.where((d) => !d.isAiGenerated).toList();

  List<RecentDesign> get aiDesigns =>
      designs.where((d) => d.isAiGenerated).toList();

  /// Shows the active profile's designs (after the user switches profile).
  void reload() => _loadFromDisk();

  void _loadFromDisk() {
    final raw = _box.read<String>(_storageKey);
    if (raw == null) {
      designs.clear();
      return;
    }
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    final loaded = list
        .map((e) => RecentDesign.fromJson(e as Map<String, dynamic>))
        .where(
          (d) =>
              d.file.existsSync() &&
              (d.backPath == null || d.backFile!.existsSync()),
        )
        .toList();
    loaded.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    designs.assignAll(loaded);
  }

  Future<void> _persist() async {
    final raw = jsonEncode(designs.map((d) => d.toJson()).toList());
    await _box.write(_storageKey, raw);
  }

  Future<RecentDesign> save(
    Uint8List thumbnailBytes, {
    Uint8List? backThumbnailBytes,
    required Map<String, dynamic> designData,
    String title = '',
    bool isPremium = false,
    bool isAiGenerated = false,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final filePath = '${dir.path}/recent_design_$id.png';
    await File(filePath).writeAsBytes(thumbnailBytes, flush: true);

    String? backPath;
    if (backThumbnailBytes != null) {
      backPath = '${dir.path}/recent_design_${id}_back.png';
      await File(backPath).writeAsBytes(backThumbnailBytes, flush: true);
    }

    final design = RecentDesign(
      id: id,
      path: filePath,
      backPath: backPath,
      savedAt: DateTime.now(),
      isPremium: isPremium,
      title: title,
      isAiGenerated: isAiGenerated,
      designData: designData,
    );
    designs.insert(0, design);
    await _persist();
    return design;
  }

  RecentDesign? byId(String id) => designs.firstWhereOrNull((d) => d.id == id);

  /// Replaces what an existing card shows and stores (its pictures and its
  /// editable data) in place: same id, same place in the list, same title and
  /// favourite mark. The pictures go to NEW files (and the old ones are
  /// removed), so no screen can keep showing a cached old picture.
  Future<RecentDesign?> update(
    String id, {
    required Uint8List front,
    Uint8List? back,
    required Map<String, dynamic> designData,
  }) async {
    final idx = designs.indexWhere((d) => d.id == id);
    if (idx == -1) return null;
    final old = designs[idx];
    final updated = await _replaceFiles(old, front, back, designData);
    // The card may have moved or gone while the files were written.
    final now = designs.indexWhere((d) => d.id == id);
    if (now == -1) {
      await _deleteFiles(updated);
      return null;
    }
    designs[now] = updated;
    await _persist();
    // Only now that the list shows the new pictures, the old ones may go.
    await _deleteFiles(old, except: updated);
    return updated;
  }

  Future<RecentDesign> _replaceFiles(
    RecentDesign old,
    Uint8List front,
    Uint8List? back,
    Map<String, dynamic> designData,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final frontPath = '${dir.path}/recent_design_${old.id}_$stamp.png';
    await File(frontPath).writeAsBytes(front, flush: true);
    String? backPath;
    if (back != null) {
      backPath = '${dir.path}/recent_design_${old.id}_${stamp}_back.png';
      await File(backPath).writeAsBytes(back, flush: true);
    }
    final updated = RecentDesign(
      id: old.id,
      path: frontPath,
      backPath: backPath ?? old.backPath,
      savedAt: old.savedAt,
      isFavorite: old.isFavorite,
      isPremium: old.isPremium,
      title: old.title,
      isAiGenerated: old.isAiGenerated,
      designData: designData,
    );
    return updated; // the caller removes the old pictures once nothing shows them
  }

  /// Removes the pictures of [d] (not the ones [except] still uses).
  Future<void> _deleteFiles(RecentDesign d, {RecentDesign? except}) async {
    for (final p in [d.path, d.backPath]) {
      if (p == null || p == except?.path || p == except?.backPath) continue;
      final f = File(p);
      if (await f.exists()) await f.delete();
    }
  }

  Future<void> delete(String id) async {
    final idx = designs.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    final design = designs[idx];
    // First out of the list (every screen that shows it lets go), then the
    // files: nothing is left pointing at a picture that is gone.
    designs.removeAt(idx);
    await _persist();
    await _deleteFiles(design);
    if (design.isAiGenerated) await _deleteAiBackgrounds(design);
  }

  /// AI cards own their background images (they are not shared with any
  /// other design), so they are removed together with the card.
  Future<void> _deleteAiBackgrounds(RecentDesign design) async {
    final data = design.designData;
    if (data == null) return;

    final paths = <String?>[
      data['backgroundImagePath'] as String?,
      (data['back'] as Map<String, dynamic>?)?['backgroundImagePath']
          as String?,
    ];

    for (final p in paths) {
      if (p == null) continue;
      final f = File(p);
      if (await f.exists()) await f.delete();
    }
  }

  // ---------------------------------------------------------------------
  // Profile -> saved cards
  // ---------------------------------------------------------------------

  Worker? _profileWorker;
  Timer? _syncTimer;
  UserProfileData? _lastProfile;
  UserProfileData? _syncFrom;
  String _lastScope = ProfileScope.id;
  bool _syncing = false;

  /// Follows the active profile: when its details change, the cards saved
  /// with the old details are brought up to date (both sides).
  void _watchProfile() {
    try {
      final profile = ProfileStore.to.profile;
      _lastProfile = profile.value;
      _lastScope = ProfileScope.id;
      _profileWorker = ever<UserProfileData>(profile, _onProfileChanged);
    } catch (_) {
      // No profile store (e.g. a bare test): nothing to follow.
    }
  }

  void _onProfileChanged(UserProfileData now) {
    // Switching profile reloads the details too: that is not an edit.
    if (ProfileScope.id != _lastScope) {
      _lastScope = ProfileScope.id;
      _lastProfile = now;
      _syncFrom = null;
      return;
    }
    final prev = _lastProfile;
    _lastProfile = now;
    if (prev == null) return;
    // A burst of changes (personal then business details) is one update.
    _syncFrom ??= prev;
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 600), _runSync);
  }

  Future<void> _runSync() async {
    if (_syncing) {
      _syncTimer = Timer(const Duration(milliseconds: 600), _runSync);
      return;
    }
    final from = _syncFrom;
    final to = _lastProfile;
    _syncFrom = null;
    if (from == null || to == null) return;
    _syncing = true;
    try {
      await syncCards(from, to);
    } catch (_) {
      // A failed refresh leaves the cards as they were.
    } finally {
      _syncing = false;
    }
  }

  /// Applies the change [old] -> [neu] of the active profile to its cards.
  Future<void> syncCards(UserProfileData old, UserProfileData neu) async {
    final logo = await _logoOf(neu);
    var any = false;
    for (final d in List<RecentDesign>.of(designs)) {
      final updated = await resyncDesign(d, old, neu, logo);
      if (updated == null) continue;
      final i = designs.indexWhere((e) => e.id == d.id);
      if (i == -1) {
        await _deleteFiles(updated);
        continue;
      }
      designs[i] = updated;
      any = true;
      await _deleteFiles(d, except: updated);
    }
    if (any) await _persist();
  }

  /// The same for a profile that is not the active one (its cards are only in
  /// storage).
  Future<void> syncStoredProfile(
    String profileId,
    UserProfileData old,
    UserProfileData neu,
  ) async {
    final key = ProfileScope.key(_baseKey, profileId);
    final raw = _box.read<String>(key);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => RecentDesign.fromJson(e as Map<String, dynamic>))
        .toList();
    final logo = await _logoOf(neu);
    var any = false;
    final replaced = <RecentDesign>[];
    for (var i = 0; i < list.length; i++) {
      final updated = await resyncDesign(list[i], old, neu, logo);
      if (updated == null) continue;
      replaced.add(list[i]);
      list[i] = updated;
      any = true;
    }
    if (any) {
      await _box.write(key, jsonEncode(list.map((d) => d.toJson()).toList()));
      for (final d in replaced) {
        await _deleteFiles(d);
      }
    }
  }

  Future<ProfileLogoFile?> _logoOf(UserProfileData p) async =>
      p.hasLogo ? ProfileLogoFile.fromBytes(p.logoBytes!) : null;

  /// [d] brought up to date with a profile change (new pictures, new data),
  /// or null when nothing in it follows the profile.
  Future<RecentDesign?> resyncDesign(
    RecentDesign d,
    UserProfileData old,
    UserProfileData neu,
    ProfileLogoFile? logo,
  ) async {
    final data = d.designData;
    if (data == null) return null;
    var next = CardProfileSync.apply(
      data,
      old,
      neu,
      newLogoPath: logo?.file.path,
      newLogoAspect: logo?.aspect ?? 1,
    );
    if (next == null) return null;
    next = await _fitTexts(next);
    final pictures = await renderDesign(next);
    return _replaceFiles(d, pictures.$1, pictures.$2, next);
  }

  /// A longer name must still fit on its line (same rule as filling a
  /// template): only the texts that would run past the edge shrink.
  Future<Map<String, dynamic>> _fitTexts(Map<String, dynamic> data) async {
    final orientation = _orientationOf(data);
    final width = orientation.canvasSize.width;
    final sides = <Map<String, dynamic>>[
      data,
      if (data['back'] is Map<String, dynamic>)
        data['back'] as Map<String, dynamic>,
    ];
    await _loadFonts([for (final s in sides) ...CardProfileSync.elementsOf(s)]);
    for (final side in sides) {
      final els = CardProfileSync.elementsOf(side);
      final fitted = TemplateData.fitTexts(els, canvasWidth: width);
      final json = (side['elements'] as List).cast<Map<String, dynamic>>();
      for (var i = 0; i < els.length && i < json.length; i++) {
        if (fitted[i].fontSize != els[i].fontSize) {
          json[i]['fontSize'] = fitted[i].fontSize;
        }
      }
    }
    return data;
  }

  CardOrientation _orientationOf(Map<String, dynamic> data) =>
      CardOrientation.values.byName(
        data['orientation'] as String? ?? 'landscape',
      );

  Future<void> _loadFonts(List<CardElement> els) async {
    for (final e in els) {
      if (e.type == CardElementType.text) {
        AppFonts.textStyle(e.fontFamily, fontWeight: e.fontWeight);
      }
    }
    try {
      await GoogleFonts.pendingFonts();
    } catch (_) {}
  }

  /// The pictures (front, back) of a card from its saved data.
  Future<(Uint8List, Uint8List?)> renderDesign(Map<String, dynamic> data) async {
    final orientation = _orientationOf(data);
    final front = TemplateSideData.fromDesign(data);
    final backJson = data['back'] as Map<String, dynamic>?;
    final back = backJson == null ? null : TemplateSideData.fromDesign(backJson);
    await _loadFonts([...front.elements, ...?back?.elements]);

    Future<Uint8List> thumb(TemplateSideData side) =>
        WidgetImageRenderer.render(
          TemplateCardCanvas(side: side, orientation: orientation),
          size: orientation.canvasSize,
          images: <ImageProvider>[
            if (side.hasBackgroundImage)
              side.isFileBackground
                  ? FileImage(File(side.background))
                  : AssetImage(side.background),
            for (final e in side.elements)
              if (e.imageFile != null) FileImage(e.imageFile!),
          ],
        );

    final f = await thumb(front);
    final b = back == null ? null : await thumb(back);
    return (f, b);
  }

  Future<void> toggleFavorite(String id) async {
    final idx = designs.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    designs[idx].isFavorite = !designs[idx].isFavorite;
    designs.refresh();
    await _persist();
  }
}
