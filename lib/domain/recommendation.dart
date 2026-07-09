import 'indicators.dart';

enum Rating { strongBuy, buy, hold, sell, strongSell }

extension RatingX on Rating {
  String get label {
    switch (this) {
      case Rating.strongBuy:
        return 'Strong Buy';
      case Rating.buy:
        return 'Buy';
      case Rating.hold:
        return 'Hold';
      case Rating.sell:
        return 'Sell';
      case Rating.strongSell:
        return 'Strong Sell';
    }
  }
}

class Recommendation {
  final Rating rating;
  final int confidence; // 0-100
  final List<String> reasons;
  final String risk; // Low / Medium / High
  final double? target;
  final double? stopLoss;
  final double? rsi;
  final MacdResult? macd;
  final double? ema20;
  final double? ema50;
  final double? ema200;

  Recommendation({
    required this.rating,
    required this.confidence,
    required this.reasons,
    required this.risk,
    this.target,
    this.stopLoss,
    this.rsi,
    this.macd,
    this.ema20,
    this.ema50,
    this.ema200,
  });
}

/// Rule-based scoring engine: RSI + MACD + EMA alignment + momentum + Fear&Greed.
class RecommendationEngine {
  static Recommendation analyze({
    required List<double> dailyCloses,
    double? change24h,
    double? change7d,
    int? fearGreed,
  }) {
    final reasons = <String>[];
    double score = 0;
    int signals = 0;

    final rsi = Indicators.rsi(dailyCloses);
    final macd = Indicators.macd(dailyCloses);
    final ema20 = Indicators.ema(dailyCloses, 20);
    final ema50 = Indicators.ema(dailyCloses, 50);
    final ema200 =
        dailyCloses.length >= 200 ? Indicators.ema(dailyCloses, 200) : null;
    final price = dailyCloses.isNotEmpty ? dailyCloses.last : null;
    final sr = Indicators.supportResistance(dailyCloses);

    // RSI
    if (rsi != null) {
      signals++;
      if (rsi < 30) {
        score += 2;
        reasons.add('RSI ${rsi.toStringAsFixed(0)} — oversold, potential bounce');
      } else if (rsi < 45) {
        score += 1;
        reasons.add('RSI ${rsi.toStringAsFixed(0)} — approaching oversold territory');
      } else if (rsi > 70) {
        score -= 2;
        reasons.add('RSI ${rsi.toStringAsFixed(0)} — overbought, pullback risk');
      } else if (rsi > 60) {
        score -= 1;
        reasons.add('RSI ${rsi.toStringAsFixed(0)} — elevated momentum, watch for exhaustion');
      } else {
        reasons.add('RSI ${rsi.toStringAsFixed(0)} — neutral zone');
      }
    }

    // MACD
    if (macd != null) {
      signals++;
      if (macd.bullishCross) {
        score += 2;
        reasons.add('MACD bullish crossover — momentum turning up');
      } else if (macd.bearishCross) {
        score -= 2;
        reasons.add('MACD bearish crossover — momentum turning down');
      } else if (macd.histogram > 0) {
        score += 1;
        reasons.add('MACD histogram positive — bullish momentum intact');
      } else {
        score -= 1;
        reasons.add('MACD histogram negative — bearish momentum intact');
      }
    }

    // EMA alignment
    if (price != null && ema20 != null && ema50 != null) {
      signals++;
      final above20 = price > ema20;
      final above50 = price > ema50;
      final above200 = ema200 == null || price > ema200;
      if (above20 && above50 && above200) {
        score += 2;
        reasons.add('Price above key EMAs — strong uptrend structure');
      } else if (!above20 && !above50 && !above200) {
        score -= 2;
        reasons.add('Price below key EMAs — downtrend structure');
      } else if (above50) {
        score += 1;
        reasons.add('Price above EMA50 — medium-term trend positive');
      } else {
        score -= 1;
        reasons.add('Price below EMA50 — medium-term trend weak');
      }
    }

    // Momentum
    if (change7d != null) {
      signals++;
      if (change7d > 10) {
        score += 1;
        reasons.add('Strong 7d momentum (${change7d.toStringAsFixed(1)}%)');
      } else if (change7d < -10) {
        score -= 1;
        reasons.add('Weak 7d momentum (${change7d.toStringAsFixed(1)}%)');
      }
    }

    // Fear & Greed (contrarian tilt)
    if (fearGreed != null) {
      signals++;
      if (fearGreed <= 25) {
        score += 1;
        reasons.add('Extreme Fear ($fearGreed) — contrarian buy zone');
      } else if (fearGreed >= 75) {
        score -= 1;
        reasons.add('Extreme Greed ($fearGreed) — market may be overheated');
      }
    }

    // Map score to rating
    Rating rating;
    if (score >= 4) {
      rating = Rating.strongBuy;
    } else if (score >= 2) {
      rating = Rating.buy;
    } else if (score <= -4) {
      rating = Rating.strongSell;
    } else if (score <= -2) {
      rating = Rating.sell;
    } else {
      rating = Rating.hold;
    }

    final maxScore = signals * 2.0;
    final confidence = maxScore > 0
        ? (50 + (score.abs() / maxScore) * 45).clamp(50, 95).round()
        : 50;

    // Volatility-based risk from daily returns
    String risk = 'Medium';
    if (dailyCloses.length > 15) {
      final returns = <double>[];
      for (int i = dailyCloses.length - 14; i < dailyCloses.length; i++) {
        returns.add(
            (dailyCloses[i] - dailyCloses[i - 1]) / dailyCloses[i - 1] * 100);
      }
      final mean = returns.reduce((a, b) => a + b) / returns.length;
      double variance = 0;
      for (final r in returns) {
        variance += (r - mean) * (r - mean);
      }
      variance /= returns.length;
      final vol = variance > 0 ? _sqrt(variance) : 0.0;
      risk = vol < 2.5 ? 'Low' : (vol < 5.5 ? 'Medium' : 'High');
    }

    return Recommendation(
      rating: rating,
      confidence: confidence,
      reasons: reasons,
      risk: risk,
      target: sr.resistance,
      stopLoss: sr.support,
      rsi: rsi,
      macd: macd,
      ema20: ema20,
      ema50: ema50,
      ema200: ema200,
    );
  }

  static double _sqrt(double v) {
    double x = v, y = 1;
    const e = 0.000001;
    while (x - y > e) {
      x = (x + y) / 2;
      y = v / x;
    }
    return x;
  }
}
