// lib/screens/nurse/assessment_queue_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:dacn_app/config/theme_config.dart';

class AssessmentQueueScreen extends StatefulWidget {
  const AssessmentQueueScreen({Key? key}) : super(key: key);

  @override
  _AssessmentQueueScreenState createState() => _AssessmentQueueScreenState();
}

class _AssessmentQueueScreenState extends State<AssessmentQueueScreen>
    with SingleTickerProviderStateMixin {
  late final Stream<List<Map<String, dynamic>>> _queueStream;
  late TabController _tabController;

  // Statistics
  int _totalRecords = 0;
  int _pendingRecords = 0;
  int _completedRecords = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _queueStream = _createQueueStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _createQueueStream() {
    return FirebaseFirestore.instance
        .collection('patients')
        .snapshots()
        .asyncMap((patientsSnapshot) async {
          final List<Map<String, dynamic>> allRecords = [];

          for (final patientDoc in patientsSnapshot.docs) {
            final patientData = patientDoc.data();
            final patientName = patientData['fullName'] as String? ?? 'Unknown';
            final patientPhone = patientData['phone'] as String? ?? 'N/A';
            final patientId = patientDoc.id;

            try {
              // Query health_records subcollection for this patient
              final healthRecordsSnapshot =
                  await patientDoc.reference
                      .collection('health_records')
                      .orderBy('timestamp', descending: true)
                      .get();

              for (final recordDoc in healthRecordsSnapshot.docs) {
                final recordData = recordDoc.data();

                // Determine status
                final status = recordData['status'] as String? ?? 'pending';
                final riskLevel =
                    recordData['risk_level'] as String? ?? 'unknown';
                final probability = recordData['probability'] as double? ?? 0.0;
                final timestamp = recordData['timestamp'] as Timestamp?;

                allRecords.add({
                  'patientName': patientName,
                  'patientPhone': patientPhone,
                  'patientId': patientId,
                  'recordId': recordDoc.id,
                  'timestamp': timestamp ?? Timestamp.now(),
                  'risk_level': riskLevel,
                  'probability': probability,
                  'recordRef': recordDoc.reference,
                  'status': status,
                  'input_data': recordData['input_data'],
                });
              }
            } catch (e) {
              // Handle error silently or log to analytics
              continue;
            }
          }

          // Sort by timestamp (newest first)
          allRecords.sort((a, b) {
            final aTime = (a['timestamp'] as Timestamp).millisecondsSinceEpoch;
            final bTime = (b['timestamp'] as Timestamp).millisecondsSinceEpoch;
            return bTime.compareTo(aTime);
          });

          // Update statistics
          _updateStatistics(allRecords);

          return allRecords;
        });
  }

  void _updateStatistics(List<Map<String, dynamic>> records) {
    _totalRecords = records.length;
    _pendingRecords =
        records
            .where((r) => r['status'] == 'pending' || r['status'] == 'unknown')
            .length;
    _completedRecords =
        records
            .where(
              (r) => r['status'] == 'completed' || r['status'] == 'processed',
            )
            .length;
  }

  List<Map<String, dynamic>> _filterRecords(
    List<Map<String, dynamic>> records,
    int tabIndex,
  ) {
    switch (tabIndex) {
      case 0: // All
        return records;
      case 1: // Pending
        return records
            .where((r) => r['status'] == 'pending' || r['status'] == 'unknown')
            .toList();
      case 2: // Completed
        return records
            .where(
              (r) => r['status'] == 'completed' || r['status'] == 'processed',
            )
            .toList();
      default:
        return records;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVI = true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isVI ? 'Hàng đợi đánh giá' : 'Assessment Queue',
          style: AppTextStyles.appBar,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _queueStream,
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi: ${snap.error}',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRecords = snap.data!;

          return Column(
            children: [
              // Statistics Cards
              _buildStatisticsCards(),

              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: isVI ? 'Tất cả' : 'All'),
                    Tab(text: isVI ? 'Chờ xử lý' : 'Pending'),
                    Tab(text: isVI ? 'Hoàn thành' : 'Completed'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecordsList(allRecords, 0), // All
                    _buildRecordsList(allRecords, 1), // Pending
                    _buildRecordsList(allRecords, 2), // Completed
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      color: const Color.fromRGBO(255, 255, 255, 255),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Tổng số',
              value: _totalRecords.toString(),
              icon: Icons.assignment,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.marginSmall),
          Expanded(
            child: _buildStatCard(
              title: 'Chờ xử lý',
              value: _pendingRecords.toString(),
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: AppSizes.marginSmall),
          Expanded(
            child: _buildStatCard(
              title: 'Hoàn thành',
              value: _completedRecords.toString(),
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: AppColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppSizes.marginSmall),
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList(
    List<Map<String, dynamic>> allRecords,
    int tabIndex,
  ) {
    final records = _filterRecords(allRecords, tabIndex);
    final isVI = true;

    if (records.isEmpty) {
      String emptyMessage;
      switch (tabIndex) {
        case 0:
          emptyMessage = isVI ? 'Chưa có bản ghi nào' : 'No records found';
          break;
        case 1:
          emptyMessage =
              isVI ? 'Không có bản ghi chờ xử lý' : 'No pending records';
          break;
        case 2:
          emptyMessage =
              isVI ? 'Không có bản ghi hoàn thành' : 'No completed records';
          break;
        default:
          emptyMessage = isVI ? 'Không có dữ liệu' : 'No data';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tabIndex == 1 ? Icons.pending_actions : Icons.inbox,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(emptyMessage, style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: records.length,
      itemBuilder: (ctx, i) {
        final rec = records[i];
        final ts = (rec['timestamp'] as Timestamp?)?.toDate();
        final timeStr =
            ts != null ? DateFormat('dd/MM/yyyy HH:mm').format(ts) : '—';
        final lvl = rec['risk_level'] as String;
        final prob = rec['probability'] as double;
        final status = rec['status'] as String;
        final isHigh = lvl == 'high';
        final isPending = status == 'pending' || status == 'unknown';

        final label =
            isVI
                ? (lvl == 'high'
                    ? 'Nguy cơ cao'
                    : lvl == 'medium'
                    ? 'Nguy cơ trung bình'
                    : 'Nguy cơ thấp')
                : lvl.toUpperCase();

        final statusLabel =
            isVI
                ? (isPending ? 'Chờ xử lý' : 'Hoàn thành')
                : (isPending ? 'Pending' : 'Completed');

        return Card(
          color: AppColors.white,
          margin: const EdgeInsets.only(bottom: AppSizes.marginMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          elevation: 1,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isHigh
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
              child: Icon(
                isHigh ? Icons.warning : Icons.check_circle,
                color: isHigh ? AppColors.error : AppColors.success,
              ),
            ),
            title: Text(
              '${rec['patientName']}',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SĐT: ${rec['patientPhone']}',
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  timeStr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isPending
                                ? Colors.orange.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isPending ? Colors.orange : AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(prob * 100).toStringAsFixed(1)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isHigh ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
            onTap: () {
              final recordRef = rec['recordRef'] as DocumentReference;
              _showRecordDetails(context, rec);
            },
          ),
        );
      },
    );
  }

  void _showRecordDetails(BuildContext context, Map<String, dynamic> record) {
    final isPending =
        record['status'] == 'pending' || record['status'] == 'unknown';

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),             
            ),
            title: Text('Chi tiết bản ghi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Bệnh nhân:', '${record['patientName']}'),
                  _buildDetailRow(
                    'Số điện thoại:',
                    '${record['patientPhone']}',
                  ),
                  _buildDetailRow('Patient ID:', '${record['patientId']}'),
                  _buildDetailRow('Record ID:', '${record['recordId']}'),
                  _buildDetailRow('Mức độ rủi ro:', '${record['risk_level']}'),
                  _buildDetailRow(
                    'Xác suất:',
                    '${(record['probability'] * 100).toStringAsFixed(1)}%',
                  ),
                  _buildDetailRow('Trạng thái:', '${record['status']}'),
                  if (record['input_data'] != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Dữ liệu đầu vào:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${record['input_data']}'),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Đóng'),
              ),
              if (isPending)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _processAssessment(record);
                  },
                  child: Text('Xử lý đánh giá'),
                ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _processAssessment(Map<String, dynamic> record) {
    // TODO: Implement actual assessment processing
    // For now, just show a dialog
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Xử lý đánh giá'),
            content: Text(
              'Xử lý đánh giá cho bệnh nhân: ${record['patientName']}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _markAsCompleted(record);
                },
                child: Text('Đánh dấu hoàn thành'),
              ),
            ],
          ),
    );
  }

  void _markAsCompleted(Map<String, dynamic> record) async {
    try {
      final recordRef = record['recordRef'] as DocumentReference;
      await recordRef.update({'status': 'completed'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã đánh dấu hoàn thành cho ${record['patientName']}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật trạng thái: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}