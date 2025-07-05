// lib/models/prediction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model kết quả dự đoán bệnh tim
class PredictionModel {
  /// Kết quả phân loại (0 = thấp, 1 = cao)
  final int prediction;

  /// Xác suất (0.0 - 1.0)
  final double probability;

  /// Thời điểm dự đoán (từ serverTimestamp)
  final DateTime timestamp;

  PredictionModel({
    required this.prediction,
    required this.probability,
    required this.timestamp,
  });

  /// Tạo từ DocumentSnapshot Firestore
  factory PredictionModel.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    final ts = data['timestamp'] as Timestamp?;
    return PredictionModel(
      prediction: data['prediction'] as int? ?? 0,
      probability: (data['probability'] as num? ?? 0).toDouble(),
      timestamp: ts?.toDate() ?? DateTime.now(),
    );
  }

  /// Tạo từ Map (nếu bạn muốn dùng để parse API hoặc map thủ công)
  factory PredictionModel.fromMap(Map<String, dynamic> map) {
    DateTime ts = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      ts = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      ts = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    }
    return PredictionModel(
      prediction: map['prediction'] as int? ?? 0,
      probability: (map['probability'] as num? ?? 0).toDouble(),
      timestamp: ts,
    );
  }

  /// Chuyển về Map để lưu hoặc gửi API
  Map<String, dynamic> toMap() {
    return {
      'prediction': prediction,
      'probability': probability,
      // timestamp sẽ được set serverTimestamp() khi ghi lên Firestore
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}