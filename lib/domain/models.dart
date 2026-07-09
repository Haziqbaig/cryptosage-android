double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class CoinMarket {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double? price;
  final double? change24h;
  final double? change7d;
  final double? marketCap;
  final double? volume24h;
  final int? rank;
  final List<double> sparkline;

  CoinMarket({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    this.price,
    this.change24h,
    this.change7d,
    this.marketCap,
    this.volume24h,
    this.rank,
    this.sparkline = const [],
  });

  factory CoinMarket.fromJson(Map<String, dynamic> j) => CoinMarket(
        id: j['id'] ?? '',
        symbol: (j['symbol'] ?? '').toString().toUpperCase(),
        name: j['name'] ?? '',
        image: j['image'] ?? '',
        price: _toDouble(j['current_price']),
        change24h: _toDouble(j['price_change_percentage_24h']),
        change7d: _toDouble(j['price_change_percentage_7d_in_currency']),
        marketCap: _toDouble(j['market_cap']),
        volume24h: _toDouble(j['total_volume']),
        rank: j['market_cap_rank'] is num
            ? (j['market_cap_rank'] as num).toInt()
            : null,
        sparkline: j['sparkline_in_7d'] is Map &&
                j['sparkline_in_7d']['price'] is List
            ? (j['sparkline_in_7d']['price'] as List)
                .map((e) => _toDouble(e) ?? 0.0)
                .toList()
            : const [],
      );
}

class GlobalMarket {
  final double? totalMarketCap;
  final double? totalVolume;
  final double? marketCapChange24h;
  final double? btcDominance;

  GlobalMarket({
    this.totalMarketCap,
    this.totalVolume,
    this.marketCapChange24h,
    this.btcDominance,
  });

  factory GlobalMarket.fromJson(Map<String, dynamic> j, String currency) {
    final data = j['data'] as Map<String, dynamic>? ?? {};
    final caps = data['total_market_cap'] as Map<String, dynamic>? ?? {};
    final vols = data['total_volume'] as Map<String, dynamic>? ?? {};
    final doms = data['market_cap_percentage'] as Map<String, dynamic>? ?? {};
    return GlobalMarket(
      totalMarketCap: _toDouble(caps[currency.toLowerCase()]),
      totalVolume: _toDouble(vols[currency.toLowerCase()]),
      marketCapChange24h:
          _toDouble(data['market_cap_change_percentage_24h_usd']),
      btcDominance: _toDouble(doms['btc']),
    );
  }
}

class FearGreed {
  final int value;
  final String classification;

  FearGreed({required this.value, required this.classification});

  factory FearGreed.fromJson(Map<String, dynamic> j) {
    final list = j['data'] as List? ?? [];
    if (list.isEmpty) {
      return FearGreed(value: 50, classification: 'Neutral');
    }
    final first = list.first as Map<String, dynamic>;
    return FearGreed(
      value: int.tryParse(first['value'].toString()) ?? 50,
      classification: first['value_classification']?.toString() ?? 'Neutral',
    );
  }
}

class TrendingCoin {
  final String id;
  final String symbol;
  final String name;
  final String thumb;
  final int? rank;

  TrendingCoin({
    required this.id,
    required this.symbol,
    required this.name,
    required this.thumb,
    this.rank,
  });

  factory TrendingCoin.fromJson(Map<String, dynamic> j) {
    final item = j['item'] as Map<String, dynamic>? ?? j;
    return TrendingCoin(
      id: item['id'] ?? '',
      symbol: (item['symbol'] ?? '').toString().toUpperCase(),
      name: item['name'] ?? '',
      thumb: item['thumb'] ?? '',
      rank: item['market_cap_rank'] is num
          ? (item['market_cap_rank'] as num).toInt()
          : null,
    );
  }
}

class SearchResult {
  final String id;
  final String symbol;
  final String name;
  final String thumb;
  final int? rank;

  SearchResult({
    required this.id,
    required this.symbol,
    required this.name,
    required this.thumb,
    this.rank,
  });

  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
        id: j['id'] ?? '',
        symbol: (j['symbol'] ?? '').toString().toUpperCase(),
        name: j['name'] ?? '',
        thumb: j['thumb'] ?? '',
        rank: j['market_cap_rank'] is num
            ? (j['market_cap_rank'] as num).toInt()
            : null,
      );
}

class CoinDetail {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final String description;
  final double? price;
  final double? change24h;
  final double? change7d;
  final double? change30d;
  final double? marketCap;
  final double? volume24h;
  final double? ath;
  final double? athChange;
  final double? atl;
  final double? atlChange;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final int? rank;

  CoinDetail({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.description,
    this.price,
    this.change24h,
    this.change7d,
    this.change30d,
    this.marketCap,
    this.volume24h,
    this.ath,
    this.athChange,
    this.atl,
    this.atlChange,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.rank,
  });

  factory CoinDetail.fromJson(Map<String, dynamic> j, String currency) {
    final md = j['market_data'] as Map<String, dynamic>? ?? {};
    final c = currency.toLowerCase();
    double? cur(String key) {
      final m = md[key];
      if (m is Map<String, dynamic>) return _toDouble(m[c]);
      return null;
    }

    return CoinDetail(
      id: j['id'] ?? '',
      symbol: (j['symbol'] ?? '').toString().toUpperCase(),
      name: j['name'] ?? '',
      image: j['image'] is Map ? (j['image']['large'] ?? '') : '',
      description: j['description'] is Map
          ? (j['description']['en'] ?? '').toString()
          : '',
      price: cur('current_price'),
      change24h: _toDouble(md['price_change_percentage_24h']),
      change7d: _toDouble(md['price_change_percentage_7d']),
      change30d: _toDouble(md['price_change_percentage_30d']),
      marketCap: cur('market_cap'),
      volume24h: cur('total_volume'),
      ath: cur('ath'),
      athChange: md['ath_change_percentage'] is Map
          ? _toDouble(md['ath_change_percentage'][c])
          : null,
      atl: cur('atl'),
      atlChange: md['atl_change_percentage'] is Map
          ? _toDouble(md['atl_change_percentage'][c])
          : null,
      circulatingSupply: _toDouble(md['circulating_supply']),
      totalSupply: _toDouble(md['total_supply']),
      maxSupply: _toDouble(md['max_supply']),
      rank: j['market_cap_rank'] is num
          ? (j['market_cap_rank'] as num).toInt()
          : null,
    );
  }
}

class PricePoint {
  final DateTime time;
  final double price;
  PricePoint(this.time, this.price);
}

class ChartData {
  final List<PricePoint> points;
  ChartData(this.points);

  factory ChartData.fromJson(Map<String, dynamic> j) {
    final prices = j['prices'] as List? ?? [];
    return ChartData(prices
        .whereType<List>()
        .where((p) => p.length >= 2)
        .map((p) => PricePoint(
              DateTime.fromMillisecondsSinceEpoch((p[0] as num).toInt()),
              (p[1] as num).toDouble(),
            ))
        .toList());
  }

  List<double> get closes => points.map((p) => p.price).toList();
}
