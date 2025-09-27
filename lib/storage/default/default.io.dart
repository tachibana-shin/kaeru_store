import 'dart:io';
import 'dart:typed_data';

import '../base.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// The default IO implementation of [StorageBase] for mobile and desktop platforms.
///
/// This class uses `dart:io` and `path_provider` to read and write data
/// to the device's local file system.
///
/// The file path is processed to replace the `{document}` string with the actual
/// path to the application's documents directory.
class StorageDefault implements StorageBase {
  @override
  Future<void> set(String path, Uint8List buffer) async {
    path = path.replaceFirst(
      '{document}',
      await getApplicationDocumentsDirectory().then((value) => value.path),
    );

    final dir = dirname(path);
    final directory = Directory(dir);

    // Ensure the directory exists before writing the file.
    await directory.create(recursive: true);

    await File(path).writeAsBytes(buffer);
  }

  @override
  Future<Uint8List> get(String path) async {
    path = path.replaceFirst(
      '{document}',
      await getApplicationDocumentsDirectory().then((value) => value.path),
    );

    final dir = Directory(dirname(path));
    if (!await dir.exists()) return Uint8List(0);

    final file = File(path);
    if (!await file.exists()) return Uint8List(0);

    return file.readAsBytes();
  }
}
