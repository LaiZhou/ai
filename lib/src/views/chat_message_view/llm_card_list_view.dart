import 'package:flutter/material.dart';
import 'llm_card_web_view.dart';
import '../../providers/interface/chat_message.dart';

class LlmCardListView extends StatefulWidget {
  final ChatMessage message;

  const LlmCardListView({
    required this.message,
    super.key,
  });

  @override
  State<LlmCardListView> createState() => _LlmCardListViewState();
}

class _LlmCardListViewState extends State<LlmCardListView> {
  late final Future<ChatMessage> _messageFuture;

  @override
  void initState() {
    super.initState();
    _messageFuture = Future.value(widget.message);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ChatMessage>(
        future: _messageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            return Column(
              children: [
                for (final url in snapshot.requireData.imageUrls!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 28),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: LlmCardWebView(
                        url: url,
                        key: ValueKey(url),
                      ),
                    ),
                  ),
              ],
            );
          } else {
            return Text('No data available');
          }
        },
      );
}
