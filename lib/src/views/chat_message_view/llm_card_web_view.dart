import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../dialogs/adaptive_dialog.dart';
import '../../utils/image_util.dart';

class LlmCardWebView extends StatefulWidget {
  final String url;

  const LlmCardWebView({
    required this.url,
    super.key,
  });

  @override
  State<LlmCardWebView> createState() => _LlmCardWebViewState();
}

class _LlmCardWebViewState extends State<LlmCardWebView> {
  Widget? _child;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _child = InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
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
      onLoadStop: (controller, url) {
        // 注入 CSS 让图片占满容器
        controller.evaluateJavascript(source: '''
              document.body.style.margin = '0';
              document.body.style.padding = '0';
              document.body.style.backgroundColor = 'white';
              document.body.style.display = 'flex';
              document.body.style.alignItems = 'center';
              document.body.style.justifyContent = 'center';
              var img = document.querySelector('img');
              if (img) {
                img.style.width = '100%';
                img.style.height = '100%';
                img.style.objectFit = 'contain';
              }
            ''');

        controller.addJavaScriptHandler(
          handlerName: 'onImageClicked',
          callback: (args) {
            if (args.isNotEmpty) {
              controller.evaluateJavascript(source: '''
                    var img = document.querySelector('img[src="${args[0]}"]');
                    var canvas = document.createElement('canvas');
                    canvas.width = img.naturalWidth;
                    canvas.height = img.naturalHeight;
                    var ctx = canvas.getContext('2d');
                    ctx.drawImage(img, 0, 0);
                    window.flutter_inappwebview.callHandler('showImage', canvas.toDataURL());
                  ''');
            }
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'showImage',
          callback: (args) {
            if (args.isNotEmpty) {
              _showFullScreenImage(context, args[0] as String);
            }
          },
        );
        controller.evaluateJavascript(source: '''
              document.addEventListener('touchend', function(e) {
                if (e.target.tagName === 'IMG') {
                  window.flutter_inappwebview.callHandler('onImageClicked', e.target.getAttribute('src'));
                  e.preventDefault();
                }
              });
              // 同时支持鼠标点击
              document.addEventListener('click', function(e) {
                if (e.target.tagName === 'IMG') {
                  window.flutter_inappwebview.callHandler('onImageClicked', e.target.getAttribute('src'));
                  e.preventDefault();
                }
              });
            ''');
      },
      onCreateWindow: (controller, createWindowAction) async => false,
      onReceivedError: (controller, request, error) {
        print('Load error: ${error.description}');
      },
    );
  }

  @override
  void didUpdateWidget(covariant LlmCardWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url) {
      _initWebView();
      setState(() {});
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    ImageUtil.showFullScreenImage(
        context, Image.memory(base64Decode(imageUrl.split(',')[1])).image);
  }

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: _child);
}
