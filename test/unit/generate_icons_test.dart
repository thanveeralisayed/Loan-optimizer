import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_optimizer/core/widgets/loan_opt_icon.dart';

void main() {
  test('Generate all app launcher and web icons', () async {
    final targets = <String, double>{
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      'web/icons/Icon-192.png': 192,
      'web/icons/Icon-512.png': 512,
      'web/icons/Icon-maskable-192.png': 192,
      'web/icons/Icon-maskable-512.png': 512,
      'web/favicon.png': 192,
    };

    for (final entry in targets.entries) {
      final size = entry.value;
      final path = entry.key;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

      const painter = LoanOptMonochromePainter();
      painter.paint(canvas, Size(size, size));

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      expect(byteData, isNotNull);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      expect(file.existsSync(), isTrue);

    }
  });
}
