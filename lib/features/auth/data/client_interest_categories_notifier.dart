import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientInterestCategoriesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int index) {
    final copy = Set<int>.from(state);
    if (copy.contains(index)) {
      copy.remove(index);
    } else {
      copy.add(index);
    }
    state = copy;
  }
}

final clientInterestCategoriesProvider =
    NotifierProvider<ClientInterestCategoriesNotifier, Set<int>>(
  ClientInterestCategoriesNotifier.new,
  isAutoDispose: true,
);
