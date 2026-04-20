import 'dart:typed_data';

import 'recording_bytes_io.dart' if (dart.library.html) 'recording_bytes_web.dart' as impl;

Future<Uint8List> readRecordingBytesFromPath(String path) => impl.readRecordingBytes(path);
