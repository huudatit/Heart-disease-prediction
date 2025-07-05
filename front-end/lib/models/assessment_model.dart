import 'package:cloud_firestore/cloud_firestore.dart';
import 'prediction_model.dart';

enum AssessmentStatus { pending, completed }

/// Model lưu thông tin một lần đánh giá bệnh tim
class AssessmentModel {
  /// Document ID trên Firestore
  final String id;

  /// ID bệnh nhân
  final String patientId;

  /// Tên bệnh nhân (nếu có)
  final String patientName;

  /// Dữ liệu đầu vào các chỉ số (13 đặc trưng)
  final Map<String, dynamic> inputData;

  /// Kết quả dự đoán
  final PredictionModel result;

  /// Thời điểm đánh giá (từ field `timestamp` của document)
  final DateTime timestamp;

  /// Trạng thái: pending hoặc completed
  final AssessmentStatus status;

  AssessmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.inputData,
    required this.result,
    required this.timestamp,
    required this.status,
  });

  /// Tạo từ DocumentSnapshot của Firestore
  factory AssessmentModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Lấy timestamp từ document
    final ts = data['timestamp'] as Timestamp?;

    // Dùng factory của PredictionModel để parse prediction, probability, timestamp
    final result = PredictionModel.fromSnapshot(doc);

    // Trạng thái lưu trong field 'status'
    final statusStr = data['status'] as String? ?? 'pending';
    final status =
        statusStr == 'completed'
            ? AssessmentStatus.completed
            : AssessmentStatus.pending;

    // Input data map
    final inputData = Map<String, dynamic>.from(
      data['input_data'] as Map? ?? {},
    );

    return AssessmentModel(
      id: doc.id,
      patientId: doc.reference.parent.parent!.id,
      patientName: inputData['fullName'] as String? ?? '',
      inputData: inputData,
      result: result,
      timestamp: ts?.toDate() ?? result.timestamp,
      status: status,
    );
  }

  /// Chuyển về Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'input_data': inputData,
      'prediction': result.prediction,
      'probability': result.probability,
      'timestamp': FieldValue.serverTimestamp(),
      'status': status == AssessmentStatus.completed ? 'completed' : 'pending',
    };
  }

  /// Helper: định dạng giờ cho UI
  String get timeString {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
