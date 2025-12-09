import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:community/config/constants.dart';

class ChatService {
  late final WebSocketChannel _channel;
  final String eventId;
  final String _wsUrl;

    ChatService({required this.eventId})
      : _wsUrl = "${Constants.baseUrl}/ws/chat/$eventId"; // Base WebSocket URL

  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('jwt_token');

    // Append token as a query parameter for authentication
    final uri =
        Uri.parse(_wsUrl).replace(queryParameters: {'token': authToken});
    _channel = WebSocketChannel.connect(uri);

    _channel.stream.listen(
      (message) {
        debugPrint('Received: $message');
      },
      onError: (error) => debugPrint('WebSocket Error: $error'),
      onDone: () => debugPrint('WebSocket Disconnected'),
    );
  }

  Stream<Map<String, dynamic>> get messages => _channel.stream.map((message) {
        return json.decode(message) as Map<String, dynamic>;
      });

  void sendMessage(Map<String, dynamic> message) {
    // Ensure message is JSON encoded before sending
    _channel.sink.add(json.encode(message));
  }

  void dispose() {
    _channel.sink.close();
  }
}
