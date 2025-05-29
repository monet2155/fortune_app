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

  runApp(MaterialApp(home: FortuneApp()));
}

class FortuneApp extends StatefulWidget {
  @override
  _FortuneAppState createState() => _FortuneAppState();
}

class _FortuneAppState extends State<FortuneApp> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();
  String _result = "";

  void _submit() {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      String birth = _birthController.text;
      setState(() {
        _result = "이름: $name\n생년월일: $birth\n운세를 불러오는 중...";
      });
      // TODO: OpenAI API 호출 함수 연결
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('나의 사주를 알려줘')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '이름'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? '이름을 입력하세요' : null,
              ),
              TextFormField(
                controller: _birthController,
                decoration: InputDecoration(labelText: '생년월일 (YYYY-MM-DD)'),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? '생년월일을 입력하세요' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: Text('운세 보기')),
              SizedBox(height: 20),
              Text(_result, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
