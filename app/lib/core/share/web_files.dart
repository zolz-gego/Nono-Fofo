/// Sharing and saving files in a browser, where the share sheet isn't
/// always there (desktop Chrome on a Mac has none). On phones and tablets
/// apps share through share_plus and these are never needed.
library;

export 'web_files_stub.dart' if (dart.library.js_interop) 'web_files_web.dart';
