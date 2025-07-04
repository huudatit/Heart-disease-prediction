// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Vai trò người dùng trong hệ thống
enum UserRole { doctor, nurse, admin }

/// Model đơn giản cho User
class UserModel {
  /// UID của Firebase
  final String uid;

  /// Họ và tên đầy đủ
  final String fullName;

  /// Email đăng nhập
  final String email;

  /// Số điện thoại (tuỳ chọn)
  final String? phone;

  /// Mã nhân viên (doctor/nurse/admin)
  final String? staffId;

  /// Vai trò của user
  final UserRole role;

  /// Ngày tạo tài khoản
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.staffId,
    required this.role,
    required this.createdAt,
  });

  /// Tạo từ DocumentSnapshot của Firestore
  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final roleStr = (data['role'] as String?) ?? 'doctor';
    final role = UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == roleStr,
      orElse: () => UserRole.doctor,
    );
    final timestamp = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    }
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      staffId: data['staffId'] as String?,
      role: role,
      createdAt: createdAt,
    );
  }

  /// Chuyển UserModel về Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      if (phone != null) 'phone': phone,
      if (staffId != null) 'staffId': staffId,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Tạo bản copy với một số trường thay đổi
  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? staffId,
    UserRole? role,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      staffId: staffId ?? this.staffId,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
