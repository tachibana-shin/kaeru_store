import 'package:flutter/foundation.dart';

/// An abstract class that defines the interface for persistent data storage.
///
/// This class provides a common API for reading and writing data as a `Uint8List`,
/// allowing `kaeru_store` to work with various storage mechanisms
/// (e.g., local file system, `localStorage` on the web) consistently.
///
/// To create a custom storage provider, implement this class and provide
/// the logic for the [get] and [set] methods.
abstract class StorageBase {
  /// Writes a byte array [data] to a specific [path].
  ///
  /// If the path or its parent directories do not exist, they should be created.
  Future<void> set(String path, Uint8List data);

  /// Reads and returns the data from a [path] as a `Uint8List`.
  ///
  /// If the file does not exist, an empty `Uint8List` should be returned.
  Future<Uint8List> get(String path);
}
