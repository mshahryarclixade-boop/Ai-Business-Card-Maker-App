import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../model/qr_style.dart';

/// Computing a QR code's modules is the expensive part of showing one, and
/// [QrImageView] redoes it on every rebuild. The same code is shown many times
/// (every style tile, the preview, Home, the saved list), so it is computed
/// once per payload and shared.
abstract final class _QrCache {
  static const _max = 24;
  static final _codes = LinkedHashMap<String, QrCode?>();

  static QrCode? of(String data) {
    if (_codes.containsKey(data)) {
      final hit = _codes.remove(data); // keep the most recent last
      _codes[data] = hit;
      return hit;
    }
    final result = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    final code = result.isValid ? result.qrCode : null;
    _codes[data] = code;
    if (_codes.length > _max) _codes.remove(_codes.keys.first);
    return code;
  }
}

/// Drawing a QR code is the slow part: each of its ~8,000 modules is its own
/// draw call (rounded styles draw a rounded rect per module), and the same
/// code is shown in every style, on every screen. So the drawing is recorded
/// once per (payload, style) into a [ui.Picture] and replayed, scaled, by
/// every [StyledQr]. Recordings are made one per frame (see [request]), so
/// opening the style picker never freezes while seven codes are built.
abstract final class _QrPictureCache {
  /// The size the codes are recorded at; they are scaled from here.
  static const canonical = 240.0;
  static const _max = 48;

  static final _pictures = LinkedHashMap<String, ui.Picture>();
  static final _pending = <String, _Job>{};
  static final _order = <String>[];
  static var _scheduled = false;

  static ui.Picture? get(String key) {
    final hit = _pictures.remove(key);
    if (hit != null) _pictures[key] = hit; // most recent last
    return hit;
  }

  /// Records [key]'s picture soon (one per frame) and calls [onReady]. A code
  /// asked for again moves to the front, so what is on screen goes first.
  static void request(
    String key,
    ui.Picture Function() record,
    VoidCallback onReady,
  ) {
    final job = _pending[key];
    if (job != null) {
      job.listeners.add(onReady);
      _order
        ..remove(key)
        ..insert(0, key);
      return;
    }
    _pending[key] = _Job(record)..listeners.add(onReady);
    _order.add(key);
    _schedule();
  }

  static void cancel(String key, VoidCallback onReady) =>
      _pending[key]?.listeners.remove(onReady);

  static void _schedule() {
    if (_scheduled || _order.isEmpty) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_order.isEmpty) return;
      final key = _order.removeAt(0);
      final job = _pending.remove(key);
      if (job != null) {
        final picture = job.record();
        _pictures[key] = picture;
        if (_pictures.length > _max) _pictures.remove(_pictures.keys.first);
        for (final l in job.listeners.toList()) {
          l();
        }
      }
      _schedule();
    });
    SchedulerBinding.instance.scheduleFrame();
  }
}

class _Job {
  _Job(this.record);
  final ui.Picture Function() record;
  final listeners = <VoidCallback>[];
}

ui.Picture _record(QrCode code, QrStyle style) {
  final painter = QrPainter.withQr(
    qr: code,
    gapless: true,
    eyeStyle: QrEyeStyle(
      eyeShape: style.eyeShape,
      color: style.eyeColor ?? style.foreground,
    ),
    dataModuleStyle: QrDataModuleStyle(
      dataModuleShape: style.moduleShape,
      color: style.foreground,
    ),
  );
  return painter.toPicture(_QrPictureCache.canonical);
}

/// A QR code drawn in a [QrStyle], on that style's background.
///
/// Drawn in its own repaint layer from a cached recording (see
/// [_QrPictureCache]), so animations elsewhere on the screen (a pulsing
/// button, a page swipe) don't make it redo thousands of dots.
class StyledQr extends StatefulWidget {
  const StyledQr({
    super.key,
    required this.data,
    required this.style,
    required this.size,
    this.padding = 0,
  });

  final String data;
  final QrStyle style;
  final double size;

  /// Quiet zone inside the background colour.
  final double padding;

  @override
  State<StyledQr> createState() => _StyledQrState();
}

class _StyledQrState extends State<StyledQr> {
  ui.Picture? _picture;
  String? _key;

  String get _wanted => '${widget.style.id}|${widget.data}';

  void _onReady() {
    if (mounted) setState(_resolve);
  }

  void _resolve() {
    final key = _wanted;
    if (key != _key && _key != null) _QrPictureCache.cancel(_key!, _onReady);
    _key = key;
    _picture = _QrPictureCache.get(key);
    if (_picture != null) return;
    final code = _QrCache.of(widget.data);
    if (code == null) return;
    final style = widget.style;
    _QrPictureCache.request(key, () => _record(code, style), _onReady);
  }

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(StyledQr old) {
    super.didUpdateWidget(old);
    if (_wanted != _key) _resolve();
  }

  @override
  void dispose() {
    if (_key != null) _QrPictureCache.cancel(_key!, _onReady);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final picture = _picture;
    return RepaintBoundary(
      child: Container(
        width: widget.size,
        height: widget.size,
        padding: EdgeInsets.all(widget.padding),
        color: widget.style.background,
        child: picture == null
            ? const SizedBox.expand()
            : SizedBox.expand(
                child: CustomPaint(painter: _PicturePainter(picture)),
              ),
      ),
    );
  }
}

class _PicturePainter extends CustomPainter {
  _PicturePainter(this.picture);

  final ui.Picture picture;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / _QrPictureCache.canonical;
    canvas
      ..save()
      ..scale(k)
      ..drawPicture(picture)
      ..restore();
  }

  @override
  bool shouldRepaint(_PicturePainter old) => old.picture != picture;
}
