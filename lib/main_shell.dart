import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/gallery/screens/gallery_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/voice/screens/voice_call_screen.dart';
import 'shared/widgets/bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = [
    AppStrings.navChat,
    AppStrings.navGallery,
    AppStrings.navProfile,
  ];

  @override
  Widget build(BuildContext context) {
    const pages = [
      ChatScreen(),
      GalleryScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      appBar: _index == 0
          ? null
          : AppBar(
              title: Text(_titles[_index]),
              actions: [
                IconButton(
                  tooltip: 'Voix',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VoiceCallScreen(),
                        fullscreenDialog: true,
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
