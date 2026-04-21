import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/architecture/view_state.dart';
import '../data/models/mood_entry.dart';
import '../data/repositories/mood_repository.dart';
import 'package:string_similarity/string_similarity.dart';

enum MoodSortOption { newestFirst, oldestFirst, reasonAsc, reasonDesc }

class MoodViewModel with ChangeNotifier {
  final MoodRepository _mRepository;

  ViewState<List<MoodEntry>> _moodsState = const Initial();

  String _searchQuery = '';
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  MoodSortOption _sortOption = MoodSortOption.newestFirst;
  Timer? _searchDebounce;
  bool _isDerivedDirty = true;
  List<MoodEntry> _visibleMoodsCache = const [];
  List<String> _availableCategoriesCache = const [];
  bool _disposed = false;

  ViewState<List<MoodEntry>> get moodsState => _moodsState;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  MoodSortOption get sortOption => _sortOption;

  List<MoodEntry> get _allEntries {
    final state = _moodsState;
    if (state is Success<List<MoodEntry>>) {
      return state.data;
    }
    return const [];
  }

  MoodViewModel({MoodRepository? repository})
    : _mRepository = repository ?? MoodRepository() {
    Future.microtask(loadMoods);
  }

  Future<void> loadMoods() async {
    _moodsState = const Loading();
    if (!_disposed) {
      notifyListeners();
    }

    try {
      final data = await _mRepository.getAllMoods();
      _moodsState = Success(data);
      _markDerivedDirty();
    } catch (e) {
      _moodsState = const Error('Failed to load history');
    }

    if (!_disposed) {
      notifyListeners();
    }
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
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      final next = query.trim().toLowerCase();
      if (_searchQuery == next) return;
      _searchQuery = next;
      _markDerivedDirty();
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  void setSelectedCategory(String? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _markDerivedDirty();
    if (!_disposed) {
      notifyListeners();
    }
  }

  void setDateRange(DateTimeRange? range) {
    if (_selectedDateRange == range) return;
    _selectedDateRange = range;
    _markDerivedDirty();
    if (!_disposed) {
      notifyListeners();
    }
  }

  void setSortOption(MoodSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    _markDerivedDirty();
    if (!_disposed) {
      notifyListeners();
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedDateRange = null;
    _sortOption = MoodSortOption.newestFirst;
    _markDerivedDirty();
    if (!_disposed) {
      notifyListeners();
    }
  }

  List<String> get availableCategories {
    _computeDerivedIfNeeded();
    return _availableCategoriesCache;
  }

  List<MoodEntry> get visibleMoods {
    _computeDerivedIfNeeded();
    return _visibleMoodsCache;
  }

  int get totalEntries {
    return _allEntries.length;
  }

  String get topCategory {
    if (_allEntries.isEmpty) {
      return 'N/A';
    }

    final counts = <String, int>{};
    for (final entry in _allEntries) {
      counts.update(entry.category, (value) => value + 1, ifAbsent: () => 1);
    }

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  int get entriesThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _allEntries
        .where((entry) => entry.dateTime.isAfter(weekStart))
        .length;
  }

  bool get hasTodayEntry {
    final now = DateTime.now();
    return _allEntries.any(
      (entry) =>
          entry.dateTime.year == now.year &&
          entry.dateTime.month == now.month &&
          entry.dateTime.day == now.day,
    );
  }

  int get currentStreakDays {
    if (!hasTodayEntry) return 0;

    final uniqueDays =
        _allEntries
            .map(
              (entry) => DateTime(
                entry.dateTime.year,
                entry.dateTime.month,
                entry.dateTime.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    while (uniqueDays.any((day) => day == cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String get favoriteEmoji {
    if (_allEntries.isEmpty) return '-';

    final counts = <String, int>{};
    for (final entry in _allEntries) {
      counts.update(entry.emoji, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  double get moodBalance {
    if (_allEntries.isEmpty) return 0.5;

    const positive = {
      '\u{1F929}',
      '\u{1F60A}',
      '\u{1F973}',
      '\u{1F970}',
      '\u{1F60E}',
    };
    const negative = {
      '\u{1F622}',
      '\u{1F621}',
      '\u{1F631}',
      '\u{1F630}',
      '\u{1F922}',
    };

    var score = 0.0;
    for (final entry in _allEntries) {
      if (positive.contains(entry.emoji)) {
        score += 1;
      } else if (negative.contains(entry.emoji)) {
        score -= 1;
      }
    }

    final normalized = (score / (_allEntries.length * 2)) + 0.5;
    return normalized.clamp(0.0, 1.0);
  }

  int? get randomEntryId {
    if (_allEntries.isEmpty) return null;
    final randomIndex = Random().nextInt(_allEntries.length);
    return _allEntries[randomIndex].id;
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

        final score = token.similarityTo(query);
        if (score > bestScore) {
          bestScore = score;
        }
      }
    }

    return bestScore >= 0.62;
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

  void _markDerivedDirty() {
    _isDerivedDirty = true;
  }

  void _computeDerivedIfNeeded() {
    if (!_isDerivedDirty) return;

    final state = _moodsState;
    if (state is! Success<List<MoodEntry>>) {
      _visibleMoodsCache = const [];
      _availableCategoriesCache = const [];
      _isDerivedDirty = false;
      return;
    }

    final data = state.data;
    final uniqueCategories = <String>{};
    for (final mood in data) {
      final category = mood.category.trim();
      if (category.isNotEmpty) uniqueCategories.add(category);
    }
    _availableCategoriesCache = uniqueCategories.toList()..sort();

    final filtered = data.where(_matchesFilters).toList();
    filtered.sort((a, b) {
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
    _visibleMoodsCache = filtered;
    _isDerivedDirty = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    super.dispose();
  }
}
