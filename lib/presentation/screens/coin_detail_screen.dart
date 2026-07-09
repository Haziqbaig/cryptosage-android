import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../domain/models.dart';
import '../../domain/recommendation.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class CoinDetailScreen extends StatefulWidget {
  final String coinId;
  final String name;
  const CoinDetailScreen(
      {super.key, required this.coinId, required this.name});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  CoinDetail? detail;
  ChartData? chart;
  Recommendation? rec;
  bool loading = true;
  String? error;
  int rangeDays = 7;

  static const ranges = {'24H': 1, '7D': 7, '30D': 30, '90D': 90};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final repo = context.read<CryptoRepository>();
    final settings = context.read<SettingsState>();
    try {
      final results = await Future.wait([
        repo.getCoinDetail(widget.coinId, settings.currency),
        repo.getChart(widget.coinId, settings.currency, rangeDays),
        repo.getDailyCloses(widget.coinId, settings.currency),
        repo.getFearGreed(),
      ]);
      final d = results[0] as CoinDetail;
      final closes = results[2] as List<double>;
      final fng = results[3] as FearGreed;
      setState(() {
        detail = d;
        chart = results[1] as ChartData;
        rec = RecommendationEngine.analyze(
          dailyCloses: closes,
          change24h: d.change24h,
          change7d: d.change7d,
          fearGreed: fng.value,
        );
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        if (detail == null) error = 'Failed to load coin data.';
      });
    }
  }

  Future<void> _changeRange(int days) async {
    setState(() => rangeDays = days);
    final repo = context.read<CryptoRepository>();
    final settings = context.read<SettingsState>();
    try {
      final c = await repo.getChart(widget.coinId, settings.currency, days);
      setState(() => chart = c);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final currency = settings.currency;

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: loading && detail == null
          ? ListView(padding: const EdgeInsets.all(16), children: const [
              SkeletonBox(height: 100),
              SizedBox(height: 16),
              SkeletonBox(height: 260),
              SizedBox(height: 16),
              SkeletonBox(height: 200),
            ])
          : error != null
              ? ErrorRetry(message: error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _header(currency),
                      const SizedBox(height: 16),
                      _chartCard(currency),
                      const SizedBox(height: 16),
                      if (rec != null) _recommendationCard(currency),
                      const SizedBox(height: 16),
                      if (rec != null) _indicatorsCard(currency),
                      const SizedBox(height: 16),
                      _statsCard(currency),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _header(String currency) {
    final d = detail!;
    return GlassCard(
      child: Row(
        children: [
          CoinIcon(url: d.image, symbol: d.symbol, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d.name} (${d.symbol})',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                if (d.rank != null)
                  Text('Rank #${d.rank}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatPrice(d.price, currency),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              ChangeText(d.change24h),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartCard(String currency) {
    final points = chart?.points ?? [];
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].price));
    }
    final positive =
        spots.length > 1 && spots.last.y >= spots.first.y;
    final color = positive ? AppColors.green : AppColors.red;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Price Chart',
                  style: Theme.of(context).textTheme.titleLarge),
              Wrap(
                spacing: 4,
                children: ranges.entries
                    .map((e) => GestureDetector(
                          onTap: () => _changeRange(e.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: rangeDays == e.value
                                  ? AppColors.cyan.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(e.key,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: rangeDays == e.value
                                        ? AppColors.cyan
                                        : AppColors.textSecondary)),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: spots.length < 2
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                            color: Colors.white.withOpacity(0.05),
                            strokeWidth: 1),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touched) => touched
                              .map((t) => LineTooltipItem(
                                    formatPrice(t.y, currency),
                                    const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600),
                                  ))
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.15,
                          color: color,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color.withOpacity(0.25),
                                color.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _recommendationCard(String currency) {
    final r = rec!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.violet),
              const SizedBox(width: 8),
              Text('AI Recommendation',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              RatingBadge(r.rating),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _pill('Confidence', '${r.confidence}%', AppColors.cyan),
              const SizedBox(width: 8),
              _pill('Risk', r.risk,
                  r.risk == 'Low'
                      ? AppColors.green
                      : (r.risk == 'High' ? AppColors.red : AppColors.yellow)),
            ],
          ),
          const SizedBox(height: 12),
          if (r.target != null)
            _kv('Target (resistance)', formatPrice(r.target, currency)),
          if (r.stopLoss != null)
            _kv('Stop loss (support)', formatPrice(r.stopLoss, currency)),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          ...r.reasons.map((reason) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: AppColors.cyan)),
                    Expanded(
                        child: Text(reason,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary))),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          const Text(
            'Not financial advice. Educational analysis only.',
            style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('$label: $value',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _indicatorsCard(String currency) {
    final r = rec!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Technical Indicators',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _kv('RSI (14)',
              r.rsi != null ? r.rsi!.toStringAsFixed(1) : '—'),
          _kv('MACD', r.macd?.status ?? '—'),
          _kv('EMA 20', formatPrice(r.ema20, currency)),
          _kv('EMA 50', formatPrice(r.ema50, currency)),
          _kv('EMA 200',
              r.ema200 != null ? formatPrice(r.ema200, currency) : 'N/A'),
        ],
      ),
    );
  }

  Widget _statsCard(String currency) {
    final d = detail!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _kv('Market Cap', formatCompact(d.marketCap, currency)),
          _kv('24h Volume', formatCompact(d.volume24h, currency)),
          _kv('All-Time High',
              '${formatPrice(d.ath, currency)} (${formatPercent(d.athChange)})'),
          _kv('All-Time Low',
              '${formatPrice(d.atl, currency)} (${formatPercent(d.atlChange)})'),
          _kv('Circulating Supply', formatSupply(d.circulatingSupply)),
          _kv('Total Supply', formatSupply(d.totalSupply)),
          _kv('Max Supply',
              d.maxSupply != null ? formatSupply(d.maxSupply) : '∞'),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            Text(v,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}
