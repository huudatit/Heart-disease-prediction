import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/screens/assessment/assessment_form_screen.dart';
import 'package:dacn_app/screens/assessment/diagnosis_result_screen.dart';
//import 'package:dacn_app/screens/doctor/clinical_insights_screen.dart';
import 'package:dacn_app/screens/doctor/patient_reports_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final UserRole userRole;
  final String language;

  const DoctorDashboardScreen({
    super.key,
    required this.userName,
    required this.userId,
    required this.userRole,
    this.language = 'en',
  });

  @override
  // ignore: library_private_types_in_public_api
  _DoctorDashboardScreenState createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  late Stream<List<Map<String, dynamic>>> _visitsStream;

  @override
  void initState() {
    super.initState();
    _visitsStream = _createCombinedStream();
  }

  /// Combine each health_record with its patient's fullName and id
  Stream<List<Map<String, dynamic>>> _createCombinedStream() {
    return FirebaseFirestore.instance
        .collection('patients')
        .snapshots()
        .asyncMap((patientsSnap) async {
          final visits = <Map<String, dynamic>>[];
          for (final patientDoc in patientsSnap.docs) {
            final patientData = patientDoc.data();
            final patientName = patientData['fullName'] as String? ?? '—';
            final patientId = patientDoc.id;
            try {
              final recSnap =
                  await patientDoc.reference
                      .collection('health_records')
                      .orderBy('timestamp', descending: true)
                      .limit(5)
                      .get();
              for (final rec in recSnap.docs) {
                final data = Map<String, dynamic>.from(rec.data());
                data['patientName'] = patientName;
                data['patientId'] = patientId;
                data['recordRef'] = rec.reference;
                visits.add(data);
              }
            } catch (e) {
              debugPrint('Error fetching records for $patientId: $e');
            }
          }
          // Sort by timestamp desc
          visits.sort((a, b) {
            final ta = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
            final tb = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
            return tb.compareTo(ta);
          });
          return visits.take(5).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    final isVI = widget.language == 'vi';
    final title = isVI ? 'Bảng điều khiển bác sĩ' : 'Doctor Dashboard';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(title, style: AppTextStyles.appBar),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: ListView(
          children: [
            // Grid Actions
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSizes.marginMedium,
              mainAxisSpacing: AppSizes.marginMedium,
              childAspectRatio: 1.2,
              children: [
                _buildCard(
                  icon: Icons.add_chart,
                  label: isVI ? 'Đánh giá mới' : 'New Assessment',
                  color: AppColors.primary,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AssessmentFormScreen(
                                language: widget.language,
                                userRole: widget.userRole,
                              ),
                        ),
                      ),
                ),
                _buildCard(
                  icon: Icons.analytics,
                  label: isVI ? 'Báo cáo phân tích' : 'Reports',
                  color: AppColors.info,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PatientReportsScreen(
                                language: widget.language,
                              ),
                        ),
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.marginLarge),
            // Recent Assessments
            Text(
              isVI ? 'Lịch sử đánh giá gần đây' : 'Recent Assessments',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSizes.marginSmall),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _visitsStream,
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snap.error}',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final visits = snap.data ?? [];
                if (visits.isEmpty) {
                  return Center(
                    child: Text(
                      isVI ? 'Chưa có đánh giá' : 'No assessments yet',
                    ),
                  );
                }
                return Column(
                  children:
                      visits.map((visit) {
                        final ts = (visit['timestamp'] as Timestamp?)?.toDate();
                        final date =
                            ts != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(ts)
                                : '—';
                        final level = visit['risk_level'] as String? ?? 'low';
                        final prob =
                            ((visit['probability'] as num?) ?? 0) * 100;
                        final isHigh = level == 'high';
                        final label =
                            isVI
                                ? (level == 'high'
                                    ? 'Nguy cơ cao'
                                    : level == 'medium'
                                    ? 'Nguy cơ trung bình'
                                    : 'Nguy cơ thấp')
                                : level.toUpperCase();
                        final patientName = visit['patientName'] as String;
                        final patientId = visit['patientId'] as String;
                        return Card(
                          color: AppColors.cardBackground,
                          margin: const EdgeInsets.symmetric(
                            vertical: AppSizes.marginSmall,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMedium,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isHigh ? Icons.warning : Icons.check_circle,
                              color:
                                  isHigh ? AppColors.error : AppColors.success,
                            ),
                            title: Text(
                              '$patientName\n$label ${prob.toStringAsFixed(1)}%',
                              style: AppTextStyles.bodyLarge,
                            ),
                            subtitle: Text(
                              date,
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: TextButton(
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => DiagnosisResultScreen(
                                            patientId: patientId,
                                            prediction:
                                                visit['prediction'] as int,
                                            probability:
                                                (visit['probability'] as num)
                                                    .toDouble(),
                                            inputData:
                                                Map<String, dynamic>.from(
                                                  visit['input_data'],
                                                ),
                                            language: widget.language,
                                            userRole: widget.userRole,
                                          ),
                                    ),
                                  ),
                              child: Text(isVI ? 'Xem' : 'View'),
                            ),
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: AppSizes.iconLarge),
            const SizedBox(height: AppSizes.marginSmall),
            Text(
              label,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}