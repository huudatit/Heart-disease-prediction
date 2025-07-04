// lib/screens/patient/patient_form_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dacn_app/config/theme_config.dart';

/// Màn hình tạo mới bệnh nhân lần đầu tiên đến khám
class PatientFormScreen extends StatefulWidget {
  final String language;
  const PatientFormScreen({super.key, this.language = 'en'});

  @override
  State createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  DateTime? _dob;
  String? _gender;
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isSaving = false;

  String get _t => widget.language;
  bool get _vi => _t == 'vi';

  Future _pickDob() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now.subtract(Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected != null) setState(() => _dob = selected);
  }

  Future _savePatient() async {
    if (!_formKey.currentState!.validate() || _dob == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _vi
                ? 'Vui lòng điền đầy đủ thông tin'
                : 'Please complete all fields',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final data = {
        'fullName': _nameCtrl.text.trim(),
        'dateOfBirth': Timestamp.fromDate(_dob!),
        'gender': _gender,
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .add(data);
      final msg =
          _vi ? 'Thêm bệnh nhân thành công!' : 'Patient added successfully!';
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context, doc.id);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vi ? 'Lỗi lưu bệnh nhân' : 'Failed to save patient'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _vi ? 'Thêm bệnh nhân' : 'Add Patient',
          style: AppTextStyles.appBar,
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: AppInputStyles.standard(
                  labelText: _vi ? 'Họ và tên' : 'Full Name',
                ),
                validator:
                    (v) =>
                        v!.trim().isEmpty
                            ? (_vi ? 'Không được để trống' : 'Required')
                            : null,
              ),
              const SizedBox(height: AppSizes.marginMedium),
              InkWell(
                onTap: _pickDob,
                child: InputDecorator(
                  decoration: AppInputStyles.standard(
                    labelText: _vi ? 'Ngày sinh' : 'Date of Birth',
                  ),
                  child: Text(
                    _dob == null
                        ? (_vi ? 'Chọn ngày' : 'Pick date')
                        : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.marginMedium),
              DropdownButtonFormField(
                decoration: AppInputStyles.standard(
                  labelText: _vi ? 'Giới tính' : 'Gender',
                ),
                items: [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text(_vi ? 'Nam' : 'Male'),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text(_vi ? 'Nữ' : 'Female'),
                  ),
                ],
                onChanged: (v) => setState(() => _gender = v),
                validator:
                    (v) =>
                        v == null
                            ? (_vi ? 'Chọn giới tính' : 'Required')
                            : null,
              ),
              const SizedBox(height: AppSizes.marginMedium),
              TextFormField(
                controller: _phoneCtrl,
                decoration: AppInputStyles.standard(
                  labelText: _vi ? 'Số điện thoại' : 'Phone',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSizes.marginMedium),
              TextFormField(
                controller: _emailCtrl,
                decoration: AppInputStyles.standard(
                  labelText: _vi ? 'Email' : 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final regex = RegExp(r"^[\w-.]+@([\w-]+.)+[\w-]{2,4}$");
                  return regex.hasMatch(v)
                      ? null
                      : (_vi ? 'Email không hợp lệ' : 'Invalid email');
                },
              ),
              const SizedBox(height: AppSizes.marginLarge),
              ElevatedButton(
                style: AppButtonStyles.primary,
                onPressed: _isSaving ? null : _savePatient,
                child:
                    _isSaving
                        ? const CircularProgressIndicator(
                          color: AppColors.white,
                        )
                        : Text(
                          _vi ? 'Lưu bệnh nhân' : 'Save Patient',
                          style: AppTextStyles.button,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
