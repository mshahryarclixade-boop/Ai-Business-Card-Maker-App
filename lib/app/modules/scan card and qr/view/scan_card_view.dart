import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NEW (copy to clipboard)
import 'package:get/get.dart';
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

enum _ScanMode { card, qr }

enum _CardOrientation { landscape, portrait }

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
  _CardOrientation _orientation = _CardOrientation.portrait;

  bool _isFlashOn = false;
  bool _isProcessing = false;
  bool _qrHandled = false;
  bool _isSwitching = false;
  String? _cameraError;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_mode != _ScanMode.card) return; // QR mode: mobile_scanner handles itself

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // ---------------------------------------------------------------------
  // Camera / scanner lifecycle
  // ---------------------------------------------------------------------

  Future<void> _initCamera() async {
    if (!mounted) return;
    setState(() => _cameraError = null);
    try {
      final cameras = await availableCameras();
      if (!mounted || _mode != _ScanMode.card) return;
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found on this device.');
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
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Camera access is needed to scan a card.');
      }
    }
  }

  Future<void> _switchMode(_ScanMode mode) async {
    if (_mode == mode || _isSwitching) return;
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

  Future<void> _captureCard() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final photo = await controller.takePicture();
      final savedPath = await _persistImage(photo.path);
      final data = await _scannerService.extractFromImage(savedPath);
      _goToCreateContact(data);
    } catch (e) {
      _showError('Could not read that card. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: _mode == _ScanMode.card ? 90 : null,
    );
    if (picked == null) return;

    setState(() => _isProcessing = true);
    try {
      if (_mode == _ScanMode.card) {
        final savedPath = await _persistImage(picked.path);
        final data = await _scannerService.extractFromImage(savedPath);
        _goToCreateContact(data);
      } else {
        final raw = await _readQrFromImage(picked.path);
        if (raw == null) {
          _showError(
            'No QR code found in that image. Try a clearer picture where the whole QR code is visible.',
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
      _showError('Could not read that image. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Reads a QR code from a still image.
  /// around it: ML Kit
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
      if (!ok) _showError('Could not open this link.');
    } catch (e) {
      debugPrint('Could not open QR link: $e');
      _showError('Could not open this link.');
    }
  }

  // NEW: user tapped "Copy" on the link card.
  Future<void> _copyScannedLink() async {
    final link = _scannedLink;
    if (link == null) return;
    await Clipboard.setData(ClipboardData(text: link));
    _showError('Link copied');
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
    Get.off(
          () => AddContactView(scannedData: data),
      transition: Transition.rightToLeft,
    );
  }

  void _showError(String message) {
    Get.snackbar('Scan', message, snackPosition: SnackPosition.BOTTOM);
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
                options: const [
                  ScanToggleOption(value: _ScanMode.card, label: 'Card', icon: Icons.badge_outlined),
                  ScanToggleOption(value: _ScanMode.qr, label: 'QR Code', icon: Icons.qr_code),
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
              'Scan',
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
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        _buildCameraLayer(),
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.25)),
        ),
        Center(child: _buildOverlayContent()),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
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
              const Expanded(
                child: Text(
                  'Website link',
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
            padding: const EdgeInsets.only(right: 8, bottom: 14),
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
            padding: const EdgeInsets.only(right: 8),
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
                    child: const Text('Copy'),
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
                    child: const Text('Open'),
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
    if (_mode == _ScanMode.qr) {
      final controller = _qrController;
      if (controller == null) {
        // camera is being handed over to the scanner
        return const ColoredBox(color: Colors.black);
      }
      return MobileScanner(controller: controller, onDetect: _onQrDetect);
    }

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
            child: const Text('Try Again', style: TextStyle(color: AppColors.primary)),
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
        statusText: _qrHandled ? 'QR code found' : 'Point at any QR code',
        instructionText: 'Point at any QR code',
        instructionSubtext: 'Works with business card QR codes and any standard QR',
      );
    }

    final isLandscape = _orientation == _CardOrientation.landscape;
    final frameWidth = isLandscape ? 280.0 : 200.0;
    final frameHeight = isLandscape ? 176.0 : 280.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: ScanSegmentedToggle<_CardOrientation>(
            selected: _orientation,
            onChanged: (v) => setState(() => _orientation = v),
            options: const [
              ScanToggleOption(
                value: _CardOrientation.landscape,
                label: 'Landscape',
                icon: Icons.crop_landscape,
              ),
              ScanToggleOption(
                value: _CardOrientation.portrait,
                label: 'Portrait',
                icon: Icons.crop_portrait,
              ),
            ],
          ),
        ),
        ScanFrameOverlay(
          width: frameWidth,
          height: frameHeight,
          isScanning: !_isProcessing,
          statusText: _isProcessing ? 'Reading card...' : 'Auto-detecting card...',
          instructionText: 'Place the business card within the frame',
        ),
      ],
    );
  }
}