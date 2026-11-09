import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ai_business_card_maker/app/modules/paywall/controller/subscription_controller.dart';
import 'package:ai_business_card_maker/app/modules/paywall/services/watermark_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class _Sub extends SubscriptionController {
  @override
  void onInit() {}
}

Future<Uint8List> _png(int w, int h) async {
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF3366CC),
  );
  final img = await rec.endRecording().toImage(w, h);
  return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer
      .asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Sub sub;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.createTempSync('gs').path,
        );
    await GetStorage.init();
  });

  setUp(() async {
    Get.reset();
    await GetStorage().erase();
    sub = _Sub();
    Get.put<SubscriptionController>(sub);
  });

  testWidgets('free exports are stamped, Pro exports are untouched', (t) async {
    await t.runAsync(() async {
      final src = await _png(600, 380);

      final free = await WatermarkService.prepareBytes(src);
      expect(free, isNot(src)); // the watermark changed pixels
      final img = await (await ui.instantiateImageCodec(free)).getNextFrame();
      expect([img.image.width, img.image.height], [600, 380]); // same size

      sub.isUserPro.value = true;
      expect(await WatermarkService.prepareBytes(src), src);
    });
  });

  testWidgets('file exports: stamped copy for free, same path for Pro', (
    t,
  ) async {
    await t.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('wm');
      final f = File('${dir.path}/a.png')..writeAsBytesSync(await _png(300, 200));

      final out = await WatermarkService.prepare([f.path]);
      expect(out.single, isNot(f.path));
      expect(File(out.single).existsSync(), isTrue);
      expect(f.readAsBytesSync(), isNotEmpty); // the original is not modified

      sub.isUserPro.value = true;
      expect(await WatermarkService.prepare([f.path]), [f.path]);
    });
  });
}
