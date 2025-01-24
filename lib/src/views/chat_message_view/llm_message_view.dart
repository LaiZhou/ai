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
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

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
    await Future.delayed(Duration(seconds: 2)); // 模拟网络请求
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
                        url: url,),
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

class WebViewContainer extends StatefulWidget {
  final String url;

  const WebViewContainer({
    required this.url,
    super.key,
  });

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  String _getMimeType(HttpClientResponse response) {
    final contentType = response.headers.contentType;
    if (contentType != null) {
      return '${contentType.mimeType}${contentType.charset != null ? '; charset=${contentType.charset}' : ''}';
    }
    return 'application/octet-stream';
  }

  Future<String> _getCachePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/card-pages');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return '${cacheDir.path}/${_getMd5(widget.url)}';
  }

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.width * 0.4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        clipBehavior: Clip.hardEdge,
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
            cacheMode: CacheMode.LOAD_CACHE_ELSE_NETWORK,
            disableVerticalScroll: true,
            disableHorizontalScroll: true,
            supportZoom: false,
          ),
          onReceivedError: (controller, request, error) {
            print('Load error: ${error.description}');
          },
          onLoadStop: (controller, url) {},
          shouldInterceptRequest: (controller, request) async {
            // 快速处理 favicon 请求
            if (request.url.toString().endsWith('/favicon.ico')) {
              return WebResourceResponse(
                data: Uint8List(0),
                statusCode: 200,
                reasonPhrase: 'OK',
                headers: {'Content-Type': 'image/x-icon'},
              );
            }

            final cachePath = await _getCachePath();
            final cacheEntry = await CacheEntry.loadFromFile(cachePath);
            if (cacheEntry != null) {
              return WebResourceResponse(
                data: cacheEntry.data,
                statusCode: 200,
                reasonPhrase: 'OK',
                headers: {'Content-Type': cacheEntry.mimeType},
              );
            } else {
              try {
                final response = await HttpClient()
                    .getUrl(Uri.parse(request.url.toString()));
                final httpResponse = await response.close();
                final bytes = await httpResponse.toList();
                final allBytes = bytes.expand((element) => element).toList();
                final newCacheEntry = CacheEntry(
                  mimeType: _getMimeType(httpResponse),
                  data: Uint8List.fromList(allBytes),
                );
                await newCacheEntry.saveToFile(cachePath);
                return WebResourceResponse(
                  data: newCacheEntry.data,
                  statusCode: 200,
                  reasonPhrase: 'OK',
                  headers: {'Content-Type': newCacheEntry.mimeType},
                );
              } catch (e) {
                print('Cache error: $e');
                return null;
              }
            }
          },
        ),
      );
}

class CacheEntry {
  final String mimeType;
  final Uint8List data;

  CacheEntry({required this.mimeType, required this.data});

  // 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'mimeType': mimeType,
        'data': base64Encode(data),
      };

  // 从 JSON 反序列化
  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        mimeType: json['mimeType'] as String,
        data: base64Decode(json['data'] as String),
      );

  // 保存到文件
  Future<void> saveToFile(String path) async {
    final file = File(path);
    await file.writeAsString(jsonEncode(toJson()));
  }

  // 从文件加载
  static Future<CacheEntry?> loadFromFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString());
        return CacheEntry.fromJson(json);
      }
    } catch (e) {
      print('Cache load error: $e');
    }
    return null;
  }
}
