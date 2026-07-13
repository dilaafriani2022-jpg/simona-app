import 'dart:typed_data';
import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart'
    if (dart.library.io) 'file_download_helper_mobile.dart';

Future<void> downloadFile(Uint8List bytes, String filename) async {
  await saveAndDownloadFile(bytes, filename);
}
