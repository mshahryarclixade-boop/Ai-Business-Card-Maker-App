import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/recent_designs_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../qr_code_generator/view/qr_code_screen.dart';
import '../../template/model/template_live_data.dart';
import '../model/card_element_model.dart';
import 'card_editor_symbols_controller_ext.dart';
import 'package:flutter/services.dart' show rootBundle;

class CardTool {
  static const String none = '';
  static const String text = 'text';
  static const String qr = 'qr';
  static const String background = 'background';
  static const String image = 'image';
  static const String symbols = 'symbols';
}

/// Everything that belongs to ONE side of the card.
class _SideData {
  List<CardElement> elements;
  Color backgroundColor;
  File? backgroundImage;
  String? backgroundTemplate;
  List<List<CardElement>> undo;
  List<List<CardElement>> redo;

  _SideData({
    List<CardElement>? elements,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.backgroundImage,
    this.backgroundTemplate,
    List<List<CardElement>>? undo,
    List<List<CardElement>>? redo,
  })  : elements = elements ?? [],
        undo = undo ?? [],
        redo = redo ?? [];
}

enum ColorPickerTarget { background, text, element }

class CardEditorController extends GetxController {
  CardEditorController({
    CardOrientation initialOrientation = CardOrientation.landscape,
  }) {
    orientation = initialOrientation.obs;
  }

  late final Rx<CardOrientation> orientation;

  final RxList<CardElement> elements = <CardElement>[].obs;
  final Rx<String?> selectedElementId = Rx<String?>(null);
  final Rx<Color> backgroundColor = const Color(0xFFFFFFFF).obs;

  final Rx<File?> backgroundImage = Rx<File?>(null);

  final Rx<String?> backgroundTemplate = Rx<String?>(null);

  final RxString activeTool = CardTool.none.obs;

  /// Which segment of the text-style bar is expanded: '', 'font', 'size', 'color'.
  final RxString expandedStylePanel = ''.obs;
  final RxBool textStyleBarOpen = false.obs;

  final Rx<ColorPickerTarget?> colorPickerTarget =
  Rx<ColorPickerTarget?>(null);

  final RxList<Color> savedBackgroundColors = <Color>[
    const Color(0xFFEC4899),
    const Color(0xFFF97316),
    const Color(0xFFFACC15),
    const Color(0xFF22C55E),
    const Color(0xFF14B8A6),
    const Color(0xFF3B82F6),
    const Color(0xFF6366F1),
    const Color(0xFF8B5CF6),
  ].obs;

  final RxList<Color> savedTextColors = <Color>[].obs;

  final RxBool canUndo = false.obs;
  final RxBool canRedo = false.obs;

  final RxBool isSaving = false.obs; // <-- EXISTING

  final RxBool isCapturing = false.obs;

  final List<List<CardElement>> _undoStack = [];
  final List<List<CardElement>> _redoStack = [];

  // ---- Front / Back sides ------------------------------------------------
  final RxInt currentSide = 0.obs; // 0 = front, 1 = back
  final List<_SideData> _sides = [_SideData(), _SideData()];
  bool _backInitialized = false;
  // QR placeholder position from the template JSON ("qrSlot").
  Rect? _qrSlot;
  int _qrSlotSide = 1;

  List<CardElement>? _preDragSnapshot;

  final ImagePicker _picker = ImagePicker();
  int _idCounter = 0;

  String get _newId =>
      'el_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  List<CardElement> _clone(List<CardElement> src) =>
      src.map((e) => e.copyWith()).toList();

  void _pushUndo() {
    _undoStack.add(_clone(elements));
    _redoStack.clear();
    _syncFlags();
  }

  void _syncFlags() {
    canUndo.value = _undoStack.isNotEmpty;
    canRedo.value = _redoStack.isNotEmpty;
  }

  Future<File> _persistFile(File src) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/editor_assets');
    if (!await dir.exists()) await dir.create(recursive: true);

    final ext = src.path.contains('.') ? src.path.split('.').last : 'png';
    final dest = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
    return src.copy(dest);
  }

  // ---------------------------------------------------------------------
  // Orientation
  // ---------------------------------------------------------------------

  void setOrientation(CardOrientation o) {
    orientation.value = o;
  }

  // ---------------------------------------------------------------------
  // Tool / panel selection
  // ---------------------------------------------------------------------

  void selectTool(String tool) {
    if (activeTool.value == tool) {
      // tapping the same tool again closes its panel
      activeTool.value = CardTool.none;
      expandedStylePanel.value = '';
      textStyleBarOpen.value = false;
      colorPickerTarget.value = null;
      return;
    }

    activeTool.value = tool;
    expandedStylePanel.value = '';
    textStyleBarOpen.value = false;
    colorPickerTarget.value = null;
  }

  void closeToolPanel() {
    activeTool.value = CardTool.none;
    expandedStylePanel.value = '';
    textStyleBarOpen.value = false;
    colorPickerTarget.value = null;
  }

  void toggleStylePanel(String panel) {
    expandedStylePanel.value =
    expandedStylePanel.value == panel ? '' : panel;
  }

  /// Opens the font/size/color style bar for "Edit Text".
  void openTextStyleBar() {
    var el = selectedElement;

    if (el == null || el.type != CardElementType.text) {
      final textElements =
      elements.where((e) => e.type == CardElementType.text).toList();

      if (textElements.isEmpty) {
        Get.snackbar(
          'No text yet',
          'Tap "Add Text" first, then Edit Text to style it.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
        );
        return;
      }

      selectedElementId.value = textElements.last.id;
    }

    expandedStylePanel.value = '';
    textStyleBarOpen.value = true;
  }

  void closeTextStyleBar() {
    textStyleBarOpen.value = false;
    expandedStylePanel.value = '';
    colorPickerTarget.value = null;
  }

  // ---------------------------------------------------------------------
  // Custom color-picker popup
  // ---------------------------------------------------------------------

  void openColorPicker({
    ColorPickerTarget target = ColorPickerTarget.background,
  }) {
    colorPickerTarget.value = target;
  }

  void closeColorPicker() => colorPickerTarget.value = null;

  void addSavedBackgroundColor(Color color) {
    if (!savedBackgroundColors
        .any((c) => c.toARGB32() == color.toARGB32())) {
      savedBackgroundColors.add(color);
    }
  }

  void addSavedTextColor(Color color) {
    if (!savedTextColors.any((c) => c.toARGB32() == color.toARGB32())) {
      savedTextColors.add(color);
    }
  }

  // ---------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------

  void selectElement(String? id) {
    selectedElementId.value = id;
  }

  CardElement? get selectedElement {
    final id = selectedElementId.value;

    if (id == null) return null;

    final idx = elements.indexWhere((e) => e.id == id);

    return idx == -1 ? null : elements[idx];
  }

  // ---------------------------------------------------------------------
  // Add elements
  // ---------------------------------------------------------------------

  void addText() {
    _pushUndo();

    final size = orientation.value.canvasSize;

    final el = CardElement.text(
      id: _newId,
      position: Offset(
        size.width / 2 - 60,
        size.height / 2 - 14,
      ),
    );

    elements.add(el);
    selectedElementId.value = el.id;
    activeTool.value = CardTool.text;
    expandedStylePanel.value = '';
  }

  void addSymbol(String symbol) {
    _pushUndo();

    final size = orientation.value.canvasSize;

    final el = CardElement.symbol(
      id: _newId,
      position: Offset(
        size.width / 2 - 18,
        size.height / 2 - 18,
      ),
      symbol: symbol,
    );

    elements.add(el);
    selectedElementId.value = el.id;
  }

  // ---------------------------------------------------------------------
  // Image picker
  // ---------------------------------------------------------------------

  /// "Upload from Gallery" under the Image tool.
  Future<void> addImageFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    await _cropAndAddImage(picked.path);
  }

  /// "Take a picture" under the Image tool.
  Future<void> addImageFromCamera() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.front,
    );

    if (picked == null) return;

    await _cropAndAddImage(picked.path);
  }

  Future<void> _cropAndAddImage(String sourcePath) async {
    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    if (cropped == null) return;

    final saved = await _persistFile(File(cropped.path));

    _pushUndo();

    final size = orientation.value.canvasSize;

    final el = CardElement.image(
      id: _newId,
      position: Offset(
        size.width / 2 - 45,
        size.height / 2 - 45,
      ),
      file: saved,
    );

    elements.add(el);
    selectedElementId.value = el.id;
    closeToolPanel();
  }

  /// "Upload from Gallery" under the QR tool.
  Future<void> uploadQrFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    final saved = await _persistFile(File(picked.path));

    _pushUndo();

    final size = orientation.value.canvasSize;

    final el = CardElement.image(
      id: _newId,
      position: Offset(
        size.width / 2 - 45,
        size.height / 2 - 45,
      ),
      file: saved,
    );

    elements.add(el);
    selectedElementId.value = el.id;
  }

  /// Adds a bundled asset image (e.g. a template logo) to the current side.
  void addAssetImage(
      String assetPath, {
        double width = 60,
        double height = 60,
        Offset? position,
      }) {
    _pushUndo();

    final size = orientation.value.canvasSize;

    final el = CardElement.assetImage(
      id: _newId,
      position: position ??
          Offset(size.width / 2 - width / 2, size.height / 2 - height / 2),
      asset: assetPath,
      width: width,
      height: height,
    );

    elements.add(el);
    selectedElementId.value = el.id;
  }

  /// Resizes the selected image keeping its aspect ratio.
  void resizeSelectedImageBy(double delta) {
    final el = selectedElement;
    if (el == null || el.type != CardElementType.image) return;

    final ratio = el.height / el.width;
    final newWidth = (el.width + delta).clamp(20.0, 300.0);

    el.width = newWidth;
    el.height = newWidth * ratio;
    elements.refresh();
  }

  Future<void> addGeneratedQrToCanvas(File file) async {
    final saved = await _persistFile(file);
    _addQrImage(saved);
  }

  /// "Generate QR Code" under the QR tool.
  Future<void> generateQrCode() async {
    final File? file = await Get.to<File>(
          () => const CustomQrCodeScreen(forCardInsertion: true),
    );

    if (file == null) return; // user cancelled the form

    final saved = await _persistFile(file);

    _pushUndo();

    final size = orientation.value.canvasSize;

    final el = CardElement.image(
      id: _newId,
      position: Offset(
        size.width / 2 - 45,
        size.height / 2 - 45,
      ),
      file: saved,
    );

    elements.add(el);
    selectedElementId.value = el.id;
    closeToolPanel();
  }

  // ---------------------------------------------------------------------
  // Background: color / image / templates
  // ---------------------------------------------------------------------

  void setBackgroundColor(Color color) {
    _pushUndo();

    backgroundColor.value = color;

    // Color, gallery image and template are mutually exclusive.
    backgroundImage.value = null;
    backgroundTemplate.value = null;
  }

  /// "Upload from Gallery" under the Background tool.
  Future<void> pickBackgroundImageFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    final saved = await _persistFile(File(picked.path));

    _pushUndo();

    backgroundImage.value = saved;

    // Gallery image replaces a selected template.
    backgroundTemplate.value = null;
  }

  /// Applies one of the bundled background template assets.
  /// Only the asset path is stored, so it can never go missing.
  void setBackgroundTemplate(String assetPath) {
    _pushUndo();

    backgroundTemplate.value = assetPath;

    // Template replaces a gallery background.
    backgroundImage.value = null;
  }

  void clearBackgroundImage() {
    _pushUndo();

    backgroundImage.value = null;
    backgroundTemplate.value = null;
  }

  /// Opens the background template flow.
  void openBackgroundTemplates() {
    // Intentionally left available for future controller-side
    // template fetching/analytics.
  }

  // ---------------------------------------------------------------------
  // Edit / move / delete elements
  // ---------------------------------------------------------------------

  void updateSelectedText({
    String? text,
    String? fontFamily,
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    final el = selectedElement;

    if (el == null || el.type != CardElementType.text) return;

    el.text = text ?? el.text;
    el.fontFamily = fontFamily ?? el.fontFamily;
    el.fontSize = fontSize ?? el.fontSize;
    el.color = color ?? el.color;
    el.fontWeight = fontWeight ?? el.fontWeight;

    elements.refresh();
  }

  /// DEV: set an exact font size on the selected text.
  void setSelectedFontSize(double size) {
    final el = selectedElement;
    if (el == null || el.type != CardElementType.text) return;

    el.fontSize = size.clamp(6.0, 120.0);
    elements.refresh();
  }

  /// DEV: nudge the selected text's font size up or down.
  void nudgeSelectedFontSize(double delta) {
    final el = selectedElement;
    if (el == null || el.type != CardElementType.text) return;

    setSelectedFontSize(el.fontSize + delta);
  }

  /// Call once, right when the user opens the style panel for an element.
  void beginStyleEdit() {
    _pushUndo();
  }

  void startDrag(String id) {
    _preDragSnapshot = _clone(elements);
  }

  void updateDragPosition(String id, Offset newPosition) {
    final idx = elements.indexWhere((e) => e.id == id);

    if (idx == -1) return;

    elements[idx].position = newPosition;
    elements.refresh();
  }

  void endDrag() {
    if (_preDragSnapshot != null) {
      _undoStack.add(_preDragSnapshot!);
      _redoStack.clear();
      _preDragSnapshot = null;
      _syncFlags();
    }
  }

  void removeSelectedElement() {
    final id = selectedElementId.value;

    if (id == null) return;

    _pushUndo();

    elements.removeWhere((e) => e.id == id);
    selectedElementId.value = null;
  }

  /// Moves the selected element to the other side (front <-> back),
  /// keeping its position and size.
  void moveSelectedToOtherSide() {
    final el = selectedElement;
    if (el == null) return;

    final fromSide = currentSide.value;
    final toSide = 1 - fromSide;

    // Take it off the current side FIRST, so that if the back is created
    // as a copy of the front below, the element is not duplicated.
    elements.removeWhere((e) => e.id == el.id);
    selectedElementId.value = null;

    if (fromSide == 0) ensureBackInitialized();

    _sides[toSide].elements.add(el);

    // Undo history of both sides would now point at a different layout,
    // so reset it to avoid the element reappearing on both sides.
    _undoStack.clear();
    _redoStack.clear();
    _sides[toSide].undo = [];
    _sides[toSide].redo = [];
    _syncFlags();

    Get.snackbar(
      toSide == 1 ? 'Moved to Back' : 'Moved to Front',
      'Switch sides to see it.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 2),
    );
  }

  // ---------------------------------------------------------------------
  // Undo / redo / save
  // ---------------------------------------------------------------------

  void undo() {
    if (_undoStack.isEmpty) return;

    _redoStack.add(_clone(elements));

    final prev = _undoStack.removeLast();

    elements.assignAll(prev);

    selectedElementId.value = null;

    _syncFlags();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    _undoStack.add(_clone(elements));

    final next = _redoStack.removeLast();

    elements.assignAll(next);

    selectedElementId.value = null;

    _syncFlags();
  }

  // ---------------------------------------------------------------------
  // Reopening a saved design
  // ---------------------------------------------------------------------

  void loadFromDesign(RecentDesign design) {
    debugPrint('EDITOR loadFromDesign: id=${design.id}, '
        'isAi=${design.isAiGenerated}, hasData=${design.designData != null}');

    final data = design.designData;
    if (data == null) {
      debugPrint('EDITOR loadFromDesign: designData NULL -> blank editor');
      return;
    }

    debugPrint('EDITOR designData keys: ${data.keys.toList()}');

    orientation.value =
        CardOrientation.values.byName(data['orientation'] as String);

    _sides[0] = _sideFromJson(data, label: 'front');
    final backJson = data['back'] as Map<String, dynamic>?;
    if (backJson != null) {
      _sides[1] = _sideFromJson(backJson, label: 'back');
      _backInitialized = true;
    } else {
      debugPrint('EDITOR: no back data');
      _sides[1] = _SideData();
      _backInitialized = false;
    }

    currentSide.value = 0;
    _showSide(_sides[0]);

    debugPrint('EDITOR loaded: on-screen elements=${elements.length}, '
        'bgImage=${backgroundImage.value?.path}');
  }

  void loadFromImage(
      File imageFile, {
        CardOrientation orientation = CardOrientation.landscape,
        File? backImageFile,
      }) {
    this.orientation.value = orientation;
    _sides[0] = _SideData(backgroundImage: imageFile);
    _sides[1] = _SideData(backgroundImage: backImageFile);
    _backInitialized = backImageFile != null;
    currentSide.value = 0;
    _showSide(_sides[0]);
  }

  /// For templates: pass TemplateItem.frontImagePath / backImagePath.
  void loadFromTemplateAssets({
    required String frontAsset,
    String? backAsset,
    CardOrientation orientation = CardOrientation.landscape,
  }) {
    this.orientation.value = orientation;
    _sides[0] = _SideData(backgroundTemplate: frontAsset);
    _sides[1] = _SideData(backgroundTemplate: backAsset);
    _backInitialized = backAsset != null;
    currentSide.value = 0;
    _showSide(_sides[0]);
  }

  /// Loads a full template (texts, logo, fonts, positions) from JSON.
  /// The user's info (name, phone, email, ...) is filled into the texts that
  /// have a "field" key; empty fields are left out. Pass [fieldValues] to
  /// override the values (defaults to the saved profile).
  /// Backgrounds are already on screen, so if this fails the user still
  /// sees the plain template instead of a blank editor.
  Future<void> loadFromTemplateJson(
      String jsonAssetPath, {
        Map<String, String>? fieldValues,
      }) async {
    try {
      final raw = await rootBundle.loadString(jsonAssetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final values = fieldValues ?? TemplateData.currentProfileValues();

      orientation.value =
          CardOrientation.values.byName(data['orientation'] as String);

      _sides[0] = _templateSide(data['front'] as Map<String, dynamic>, values);
      _sides[1] = _templateSide(data['back'] as Map<String, dynamic>, values);
      _backInitialized = true;

      final qr = data['qrSlot'] as Map<String, dynamic>?;
      if (qr != null) {
        final s = (qr['size'] as num).toDouble();
        _qrSlot = Rect.fromLTWH(
          (qr['dx'] as num).toDouble(),
          (qr['dy'] as num).toDouble(),
          s,
          s,
        );
        _qrSlotSide = (qr['side'] as num?)?.toInt() ?? 1;
      }

      currentSide.value = 0;
      _showSide(_sides[0]);
    } catch (e, st) {
      debugPrint('TEMPLATE JSON load failed ($jsonAssetPath): $e');
      debugPrint('$st');
    }
  }

  _SideData _templateSide(Map<String, dynamic> d, Map<String, String> values) {
    final els = (d['elements'] as List<dynamic>? ?? const [])
        .map((e) => CardElement.fromJson(e as Map<String, dynamic>))
        .toList();
    return _SideData(
      elements: TemplateData.fillElements(els, values),
      backgroundTemplate: d['background'] as String?,
    );
  }

  /// Adds a QR image. Uses the template's QR slot when we're on that side.
  void _addQrImage(File saved) {
    _pushUndo();

    final canvas = orientation.value.canvasSize;
    final slot =
    (_qrSlot != null && currentSide.value == _qrSlotSide) ? _qrSlot : null;
    final w = slot?.width ?? 90.0;

    final el = CardElement.image(
      id: _newId,
      position:
      slot?.topLeft ?? Offset(canvas.width / 2 - 45, canvas.height / 2 - 45),
      file: saved,
      width: w,
      height: w,
    );

    elements.add(el);
    selectedElementId.value = el.id;
  }

  // ---------------------------------------------------------------------
  // Front / Back sides
  // ---------------------------------------------------------------------

  /// True if either side has anything on it (used by the back-button prompt).
  bool get hasContent =>
      elements.isNotEmpty || _sides[1 - currentSide.value].elements.isNotEmpty;

  /// Copies the on-screen state into the storage slot of the current side.
  void _stashLiveSide() {
    final s = _sides[currentSide.value];
    s.elements = _clone(elements);
    s.backgroundColor = backgroundColor.value;
    s.backgroundImage = backgroundImage.value;
    s.backgroundTemplate = backgroundTemplate.value;
    s.undo = List.of(_undoStack);
    s.redo = List.of(_redoStack);
  }

  /// Puts a stored side on screen.
  void _showSide(_SideData s) {
    elements.assignAll(_clone(s.elements));
    backgroundColor.value = s.backgroundColor;
    backgroundImage.value = s.backgroundImage;
    backgroundTemplate.value = s.backgroundTemplate;
    _undoStack
      ..clear()
      ..addAll(s.undo);
    _redoStack
      ..clear()
      ..addAll(s.redo);
    selectedElementId.value = null;
    closeToolPanel();
    _syncFlags();
  }

  /// Until the user first visits the back, it is a copy of the front.
  /// Only ever called while the front is on screen.
  void ensureBackInitialized() {
    if (_backInitialized) return;
    _sides[1] = _SideData(
      elements: _clone(elements),
      backgroundColor: backgroundColor.value,
      backgroundImage: backgroundImage.value,
      backgroundTemplate: backgroundTemplate.value,
    );
    _backInitialized = true;
  }

  /// 0 = front, 1 = back.
  void switchToSide(int target) {
    if (target == currentSide.value || target < 0 || target > 1) return;
    ensureBackInitialized();
    _stashLiveSide();
    currentSide.value = target;
    _showSide(_sides[target]);
  }

  Map<String, dynamic> _sideToJson(_SideData s) => {
    'backgroundColor': s.backgroundColor.toARGB32(),
    'backgroundImagePath': s.backgroundImage?.path,
    'backgroundTemplate': s.backgroundTemplate,
    'elements': s.elements.map((e) => e.toJson()).toList(),
  };

  _SideData _sideFromJson(Map<String, dynamic> d, {String label = ''}) {
    final path = d['backgroundImagePath'] as String?;
    final file = path != null ? File(path) : null;

    debugPrint('EDITOR side[$label]: bgPath=$path, '
        'bgExists=${file?.existsSync()}, '
        'rawElements=${(d['elements'] as List?)?.length}');

    final parsed = <CardElement>[];
    final raw = (d['elements'] as List<dynamic>? ?? const []);
    for (var i = 0; i < raw.length; i++) {
      try {
        parsed.add(CardElement.fromJson(raw[i] as Map<String, dynamic>));
      } catch (e, st) {
        debugPrint('EDITOR side[$label]: element $i FAILED to parse: $e');
        debugPrint('EDITOR element json: ${raw[i]}');
        debugPrint('$st');
      }
    }

    debugPrint('EDITOR side[$label]: parsed elements=${parsed.length}');

    return _SideData(
      elements: parsed,
      backgroundColor: Color(d['backgroundColor'] as int),
      backgroundImage: (file != null && file.existsSync()) ? file : null,
      backgroundTemplate: d['backgroundTemplate'] as String?,
    );
  }

  /// Front keeps the OLD top-level keys, so old designs (and anything else
  /// reading designData) keep working. The back lives under 'back'.
  Map<String, dynamic> buildDesignData() {
    ensureBackInitialized();
    _stashLiveSide();
    return {
      'orientation': orientation.value.name,
      ..._sideToJson(_sides[0]),
      'back': _sideToJson(_sides[1]),
    };
  }

  /// DEV ONLY: builds the template JSON (both sides) from what is on screen.
  String buildTemplateJson(String templateId) {
    ensureBackInitialized();
    _stashLiveSide();

    Map<String, dynamic> side(_SideData s) => {
      'background': s.backgroundTemplate,
      'elements': s.elements.map((e) {
        final m = e.toJson();
        m.removeWhere((k, v) => v == null); // keep the JSON short
        return m;
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert({
      'id': templateId,
      'orientation': orientation.value.name,
      'front': side(_sides[0]),
      'back': side(_sides[1]),
    });
  }

  Future<void> save(GlobalKey repaintKey) async {
    if (isSaving.value) return; // guard against double-tap
    isSaving.value = true;

    try {
      await saveToRecentDesigns(repaintKey);

      Get.snackbar(
        'Saved',
        'Your card has been saved.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );

      Get.back(
        result: {
          'orientation': orientation.value,
          'backgroundColor': backgroundColor.value,
          'backgroundImage': backgroundImage.value,
          'backgroundTemplate': backgroundTemplate.value,
          'elements': elements.toList(),
        },
      );
    } finally {
      isSaving.value = false;
    }
  }
}