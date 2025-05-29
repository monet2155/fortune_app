import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('birthdays');

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

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      String name = _nameController.text;
      String? birth = searchBirthday(name);
      if (birth == null) {
        birth = _birthController.text;
        saveBirthday(name, birth);
      }
      setState(() {
        _result = "운세를 불러오는 중...";
      });
      String fortune = await fetchFortune(name, birth);
      setState(() {
        _result = fortune;
      });
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

Future<String> fetchFortune(String name, String birth) async {
  final uri = Uri.parse("https://api.openai.com/v1/chat/completions");
  final headers = {
    "Authorization": "Bearer ${dotenv.env['OPENAI_API_KEY']}",
    "Content-Type": "application/json",
  };
  final prompt = "$name님의 생년월일은 $birth입니다. 오늘의 운세를 알려주세요.";
  final body = jsonEncode({
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "user", "content": prompt},
    ],
    "max_tokens": 100,
    "temperature": 0.7,
  });

  try {
    final response = await http.post(uri, headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data['choices'][0]['message']['content'];
      return reply.trim();
    } else {
      return "API 오류: 상태코드 ${response.statusCode}";
    }
  } catch (e) {
    return "네트워크 오류: $e";
  }
}

void saveBirthday(String name, String birth) {
  final box = Hive.box('birthdays');
  box.put(name, birth);
}

String? searchBirthday(String name) {
  final box = Hive.box('birthdays');
  return box.get(name);
}
