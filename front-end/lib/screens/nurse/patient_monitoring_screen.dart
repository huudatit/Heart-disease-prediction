// lib/screens/nurse/patient_monitoring_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dacn_app/config/theme_config.dart';

class PatientMonitoringScreen extends StatefulWidget {
  const PatientMonitoringScreen({Key? key}) : super(key: key);

  @override
  State<PatientMonitoringScreen> createState() =>
      _PatientMonitoringScreenState();
}

class _PatientMonitoringScreenState extends State<PatientMonitoringScreen> {
  String selectedPatientId = '';
  List<Map<String, dynamic>> patients = [];
  bool isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      setState(() {
        isLoading = true;
      });

      final QuerySnapshot patientsSnapshot =
          await _firestore.collection('patients').get();

      List<Map<String, dynamic>> loadedPatients = [];

      for (var doc in patientsSnapshot.docs) {
        final patientData = doc.data() as Map<String, dynamic>;

        // Lấy health record mới nhất
        final healthRecordsQuery =
            await _firestore
                .collection('patients')
                .doc(doc.id)
                .collection('health_records')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

        Map<String, dynamic>? latestRecord;
        if (healthRecordsQuery.docs.isNotEmpty) {
          latestRecord = healthRecordsQuery.docs.first.data();
        }

        // Tính toán các chỉ số sinh hiệu từ dữ liệu
        Map<String, dynamic> vitals = _calculateVitals(latestRecord);
        String status = _calculateStatus(vitals, latestRecord);

        loadedPatients.add({
          'id': doc.id,
          'name': patientData['fullName'] ?? 'N/A',
          'room': 'Phòng ${(loadedPatients.length + 101)}', // Tạm thời
          'age': _calculateAge(patientData['dateOfBirth']),
          'condition': _getConditionFromData(latestRecord),
          'vitals': vitals,
          'lastUpdate':
              latestRecord?['timestamp'] != null
                  ? _formatTime(latestRecord!['timestamp'])
                  : 'N/A',
          'status': status,
          'email': patientData['email'] ?? '',
          'phone': patientData['phone'] ?? '',
          'rawData': latestRecord,
        });
      }

      setState(() {
        patients = loadedPatients;
        if (patients.isNotEmpty && selectedPatientId.isEmpty) {
          selectedPatientId = patients.first['id'];
        }
        isLoading = false;
      });
    } catch (e) {
      print('Error loading patients: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải dữ liệu bệnh nhân: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Map<String, dynamic> _calculateVitals(Map<String, dynamic>? data) {
    if (data == null || data['input_data'] == null) {
      return {
        'bloodPressure': 'N/A',
        'heartRate': 0,
        'temperature': 0.0,
        'oxygenSaturation': 0,
        'respiratoryRate': 0,
      };
    }

    final inputData = data['input_data'];

    // Tính huyết áp từ thalach (max heart rate achieved)
    int systolic = (inputData['thalach'] ?? 0) + 50;
    int diastolic = (inputData['trestbps'] ?? 0);

    return {
      'bloodPressure': '$systolic/$diastolic',
      'heartRate': inputData['thalach'] ?? 0,
      'temperature': 36.5 + (inputData['oldpeak'] ?? 0), // Tạm tính
      'oxygenSaturation': 100 - (inputData['ca'] ?? 0) * 2, // Tạm tính
      'respiratoryRate': 18 + (inputData['slope'] ?? 0) * 2, // Tạm tính
    };
  }

  String _calculateStatus(
    Map<String, dynamic> vitals,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return 'unknown';

    // Dựa trên prediction và probability
    final prediction = data['prediction'] ?? 0;
    final probability = data['probability'] ?? 0.0;

    if (prediction == 1 && probability > 0.7) {
      return 'critical';
    } else if (prediction == 1 && probability > 0.5) {
      return 'warning';
    } else {
      return 'stable';
    }
  }

  String _getConditionFromData(Map<String, dynamic>? data) {
    if (data == null) return 'Chưa có dữ liệu';

    final riskDescription = data['risk_description'] ?? '';
    if (riskDescription.isNotEmpty) {
      return riskDescription;
    }

    final prediction = data['prediction'] ?? 0;
    return prediction == 1 ? 'Nguy cơ bệnh tim' : 'Bình thường';
  }

  int _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 0;

    DateTime birthDate;
    if (dateOfBirth is Timestamp) {
      birthDate = dateOfBirth.toDate();
    } else if (dateOfBirth is String) {
      birthDate = DateTime.tryParse(dateOfBirth) ?? DateTime.now();
    } else {
      return 0;
    }

    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return 'N/A';
    }

    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Theo dõi bệnh nhân', style: AppTextStyles.appBar),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (patients.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Theo dõi bệnh nhân', style: AppTextStyles.appBar),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPatients,
            ),
          ],
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Không có dữ liệu bệnh nhân')),
      );
    }

    final currentPatient = patients.firstWhere(
      (p) => p['id'] == selectedPatientId,
      orElse: () => patients.first,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Theo dõi bệnh nhân', style: AppTextStyles.appBar),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: AppColors.white), onPressed: _loadPatients),
        ],
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Patient Selector
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            child: Card(
              color: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn bệnh nhân',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.marginMedium),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            patients.map((patient) {
                              final isSelected =
                                  patient['id'] == selectedPatientId;
                              return Container(
                                margin: const EdgeInsets.only(
                                  right: AppSizes.marginMedium,
                                ),
                                child: FilterChip(
                                  selected: isSelected,
                                  label: Text(
                                    '${patient['name']} - ${patient['room']}',
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedPatientId = patient['id'];
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Patient Details and Vitals
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Info Card
                  Card(
                    color: AppColors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: _getStatusColor(
                                  currentPatient['status'],
                                ),
                                child: Text(
                                  currentPatient['name'][0],
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.marginMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentPatient['name'],
                                      style: AppTextStyles.h3,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${currentPatient['room']} • ${currentPatient['age']} tuổi',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentPatient['condition'],
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    if (currentPatient['rawData'] != null &&
                                        currentPatient['rawData']['probability'] !=
                                            null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Xác suất: ${(currentPatient['rawData']['probability'] * 100).toStringAsFixed(1)}%',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.paddingMedium,
                                  vertical: AppSizes.paddingSmall,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    currentPatient['status'],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSmall,
                                  ),
                                ),
                                child: Text(
                                  _getStatusText(currentPatient['status']),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.marginMedium),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: AppSizes.iconSmall,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSizes.marginSmall),
                              Text(
                                'Cập nhật lần cuối: ${currentPatient['lastUpdate']}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.marginMedium),

                  // Vital Signs
                  Text('Chỉ số sinh hiệu', style: AppTextStyles.h3),
                  const SizedBox(height: AppSizes.marginMedium),

                  // Vital Signs Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSizes.marginMedium,
                    mainAxisSpacing: AppSizes.marginMedium,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildVitalCard(
                        'Huyết áp',
                        currentPatient['vitals']['bloodPressure'],
                        'mmHg',
                        Icons.favorite,
                        _getBloodPressureColor(
                          currentPatient['vitals']['bloodPressure'],
                        ),
                      ),
                      _buildVitalCard(
                        'Nhịp tim',
                        currentPatient['vitals']['heartRate'].toString(),
                        'bpm',
                        Icons.monitor_heart,
                        _getHeartRateColor(
                          currentPatient['vitals']['heartRate'],
                        ),
                      ),
                      _buildVitalCard(
                        'Nhiệt độ',
                        '${currentPatient['vitals']['temperature'].toStringAsFixed(1)}°C',
                        '',
                        Icons.thermostat,
                        _getTemperatureColor(
                          currentPatient['vitals']['temperature'],
                        ),
                      ),
                      _buildVitalCard(
                        'SpO2',
                        '${currentPatient['vitals']['oxygenSaturation']}%',
                        '',
                        Icons.air,
                        _getOxygenColor(
                          currentPatient['vitals']['oxygenSaturation'],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.marginSmall),

                  // Respiratory Rate
                  Card(
                    color: AppColors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(
                              AppSizes.paddingMedium,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMedium,
                              ),
                            ),
                            child: Icon(
                              Icons.waves,
                              size: AppSizes.iconLarge,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: AppSizes.marginLarge),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nhịp thở',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${currentPatient['vitals']['respiratoryRate']} lần/phút',
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.marginMedium),

                  // Raw Data Display (for debugging)
                  if (currentPatient['rawData'] != null) ...[
                    Card(
                      color: AppColors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dữ liệu chẩn đoán', style: AppTextStyles.h3, textAlign: TextAlign.center,),
                            const SizedBox(height: AppSizes.marginMedium),
                            _buildDataRow(
                              'Tuổi',
                              '${currentPatient['rawData']['input_data']['age'] ?? 'N/A'}',
                            ),
                            _buildDataRow(
                              'Giới tính',
                              currentPatient['rawData']['input_data']['sex'] ==
                                      1
                                  ? 'Nam'
                                  : 'Nữ',
                            ),
                            _buildDataRow(
                              'Đau ngực (cp)',
                              '${currentPatient['rawData']['input_data']['cp'] ?? 'N/A'}',
                            ),
                            _buildDataRow(
                              'Cholesterol',
                              '${currentPatient['rawData']['input_data']['chol'] ?? 'N/A'} mg/dl',
                            ),
                            _buildDataRow(
                              'Đường huyết (fbs)',
                              '${currentPatient['rawData']['input_data']['fbs'] ?? 'N/A'}',
                            ),
                            _buildDataRow(
                              'Exang (exercise induced)',
                              currentPatient['rawData']['input_data']['exang'] ==
                                      1
                                  ? 'Có'
                                  : 'Không',
                            ),
                            _buildDataRow(
                              'Oldpeak',
                              '${currentPatient['rawData']['input_data']['oldpeak'] ?? 'N/A'}',
                            ),
                            _buildDataRow(
                              'Rest ECG (restecg)',
                              '${currentPatient['rawData']['input_data']['restecg'] ?? 'N/A'}',
                            ),
                            _buildDataRow(
                              'Slope',
                              '${currentPatient['rawData']['input_data']['slope'] ?? 'N/A'}',
                            ),
                            _buildDataRow(
                              'Thal',
                              '${currentPatient['rawData']['input_data']['thal'] ?? 'N/A'}',
                            ),
                            _buildDataRow(
                              'Max HR (thalach)',
                              '${currentPatient['rawData']['input_data']['thalach'] ?? 'N/A'}',
                            ),
                            _buildDataRow(
                              'Trestbps',
                              '${currentPatient['rawData']['input_data']['trestbps'] ?? 'N/A'}',
                            ),
                            _buildDataRow(
                              'CA (major vessels)',
                              '${currentPatient['rawData']['input_data']['ca'] ?? 'N/A'}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.marginMedium),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showPatientDetails(currentPatient),
                          icon: const Icon(Icons.info),
                          label: const Text('Chi tiết'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.marginMedium),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showVitalHistory(currentPatient),
                          icon: const Icon(Icons.history),
                          label: const Text('Lịch sử'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSizes.marginLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildVitalCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizes.iconLarge, color: color),
            const SizedBox(height: AppSizes.marginMedium),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.marginSmall),
            // CHỖ NÀY: Flexible + FittedBox để text co lại tự động
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: AppTextStyles.h3.copyWith(color: color),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                unit,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'stable':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'critical':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'stable':
        return 'Ổn định';
      case 'warning':
        return 'Cảnh báo';
      case 'critical':
        return 'Nguy hiểm';
      default:
        return 'Bình thường';
    }
  }

  Color _getBloodPressureColor(String bp) {
    if (bp == 'N/A') return AppColors.textSecondary;

    final parts = bp.split('/');
    if (parts.length == 2) {
      final systolic = int.tryParse(parts[0]) ?? 0;
      final diastolic = int.tryParse(parts[1]) ?? 0;

      if (systolic > 140 || diastolic > 90) {
        return AppColors.error;
      } else if (systolic > 130 || diastolic > 80) {
        return AppColors.warning;
      }
    }
    return AppColors.success;
  }

  Color _getHeartRateColor(int heartRate) {
    if (heartRate == 0) return AppColors.textSecondary;

    if (heartRate < 60 || heartRate > 100) {
      return AppColors.error;
    } else if (heartRate < 70 || heartRate > 90) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature == 0) return AppColors.textSecondary;

    if (temperature < 36.0 || temperature > 37.5) {
      return AppColors.error;
    } else if (temperature < 36.5 || temperature > 37.2) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  Color _getOxygenColor(int oxygen) {
    if (oxygen == 0) return AppColors.textSecondary;

    if (oxygen < 95) {
      return AppColors.error;
    } else if (oxygen < 97) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Thông tin bệnh nhân'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Họ tên', patient['name']),
                  _buildDetailRow('Tuổi', '${patient['age']} tuổi'),
                  _buildDetailRow('Phòng', patient['room']),
                  _buildDetailRow('Email', patient['email']),
                  _buildDetailRow('Điện thoại', patient['phone']),
                  _buildDetailRow('Tình trạng', patient['condition']),
                  if (patient['rawData'] != null) ...[
                    const Divider(),
                    Text(
                      'Dự đoán nguy cơ',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.marginSmall),
                    _buildDetailRow(
                      'Kết quả',
                      patient['rawData']['prediction'] == 1
                          ? 'Có nguy cơ'
                          : 'Không có nguy cơ',
                    ),
                    _buildDetailRow(
                      'Xác suất',
                      '${(patient['rawData']['probability'] * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  void _showVitalHistory(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Lịch sử theo dõi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bệnh nhân: ${patient['name']}'),
                const SizedBox(height: AppSizes.marginMedium),
                Text(
                  'Lịch sử gần đây:',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.marginMedium),
                Text(
                  'Dữ liệu được lấy từ Firebase theo thời gian thực.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }
}
