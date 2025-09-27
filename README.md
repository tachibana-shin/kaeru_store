# kaeru_store

A simple and powerful persistence library for Flutter that seamlessly integrates with the `kaeru` reactive state management package. `kaeru_store` allows you to effortlessly persist your application's state, with built-in support for data encryption.

## Features

- **Easy to Use**: Define stores and persist their state with minimal boilerplate.
- **Reactive**: Built on `kaeru`, your UI automatically updates when the store's data changes.
- **Secure**: Built-in AES encryption to protect sensitive user data.
- **Cross-Platform**: Works on mobile, desktop, and web.
- **Customizable**: Provides the ability to implement custom storage backends (e.g., SQLite, ObjectBox, secure storage).

## Getting Started

### 1. Add Dependencies

Add `kaeru` and `kaeru_store` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  kaeru: ^1.0.0 # Use the latest version
  kaeru_store: ^1.0.0 # Use the latest version
```

### 2. Create a Store

Create a class that extends `Store`. Define your state variables using `Ref` and specify which ones to persist by overriding the `persistents` method.

```dart
// lib/stores/counter_store.dart
import 'package:kaeru/kaeru.dart';
import 'package:kaeru_store/kaeru_store.dart';

class CounterStore extends Store {
  // A unique ID for the store. This is used as the filename.
  @override
  String get id => 'counter';

  // Define a reactive state variable with an initial value of 0.
  late final count = Ref<int>(0);

  // Specify that the `count` variable should be persisted.
  // The order in this list is important and should not be changed.
  @override
  List<Ref> persistents() => [count];
}

// Create a global instance of your store.
final counterStore = CounterStore();
```

### 3. Use the Store in Your UI

Use `Watch` (from `kaeru`) to listen to changes in your store and automatically rebuild your widget.

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:kaeru/kaeru.dart';
import 'stores/counter_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Kaeru Store Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use Watch to rebuild the Text widget whenever count changes.
              Watch(() => Text(
                'Count: ${counterStore.count.value}',
                style: Theme.of(context).textTheme.headlineMedium,
              )),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => counterStore.count.value++,
                child: const Text('Increment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Data Encryption

`kaeru_store` provides built-in AES encryption. If a password is provided, all data will be encrypted before being written to storage.

### Global Password

You can set a global password that will be used for all stores. Set `Store.privateKey` before your app runs.

```dart
void main() async {
  // Set a global password for all stores.
  Store.privateKey = 'my_super_secret_password';

  runApp(const MyApp());
}
```

If `Store.privateKey` is an empty string (the default), encryption is disabled.

### Per-Store Password

You can also specify a password for an individual store by overriding the `privateKeyScope` getter. This will override any global password for that specific store.

```dart
class SecureNotesStore extends Store {
  @override
  String get id => 'secure_notes';

  // This store will use its own password.
  @override
  String get privateKeyScope => 'a_different_password_for_notes';

  late final notes = Ref<List<String>>([]);

  @override
  List<Ref> persistents() => [notes];
}
```

## Preloading Data

When an app starts, `kaeru_store` begins restoring data from storage in the background. If you need to ensure that data is available before your UI is displayed (e.g., to avoid a flicker), you can use the `Store.preload()` method.

Call this method in your `main` function before `runApp()`.

```dart
void main() async {
  // Ensure the Flutter binding is initialized.
  WidgetsFlutterBinding.ensureInitialized();

  // Wait for counterStore and any other stores to finish restoring data.
  await Store.preload([counterStore]);

  runApp(const MyApp());
}
```

## Advanced Configuration

For more fine-grained control, you can customize the following properties:

### `Store.dir`

This static property sets the directory where store files are saved. The default is `{document}/kaeru_store`, where `{document}` is the application's documents directory.

```dart
void main() {
  // Change the default storage directory
  Store.dir = '{document}/my_app_data';

  runApp(const MyApp());
}
```

### `Store.salt`

This static property defines the salt used for deriving the encryption key from your password. Changing the salt enhances security. It's recommended to set a custom salt for your application.

```dart
void main() {
  // Set a custom salt for key derivation
  Store.salt = 'my_unique_app_salt';
  Store.privateKey = 'my_super_secret_password';

  runApp(const MyApp());
}
```

### `filename`

You can override the `filename` getter in your store to change the default file name, which is `[id].data` by default.

```dart
class UserSettingsStore extends Store {
  @override
  String get id => 'user_settings';

  // Customize the filename for this store
  @override
  String get filename => 'user/settings.json';

  // ...
}
```

## Custom Storage Implementation

By default, `kaeru_store` uses the local file system on mobile/desktop and `localStorage` on the web. You can create your own storage backend by implementing the `StorageBase` abstract class.

This is useful for integrating with databases like **SQLite**, **ObjectBox**, or using secure storage APIs like `flutter_secure_storage`.

### Example: Custom SQLite Storage

Here is a conceptual example of how you might create a storage backend using a database.

**1. Implement `StorageBase`**

Create a class that implements the `get` and `set` methods.

```dart
import 'dart:typed_data';
import 'package:kaeru_store/kaeru_store.dart';
import 'package:sqflite/sqflite.dart'; // Example dependency

class SQLiteStorage implements StorageBase {
  final Future<Database> _db;

  SQLiteStorage(this._db);

  @override
  Future<Uint8List> get(String path) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'store',
      columns: ['data'],
      where: 'id = ?',
      whereArgs: [path],
    );

    if (maps.isNotEmpty) {
      // In a real implementation, you would handle the case where `data` is null
      // and decode it correctly. Here we assume it's a blob.
      return maps.first['data'] as Uint8List;
    }
    return Uint8List(0); // Return empty list if not found
  }

  @override
  Future<void> set(String path, Uint8List data) async {
    final db = await _db;
    await db.insert(
      'store',
      {'id': path, 'data': data},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
```

**2. Configure Your Store to Use It**

You can set your custom storage implementation globally or on a per-store basis.

**Global Configuration:**

Set the `Store.storage` static property before your app runs.

```dart
void main() async {
  // Initialize your database
  final db = openDatabase('kaeru_store.db', onCreate: (db, version) {
    return db.execute(
      "CREATE TABLE store(id TEXT PRIMARY KEY, data BLOB)",
    );
  }, version: 1);

  // Set your custom storage as the global default
  Store.storage = SQLiteStorage(db);

  await Store.preload([counterStore]);
  runApp(const MyApp());
}
```

**Per-Store Configuration:**

Override the `storageScope` getter in a specific store.

```dart
class MyCustomStoredData extends Store {
  @override
  String get id => 'my_custom_data';

  // This store uses a different storage backend
  @override
  StorageBase get storageScope => MySpecialStorage(); // Your custom implementation

  // ...
}
```