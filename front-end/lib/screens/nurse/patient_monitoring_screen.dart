// lib/screens/nurse/patient_monitoring_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dacn_app/config/theme_config.dart';

class PatientMonitoringScreen extends StatelessWidget {
  final String language;
  const PatientMonitoringScreen({Key? key, this.language = 'en'})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tvi = language == 'vi';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tvi ? 'Giám sát bệnh nhân' : 'Patient Monitoring',
          style: AppTextStyles.appBar,
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('patients').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final patients = snap.data!.docs;
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (_, i) {
              final p = patients[i];
              final pid = p.id;
              return StreamBuilder(
                stream:
                    FirebaseFirestore.instance
                        .collection('assessments')
                        .where('patientId', isEqualTo: pid)
                        .orderBy('timestamp', descending: true)
                        .limit(1)
                        .snapshots(),
                builder: (ctx2, snap2) {
                  if (!snap2.hasData) return const SizedBox();
                  final latest = snap2.data!.docs;
                  if (latest.isEmpty) return const SizedBox();
                  final data = latest.first.data() as Map<String, dynamic>;
                  final risk = data['riskLevel'];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMedium,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(p['fullName'] ?? ''),
                      subtitle: Text(
                        'BP: ${data['input_data']['trestbps']}  HR: ${data['input_data']['thalach']}',
                      ),
                      trailing: Icon(
                        risk == 'high' ? Icons.warning : Icons.check_circle,
                        color:
                            risk == 'high'
                                ? AppColors.error
                                : AppColors.success,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
