import 'dart:typed_data';

/// Whether this browser can share [bytes] as a file (never off the web).
bool webCanShareFile(Uint8List bytes, String name, String type) => false;

/// Saves [bytes] to the browser's downloads (does nothing off the web).
Future<void> webDownloadFile(Uint8List bytes, String name, String type) async {}
