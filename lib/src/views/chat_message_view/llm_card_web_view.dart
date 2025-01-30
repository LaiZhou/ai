import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../dialogs/adaptive_dialog.dart';

class LlmCardWebView extends StatelessWidget {
  final String url;

  const LlmCardWebView({
    required this.url,
    super.key,
  });

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    AdaptiveAlertDialog.show<void>(
      context: context,
      barrierDismissible: true,
      content: Padding(
        padding: const EdgeInsets.all(0),
        child: Center(
          child: Image.memory(
            base64Decode(imageUrl.split(',')[1]),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
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
          onLoadStop: (controller, url) {
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
              let lastTap = 0;
              document.addEventListener('touchend', function(e) {
                if (e.target.tagName === 'IMG') {
                  const currentTime = new Date().getTime();
                  const tapLength = currentTime - lastTap;
                  if (tapLength < 300 && tapLength > 0) {
                    window.flutter_inappwebview.callHandler('onImageClicked', e.target.getAttribute('src'));
                    e.preventDefault();
                  }
                  lastTap = currentTime;
                }
              });
            ''');
          },
          onCreateWindow: (controller, createWindowAction) async => false,
          onReceivedError: (controller, request, error) {
            print('Load error: ${error.description}');
          },
        ),
      );
}
