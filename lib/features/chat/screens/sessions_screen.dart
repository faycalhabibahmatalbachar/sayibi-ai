import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: Center(
        child: Text('${AppStrings.loading}\n(branchement API /chat/sessions)'),
      ),
    );
  }
}
