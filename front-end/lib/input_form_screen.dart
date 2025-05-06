import 'package:flutter/material.dart';
import 'package:dacn_app/main.dart';

class InputFormScreen extends StatefulWidget {
  const InputFormScreen({Key? key}) : super(key: key);

  @override
  State<InputFormScreen> createState() => _InputFormScreenState();
}

class _InputFormScreenState extends State<InputFormScreen> {
  final Map<String, TextEditingController> controllers = {
    'age': TextEditingController(),
    'sex': TextEditingController(),
    'cp': TextEditingController(),
    'trestbps': TextEditingController(),
    'chol': TextEditingController(),
    'fbs': TextEditingController(),
    'restecg': TextEditingController(),
    'thalach': TextEditingController(),
    'exang': TextEditingController(),
    'oldpeak': TextEditingController(),
    'slope': TextEditingController(),
    'ca': TextEditingController(),
    'thal': TextEditingController(),
  };

  void _submit() async {
  final inputData = controllers.map((key, controller) =>
      MapEntry(key, controller.text));

  final result = await predictHeartDisease(inputData);

  if (result != null) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Prediction Result"),
        content: Text(
            "Prediction: ${result['prediction']}\nProbability: ${result['probability']}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Navigator.pop(context, inputData);
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập thông tin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: controllers.keys.map((key) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: controllers[key],
                decoration: InputDecoration(
                  labelText: key,
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submit,
        label: const Text('Lưu'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
