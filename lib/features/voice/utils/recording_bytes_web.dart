import 'dart:html' as html;
import 'dart:typed_data';

/// Sur le web, [path] est souvent une URL `blob:` après [AudioRecorder.stop].
Future<Uint8List> readRecordingBytes(String path) async {
  final request = await html.HttpRequest.request(
    path,
    responseType: 'arraybuffer',
  );
  final buffer = request.response;
  if (buffer is ByteBuffer) {
    return Uint8List.view(buffer);
  }
  throw StateError('Réponse audio invalide');
}
