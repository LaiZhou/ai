// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../chat_view_model/chat_view_model_client.dart';
import '../../providers/interface/chat_message.dart';
import '../../styles/llm_chat_view_style.dart';
import '../../styles/llm_message_style.dart';
import '../jumping_dots_progress_indicator/jumping_dots_progress_indicator.dart';
import 'adaptive_copy_text.dart';
import 'hovering_buttons.dart';

/// A widget that displays an LLM (Language Model) message in a chat interface.
@immutable
class LlmMessageView extends StatelessWidget {
  /// Creates an [LlmMessageView].
  ///
  /// The [message] parameter is required and represents the LLM chat message to
  /// be displayed.
  const LlmMessageView(
    this.message, {
    this.isWelcomeMessage = false,
    super.key,
  });

  /// The LLM chat message to be displayed.
  final ChatMessage message;

  /// Whether the message is the welcome message.
  final bool isWelcomeMessage;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Flexible(
            flex: 7,
            child: Column(
              children: [
                ChatViewModelClient(
                  builder: (context, viewModel, child) {
                    final text = message.text;
                    final chatStyle = LlmChatViewStyle.resolve(viewModel.style);
                    final llmStyle = LlmMessageStyle.resolve(
                      chatStyle.llmMessageStyle,
                    );
                    final cardViewBuilder = message.imageUrls != null &&
                            message.imageUrls!.isNotEmpty
                        ? createCardViewBuilder(message)
                        : null;
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            height: 20,
                            width: 20,
                            decoration: llmStyle.iconDecoration,
                            child: Icon(
                              llmStyle.icon,
                              color: llmStyle.iconColor,
                              size: 12,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HoveringButtons(
                              isUserMessage: false,
                              chatStyle: chatStyle,
                              clipboardText: text,
                              child: Container(
                                decoration: llmStyle.decoration,
                                margin: const EdgeInsets.only(left: 28),
                                padding: const EdgeInsets.all(8),
                                child: text == null
                                    ? SizedBox(
                                        width: 24,
                                        child: JumpingDotsProgressIndicator(
                                          fontSize: 24,
                                          color:
                                              chatStyle.progressIndicatorColor!,
                                        ),
                                      )
                                    : AdaptiveCopyText(
                                        clipboardText: text,
                                        chatStyle: chatStyle,
                                        child: isWelcomeMessage ||
                                                viewModel.responseBuilder ==
                                                    null
                                            ? MarkdownBody(
                                                data: text,
                                                selectable: true,
                                                styleSheet:
                                                    llmStyle.markdownStyle,
                                              )
                                            : viewModel.responseBuilder!(
                                                context,
                                                text,
                                              ),
                                      ),
                              ),
                            ),
                            cardViewBuilder ??
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SizedBox(),
                                )
                          ],
                        )
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const Flexible(flex: 1, child: SizedBox()),
        ],
      );

  Future<ChatMessage> withMessage(ChatMessage message) async {
    // await Future.delayed(Duration(seconds: 2)); // 模拟网络请求
    return message;
  }

  FutureBuilder<ChatMessage> createCardViewBuilder(ChatMessage message) {
    return FutureBuilder<ChatMessage>(
        future: withMessage(message),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return Column(children: [
              ...[
                for (final url in snapshot.requireData.imageUrls!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 28),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: WebViewContainer(
                        url: url,
                      ),
                    ),
                  ),
              ]
            ]);
          } else {
            return Text('No data available');
          }
        });
  }
}

class WebViewContainer extends StatelessWidget {
  final String url;

  const WebViewContainer({
    required this.url,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        clipBehavior: Clip.hardEdge,
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(url)),
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            useShouldInterceptRequest: true,
            useOnLoadResource: true,
            disableVerticalScroll: true,
            disableHorizontalScroll: true,
            supportZoom: false,
          ),
          onReceivedError: (controller, request, error) {
            print('Load error: ${error.description}');
          },
          onLoadStop: (controller, url) {},
        ),
      );
}
