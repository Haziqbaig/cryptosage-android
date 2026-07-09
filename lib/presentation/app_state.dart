import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repository.dart';
import '../domain/indicators.dart';
import '../domain/models.dart';
import '../domain/recommendation.dart';

class SettingsState extends ChangeNotifier {
  String currency = 'usd';
  bool darkMode = true;
  int refreshIntervalSec = 60;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    currency = prefs.getString('currency') ?? 'usd';
    darkMode = prefs.getBool('darkMode') ?? true;
    refreshIntervalSec = prefs.getInt('refreshInterval') ?? 60;
    notifyListeners();
  }

  Future<void> setCurrency(String c) async {
    currency = c;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', c);
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    darkMode = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', v);
    notifyListeners();
  }

  Future<void> setRefreshInterval(int sec) async {
    refreshIntervalSec = sec;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refreshInterval', sec);
    notifyListeners();
  }
}

class DashboardState extends ChangeNotifier {
  final CryptoRepository repo;
  final SettingsState settings;

  DashboardState(this.repo, this.settings);

  bool loading = true;
  String? error;
  GlobalMarket? global;
  FearGreed? fearGreed;
  List<TrendingCoin> trending = [];
  List<CoinMarket> topCoins = [];
  Timer? _timer;

  List<CoinMarket> get gainers {
    final list = topCoins.where((c) => c.change24h != null).toList()
      ..sort((a, b) => b.change24h!.compareTo(a.change24h!));
    return list.take(5).toList();
  }

  List<CoinMarket> get losers {
    final list = topCoins.where((c) => c.change24h != null).toList()
      ..sort((a, b) => a.change24h!.compareTo(b.change24h!));
    return list.take(5).toList();
  }

  void startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: settings.refreshIntervalSec),
      (_) => load(silent: true),
    );
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final results = await Future.wait([
        repo.getGlobal(settings.currency),
        repo.getFearGreed(),
        repo.getTrending(),
        repo.getMarkets(settings.currency, perPage: 100),
      ]);
      global = results[0] as GlobalMarket;
      fearGreed = results[1] as FearGreed;
      trending = results[2] as List<TrendingCoin>;
      topCoins = results[3] as List<CoinMarket>;
      error = null;
    } catch (e) {
      if (global == null) error = 'Failed to load market data. Tap to retry.';
    }
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class WatchlistEntry {
  final CoinMarket coin;
  final double? rsi;
  final MacdResult? macd;
  final Recommendation? recommendation;

  WatchlistEntry(this.coin, {this.rsi, this.macd, this.recommendation});
}

class WatchlistState extends ChangeNotifier {
  final CryptoRepository repo;
  final SettingsState settings;

  WatchlistState(this.repo, this.settings);

  bool loading = true;
  String? error;
  List<String> ids = [];
  List<WatchlistEntry> entries = [];
  int? _fearGreed;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      ids = await repo.loadWatchlist();
      final fng = await repo.getFearGreed();
      _fearGreed = fng.value;
      final markets =
          await repo.getMarkets(settings.currency, ids: ids, sparkline: true);
      final newEntries = <WatchlistEntry>[];
      for (final coin in markets) {
        double? rsi;
        MacdResult? macd;
        Recommendation? rec;
        try {
          final closes =
              await repo.getDailyCloses(coin.id, settings.currency);
          rsi = Indicators.rsi(closes);
          macd = Indicators.macd(closes);
          rec = RecommendationEngine.analyze(
            dailyCloses: closes,
            change24h: coin.change24h,
            change7d: coin.change7d,
            fearGreed: _fearGreed,
          );
        } catch (_) {
          // Indicator data optional; keep the row with market data only.
        }
        newEntries.add(
            WatchlistEntry(coin, rsi: rsi, macd: macd, recommendation: rec));
        notifyListenersSafely(newEntries, markets.length);
      }
      entries = newEntries;
      error = null;
    } catch (e) {
      if (entries.isEmpty) {
        error = 'Failed to load watchlist. Tap to retry.';
      }
    }
    loading = false;
    notifyListeners();
  }

  void notifyListenersSafely(List<WatchlistEntry> partial, int total) {
    entries = List.of(partial);
    loading = partial.length < total && partial.length < 3;
    notifyListeners();
  }

  Future<void> add(String id) async {
    if (ids.contains(id)) return;
    ids.add(id);
    await repo.saveWatchlist(ids);
    await load(silent: true);
  }

  Future<void> remove(String id) async {
    ids.remove(id);
    entries.removeWhere((e) => e.coin.id == id);
    await repo.saveWatchlist(ids);
    notifyListeners();
  }

  bool contains(String id) => ids.contains(id);
}
