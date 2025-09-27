import 'package:kaeru/kaeru.dart';
import 'package:kaeru_store/kaeru_store.dart';

class CounterStore extends Store {
  @override
  String get id => 'counter';

  late final count = Ref<int>(0);
  @override
  persistents() => [count];
}

final counterStore = CounterStore();
