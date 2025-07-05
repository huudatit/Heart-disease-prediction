// lib/screens/home/doctor/patient_history_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/screens/assessment/diagnosis_result_screen.dart';
import 'package:dacn_app/models/user_model.dart';

class PatientHistoryScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final String language;

  const PatientHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.language = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final tvi = language == 'vi';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          tvi ? 'Lịch sử khám của $patientName' : "$patientName's History",
          style: AppTextStyles.appBar,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('patients')
                .doc(patientId)
                .collection('health_records')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                tvi ? 'Chưa có lịch sử khám' : 'No records found',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            separatorBuilder:
                (_, _) => const SizedBox(height: AppSizes.marginSmall),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              final date =
                  ts != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate())
                      : '—';
              final prob = (data['probability'] as num? ?? 0).toDouble();
              final level = data['risk_level'] as String? ?? 'low';
              final desc = data['risk_description'] as String? ?? '';
              final isHigh = level == 'high';

              return Card(
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                elevation: 1,
                child: ListTile(
                  leading: Icon(
                    isHigh ? Icons.warning : Icons.check_circle,
                    color: isHigh ? AppColors.error : AppColors.success,
                  ),
                  title: Text(
                    '$desc – ${(prob * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.bodyLarge,
                  ),
                  subtitle: Text(date, style: AppTextStyles.bodySmall),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => DiagnosisResultScreen(
                              patientId: patientId,
                              prediction: data['prediction'] as int,
                              probability: prob,
                              inputData: Map<String, dynamic>.from(
                                data['input_data'],
                              ),
                              language: language,
                              userRole: UserRole.doctor,
                              isSaved: false, // Không lưu lại khi xem lịch sử
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}