import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

class SayibiBottomNav extends StatelessWidget {
  const SayibiBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onChanged,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          label: AppStrings.navChat,
        ),
        NavigationDestination(
          icon: Icon(Icons.photo_library_outlined),
          label: AppStrings.navGallery,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: AppStrings.navProfile,
        ),
      ],
    );
  }
}
