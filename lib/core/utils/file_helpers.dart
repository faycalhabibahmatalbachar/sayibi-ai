import 'dart:io';

String safeFileName(String name) {
  final i = name.replaceAll('\\', '/').split('/');
  return i.isNotEmpty ? i.last : name;
}

Future<int> fileSize(File f) async {
  return f.length();
}
