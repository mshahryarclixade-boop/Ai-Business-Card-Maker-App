import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../modules/custom_create/model/card_element_model.dart';

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
  static const _storageKey = 'recent_designs';

  /// Source of truth for both tabs. My Cards / Ai Cards are filtered views.
  final RxList<RecentDesign> designs = <RecentDesign>[].obs;

  final _box = GetStorage();

  Future<RecentDesignsService> init() async {
    await GetStorage.init();
    _loadFromDisk();
    return this;
  }

  List<RecentDesign> get savedDesigns =>
      designs.where((d) => !d.isAiGenerated).toList();

  List<RecentDesign> get aiDesigns =>
      designs.where((d) => d.isAiGenerated).toList();

  void _loadFromDisk() {
    final raw = _box.read<String>(_storageKey);
    if (raw == null) return;
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    final loaded = list
        .map((e) => RecentDesign.fromJson(e as Map<String, dynamic>))
        .where((d) =>
    d.file.existsSync() &&
        (d.backPath == null || d.backFile!.existsSync()))
        .toList();
    loaded.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    designs.assignAll(loaded);
  }

  Future<void> _persist() async {
    final raw = jsonEncode(designs.map((d) => d.toJson()).toList());
    await _box.write(_storageKey, raw);
  }

  Future<void> save(
      Uint8List thumbnailBytes, {
        Uint8List? backThumbnailBytes,
        required Map<String, dynamic> designData,
        String title = '',
        bool isPremium = false,
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

    designs.insert(
      0,
      RecentDesign(
        id: id,
        path: filePath,
        backPath: backPath,
        savedAt: DateTime.now(),
        isPremium: isPremium,
        title: title,
        designData: designData,
      ),
    );
    await _persist();
  }

  /// Copies a generated card's temp front/back images into permanent
  /// storage and adds it to the list as an AI-generated design.
  ///
  /// If the editable version was built (text-free background + elements),
  /// it is stored as `designData` in the same format CardEditorController
  /// uses, so the card reopens in the editor with every text/icon editable.
  /// A side without editable data falls back to its full image as a flat
  /// background (same as before).
  Future<void> saveAiCard({
    required String frontTempPath,
    required String backTempPath,
    String? frontBackgroundTempPath,
    String? backBackgroundTempPath,
    List<Map<String, dynamic>>? frontElements,
    List<Map<String, dynamic>>? backElements,
    String title = '',
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final frontPath = '${dir.path}/ai_card_front_$id.png';
    final backPath = '${dir.path}/ai_card_back_$id.png';

    await File(frontTempPath).copy(frontPath);
    await File(backTempPath).copy(backPath);

    final hasFront = frontBackgroundTempPath != null && frontElements != null;
    final hasBack = backBackgroundTempPath != null && backElements != null;

    Map<String, dynamic>? designData;

    if (hasFront || hasBack) {
      String frontBackground = frontPath;
      if (hasFront) {
        frontBackground = '${dir.path}/ai_card_front_bg_$id.png';
        await File(frontBackgroundTempPath).copy(frontBackground);
      }

      String backBackground = backPath;
      if (hasBack) {
        backBackground = '${dir.path}/ai_card_back_bg_$id.png';
        await File(backBackgroundTempPath).copy(backBackground);
      }

      Map<String, dynamic> side(
          String background,
          List<Map<String, dynamic>> elements,
          ) =>
          {
            'backgroundColor': 0xFFFFFFFF,
            'backgroundImagePath': background,
            'backgroundTemplate': null,
            'elements': elements,
          };

      designData = {
        'orientation': CardOrientation.landscape.name,
        ...side(frontBackground, hasFront ? frontElements : const []),
        'back': side(backBackground, hasBack ? backElements : const []),
      };
    }

    designs.insert(
      0,
      RecentDesign(
        id: id,
        path: frontPath,
        backPath: backPath,
        savedAt: DateTime.now(),
        title: title,
        isAiGenerated: true,
        designData: designData,
      ),
    );
    await _persist();
  }

  Future<void> delete(String id) async {
    final idx = designs.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    final design = designs[idx];
    if (await design.file.exists()) await design.file.delete();
    if (design.backFile != null && await design.backFile!.exists()) {
      await design.backFile!.delete();
    }
    if (design.isAiGenerated) await _deleteAiBackgrounds(design);
    designs.removeAt(idx);
    await _persist();
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

  Future<void> toggleFavorite(String id) async {
    final idx = designs.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    designs[idx].isFavorite = !designs[idx].isFavorite;
    designs.refresh();
    await _persist();
  }

}