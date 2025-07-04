// lib/screens/nurse/assessment_queue_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/models/user_model.dart';
import 'package:dacn_app/screens/assessment/diagnosis_result_screen.dart';

class AssessmentQueueScreen extends StatelessWidget {
  final String language;
  const AssessmentQueueScreen({Key? key, this.language = 'en'})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tvi = language == 'vi';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tvi ? 'Hàng đợi đánh giá' : 'Assessment Queue',
          style: AppTextStyles.appBar,
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('assessments')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // docs[index].data() đã là Map<String, dynamic> theo kiểu QueryDocumentSnapshot
              final data = docs[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['patientName'] ?? ''),
                subtitle: Text('Risk: ${data['riskLevel']}'),
                trailing: TextButton(
                  child: Text(tvi ? 'Xem' : 'View'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DiagnosisResultScreen(
                              // truyền đủ các tham số theo constructor mới
                              patientId: data['patientId'] as String,
                              prediction: data['prediction'] as int,
                              probability: data['probability'] as double,
                              inputData: Map<String, num>.from(
                                data['input_data'] as Map,
                              ),
                              language: language,
                              userRole: UserRole.nurse,
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
