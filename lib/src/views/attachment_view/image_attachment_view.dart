// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../dialogs/adaptive_dialog.dart';
import '../../dialogs/image_preview_dialog.dart';
import '../../providers/interface/attachments.dart';

/// A widget that displays an image attachment.
///
/// This widget aligns the image to the center-right of its parent and
/// allows the user to tap on the image to open a preview dialog.
@immutable
class ImageAttachmentView extends StatelessWidget {
  /// Creates an ImageAttachmentView.
  ///
  /// The [attachment] parameter must not be null and represents the
  /// image file attachment to be displayed.
  const ImageAttachmentView(this.attachment, {super.key});

  /// The image file attachment to be displayed.
  final ImageFileAttachment attachment;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
            onTap: () => unawaited(_showPreviewDialog(context)),
            child: Image.memory(attachment.bytes)),
      );

  Future<void> _showPreviewDialog(BuildContext context) async =>
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  constrained: false,
                  child: Image.memory(
                    attachment.bytes,
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      );
      // AdaptiveAlertDialog.show<void>(
      //   context: context,
      //   barrierDismissible: true,
      //   content: ImagePreviewDialog(attachment),
      // );
}
