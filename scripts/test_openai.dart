import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final env = Platform.environment;
  String? key = env['OPENAI_API_KEY'];
  if ((key == null || key.isEmpty) && args.isNotEmpty) key = args[0];
  if (key == null || key.isEmpty) {
    stdout.writeln('OpenAI API key not found in OPENAI_API_KEY env var.');
    stdout.write('Enter key (will not be saved): ');
    key = stdin.readLineSync();
    if (key == null || key.isEmpty) {
      stderr.writeln('No key provided. Exiting.');
      exit(2);
    }
  }

  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  final body = jsonEncode({
    'model': 'gpt-3.5-turbo',
    'messages': [
      {'role': 'user', 'content': 'Say hello in one word.'}
    ],
    'max_tokens': 5
  });

  try {
    final resp = await http.post(url, headers: {
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json'
    }, body: body);

    stdout.writeln('Status: ${resp.statusCode}');
    final t = resp.body;
    if (t.length > 800) {
      stdout.writeln('Body excerpt: ${t.substring(0, 800)}...');
    } else {
      stdout.writeln('Body: $t');
    }
  } catch (e) {
    stderr.writeln('Request failed: $e');
    exit(3);
  }
}