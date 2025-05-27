
import 'package:kaeru/kaeru.dart';

import 'use_storage.dart';

class ComputedGetter<T> extends Computed<T> {
  final void Function(T value) _setter;

  ComputedGetter(super.getter, this._setter);

  set value(T value) {
    _setter(value);
  }
}

class DefineStore<T> {
  late final Ref<T> _model;

  DefineStore(
    String name,
    T model, {
    String Function(T value)? toJson,
    T Function(dynamic json)? fromJson,
  }) {
    _model = useStorage(
      name,

      defaultValue: model,
      toJson: toJson,
      fromJson: fromJson,
    );
  }

  ComputedGetter<U> use<U>(
    U Function(T model) getter,
    T Function(U value, T model) setter,
  ) {
    final ref = ComputedGetter<U>(() => getter(_model.value), (value) {
      _model.value = setter(value, _model.value);
    });

    return ref;
  }
}
