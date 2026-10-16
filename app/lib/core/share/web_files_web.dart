import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Whether this browser can share [bytes] as a file through the system
/// share sheet.
bool webCanShareFile(Uint8List bytes, String name, String type) {
  final navigator = web.window.navigator;
  final js = navigator as JSObject;
  if (!js.has('share') || !js.has('canShare')) return false;
  try {
    final file = web.File(
      [bytes.toJS].toJS,
      name,
      web.FilePropertyBag(type: type),
    );
    return navigator.canShare(web.ShareData(files: [file].toJS));
  } catch (_) {
    return false;
  }
}

/// Saves [bytes] to the browser's downloads as [name].
Future<void> webDownloadFile(Uint8List bytes, String name, String type) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: type));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..style.display = 'none';
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  // Give the browser a moment to start the download before freeing it.
  Future<void>.delayed(
    const Duration(seconds: 10),
    () => web.URL.revokeObjectURL(url),
  );
}
