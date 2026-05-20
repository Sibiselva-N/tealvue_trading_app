import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class StorageHelper {
  static const String _watchlistKey = 'watchlist';
  static const String _themeKey = 'theme_mode';

  static Future<void> saveWatchlist(List<String> watchlist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_watchlistKey, watchlist);
    } catch (e) {
      print('Error saving watchlist: $e');
    }
  }

  static List<String> getWatchlist() {
    try {
      // In production, load from SharedPreferences
      // For demo with proper async handling:
      // final prefs = await SharedPreferences.getInstance();
      // return prefs.getStringList(_watchlistKey) ?? ['RELIANCE', 'TCS', 'INFY', 'HDFC', 'ICICIBANK'];

      // For now, return default watchlist (will be loaded async in real app)
      return ['RELIANCE', 'TCS', 'INFY', 'HDFC', 'ICICIBANK'];
    } catch (e) {
      print('Error loading watchlist: $e');
      return ['RELIANCE', 'TCS', 'INFY', 'HDFC', 'ICICIBANK'];
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  static Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt(_themeKey);
      if (index != null && index >= 0 && index <= 2) {
        return ThemeMode.values[index];
      }
    } catch (e) {
      print('Error loading theme: $e');
    }
    return ThemeMode.light;
  }

  // Cache for latest prices
  static Future<void> cacheLatestPrice(String symbol, double price) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cached_price_$symbol', price);
      await prefs.setInt(
        'cached_timestamp_$symbol',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print('Error caching price: $e');
    }
  }

  static Future<double?> getCachedPrice(String symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('cached_timestamp_$symbol');

      // Check if cache is less than 24 hours old
      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age < 86400000) {
          // 24 hours
          return prefs.getDouble('cached_price_$symbol');
        }
      }
    } catch (e) {
      print('Error loading cached price: $e');
    }
    return null;
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('cached_price_') ||
            key.startsWith('cached_timestamp_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
