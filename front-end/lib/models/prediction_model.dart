// lib/models/prediction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model kết quả dự đoán bệnh tim
typedef Prediction = PredictionModel;

class PredictionModel {
  /// Kết quả phân loại (0 = thấp, 1 = cao)
  final int prediction;

  /// Xác suất (0.0 - 1.0)
  final double probability;

  /// Thời điểm dự đoán
  final DateTime? timestamp;

  PredictionModel({
    required this.prediction,
    required this.probability,
    this.timestamp,
  });

  /// Tạo từ Map (ví dụ response API hoặc Firestore)
  factory PredictionModel.fromMap(Map<String, dynamic> map) {
    DateTime? ts;
    if (map['timestamp'] is Timestamp) {
      ts = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      ts = DateTime.tryParse(map['timestamp']);
    }
    return PredictionModel(
      prediction: map['prediction'] as int? ?? 0,
      probability: (map['probability'] as num?)?.toDouble() ?? 0.0,
      timestamp: ts,
    );
  }

  /// Chuyển về Map để lưu hoặc hiển thị
  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'prediction': prediction,
      'probability': probability,
    };
    if (timestamp != null) {
      m['timestamp'] = Timestamp.fromDate(timestamp!);
    }
    return m;
  }
}
