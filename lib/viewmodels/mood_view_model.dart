import 'package:flutter/material.dart';
import '../data/models/mood_entry.dart';
import '../data/repositories/mood_repository.dart';
import '../data/repositories/quote_repository.dart';
import '../core/architecture/view_state.dart';
import '../data/models/quote_entry.dart';

class MoodViewModel with ChangeNotifier {
  final QuoteRepository _qRepository = QuoteRepository();
  final MoodRepository _mRepository = MoodRepository();

  ViewState<List<MoodEntry>> _moodsState = const Initial();
  ViewState<Quote> _quoteState = const Initial();
  
  ViewState<List<MoodEntry>> get moodsState => _moodsState;
  ViewState<Quote> get quoteState => _quoteState;

  MoodViewModel() {
    refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadMoods(),
      loadQuote(),
    ]);
  }

  Future<void> loadQuote() async {
    await _fetchQuoteLogic(forceRefresh: false);
  }


  Future<void> refreshQuoteManually() async {
    await _fetchQuoteLogic(forceRefresh: true);
  }


  Future<void> _fetchQuoteLogic({required bool forceRefresh}) async {
    _quoteState = const Loading();
    notifyListeners();

    try {
      final quote = await _qRepository.getQuote(forceRefresh: forceRefresh);
      if (quote != null) {
        _quoteState = Success(quote);
      } else {
        _quoteState = Success(Quote(text: "❤️", author: "System"));
      }
    } catch (e) {
      _quoteState = Error(e.toString());
    }
    notifyListeners();
}

  Future<void> loadMoods() async {
    _moodsState = const Loading();
    notifyListeners();
    try {
      final data = await _mRepository.getAllMoods();
      _moodsState = Success(data);
    } catch (e) {
      _moodsState = const Error("Failed to load history");
    }
    notifyListeners();
  }

  Future<void> addMood(MoodEntry entry) async {
    await _mRepository.addMood(entry);
    await loadMoods();
  }

  Future<void> updateMood(MoodEntry entry) async {
    await _mRepository.updateMood(entry);
    await loadMoods();
  }

  Future<void> deleteMood(int id) async {
    await _mRepository.deleteMood(id);
    await loadMoods();
  }

  MoodEntry? getEntryById(int id) {
    final state = _moodsState;
    if (state is Success<List<MoodEntry>>) {
      return state.data.firstWhere(
        (e) => e.id == id, 
        orElse: () => throw Exception('Entry not found'),
      );
    }
    return null;
  }

  Quote? get currentQuote {
    final state = _quoteState;
    if (state is Success<Quote>) {
      return state.data;
    }
    return null;
  }
}