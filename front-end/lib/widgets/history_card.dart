import 'package:flutter/material.dart';

/// Một card đơn giản cho "Diagnosis History"
class HistoryCard extends StatelessWidget {
  final VoidCallback onTap;

  const HistoryCard({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.history, size: 32, color: Colors.green[600]),
        title: const Text(
          'Lịch sử chẩn đoán',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
