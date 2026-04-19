import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/documents/screens/documents_screen.dart';
import 'features/generate/screens/generate_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/voice/screens/voice_screen.dart';
import 'shared/widgets/bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      ChatScreen(),
      DocumentsScreen(),
      GenerateScreen(),
      SearchScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          [
            AppStrings.navChat,
            AppStrings.navDocs,
            AppStrings.navGenerate,
            AppStrings.navSearch,
            AppStrings.navProfile,
          ][_index],
        ),
        actions: [
          IconButton(
            tooltip: 'Voix',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (context) => const SizedBox(
                  height: 420,
                  child: VoiceScreen(),
                ),
              );
            },
            icon: const Icon(Icons.graphic_eq),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: SayibiBottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
