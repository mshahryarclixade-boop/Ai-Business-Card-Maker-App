import '../../../core/services/remote_config_service.dart';
import '../../paywall/services/free_limits.dart';
import '../../paywall/services/usage_service.dart';
import '../../../core/services/permission_gate.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NEW (copy to clipboard)
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../contacts/view/add_contact_view.dart';
import '../../contacts/widgets/round_icon_button.dart';
import '../model/scanned_contact_data.dart';
import '../service/card_scanner_service.dart';
import '../widgets/scan_bottom_controls.dart';
import '../widgets/scan_frame_overlay.dart';
import '../widgets/scan_segmented_toggle.dart';
import '../../../core/translations/tr_extension.dart';

enum _ScanMode { card, qr }

/// [auto] is the default: the card is detected wherever it is held; the
/// frame guide is the usual (landscape) card shape. The manual toggle is
/// hidden unless Remote Config `scan_orientation_toggle` turns it on.
enum _CardOrientation { auto, landscape, portrait }

class ScanCardView extends StatefulWidget {
  const ScanCardView({super.key});

  @override
  State<ScanCardView> createState() => _ScanCardViewState();
}

class _ScanCardViewState extends State<ScanCardView> with WidgetsBindingObserver {
  final _scannerService = CardScannerService();
  final _picker = ImagePicker();

  CameraController? _cameraController;
  Future<void>? _cameraInitFuture;
  MobileScannerController? _qrController;

  _ScanMode _mode = _ScanMode.card;
  _CardOrientation _orientation = _CardOrientation.auto;

  bool _isFlashOn = false;
  bool _isProcessing = false;
  bool _qrHandled = false;
  bool _isSwitching = false;
  String? _cameraError;

  /// "Why we need the camera" is shown before the system prompt.
  bool _showPrimer = false;
  bool _primerAccepted = false;

  /// The camera is refused and only the system Settings can change it.
  bool _permissionDenied = false;
  String? _scannedLink; // NEW: web link found in the QR, shown on screen

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _qrController?.dispose();
    _scannerService.dispose();
    super.dispose();
  }

  /// The gallery picker (or the next screen) is open: the camera is left as
  /// it is. Without this, the picker made the app "inactive", which disposed
  /// the camera while its preview was still on screen, and coming back
  /// restarted it in the middle of reading the picked photo and opening the
  /// next screen.
  bool _externalUiOpen = false;
  bool _leaving = false;
  bool _initializing = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_mode != _ScanMode.card) return; // QR mode: mobile_scanner handles itself
    if (_externalUiOpen || _leaving || _isProcessing || !mounted) return;

    final controller = _cameraController;
    if (controller == null) {
      if (state == AppLifecycleState.resumed && !_initializing) {
        // Back from Settings, or after the app was in the background: start
        // the camera (if it is allowed).
        PermissionGate.isGranted(AppPermission.camera).then((ok) {
          if (ok && mounted && _cameraController == null) _initCamera();
        });
      }
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Take the preview out of the tree first, then release the camera.
      setState(() {
        _cameraController = null;
        _cameraInitFuture = null;
      });
      WidgetsBinding.instance.endOfFrame.then((_) => controller.dispose());
    }
  }

  // ---------------------------------------------------------------------
  // Camera / scanner lifecycle
  // ---------------------------------------------------------------------

  Future<void> _initCamera() async {
    if (!mounted || _initializing || _leaving) return;
    _initializing = true;
    try {
      await _initCameraInner();
    } finally {
      _initializing = false;
    }
  }

  Future<void> _initCameraInner() async {
    setState(() {
      _cameraError = null;
      _permissionDenied = false;
    });
    // First the explanation (why the camera), then the system prompt. Already
    // allowed: straight to the camera.
    if (!await PermissionGate.isGranted(AppPermission.camera)) {
      if (!_primerAccepted) {
        if (mounted) setState(() => _showPrimer = true);
        return;
      }
      // Asks for the camera; if refused for good, Open Settings / Later is
      // shown, and the screen keeps an Open Settings button.
      if (!await PermissionGate.ensure(AppPermission.camera)) {
        if (mounted) {
          setState(() {
            _cameraError = 'scan_camera_permission_needed'.tr;
            _permissionDenied = true;
          });
        }
        return;
      }
    }
    if (mounted && _showPrimer) setState(() => _showPrimer = false);
    if (!mounted) return;
    try {
      final cameras = await availableCameras();
      if (!mounted || _mode != _ScanMode.card) return;
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'scan_no_camera'.tr);
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      setState(() {
        _cameraController = controller;
        _cameraInitFuture = controller.initialize();
      });
      await _cameraInitFuture;
      if (!mounted || _leaving) {
        // Left the screen while the camera was starting.
        if (!identical(_cameraController, controller)) await controller.dispose();
        return;
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'scan_camera_permission_needed'.tr);
      }
    }
  }

  Future<void> _switchMode(_ScanMode mode) async {
    if (_mode == mode || _isSwitching) return;
    if (mode == _ScanMode.qr &&
        !await PermissionGate.isGranted(AppPermission.camera)) {
      // Not allowed yet: the explanation first (the camera area shows it).
      if (mounted && !_primerAccepted) setState(() => _showPrimer = true);
      if (!_primerAccepted || !await PermissionGate.ensure(AppPermission.camera)) {
        return;
      }
    }
    if (!mounted) return;
    _isSwitching = true;

    try {
      if (mode == _ScanMode.qr) {
        // Card -> QR: release the card camera first, then start the scanner.
        final oldCamera = _cameraController;
        setState(() {
          _mode = mode;
          _qrHandled = false;
          _scannedLink = null; // NEW
          _isFlashOn = false;
          _cameraController = null;
          _cameraInitFuture = null;
        });
        // Let the CameraPreview leave the tree before disposing its controller.
        await WidgetsBinding.instance.endOfFrame;
        await oldCamera?.dispose();

        final qr = MobileScannerController(
          autoStart: false,
          detectionSpeed: DetectionSpeed.normal,
          formats: const [BarcodeFormat.qrCode],
        );
        if (!mounted) {
          await qr.dispose();
          return;
        }
        setState(() => _qrController = qr);
        await qr.start();
      } else {
        // QR -> Card: fully release the scanner, then re-open the camera.
        final oldQr = _qrController;
        setState(() {
          _mode = mode;
          _scannedLink = null; // NEW
          _isFlashOn = false;
          _qrController = null;
        });
        await WidgetsBinding.instance.endOfFrame;
        try {
          await oldQr?.stop();
        } catch (_) {}
        await oldQr?.dispose();

        await _initCamera();
      }
    } finally {
      _isSwitching = false;
    }
  }

  Future<void> _toggleFlash() async {
    setState(() => _isFlashOn = !_isFlashOn);
    if (_mode == _ScanMode.card) {
      await _cameraController?.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    } else {
      await _qrController?.toggleTorch();
    }
  }

  // ---------------------------------------------------------------------
  // Capture / pick / decode
  // ---------------------------------------------------------------------

  /// A NEW card scan starts only with a free scan left (CRO plan): out of
  /// scans, the "Scan unlimited cards" paywall opens and nothing is lost -
  /// the earlier scans and contacts stay as they are.
  Future<bool> _allowScan() => FreeLimits.ensure(UsageFeature.scan, screen: 'scan');

  /// The scan produced a result: spend the free scan (once per picture), warn
  /// on the second-last one, then continue with the result. The result is held
  /// here while the (skippable) paywall is up, so it is kept either way.
  Future<void> _finishScan(String savedPath, ScannedContactData data) async {
    final usage = UsageService.to;
    final wasPro = usage.isPro;
    usage.consume(UsageFeature.scan, dedupeKey: savedPath, source: 'scan');
    final warnAt = RemoteConfigService().croLimits.scanWarningRemaining;
    if (!wasPro && warnAt > 0 && usage.remaining(UsageFeature.scan) == warnAt) {
      await FreeLimits.promptScanWarning(screen: 'scan');
    }
    if (!mounted) return;
    _goToCreateContact(data);
  }

  Future<void> _captureCard() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isProcessing) return;
    if (!await _allowScan()) return;

    setState(() => _isProcessing = true);
    try {
      final photo = await controller.takePicture();
      final savedPath = await _persistImage(photo.path);
      final data = await _scannerService.extractFromImage(savedPath);
      await _finishScan(savedPath, data);
    } catch (e) {
      _showError('scan_read_card_failed'.tr);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    _externalUiOpen = true;
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _mode == _ScanMode.card ? 90 : null,
        // A 48 MP photo is no better for reading text and can exhaust memory.
        maxWidth: _mode == _ScanMode.card ? 2400 : null,
        maxHeight: _mode == _ScanMode.card ? 2400 : null,
      );
    } finally {
      _externalUiOpen = false;
    }
    if (picked == null || !mounted) return;
    if (_mode == _ScanMode.card && !await _allowScan()) return;

    setState(() => _isProcessing = true);
    try {
      if (_mode == _ScanMode.card) {
        final savedPath = await _persistImage(picked.path);
        final data = await _scannerService.extractFromImage(savedPath);
        await _finishScan(savedPath, data);
      } else {
        final raw = await _readQrFromImage(picked.path);
        if (raw == null) {
          _showError(
            'scan_qr_not_found_in_image'.tr,
          );
        } else if (!_qrHandled) {
          _qrHandled = true;
          _qrController?.stop();
          await _handleQrPayload(raw);
        }
      }
    } catch (e, stackTrace) {
      // Log the real reason: before, this catch swallowed every error.
      debugPrint('Gallery scan failed: $e\n$stackTrace');
      _showError('scan_read_image_failed'.tr);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Reads a QR code from a still image.
  Future<String?> _readQrFromImage(String path) async {
    final analyzer = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
    );

    String? paddedPath;
    try {
      var raw = _firstRawValue(await analyzer.analyzeImage(path));
      debugPrint('QR gallery scan (original image): ${raw ?? 'nothing found'}');
      if (raw != null) return raw;

      paddedPath = await _makePaddedCopy(path);
      if (paddedPath != null) {
        raw = _firstRawValue(await analyzer.analyzeImage(paddedPath));
        debugPrint('QR gallery scan (padded image): ${raw ?? 'nothing found'}');
      }
      return raw;
    } finally {
      await analyzer.dispose();
      if (paddedPath != null) {
        try {
          await File(paddedPath).delete();
        } catch (_) {}
      }
    }
  }

  String? _firstRawValue(BarcodeCapture? capture) {
    for (final barcode in capture?.barcodes ?? const <Barcode>[]) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Saves a copy of the image on a white background with a border around it.
  Future<String?> _makePaddedCopy(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final source = frame.image;

      final longestSide =
      source.width > source.height ? source.width : source.height;
      final pad = (longestSide * 0.15).round();
      final width = source.width + pad * 2;
      final height = source.height + pad * 2;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.white,
      );
      canvas.drawImage(source, Offset(pad.toDouble(), pad.toDouble()), Paint());

      final padded = await recorder.endRecording().toImage(width, height);
      final data = await padded.toByteData(format: ui.ImageByteFormat.png);

      source.dispose();
      padded.dispose();
      codec.dispose();

      if (data == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/qr_padded_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Could not create padded QR image: $e');
      return null;
    }
  }

  void _onQrDetect(BarcodeCapture capture) {
    if (_qrHandled) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _qrHandled = true;
    _qrController?.stop();
    _handleQrPayload(raw);
  }

  // Returns a web Uri if the QR text is just a web link, else null.
  Uri? _asWebUri(String raw) {
    final text = raw.trim();
    if (text.isEmpty || RegExp(r'\s').hasMatch(text)) return null;

    final lower = text.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final uri = Uri.tryParse(text);
      return (uri != null && uri.host.isNotEmpty) ? uri : null;
    }
    if (lower.startsWith('www.')) {
      return Uri.tryParse('https://$text');
    }
    return null;
  }

  // CHANGED: web link -> show it on screen (no auto open), else contact flow.
  Future<void> _handleQrPayload(String raw) async {
    final uri = _asWebUri(raw);
    if (uri == null) {
      _goToCreateContact(_scannerService.parseQrPayload(raw));
      return;
    }
    if (!mounted) return;
    setState(() => _scannedLink = uri.toString());
  }

  // NEW: user tapped "Open" on the link card.
  Future<void> _openScannedLink() async {
    final link = _scannedLink;
    if (link == null) return;
    try {
      final ok = await launchUrl(
        Uri.parse(link),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) _showError('scan_open_link_failed'.tr);
    } catch (e) {
      debugPrint('Could not open QR link: $e');
      _showError('scan_open_link_failed'.tr);
    }
  }

  // NEW: user tapped "Copy" on the link card.
  Future<void> _copyScannedLink() async {
    final link = _scannedLink;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link));
    _showError('scan_link_copied'.tr);
  }

  // NEW: user closed the link card -> scan again.
  Future<void> _dismissScannedLink() async {
    setState(() {
      _scannedLink = null;
      _qrHandled = false;
    });
    try {
      await _qrController?.start();
    } catch (e) {
      debugPrint('Could not restart QR scanner: $e');
    }
  }

  Future<String> _persistImage(String tempPath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/card_scans');
    if (!await dir.exists()) await dir.create(recursive: true);

    final ext = tempPath.split('.').last;
    final fileName = 'card_${DateTime.now().microsecondsSinceEpoch}.$ext';
    final saved = await File(tempPath).copy('${dir.path}/$fileName');
    return saved.path;
  }

  void _goToCreateContact(ScannedContactData data) {
    if (!mounted) return;
    _leaving = true; // no camera restart while the next screen opens
    Get.off(
          () => AddContactView(scannedData: data),
      transition: Transition.rightToLeft,
    );
  }

  void _showError(String message) {
    Get.snackbar('scan_title'.tr, message, snackPosition: SnackPosition.BOTTOM);
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildPreviewArea()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: ScanSegmentedToggle<_ScanMode>(
                selected: _mode,
                onChanged: _switchMode,
                options: [
                  ScanToggleOption(value: _ScanMode.card, label: 'scan_mode_card'.tr, icon: Icons.badge_outlined),
                  ScanToggleOption(value: _ScanMode.qr, label: 'scan_mode_qr'.tr, icon: Icons.qr_code),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ScanBottomControls(
                // CHANGED: gallery picking is disabled on the QR side.
                onGalleryTap: _mode == _ScanMode.qr ? () {} : _pickFromGallery,
                onCaptureTap: _captureCard,
                onFlashTap: _toggleFlash,
                isFlashOn: _isFlashOn,
                isProcessing: _isProcessing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          RoundIconButton(icon: Icons.arrow_back, onTap: () => Get.back()),
          Expanded(
            child: Text(
              'scan_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    // The explanation / "camera refused" screens stand alone: no frame guide
    // or dimming layer on top of their buttons.
    if (_showPrimer || (_mode == _ScanMode.card && _cameraError != null)) {
      return _buildCameraLayer();
    }
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        _buildCameraLayer(),
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.25)),
        ),
        // Scaled down on short screens instead of overflowing the preview.
        Center(
          child: LayoutBuilder(
            builder: (context, c) => FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(width: c.maxWidth, child: _buildOverlayContent()),
            ),
          ),
        ),
        // "3 of 5 scans used": always shown to free users, in card mode.
        if (_mode == _ScanMode.card)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() {
                UsageService.to.revision.value; // refresh when a scan is spent
                final text = FreeLimits.counter(UsageFeature.scan);
                if (text == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                );
              }),
            ),
          ),
        // NEW: link card shown after a web QR is scanned
        if (_scannedLink != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildLinkCard(_scannedLink!),
          ),
      ],
    );
  }

  // NEW
  Widget _buildLinkCard(String link) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'scan_website_link'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              IconButton(
                onPressed: _dismissScannedLink,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: Colors.black54,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8, bottom: 14),
            child: Text(
              link,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _copyScannedLink,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('scan_copy'.tr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _openScannedLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('scan_open'.tr),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_showPrimer) return _buildCameraPrimer();

    if (_mode == _ScanMode.qr) {
      final controller = _qrController;
      if (controller == null) {
        // camera is being handed over to the scanner
        return const ColoredBox(color: Colors.black);
      }
      return MobileScanner(controller: controller, onDetect: _onQrDetect);
    }

    if (_showPrimer) return _buildCameraPrimer();

    if (_cameraError != null) {
      return _buildCameraFallback(_cameraError!);
    }

    final controller = _cameraController;
    if (controller == null || _cameraInitFuture == null) {
      return const ColoredBox(color: Colors.black);
    }

    return FutureBuilder<void>(
      future: _cameraInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !controller.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Why the camera is needed, before the system's Allow / Don't Allow prompt.
  Widget _buildCameraPrimer() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'scan_primer_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'scan_primer_message'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _primerAccepted = true;
                      _showPrimer = false;
                    });
                    _initCamera();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'scan_primer_continue'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCameraFallback(String message) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.no_photography_outlined, color: Colors.white.withOpacity(0.5), size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _initCamera,
            child: Text('scan_try_again'.tr, style: TextStyle(color: AppColors.primary)),
          ),
          // Refused: only the system Settings can allow it now.
          if (_permissionDenied)
            ElevatedButton(
              onPressed: PermissionGate.openSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text('perm_open_settings'.tr),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlayContent() {
    if (_mode == _ScanMode.qr) {
      return ScanFrameOverlay(
        width: 240,
        height: 240,
        isScanning: !_qrHandled,
        statusText: _qrHandled ? 'scan_status_qr_found'.tr : 'scan_instruction_qr'.tr,
        instructionText: 'scan_instruction_qr'.tr,
        instructionSubtext: 'scan_instruction_qr_subtext'.tr,
      );
    }

    // Auto: the usual (landscape) card guide; Portrait only when chosen.
    final isLandscape = _orientation != _CardOrientation.portrait;
    final showToggle = RemoteConfigService().scanOrientationToggle;
    final frameWidth = isLandscape ? 280.0 : 200.0;
    final frameHeight = isLandscape ? 176.0 : 280.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showToggle)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: ScanSegmentedToggle<_CardOrientation>(
            selected: _orientation,
            onChanged: (v) => setState(() => _orientation = v),
            options: [
              ScanToggleOption(
                value: _CardOrientation.auto,
                label: 'scan_orientation_auto'.tr,
                icon: Icons.auto_awesome,
              ),
              ScanToggleOption(
                value: _CardOrientation.landscape,
                label: 'scan_orientation_landscape'.tr,
                icon: Icons.crop_landscape,
              ),
              ScanToggleOption(
                value: _CardOrientation.portrait,
                label: 'scan_orientation_portrait'.tr,
                icon: Icons.crop_portrait,
              ),
            ],
          ),
        ),
        ScanFrameOverlay(
          width: frameWidth,
          height: frameHeight,
          isScanning: !_isProcessing,
          statusText: _isProcessing ? 'scan_status_reading_card'.tr : 'scan_status_auto_detecting'.tr,
          instructionText: 'scan_instruction_card'.tr,
        ),
      ],
    );
  }
}