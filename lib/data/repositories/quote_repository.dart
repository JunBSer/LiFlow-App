import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote_entry.dart';

class QuoteRepository {
  static const Duration _requestTimeout = Duration(seconds: 8);

  String get _baseUrl {
    try {
      return dotenv.env['QUOTE_API_URL'] ??
          dotenv.env['BASE_QUOTE_URL'] ??
          'https://zenquotes.io/api/random';
    } catch (_) {
      return 'https://zenquotes.io/api/random';
    }
  }

  Future<Quote?> getQuote({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    final String today = DateTime.now().toIso8601String().split('T').first;
    final String? cachedDate = prefs.getString('quote_date');

    if (cachedDate == today && !forceRefresh) {
      return await _loadFromCache(prefs);
    }

    var connectivityResult = await (Connectivity().checkConnectivity());
    bool hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (hasInternet) {
      try {
        final quote = await _fetchFromApi();
        await _saveToCache(prefs, quote, today);
        return quote;
      } catch (e) {
        return await _loadFromCache(prefs);
      }
    } else {
      return await _loadFromCache(prefs);
    }
  }

  Future<Quote> _fetchFromApi() async {
    final response = await http
        .get(Uri.parse(_baseUrl), headers: const {'Accept': 'application/json'})
        .timeout(_requestTimeout);
    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return Quote.fromJson(data.first as Map<String, dynamic>);
      }
      if (data is Map<String, dynamic>) {
        return Quote.fromJson(data);
      }
      throw Exception('Unexpected quote payload');
    }
    throw Exception('Quote API status: ${response.statusCode}');
  }

  Future<void> _saveToCache(
    SharedPreferences prefs,
    Quote quote,
    String date,
  ) async {
    await prefs.setString('cached_quote', jsonEncode(quote.toJson()));
    await prefs.setString('quote_date', date);
  }

  Future<Quote?> _loadFromCache(SharedPreferences prefs) async {
    final String? cachedData = prefs.getString('cached_quote');
    if (cachedData != null) {
      return Quote.fromJson(jsonDecode(cachedData));
    }
    return null;
  }
}
