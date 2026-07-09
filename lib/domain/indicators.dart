import 'dart:math';

/// Pure-Dart technical indicator engine.
class Indicators {
  /// RSI(14) using Wilder's smoothing. Returns null if not enough data.
  static double? rsi(List<double> closes, {int period = 14}) {
    if (closes.length < period + 1) return null;
    double avgGain = 0, avgLoss = 0;
    for (int i = 1; i <= period; i++) {
      final diff = closes[i] - closes[i - 1];
      if (diff > 0) {
        avgGain += diff;
      } else {
        avgLoss -= diff;
      }
    }
    avgGain /= period;
    avgLoss /= period;
    for (int i = period + 1; i < closes.length; i++) {
      final diff = closes[i] - closes[i - 1];
      final gain = diff > 0 ? diff : 0.0;
      final loss = diff < 0 ? -diff : 0.0;
      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;
    }
    if (avgLoss == 0) return 100;
    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  /// EMA series for a given period.
  static List<double> emaSeries(List<double> closes, int period) {
    if (closes.isEmpty) return [];
    final k = 2 / (period + 1);
    final out = <double>[closes.first];
    for (int i = 1; i < closes.length; i++) {
      out.add(closes[i] * k + out[i - 1] * (1 - k));
    }
    return out;
  }

  /// Latest EMA value, or null if insufficient data.
  static double? ema(List<double> closes, int period) {
    if (closes.length < period) return null;
    return emaSeries(closes, period).last;
  }

  /// MACD(12,26,9): returns (macd, signal, histogram) or null.
  static MacdResult? macd(List<double> closes) {
    if (closes.length < 35) return null;
    final ema12 = emaSeries(closes, 12);
    final ema26 = emaSeries(closes, 26);
    final macdLine = List<double>.generate(
        closes.length, (i) => ema12[i] - ema26[i]);
    final signal = emaSeries(macdLine, 9);
    final hist = macdLine.last - signal.last;
    final prevHist =
        macdLine[macdLine.length - 2] - signal[signal.length - 2];
    return MacdResult(
      macd: macdLine.last,
      signal: signal.last,
      histogram: hist,
      bullishCross: prevHist <= 0 && hist > 0,
      bearishCross: prevHist >= 0 && hist < 0,
    );
  }

  /// Simple support/resistance from local extrema of daily closes.
  static SupportResistance supportResistance(List<double> closes) {
    if (closes.length < 10) {
      return SupportResistance(support: null, resistance: null);
    }
    final last = closes.last;
    final lows = <double>[];
    final highs = <double>[];
    for (int i = 2; i < closes.length - 2; i++) {
      final c = closes[i];
      if (c < closes[i - 1] &&
          c < closes[i - 2] &&
          c < closes[i + 1] &&
          c < closes[i + 2]) {
        lows.add(c);
      }
      if (c > closes[i - 1] &&
          c > closes[i - 2] &&
          c > closes[i + 1] &&
          c > closes[i + 2]) {
        highs.add(c);
      }
    }
    final supports = lows.where((l) => l < last).toList()..sort();
    final resistances = highs.where((h) => h > last).toList()..sort();
    return SupportResistance(
      support: supports.isNotEmpty
          ? supports.last
          : closes.reduce(min),
      resistance: resistances.isNotEmpty
          ? resistances.first
          : closes.reduce(max),
    );
  }
}

class MacdResult {
  final double macd;
  final double signal;
  final double histogram;
  final bool bullishCross;
  final bool bearishCross;

  MacdResult({
    required this.macd,
    required this.signal,
    required this.histogram,
    required this.bullishCross,
    required this.bearishCross,
  });

  String get status {
    if (bullishCross) return 'Bullish Cross';
    if (bearishCross) return 'Bearish Cross';
    return histogram > 0 ? 'Bullish' : 'Bearish';
  }
}

class SupportResistance {
  final double? support;
  final double? resistance;
  SupportResistance({this.support, this.resistance});
}
