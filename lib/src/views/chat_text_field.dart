// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart'
    show CupertinoButton, CupertinoIcons, CupertinoTextField;
import 'package:flutter/material.dart'
    show
        InputBorder,
        InputDecoration,
        TextField,
        TextInputAction,
        IconButton,
        Icon,
        Icons,
        Colors,
        BoxConstraints;
import 'package:flutter/widgets.dart';

import '../styles/toolkit_colors.dart';
import '../utility.dart';

/// A text field that adapts to the current app style (Material or Cupertino).
///
/// This widget will render either a [CupertinoTextField] or a [TextField]
/// depending on whether the app is using Cupertino or Material design.
@immutable
class ChatTextField extends StatelessWidget {
  /// Creates an adaptive text field.
  ///
  /// Many of the parameters are required to ensure consistent behavior
  /// across both Cupertino and Material designs.
  const ChatTextField({
    required this.minLines,
    required this.maxLines,
    required this.autofocus,
    required this.style,
    required this.textInputAction,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.hintText,
    required this.hintStyle,
    required this.hintPadding,
    required this.onClear,
    super.key,
  });

  /// The minimum number of lines to show.
  final int minLines;

  /// The maximum number of lines to show.
  final int maxLines;

  /// Whether the text field should be focused initially.
  final bool autofocus;

  /// The style to use for the text being edited.
  final TextStyle style;

  /// The type of action button to use for the keyboard.
  final TextInputAction textInputAction;

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Defines the keyboard focus for this widget.
  final FocusNode focusNode;

  /// The text to show when the text field is empty.
  final String hintText;

  /// The style to use for the hint text.
  final TextStyle hintStyle;

  /// The padding to use for the hint text.
  final EdgeInsetsGeometry? hintPadding;

  /// Called when the user submits editable content.
  final void Function(String text) onSubmitted;

  /// Called when the user clears the text field.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => isCupertinoApp(context)
      ? CupertinoTextField(
          minLines: minLines,
          maxLines: maxLines,
          controller: controller,
          autofocus: autofocus,
          focusNode: focusNode,
          onSubmitted: onSubmitted,
          style: style,
          placeholder: hintText,
          placeholderStyle: hintStyle,
          padding: hintPadding ?? EdgeInsets.zero,
          decoration: BoxDecoration(
            border: Border.all(width: 0, color: ToolkitColors.transparent),
          ),
          textInputAction: textInputAction,
          suffix: controller.text.isNotEmpty
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => controller.clear(),
                  child: const Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: Colors.grey,
                    size: 20,
                  ),
                )
              : null,
        )
      : TextField(
          minLines: minLines,
          maxLines: maxLines,
          controller: controller,
          autofocus: autofocus,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: style,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: hintStyle,
            contentPadding: hintPadding,
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel, size: 20),
                    color: Colors.black54,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClear,
                  )
                : null,
          ),
        );
}
