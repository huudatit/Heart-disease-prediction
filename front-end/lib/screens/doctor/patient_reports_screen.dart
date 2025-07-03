// lib/screens/home/doctor/patient_reports_screen.dart

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/screens/assessment/diagnosis_result_screen.dart';
import 'package:dacn_app/models/user_model.dart';

/// Màn Báo Cáo Đánh Giá Bệnh Nhân cho Bác sĩ
class PatientReportsScreen extends StatelessWidget {
  const PatientReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Assessment Reports', style: AppTextStyles.appBar),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('assessments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text('No reports found', style: AppTextStyles.bodyMedium),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final ts = data['createdAt'] as Timestamp?;
              final date =
                  ts != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate())
                      : 'Unknown';
              final prob = (data['probability'] as num?)?.toDouble() ?? 0.0;
              final desc = data['risk_description'] as String? ?? '';
              final isHigh =
                  desc.toLowerCase().contains('cao') ||
                  desc.toLowerCase().contains('high');
              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.marginSmall),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    isHigh ? Icons.warning : Icons.check_circle,
                    color: isHigh ? AppColors.error : AppColors.success,
                  ),
                  title: Text(
                    '$desc - ${(prob * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.bodyLarge,
                  ),
                  subtitle: Text(date, style: AppTextStyles.bodySmall),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => DiagnosisResultScreen(
                              patientId: docs[i].id,
                              prediction: data['prediction'] as int,
                              probability: prob,
                              inputData: Map<String, dynamic>.from(
                                data['input_data'] as Map,
                              ),
                              language: 'en',
                              userRole: UserRole.doctor,
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