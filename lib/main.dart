import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

void main() async {
  await dotenv.load(fileName: ".env");

  final uri = Uri.parse("https://api.openai.com/v1/chat/completions");
  final headers = {
    "Authorization": "Bearer ${dotenv.env['OPENAI_API_KEY']}",
    "Content-Type": "application/json",
  };

  final body = jsonEncode({
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "user", "content": "오늘의 운세를 알려줘"},
    ],
    "max_tokens": 100,
    "temperature": 0.7,
  });

  final response = await http.post(uri, headers: headers, body: body);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final reply = data['choices'][0]['message']['content'];
    print("응답: $reply");
  } else {
    print("오류 발생: ${response.statusCode}");
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
