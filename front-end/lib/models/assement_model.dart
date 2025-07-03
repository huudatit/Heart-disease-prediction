// lib/models/assessment_model.dart
import 'prediction_model.dart';

/// Model lưu thông tin một lần đánh giá bệnh tim
class AssessmentModel {
  /// Dữ liệu đầu vào các chỉ số (13 đặc trưng)
  final Map<String, dynamic> inputData;

  /// Kết quả dự đoán
  final PredictionModel result;

  /// Thời điểm đánh giá
  final DateTime createdAt;

  AssessmentModel({
    required this.inputData,
    required this.result,
    required this.createdAt,
  });

  /// Tạo từ Map (ví dụ gọi API trả về hoặc Firestore)
  factory AssessmentModel.fromMap(Map<String, dynamic> map) {
    return AssessmentModel(
      inputData: Map<String, dynamic>.from(map['inputData'] as Map),
      result: PredictionModel.fromMap(map),
      createdAt:
          (map['timestamp'] is DateTime)
              ? map['timestamp'] as DateTime
              : DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Chuyển về Map để lưu lên Firestore hoặc gửi API
  Map<String, dynamic> toMap() {
    return {
      ...inputData,
      ...result.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
