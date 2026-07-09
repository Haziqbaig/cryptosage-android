import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import 'api_client.dart';

class CryptoRepository {
  final ApiClient api;
  CryptoRepository(this.api);

  static const defaultWatchlist = [
    'bitcoin',
    'ethereum',
    'solana',
    'sui',
    'dogecoin',
    'chainlink',
    'ripple',
    'cardano',
  ];

  Future<GlobalMarket> getGlobal(String currency) async {
    final j = await api.coinGecko('/global',
        cacheTtl: const Duration(minutes: 2));
    return GlobalMarket.fromJson(Map<String, dynamic>.from(j), currency);
  }

  Future<FearGreed> getFearGreed() async {
    final j = await api.fearGreed();
    return FearGreed.fromJson(Map<String, dynamic>.from(j));
  }

  Future<List<TrendingCoin>> getTrending() async {
    final j = await api.coinGecko('/search/trending',
        cacheTtl: const Duration(minutes: 10));
    final coins = (j['coins'] as List? ?? []);
    return coins
        .map((e) => TrendingCoin.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<CoinMarket>> getMarkets(
    String currency, {
    List<String>? ids,
    int perPage = 100,
    bool sparkline = false,
  }) async {
    final j = await api.coinGecko('/coins/markets', query: {
      'vs_currency': currency.toLowerCase(),
      if (ids != null && ids.isNotEmpty) 'ids': ids.join(','),
      'order': 'market_cap_desc',
      'per_page': perPage,
      'page': 1,
      'sparkline': sparkline,
      'price_change_percentage': '24h,7d',
    });
    return (j as List)
        .map((e) => CoinMarket.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CoinDetail> getCoinDetail(String id, String currency) async {
    final j = await api.coinGecko('/coins/$id', query: {
      'localization': false,
      'tickers': false,
      'market_data': true,
      'community_data': false,
      'developer_data': false,
      'sparkline': false,
    });
    return CoinDetail.fromJson(Map<String, dynamic>.from(j), currency);
  }

  Future<ChartData> getChart(String id, String currency, int days) async {
    final j = await api.coinGecko('/coins/$id/market_chart', query: {
      'vs_currency': currency.toLowerCase(),
      'days': days,
      if (days > 30) 'interval': 'daily',
    }, cacheTtl: const Duration(minutes: 5));
    return ChartData.fromJson(Map<String, dynamic>.from(j));
  }

  /// 90d daily closes used by the indicator engine.
  Future<List<double>> getDailyCloses(String id, String currency) async {
    final chart = await getChart(id, currency, 90);
    return chart.closes;
  }

  Future<List<SearchResult>> search(String query) async {
    final j = await api.coinGecko('/search',
        query: {'query': query}, cacheTtl: const Duration(minutes: 10));
    final coins = (j['coins'] as List? ?? []);
    return coins
        .map((e) => SearchResult.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // --- Watchlist persistence ---

  Future<List<String>> loadWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('watchlist');
    if (raw == null) return List.of(defaultWatchlist);
    final list = (jsonDecode(raw) as List).map((e) => e.toString()).toList();
    return list.isEmpty ? List.of(defaultWatchlist) : list;
  }

  Future<void> saveWatchlist(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('watchlist', jsonEncode(ids));
  }
}
