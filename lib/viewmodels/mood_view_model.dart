import 'package:flutter/material.dart';

import '../core/architecture/view_state.dart';
import '../data/models/mood_entry.dart';
import '../data/models/quote_entry.dart';
import '../data/repositories/mood_repository.dart';
import '../data/repositories/quote_repository.dart';

enum MoodSortOption { newestFirst, oldestFirst, reasonAsc, reasonDesc }

class MoodViewModel with ChangeNotifier {
  final QuoteRepository _qRepository = QuoteRepository();
  final MoodRepository _mRepository = MoodRepository();

  ViewState<List<MoodEntry>> _moodsState = const Initial();
  ViewState<Quote> _quoteState = const Initial();

  String _searchQuery = '';
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  MoodSortOption _sortOption = MoodSortOption.newestFirst;

  ViewState<List<MoodEntry>> get moodsState => _moodsState;
  ViewState<Quote> get quoteState => _quoteState;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  MoodSortOption get sortOption => _sortOption;

  MoodViewModel() {
    refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([loadMoods(), loadQuote()]);
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
        _quoteState = Success(
          Quote(text: 'No quote available', author: 'System'),
        );
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
      _moodsState = const Error('Failed to load history');
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

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  void setSortOption(MoodSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedDateRange = null;
    _sortOption = MoodSortOption.newestFirst;
    notifyListeners();
  }

  List<String> get availableCategories {
    final state = _moodsState;
    if (state is! Success<List<MoodEntry>>) return const [];

    final unique = <String>{};
    for (final mood in state.data) {
      if (mood.category.trim().isNotEmpty) {
        unique.add(mood.category.trim());
      }
    }

    final sorted = unique.toList()..sort();
    return sorted;
  }

  List<MoodEntry> get visibleMoods {
    final state = _moodsState;
    if (state is! Success<List<MoodEntry>>) return const [];

    final result = state.data.where(_matchesFilters).toList();

    result.sort((a, b) {
      switch (_sortOption) {
        case MoodSortOption.newestFirst:
          return b.dateTime.compareTo(a.dateTime);
        case MoodSortOption.oldestFirst:
          return a.dateTime.compareTo(b.dateTime);
        case MoodSortOption.reasonAsc:
          return a.reason.toLowerCase().compareTo(b.reason.toLowerCase());
        case MoodSortOption.reasonDesc:
          return b.reason.toLowerCase().compareTo(a.reason.toLowerCase());
      }
    });

    return result;
  }

  int get totalEntries {
    final state = _moodsState;
    if (state is! Success<List<MoodEntry>>) return 0;
    return state.data.length;
  }

  String get topCategory {
    final state = _moodsState;
    if (state is! Success<List<MoodEntry>> || state.data.isEmpty) {
      return 'N/A';
    }

    final counts = <String, int>{};
    for (final entry in state.data) {
      counts.update(entry.category, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  int get entriesThisWeek {
    final state = _moodsState;
    if (state is! Success<List<MoodEntry>>) return 0;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return state.data.where((entry) => entry.dateTime.isAfter(weekStart)).length;
  }

  bool _matchesFilters(MoodEntry entry) {
    final categoryMatch =
        _selectedCategory == null || entry.category == _selectedCategory;

    final dateMatch =
        _selectedDateRange == null ||
        (entry.dateTime.isAfter(
              _selectedDateRange!.start.subtract(const Duration(seconds: 1)),
            ) &&
            entry.dateTime.isBefore(
              _selectedDateRange!.end.add(const Duration(days: 1)),
            ));

    final queryMatch =
        _searchQuery.isEmpty || _matchesQuery(entry, _searchQuery);

    return categoryMatch && dateMatch && queryMatch;
  }

  bool _matchesQuery(MoodEntry entry, String query) {
    final fields = <String>[
      entry.reason,
      entry.category,
      ...entry.keywords,
    ].map((e) => e.toLowerCase()).toList();

    if (fields.any((field) => field.contains(query))) {
      return true;
    }

    var bestScore = 0.0;
    for (final field in fields) {
      for (final token in field.split(RegExp(r'\s+'))) {
        if (token.isEmpty) continue;
        final distance = _levenshteinDistance(token, query);
        final maxLen = token.length > query.length
            ? token.length
            : query.length;
        final score = 1.0 - (distance / maxLen);
        if (score > bestScore) {
          bestScore = score;
        }
      }
    }

    return bestScore >= 0.62;
  }

  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final previous = List<int>.generate(t.length + 1, (i) => i);
    final current = List<int>.filled(t.length + 1, 0);

    for (var i = 1; i <= s.length; i++) {
      current[0] = i;

      for (var j = 1; j <= t.length; j++) {
        final cost = s.codeUnitAt(i - 1) == t.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;

        current[j] = deletion < insertion
            ? (deletion < substitution ? deletion : substitution)
            : (insertion < substitution ? insertion : substitution);
      }

      for (var j = 0; j <= t.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[t.length];
  }

  MoodEntry? getEntryById(int id) {
    final state = _moodsState;
    if (state is Success<List<MoodEntry>>) {
      for (final entry in state.data) {
        if (entry.id == id) return entry;
      }
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
