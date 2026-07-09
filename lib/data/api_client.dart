import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP client for CoinGecko + Alternative.me with a lightweight
/// shared_preferences cache to respect free-tier rate limits.
class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
  ));

  static const _cgBase = 'https://api.coingecko.com/api/v3';
  static const _fngUrl = 'https://api.alternative.me/fng/?limit=1';

  Future<dynamic> getJson(
    String url, {
    Map<String, dynamic>? query,
    Duration cacheTtl = const Duration(seconds: 60),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cache:$url:${query?.toString() ?? ''}';
    final tsKey = '$key:ts';
    final cached = prefs.getString(key);
    final ts = prefs.getInt(tsKey) ?? 0;
    final fresh = DateTime.now().millisecondsSinceEpoch - ts <
        cacheTtl.inMilliseconds;

    if (cached != null && fresh) {
      return jsonDecode(cached);
    }
    try {
      final resp = await _dio.get(url, queryParameters: query);
      await prefs.setString(key, jsonEncode(resp.data));
      await prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
      return resp.data;
    } catch (e) {
      // Fall back to stale cache when the network/rate-limit fails.
      if (cached != null) return jsonDecode(cached);
      rethrow;
    }
  }

  Future<dynamic> coinGecko(
    String path, {
    Map<String, dynamic>? query,
    Duration cacheTtl = const Duration(seconds: 60),
  }) =>
      getJson('$_cgBase$path', query: query, cacheTtl: cacheTtl);

  Future<dynamic> fearGreed() =>
      getJson(_fngUrl, cacheTtl: const Duration(minutes: 30));
}
