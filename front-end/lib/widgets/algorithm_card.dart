import 'package:flutter/material.dart';

/// Một card cho "Algorithm Explanation"
class AlgorithmCard extends StatelessWidget {
  final VoidCallback onTap;

  const AlgorithmCard({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.psychology, size: 32, color: Colors.purple[600]),
        title: const Text(
          'Giải thích thuật toán',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
