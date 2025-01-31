import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtil {
  static const platform = MethodChannel('image_util');

  static void _showMessage(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  static Future<bool> _saveAndroidImage(
      Uint8List bytes, String filename) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return false;

      final imagePath = '${directory.path}/$filename';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(bytes);

      final result = await platform.invokeMethod('saveImageToGallery', {
        'path': imagePath,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _saveIosImage(Uint8List bytes) async {
    try {
      final result = await platform.invokeMethod('saveImageToGallery', {
        'data': bytes,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  static void showFullScreenImage(BuildContext context, ImageProvider image) {
    final fullScreenImage = Image(
      image: image,
      fit: BoxFit.contain,
    );

    Future<void> _saveImage() async {
      try {
        final ImageStream stream = image.resolve(ImageConfiguration.empty);
        final Completer<Uint8List> completer = Completer<Uint8List>();

        stream.addListener(ImageStreamListener((info, _) async {
          final ByteData? byteData =
              await info.image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final Uint8List bytes = byteData.buffer.asUint8List();
            completer.complete(bytes);
          }
        }));

        final Uint8List bytes = await completer.future;
        final String filename =
            'image_${DateTime.now().millisecondsSinceEpoch}.png';
        bool success = false;

        if (defaultTargetPlatform == TargetPlatform.android) {
          success = await _saveAndroidImage(bytes, filename);
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          success = await _saveIosImage(bytes);
        }

        if (success) {
          _showMessage(context, 'Image saved to gallery');
        } else {
          throw Exception('Failed to save image');
        }
      } catch (e) {
        _showMessage(context, 'Failed to save image');
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                        maxHeight: constraints.maxHeight * 0.8,
                      ),
                      child: fullScreenImage,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      _saveImage();
                      return;
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.download, color: Colors.white),
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
}
