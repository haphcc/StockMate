import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedAccountNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void select(int? accountId) => state = accountId;
}

final selectedAccountProvider = NotifierProvider<SelectedAccountNotifier, int?>(SelectedAccountNotifier.new);
