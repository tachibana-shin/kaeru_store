import 'package:flutter/foundation.dart';
import 'package:kaeru_store/storage/base.dart';
import 'package:kaeru_store/storage/default/default.io.dart';
import 'package:path/path.dart';
import 'package:kaeru/kaeru.dart';

import 'encrypt.dart';

/// An abstract base class for creating stores that hold application state
/// with persistence capabilities.
///
/// Extend this class to define a new store. Each store is a singleton that
/// manages a specific part of the application's state.
///
/// ### How to Use
///
/// 1.  **Create a Store Class:**
///     Extend `Store` and implement the `id` getter and the `persistents()` method.
///
/// 2.  **Define State:**
///     Use `Ref<T>` from the `kaeru` library to define state variables.
///
/// 3.  **Specify Persistent State:**
///     Return the list of `Ref`s that should be persisted in the `persistents()` method.
///
/// ### Full Example
///
/// ```dart
/// // stores/counter.dart
/// import 'package:kaeru/kaeru.dart';
/// import 'package:kaeru_store/kaeru_store.dart';
///
/// class CounterStore extends Store {
///   // A unique ID for the store, used as the filename.
///   @override
///   String get id => 'counter';
///
///   // Define a reactive state variable.
///   late final count = Ref<int>(0);
///
///   // Specify that `count` should be persisted.
///   @override
///   List<Ref> persistents() => [count];
/// }
///
/// // Create a single instance of the store.
/// final counterStore = CounterStore();
/// ```
///
/// ### Preloading Data
///
/// If you need to ensure data is restored before the UI is built,
/// use the static `Store.preload()` method.
///
/// ```dart
/// // main.dart
/// void main() async {
///   // Ensure Flutter is initialized.
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Preload the data for the counterStore.
///   await Store.preload([counterStore]);
///
///   runApp(MyApp());
/// }
/// ```
abstract class Store {
  /// The global password used to encrypt data for all stores.
  /// If left empty, encryption is disabled.
  static String privateKey = '';

  /// The "salt" string used during key derivation from the password.
  /// Change this value to enhance security.
  static String salt = 'kaeru_store';

  /// The directory where store files will be saved.
  ///
  /// The `{document}` string will be automatically replaced with the path to
  /// the application's documents directory (`getApplicationDocumentsDirectory`).
  static String dir = '{document}/kaeru_store';

  /// The global storage instance used by all stores.
  /// Defaults to [StorageDefault], which uses the file system on mobile/desktop
  /// and `localStorage` on the web.
  static StorageBase storage = StorageDefault();

  /// Preloads and restores data for a list of [stores].
  ///
  /// This function waits until all data restoration operations for the provided
  /// stores are complete. This is useful when you need to ensure data is
  /// available before launching the app.
  static Future<void> preload(List<Store> stores) async {
    await Future.wait(
      stores.map((store) => store.restoring).whereType<Future<void>>(),
    );
  }

  /// A unique ID for the store. This value is used to create the storage filename,
  /// so it must be unique among all stores.
  String get id;

  /// The encryption password specific to this store.
  /// By default, it uses the global [Store.privateKey].
  /// Override this getter to provide a different password for a specific store.
  @protected
  String get privateKeyScope => Store.privateKey;

  /// The filename where the store's data is saved.
  /// Defaults to `[id].data`.
  @protected
  String get filename => '$id.data';

  /// The storage instance specific to this store.
  /// By default, it uses the global [Store.storage].
  /// Override this getter to provide a different storage mechanism.
  @protected
  StorageBase get storageScope => storage;

  /// Returns a list of `Ref` variables that should be persisted.
  ///
  /// The order of the `Ref`s in this list is important and should not be
  /// changed after data has been saved, as it affects how data is restored.
  @protected
  List<Ref> persistents() => const <Ref>[];

  /// A `Future` that completes when the initial data restoration is finished.
  ///
  /// This is `null` if there is nothing to restore or after the restoration
  /// is complete. You can `await` on `Store.preload()` to wait for multiple stores.
  Future<void>? restoring;

  Store() {
    final pers = persistents();

    if (pers.isNotEmpty) {
      // Start the data restoration process.
      restoring = _setupPersistents(pers).then(
        (_) => restoring = null, // Reset restoring on completion
        onError: (error, stackTrace) {
          debugPrintStack(
            stackTrace: stackTrace,
            label: '[kaeru_store]: Restore data "$id" failed because of $error',
          );

          restoring = null;
        },
      );
    }
  }

  Future<void> _setupPersistents(List<Ref> pers) async {
    final file = join(normalize(dir), filename);

    final restoreData = await storageScope.get(file).catchError((
      error,
      stackTrace,
    ) {
      debugPrintStack(
        stackTrace: stackTrace,
        label:
            '[kaeru_store]: Restore data "$id" failed because of $error at file "$file"',
      );

      return Uint8List(0);
    });

    try {
      if (restoreData.isNotEmpty) {
        // If data exists, decrypt and restore the state.
        final data =
            await decryptWithPassword(restoreData, privateKeyScope, salt)
                as List;

        for (final (index, item) in data.indexed) {
          try {
            pers[index].value = item;
          } catch (error, stackTrace) {
            debugPrintStack(
              stackTrace: stackTrace,
              label:
                  '[kaeru_store]: Restore data "$id" at item $index failed because of $error',
            );
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrintStack(
        stackTrace: stackTrace,
        label: '[kaeru_store]: Restore data "$id" failed because of $error',
      );
    }

    // Watch for changes in the persistent Refs and save them.
    watch$(pers, () async {
      final listData = pers.map((e) => e.value).toList();

      final buffer = await encryptWithPassword(listData, privateKeyScope, salt);

      await storageScope.set(file, buffer);
    });
  }
}
