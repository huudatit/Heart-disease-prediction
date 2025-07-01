// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dacn_app/services/api/api_config.dart'; // đường dẫn tới file của bạn

class ApiService {
  /// Gọi endpoint /predict
  static Future<Map<String, dynamic>?> predictHeartDisease(
    Map<String, dynamic> inputData,
  ) async {
    final uri = Uri.parse(ApiConfig.predictEndpoint());
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(inputData),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      // Bạn có thể in lỗi hoặc ném exception tuỳ ý
      print('Predict failed: ${resp.statusCode} ${resp.body}');
      return null;
    }
  }
//   Future<Map<String, dynamic>?> predictHeartDisease(
//   Map<String, dynamic> inputData,
//     ) async {
//   // Sử dụng địa chỉ IP của máy bạn khi chạy backend
//   final url = Uri.parse(ApiConfig.baseUrl);

//   try {
//     // In ra dữ liệu đầu vào để kiểm tra
//     print('Input Data: $inputData');

//     final response = await http.post(
//       url,
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(inputData),
//     );

//     print('Response Status Code: ${response.statusCode}');
//     print('Response Body: ${response.body}');

//     if (response.statusCode == 200) {
//       final result = jsonDecode(response.body);
//       return result; // TRẢ VỀ KẾT QUẢ
//     } else {
//       print("Server error: ${response.statusCode}");
//       print("Message: ${response.body}");
//       return null;
//     }
//   } catch (e) {
//     print("Exception: $e");
//     return null;
//   }
// }

  /// Ví dụ nếu bạn cần endpoint khác
  static Future<Map<String, dynamic>?> anotherCall(
    Map<String, dynamic> data,
  ) async {
    final uri = Uri.parse(ApiConfig.anotherEndpoint());
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }
}
