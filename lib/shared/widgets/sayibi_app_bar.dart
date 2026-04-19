import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

class SayibiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SayibiAppBar({super.key, this.title, this.actions});

  final String? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title ?? AppStrings.appName),
      actions: actions,
    );
  }
}
