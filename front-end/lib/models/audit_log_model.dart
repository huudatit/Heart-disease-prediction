// lib/models/audit_log_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model ghi lại nhật ký hoạt động của user
class AuditLogModel {
  /// ID của document (nếu cần)
  final String? id;

  /// UID của user thực hiện hành động
  final String userId;

  /// Tên hành động (ví dụ 'CREATE_ASSESSMENT')
  final String action;

  /// Loại tài nguyên (ví dụ 'assessment', 'user')
  final String resourceType;

  /// ID tài nguyên liên quan
  final String resourceId;

  /// Thời điểm thực hiện
  final DateTime timestamp;

  AuditLogModel({
    this.id,
    required this.userId,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.timestamp,
  });

  /// Tạo từ Firestore DocumentSnapshot
  factory AuditLogModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final ts = data['timestamp'] as Timestamp?;
    return AuditLogModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      action: data['action'] as String? ?? '',
      resourceType: data['resourceType'] as String? ?? '',
      resourceId: data['resourceId'] as String? ?? '',
      timestamp: ts?.toDate() ?? DateTime.now(),
    );
  }

  /// Chuyển về Map để lưu
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'action': action,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
