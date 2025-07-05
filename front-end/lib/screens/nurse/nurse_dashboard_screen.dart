// lib/screens/nurse/nurse_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:dacn_app/config/theme_config.dart';

class NurseDashboardScreen extends StatelessWidget {
  const NurseDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Nurse Dashboard', style: AppTextStyles.appBar),
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            Text('Thống kê hôm nay', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.marginMedium),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Bệnh nhân',
                    '12',
                    Icons.people,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSizes.marginMedium),
                Expanded(
                  child: _buildStatCard(
                    'Assessment',
                    '8',
                    Icons.assignment,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.marginMedium),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Hoàn thành',
                    '5',
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSizes.marginMedium),
                Expanded(
                  child: _buildStatCard(
                    'Khẩn cấp',
                    '2',
                    Icons.warning,
                    AppColors.error,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.marginLarge),

            // Quick Actions
            Text('Thao tác nhanh', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.marginMedium),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  children: [
                    _buildQuickAction(
                      'Danh sách Assessment',
                      'Xem các đánh giá cần thực hiện',
                      Icons.assignment_outlined,
                      AppColors.primary,
                      () => Navigator.pushNamed(
                        context,
                        '/nurse/assessment-queue',
                      ),
                    ),
                    const Divider(),
                    _buildQuickAction(
                      'Theo dõi bệnh nhân',
                      'Cập nhật chỉ số sinh hiệu',
                      Icons.monitor_heart_outlined,
                      AppColors.info,
                      () => Navigator.pushNamed(
                        context,
                        '/nurse/patient-monitoring',
                      ),
                    ),
                    const Divider(),
                    _buildQuickAction(
                      'Lịch sử khám',
                      'Xem lịch sử khám bệnh',
                      Icons.history,
                      AppColors.success,
                      () =>
                          Navigator.pushNamed(context, '/patient/patient-list'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.marginLarge),

            // Recent Activities
            Text('Hoạt động gần đây', style: AppTextStyles.h3),
            const SizedBox(height: AppSizes.marginMedium),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  children: [
                    _buildActivityItem(
                      'Hoàn thành assessment cho bệnh nhân Nguyễn Văn A',
                      '10 phút trước',
                      Icons.check_circle,
                      AppColors.success,
                    ),
                    const Divider(),
                    _buildActivityItem(
                      'Cập nhật chỉ số sinh hiệu cho bệnh nhân Trần Thị B',
                      '30 phút trước',
                      Icons.monitor_heart,
                      AppColors.info,
                    ),
                    const Divider(),
                    _buildActivityItem(
                      'Nhận thông báo khẩn cấp từ phòng 201',
                      '1 giờ trước',
                      Icons.notification_important,
                      AppColors.warning,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            Icon(icon, size: AppSizes.iconLarge, color: color),
            const SizedBox(height: AppSizes.marginSmall),
            Text(value, style: AppTextStyles.h2.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSizes.paddingSmall),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        ),
        child: Icon(icon, color: color, size: AppSizes.iconMedium),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color, size: AppSizes.iconMedium),
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: Text(time, style: AppTextStyles.bodySmall),
      contentPadding: EdgeInsets.zero,
    );
  }
}