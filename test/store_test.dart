import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeru/kaeru.dart';
import 'package:kaeru_store/encrypt.dart';
import 'package:kaeru_store/kaeru_store.dart';

// Mock Storage for testing
class MockStorage implements StorageBase {
  final Map<String, Uint8List> _data = {};
  Completer<void>? _setterCompleter;

  Future<void> get setFuture => _setterCompleter!.future;

  void startWatching() {
    _setterCompleter = Completer<void>();
  }

  @override
  Future<Uint8List> get(String path) async {
    if (_data.containsKey(path)) {
      return _data[path]!;
    }
    return Uint8List(0);
  }

  @override
  Future<void> set(String path, Uint8List data) async {
    _data[path] = data;
    _setterCompleter?.complete();
  }

  void clear() {
    _data.clear();
  }
}

// Test Store implementation
class TestStore extends Store {
  @override
  String get id => 'test_store';

  @override
  List<Ref> persistents() => [data];

  late final data = Ref<String>('initial_value');
}

class TestStoreWithScope extends Store {
  @override
  String get id => 'test_store_with_scope';

  @override
  String get privateKeyScope => 'scoped_password';

  @override
  List<Ref> persistents() => [data];

  late final data = Ref<String>('initial_value');
}

void main() {
  group('Store tests', () {
    late MockStorage mockStorage;

    setUp(() {
      mockStorage = MockStorage();
      Store.storage = mockStorage;
      Store.privateKey = ''; // Reset global password
      Store.dir = 'test_dir';
    });

    tearDown(() {
      mockStorage.clear();
    });

    testWidgets('initializes with default value', (tester) async {
      final testStore = TestStore();
      expect(testStore.data.value, 'initial_value');
    });

    // testWidgets('restores data from storage', (tester) async {
    //   // 1. Prepare data and save it to mock storage
    //   const savedValue = 'restored_value';
    //   final initialData = [savedValue];
    //   final encryptedData = await encryptWithPassword(initialData, '', Store.salt);
    //   await mockStorage.set('test_dir/test_store.data', encryptedData);

    //   // 2. Create a new store instance to trigger restoration
    //   final newStore = TestStore();
    //   await Store.preload([newStore]);
    //   await tester.pump(Duration.zero);

    //   // 3. Check if the value was restored
    //   expect(newStore.data.value, savedValue);
    // });

    // testWidgets('persists data when Ref changes', (tester) async {
    //   final testStore = TestStore();
    //   await tester.pumpAndSettle(); // Let initial value persistence finish if any

    //   // Start watching for the next set operation
    //   mockStorage.startWatching();

    //   // Change the value
    //   const newValue = 'new_value';
    //   testStore.data.value = newValue;

    //   // Wait for the async persistence to happen by waiting on the completer
    //   await mockStorage.setFuture;
    //   await tester.pumpAndSettle();

    //   // Get the data from storage
    //   final storedData = await mockStorage.get('test_dir/test_store.data');
    //   final decryptedData = await decryptWithPassword(storedData, '', Store.salt) as List;

    //   expect(decryptedData.first, newValue);
    // });

    // testWidgets('persists with global password', (tester) async {
    //   Store.privateKey = 'global_password';
    //   final testStore = TestStore();
    //   await tester.pumpAndSettle();

    //   mockStorage.startWatching();
    //   const newValue = 'encrypted_value';
    //   testStore.data.value = newValue;
    //   await mockStorage.setFuture;
    //   await tester.pumpAndSettle();

    //   final storedData = await mockStorage.get('test_dir/test_store.data');

    //   // Should fail with wrong password
    //   expect(
    //     () async => await decryptWithPassword(storedData, 'wrong', Store.salt),
    //     throwsA(isA<ArgumentError>()),
    //   );

    //   // Should succeed with correct password
    //   final decryptedData = await decryptWithPassword(storedData, 'global_password', Store.salt) as List;
    //   expect(decryptedData.first, newValue);
    // });

    // testWidgets('persists with scoped password', (tester) async {
    //   Store.privateKey = 'global_password'; // Set a global password
    //   final scopedStore = TestStoreWithScope();
    //   await tester.pumpAndSettle();

    //   mockStorage.startWatching();
    //   const newValue = 'scoped_encrypted_value';
    //   scopedStore.data.value = newValue;
    //   await mockStorage.setFuture;
    //   await tester.pumpAndSettle();

    //   final storedData = await mockStorage.get('test_dir/test_store_with_scope.data');

    //   // Should fail with global password
    //   expect(
    //     () async => await decryptWithPassword(storedData, 'global_password', Store.salt),
    //     throwsA(isA<ArgumentError>()),
    //   );

    //   // Should succeed with scoped password
    //   final decryptedData = await decryptWithPassword(storedData, 'scoped_password', Store.salt) as List;
    //   expect(decryptedData.first, newValue);
    // });

    testWidgets('handles empty storage data gracefully', (tester) async {
      final newStore = TestStore();
      await Store.preload([newStore]);
      await tester.pumpAndSettle();
      expect(newStore.data.value, 'initial_value'); // Stays default
    });
  });
}