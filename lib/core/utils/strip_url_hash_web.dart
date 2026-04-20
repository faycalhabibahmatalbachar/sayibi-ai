// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

void stripAuthFragmentFromBrowserUrl() {
  final path = html.window.location.pathname;
  final p = (path == null || path.isEmpty) ? '/' : path;
  html.window.history.replaceState(null, '', p);
}
