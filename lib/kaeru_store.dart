/// The kaeru_store library provides a simple way to persist and manage Flutter
/// application state. It is built on top of `kaeru` for reactive state
/// management and provides automatic data encryption capabilities.
///
/// Key Features:
/// - Easily define "stores" to hold your state.
/// - Automatically persists state to local storage (device or web).
/// - Supports AES encryption to protect sensitive data.
/// - Seamlessly integrates with `kaeru`'s reactive system.
///
/// To get started, create a class that extends [Store] and define your state
/// using [Ref] from `kaeru`.
///
/// Example of a simple store:
/// ```dart
/// import 'package:kaeru/kaeru.dart';
/// import 'package:kaeru_store/kaeru_store.dart';
///
/// class CounterStore extends Store {
///   @override
///   String get id => 'counter'; // Unique ID for the store
///
///   // The state to be persisted
///   late final count = Ref<int>(0);
///
///   @override
///   List<Ref> persistents() => [count];
/// }
///
/// final counterStore = CounterStore();
/// ```
library;

export 'storage/default/default.dart';
export 'storage/base.dart';

export 'store.dart';
