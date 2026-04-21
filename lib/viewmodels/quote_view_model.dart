import 'package:flutter/material.dart';

import '../core/architecture/view_state.dart';
import '../data/models/quote_entry.dart';
import '../data/repositories/quote_repository.dart';

class QuoteViewModel with ChangeNotifier {
  final QuoteRepository _repository;

  ViewState<Quote> _quoteState = const Initial();
  bool _disposed = false;

  ViewState<Quote> get quoteState => _quoteState;

  QuoteViewModel({QuoteRepository? repository})
    : _repository = repository ?? QuoteRepository() {
    Future.microtask(loadQuote);
  }

  Future<void> loadQuote() async {
    await _fetchQuote(forceRefresh: false);
  }

  Future<void> refreshQuoteManually() async {
    await _fetchQuote(forceRefresh: true);
  }

  Future<void> _fetchQuote({required bool forceRefresh}) async {
    _quoteState = const Loading();
    if (!_disposed) {
      notifyListeners();
    }

    try {
      final quote = await _repository.getQuote(forceRefresh: forceRefresh);
      _quoteState = Success(
        quote ?? Quote(text: 'No quote available', author: 'System'),
      );
    } catch (e) {
      _quoteState = Error(e.toString());
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
