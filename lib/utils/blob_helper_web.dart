// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:js' as js;
import 'dart:typed_data';

Future<Uint8List> fetchBlobBytesPlatform(String url) {
  final completer = Completer<Uint8List>();
  final callbackName = 'tempCallback_${DateTime.now().millisecondsSinceEpoch}';
  
  // Inject the script if not already present
  if (js.context['readBlobAsBytes'] == null) {
    js.context.callMethod('eval', [
      """
      window.readBlobAsBytes = function(url, callbackName) {
        fetch(url)
          .then(function(r) { return r.arrayBuffer(); })
          .then(function(buf) {
            var arr = new Uint8Array(buf);
            var regularArray = [];
            for (var i = 0; i < arr.length; i++) {
              regularArray.push(arr[i]);
            }
            if (typeof window[callbackName] === 'function') {
              window[callbackName](regularArray);
            }
          })
          .catch(function(err) {
            console.error('readBlobAsBytes error:', err);
            if (typeof window[callbackName] === 'function') {
              window[callbackName](null);
            }
          });
      };
      """
    ]);
  }
  
  js.context[callbackName] = (dynamic bytes) {
    // Clean up window callback
    js.context.callMethod('eval', ['delete window["$callbackName"]']);
    
    if (bytes == null) {
      completer.completeError(Exception('Failed to read blob bytes'));
    } else {
      try {
        final List<int> list = List<int>.from(bytes);
        completer.complete(Uint8List.fromList(list));
      } catch (e) {
        completer.completeError(e);
      }
    }
  };
  
  js.context.callMethod('readBlobAsBytes', [url, callbackName]);
  
  return completer.future;
}
