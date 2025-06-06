import 'package:dacn_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Đảm bảo Firebase được khởi tạo trước khi chạy app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

Future<Map<String, dynamic>?> predictHeartDisease(
  Map<String, dynamic> inputData,
) async {
  // Sử dụng địa chỉ IP của máy bạn khi chạy backend
  final url = Uri.parse("http://192.168.1.111:5000/predict");


  try {
    // In ra dữ liệu đầu vào để kiểm tra
    print('Input Data: $inputData');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(inputData),
    );

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result; // TRẢ VỀ KẾT QUẢ
    } else {
      print("Server error: ${response.statusCode}");
      print("Message: ${response.body}");
      return null;
    }
  } catch (e) {
    print("Exception: $e");
    return null;
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
