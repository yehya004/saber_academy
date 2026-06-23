import 'dart:typed_data';

Future<Uint8List> fetchBlobBytesPlatform(String url) async {
  throw UnsupportedError('fetchBlobBytes is only supported on Web');
}
