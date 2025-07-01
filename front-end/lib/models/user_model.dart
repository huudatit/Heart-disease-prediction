// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Các quyền user trong hệ thống
enum UserRole { doctor, nurse, admin, patient }

/// Model chung cho cả staff và bệnh nhân
class UserModel {
  /// Firebase document ID
  final String uid;

  /// Họ tên đầy đủ hoặc display name
  final String fullname;

  /// Email (chỉ dùng với user patient hoặc nếu staff có email)
  final String email;

  /// Số điện thoại (chỉ dùng với patient)
  final String phone;

  /// staffId, chỉ có staff mới có
  final String? staffId;

  /// Role của user: doctor/nurse/admin/patient
  final UserRole role;

  /// Department (chỉ có staff)
  final String? department;

  UserModel({
    required this.uid,
    required this.fullname,
    required this.email,
    required this.phone,
    this.staffId,
    required this.role,
    this.department,
  });

  /// Tạo từ Firestore DocumentSnapshot
  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final roleStr = (data['role'] as String?)?.toLowerCase() ?? 'patient';
    final role = UserRole.values.firstWhere(
      (r) => r.toString().split('.').last == roleStr,
      orElse: () => UserRole.patient,
    );
    return UserModel(
      uid: doc.id,
      fullname: data['fullname'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      staffId: data['staffId'] as String?,
      role: role,
      department: data['department'] as String?,
    );
  }

  /// Tạo từ Map (ví dụ khi đã merge với id)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    final roleStr = (map['role'] as String?)?.toLowerCase() ?? 'patient';
    final role = UserRole.values.firstWhere(
      (r) => r.toString().split('.').last == roleStr,
      orElse: () => UserRole.patient,
    );
    return UserModel(
      uid: map['id'] as String,
      fullname: map['fullname'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      staffId: map['staffId'] as String?,
      role: role,
      department: map['department'] as String?,
    );
  }

  /// Chuyển về Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullname': fullname,
      'email': email,
      'phone': phone,
      if (staffId != null) 'staffId': staffId,
      'role': role.toString().split('.').last,
      if (department != null) 'department': department,
    };
  }
}
