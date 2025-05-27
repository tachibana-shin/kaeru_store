import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kaeru/kaeru.dart';
import 'package:shared_preferences/shared_preferences.dart';

final List<Future<void>> _storageInitialization = [];
final Map<String, Ref> _storeRefs = {};

Future<void> initializeStorage() async {
  await Future.wait(_storageInitialization);
}

Ref<T> _useStorage<T>(
  String name, {
  required T defaultValue,
  String Function(T value)? toJson,
  T Function(dynamic json)? fromJson,
}) {
  final asyncPref = SharedPreferencesAsync();

  final ref = Ref<T>(defaultValue);

  ref.addListener(() {
    asyncPref
        .setString(name, toJson?.call(ref.value) ?? jsonEncode(ref.value))
        .catchError((error) {
          // Handle error if needed
          if (kDebugMode) {
            print('[use_storage]: Error saving to storage: $error');
          }
        });
  });

  _storageInitialization.add(
    asyncPref
        .getString(name)
        .then((json) {
          if (json != null) {
            ref.value = fromJson?.call(jsonDecode(json)) ?? jsonDecode(json);
          }
        })
        .catchError((error) {
          if (kDebugMode) {
            print('[use_storage]: Error loading from storage: $error');
          }
        }),
  );

  return ref;
}

Ref<T> useStorage<T>(
  String name, {
  required T defaultValue,
  String Function(T value)? toJson,
  T Function(dynamic json)? fromJson,
}) {
  _storeRefs[name] ??= _useStorage<T>(
    name,
    defaultValue: defaultValue,
    toJson: toJson,
    fromJson: fromJson,
  );

  return _storeRefs[name] as Ref<T>;
}
