import 'dart:typed_data';
import 'blob_helper_stub.dart'
    if (dart.library.html) 'blob_helper_web.dart';

Future<Uint8List> fetchBlobBytes(String url) {
  return fetchBlobBytesPlatform(url);
}
