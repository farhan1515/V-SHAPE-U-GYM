// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';

Future<Uint8List?> pickWebImage({int maxSizeMB = 3}) async {
  final completer = Completer<Uint8List?>();
  final input = html.FileUploadInputElement();
  input.accept = 'image/*';
  input.click();

  input.onChange.listen((e) async {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      if (file.size > maxSizeMB * 1024 * 1024) {
        completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final result = reader.result;
      Uint8List bytes;
      if (result is Uint8List) {
        bytes = result;
      } else if (result is ByteBuffer) {
        bytes = Uint8List.view(result);
      } else {
        completer.complete(null);
        return;
      }
      completer.complete(bytes);
    } else {
      completer.complete(null);
    }
  });
  return completer.future;
}
