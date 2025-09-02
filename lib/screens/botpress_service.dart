import 'dart:convert';
import 'package:http/http.dart' as http;

class BotpressService {
  static const String botpressUrl = 'https://api.botpress.cloud/api/v1/bots/e2cd86ce-c6ed-4d04-9d2f-5abdfa26d0ef/converse';

  Future<String> sendMessage(String userMessage) async {
    final response = await http.post(
      Uri.parse(botpressUrl),
      headers: {'Content-Type': 'application/json',
        'Authorization':'bp_pat_zZibOTJ53YizD4FvoTD9j0Jzq8ST22ZwK0EY'},
      body: jsonEncode({'text': userMessage, 'userId': 'flutter_user'}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['responses'][0]['text'];
    } else {
      // Print error details for debugging
      print('Botpress API error: \\nStatus: \\${response.statusCode}\\nBody: \\${response.body}');
      throw Exception('Failed to communicate with Botpress. Status: \\${response.statusCode}');
    }
  }
}