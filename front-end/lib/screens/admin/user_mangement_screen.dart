// lib/screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/config/theme_config.dart';

/// Màn hình quản lý user cho Admin
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late Future<Map<UserRole, List<UserModel>>> _usersByRoleFuture;

  @override
  void initState() {
    super.initState();
    _usersByRoleFuture = _fetchUsersGroupedByRole();
  }

  Future<Map<UserRole, List<UserModel>>> _fetchUsersGroupedByRole() async {
    final firestore = FirebaseFirestore.instance;
    // Query staff (admin, doctor, nurse)
    final staffSnap = await firestore.collection('staff').get();
    // Query patients
    final patientSnap = await firestore.collection('patients').get();

    // Chuyển thành UserModel
    final allStaff =
        staffSnap.docs.map((doc) => UserModel.fromDoc(doc)).toList();
    final allPatients =
        patientSnap.docs.map((doc) => UserModel.fromDoc(doc)).toList();

    // Gom nhóm theo role
    final Map<UserRole, List<UserModel>> grouped = {
      UserRole.admin: [],
      UserRole.doctor: [],
      UserRole.nurse: [],
      UserRole.patient: [],
    };

    for (var user in allStaff) {
      grouped[user.role]?.add(user);
    }
    for (var user in allPatients) {
      grouped[UserRole.patient]?.add(user);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Quản lý người dùng', style: AppTextStyles.appBarTitle),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<UserRole, List<UserModel>>>(
        future: _usersByRoleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi khi tải dữ liệu',
                style: AppTextStyles.bodyLarge,
              ),
            );
          }
          final grouped = snapshot.data!;

          // Hiển thị thống kê và danh sách
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              children: [
                // Thống kê
                _buildSummaryRow(grouped),
                const SizedBox(height: AppDimensions.marginLarge),
                // Danh sách chi tiết
                Expanded(
                  child: ListView(
                    children:
                        grouped.entries.map((entry) {
                          return _buildRoleSection(entry.key, entry.value);
                        }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Thống kê số lượng mỗi role dưới dạng row
  Widget _buildSummaryRow(Map<UserRole, List<UserModel>> grouped) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          grouped.entries.map((entry) {
            final role = entry.key;
            final count = entry.value.length;
            final label = _roleLabel(role);
            return Expanded(
              child: Card(
                color: AppColors.cardBackground,
                elevation: 2,
                shadowColor: AppColors.shadowMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingSmall,
                  ),
                  child: Column(
                    children: [
                      Text(count.toString(), style: AppTextStyles.h3),
                      const SizedBox(height: AppDimensions.paddingXSmall),
                      Text(
                        label,
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  /// Section cho từng role với ExpansionTile
  Widget _buildRoleSection(UserRole role, List<UserModel> users) {
    return Card(
      color: AppColors.surfaceColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: ExpansionTile(
        title: Text(
          _roleLabel(role),
          style: AppTextStyles.h4.copyWith(color: AppColors.primary),
        ),
        children:
            users.map((user) {
              return ListTile(
                leading: Icon(Icons.person, color: AppColors.primary),
                title: Text(user.fullname, style: AppTextStyles.bodyLarge),
                subtitle: Text(
                  user.staffId ?? user.phone,
                  style: AppTextStyles.bodyMedium,
                ),
              );
            }).toList(),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.doctor:
        return 'Bác sĩ';
      case UserRole.nurse:
        return 'Y tá';
      case UserRole.patient:
        return 'Bệnh nhân';
    }
  }
}
