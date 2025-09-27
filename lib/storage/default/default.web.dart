import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';

import '../base.dart';

@JS('window.localStorage')
external JSLocalStorage get _localStorage;

@JS()
@staticInterop
class JSLocalStorage {}

extension JSLocalStorageExt on JSLocalStorage {
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}

/// The default implementation of [StorageBase] for the web platform.
///
/// This class uses `window.localStorage` to persist data in the user's browser.
///
/// The `Uint8List` data is Base64 encoded before being stored and is decoded
/// upon retrieval. The `{document}` string in the path is replaced with `document`
/// to create the key for `localStorage`.
class StorageDefault implements StorageBase {
  @override
  Future<void> set(String path, Uint8List buffer) async {
    final key = path.replaceFirst('{document}', 'document');
    final value = base64Encode(buffer);

    _localStorage.setItem(key, value);
  }

  @override
  Future<Uint8List> get(String path) async {
    final key = path.replaceFirst('{document}', 'document');
    final value = _localStorage.getItem(key);

    if (value == null) {
      // Match the behavior of the IO implementation, returning an empty list
      // instead of throwing an error.
      return Uint8List(0);
    }

    return base64Decode(value);
  }
}
