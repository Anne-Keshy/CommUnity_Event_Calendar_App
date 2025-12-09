import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../config/constants.dart';  // LLM_URL, API_KEY
import 'package:community/models/event.dart';

class AIService {
  final Box _cacheBox = Hive.box('llm_cache');  // Simple key-value cache

  Future<String> getSuggestions(String userId, List<Event> events) async {
    final key = 'suggestions_$userId';
    if (_cacheBox.containsKey(key)) return _cacheBox.get(key);

    final payload = jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {
          'role': 'user',
          'content': 'Recommend 3 events: ${events.map((e) => e.title).join(', ')}'
        }
      ],
    });
    final response = await http.post(
      Uri.parse(Constants.llmUrl),
      headers: {'Authorization': 'Bearer ${Constants.llmKey}', 'Content-Type': 'application/json'},
      body: payload,
    );
    if (response.statusCode == 200) {
      final msg = jsonDecode(response.body)['choices'][0]['message']['content'];
      _cacheBox.put(key, msg);  // Cache for cost opt
      return msg;
    }
    return 'Great events ahead! 🌟';  // Fallback
  }

  Future<String> getConfirmation(String status, Event event) async {
    return 'Yay! You ${status.toLowerCase()} for ${event.title} ✨';
  }
}