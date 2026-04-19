import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/document_model.dart';

class DocumentState {
  const DocumentState({this.items = const [], this.loading = false, this.error});

  final List<DocumentModel> items;
  final bool loading;
  final String? error;
}

class DocumentNotifier extends StateNotifier<DocumentState> {
  DocumentNotifier() : super(const DocumentState());

  void setItems(List<DocumentModel> v) => state = DocumentState(items: v);
}

final documentProvider =
    StateNotifierProvider<DocumentNotifier, DocumentState>((ref) => DocumentNotifier());
