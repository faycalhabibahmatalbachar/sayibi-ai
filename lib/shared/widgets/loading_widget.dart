import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text(AppStrings.loading),
        ],
      ),
    );
  }
}
