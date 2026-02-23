import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../services/db_helper.dart';

class MoodProvider with ChangeNotifier {
  List<MoodEntry> _entries = [];
  bool _isLoading = true;

  List<MoodEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  MoodProvider() {
    loadEntries();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    
    _entries = await DBHelper().getEntries();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(MoodEntry entry) async {
    await DBHelper().insertEntry(entry);
    await loadEntries();
  }

  Future<void> updateEntry(MoodEntry entry) async {
    await DBHelper().updateEntry(entry);
    await loadEntries();
  }

  Future<void> deleteEntry(int id) async {
    await DBHelper().deleteEntry(id);
    await loadEntries();
  }
}