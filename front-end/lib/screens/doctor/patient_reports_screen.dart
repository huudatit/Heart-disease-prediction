// lib/screens/home/doctor/patient_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:dacn_app/config/theme_config.dart';
import 'package:dacn_app/screens/patients/patient_history_screen.dart';

class PatientReportsScreen extends StatefulWidget {
  final String language;
  const PatientReportsScreen({super.key, this.language = 'en'});

  @override
  // ignore: library_private_types_in_public_api
  _PatientReportsScreenState createState() => _PatientReportsScreenState();
}

class _PatientReportsScreenState extends State<PatientReportsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tvi = widget.language == 'vi';
    final title = tvi ? 'Danh sách bệnh nhân' : 'Patients';

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
      body: Column(
        children: [
          // --- 1. Thanh tìm kiếm ---
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    tvi ? 'Tìm tên hoặc số điện thoại' : 'Search name or phone',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  borderSide: BorderSide(color: AppColors.inputBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSizes.paddingSmall,
                  horizontal: AppSizes.paddingMedium,
                ),
              ),
              onChanged:
                  (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),

          // --- 2. Danh sách bệnh nhân ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('patients')
                      .orderBy('fullName')
                      .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return Center(child: Text(tvi ? 'Không có bệnh nhân' : 'No patients', style: AppTextStyles.bodyMedium));

                // 3. Lọc theo tên hoặc phone
                final filtered =
                    docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          (data['fullName'] ?? '').toString().toLowerCase();
                      final phone =
                          (data['phone'] ?? '').toString().toLowerCase();
                      if (_searchQuery.isEmpty) return true;
                      return name.contains(_searchQuery) ||
                          phone.contains(_searchQuery);
                    }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      tvi ? 'Không tìm thấy bệnh nhân' : 'No patients found',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMedium,
                  ),
                  separatorBuilder:
                      (_, _) => const SizedBox(height: AppSizes.marginSmall),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final doc = filtered[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final fullName = data['fullName'] as String? ?? '—';
                    final phone = data['phone'] as String? ?? '—';
                  
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusMedium,
                        ),
                      ),
                      elevation: 1,
                      child: ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: AppColors.info,
                        ),
                        title: Text(fullName, style: AppTextStyles.bodyLarge),
                        subtitle: Text(phone, style: AppTextStyles.bodySmall),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientHistoryScreen(
                                patientId: doc.id,
                                language: widget.language,
                                patientName: fullName,
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
          ),
        ],
      ),
    );
  }
}