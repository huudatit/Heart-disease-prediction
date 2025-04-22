import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Đảm bảo Firebase được khởi tạo trước khi chạy app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

Future<void> predictHeartDisease(Map<String, dynamic> inputData) async {
  final url = Uri.parse("http://192.168.1.103:5000/predict");

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(inputData),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      print("✅ Prediction: ${result['prediction']}");
      print("📊 Probability: ${result['probability']}");
    } else {
      print("❌ Server error: ${response.statusCode}");
      print("Message: ${response.body}");
    }
  } catch (e) {
    print("❌ Exception: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hệ Thống Y Tế',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}
