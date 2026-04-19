import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenerateState {
  const GenerateState({this.busy = false, this.lastUrl, this.error});

  final bool busy;
  final String? lastUrl;
  final String? error;
}

class GenerateNotifier extends StateNotifier<GenerateState> {
  GenerateNotifier() : super(const GenerateState());

  void setBusy(bool v) => state = GenerateState(busy: v, lastUrl: state.lastUrl);
}

final generateProvider =
    StateNotifierProvider<GenerateNotifier, GenerateState>((ref) => GenerateNotifier());
