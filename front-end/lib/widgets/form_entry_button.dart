import 'package:flutter/material.dart';

/// Một Button Card chung để dùng cho "New Diagnosis", "Input Parameters"…
class FormEntryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const FormEntryButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, size: 32, color: Colors.blue[800]),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
