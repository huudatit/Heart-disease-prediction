// lib/screens/nurse/nurse_home_screen.dart
import 'package:flutter/material.dart';

import 'package:dacn_app/widgets/form_entry_button.dart';
import 'package:dacn_app/widgets/history_card.dart';
import 'package:dacn_app/models/user_model.dart';

class NurseHomeScreen extends StatelessWidget {
  final UserModel user;
  const NurseHomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('Y tá: ${user.fullname}')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          FormEntryButton(
            icon: Icons.input,
            label: 'Nhập thông số',
            onTap: () {
              /* push InputFormScreen */
            },
          ),
          SizedBox(height: 12),
          HistoryCard(
            onTap: () {
              /* push HistoryScreen */
            },
          ),
        ],
      ),
    );
  }
}
