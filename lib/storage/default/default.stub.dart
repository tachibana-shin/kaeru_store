import 'dart:typed_data';

import '../base.dart';

class StorageDefault implements StorageBase {
  @override
  Future<void> set(String path, Uint8List buffer) async {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> get(String path) async {
    throw UnimplementedError();
  }
}
