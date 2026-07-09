import 'package:intl/intl.dart';

String currencySymbol(String currency) {
  switch (currency.toLowerCase()) {
    case 'eur':
      return '€';
    case 'pkr':
      return '₨';
    default:
      return '\$';
  }
}

String formatPrice(double? v, String currency) {
  if (v == null) return '—';
  final sym = currencySymbol(currency);
  if (v >= 1000) {
    return '$sym${NumberFormat('#,##0').format(v)}';
  } else if (v >= 1) {
    return '$sym${v.toStringAsFixed(2)}';
  } else if (v >= 0.01) {
    return '$sym${v.toStringAsFixed(4)}';
  }
  return '$sym${v.toStringAsFixed(6)}';
}

String formatCompact(double? v, String currency) {
  if (v == null) return '—';
  final sym = currencySymbol(currency);
  if (v >= 1e12) return '$sym${(v / 1e12).toStringAsFixed(2)}T';
  if (v >= 1e9) return '$sym${(v / 1e9).toStringAsFixed(2)}B';
  if (v >= 1e6) return '$sym${(v / 1e6).toStringAsFixed(2)}M';
  if (v >= 1e3) return '$sym${(v / 1e3).toStringAsFixed(1)}K';
  return '$sym${v.toStringAsFixed(2)}';
}

String formatPercent(double? v) {
  if (v == null) return '—';
  final sign = v >= 0 ? '+' : '';
  return '$sign${v.toStringAsFixed(2)}%';
}

String formatSupply(double? v) {
  if (v == null) return '—';
  if (v >= 1e12) return '${(v / 1e12).toStringAsFixed(2)}T';
  if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
  return NumberFormat('#,##0').format(v);
}
