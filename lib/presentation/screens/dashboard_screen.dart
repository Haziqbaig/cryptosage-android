import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';
import 'coin_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<DashboardState>();
      state.load();
      state.startAutoRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final settings = context.watch<SettingsState>();
    final currency = settings.currency;

    return Scaffold(
      appBar: AppBar(title: const Text('CryptoSage AI')),
      body: RefreshIndicator(
        onRefresh: () => state.load(silent: true),
        child: state.loading && state.global == null
            ? _skeleton()
            : state.error != null && state.global == null
                ? ErrorRetry(message: state.error!, onRetry: state.load)
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _marketOverview(state, currency),
                      const SizedBox(height: 16),
                      _fearGreedCard(state),
                      const SizedBox(height: 16),
                      _moversRow(state, currency),
                      const SizedBox(height: 16),
                      _trendingCard(state),
                      const SizedBox(height: 32),
                    ],
                  ),
      ),
    );
  }

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonBox(height: 110),
          SizedBox(height: 16),
          SkeletonBox(height: 160),
          SizedBox(height: 16),
          SkeletonBox(height: 220),
          SizedBox(height: 16),
          SkeletonBox(height: 180),
        ],
      );

  Widget _marketOverview(DashboardState state, String currency) {
    final g = state.global;
    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Market Cap',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(formatCompact(g?.totalMarketCap, currency),
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                ChangeText(g?.marketCapChange24h),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('BTC Dominance',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                g?.btcDominance != null
                    ? '${g!.btcDominance!.toStringAsFixed(1)}%'
                    : '—',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cyan),
              ),
              const SizedBox(height: 4),
              Text('Vol ${formatCompact(g?.totalVolume, currency)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fearGreedCard(DashboardState state) {
    final fg = state.fearGreed;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fear & Greed Index',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 70,
                child: CustomPaint(
                  painter: _GaugePainter(fg?.value ?? 50),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${fg?.value ?? '—'}',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  Text(fg?.classification ?? '',
                      style: TextStyle(
                          color: _fgColor(fg?.value ?? 50),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _fgColor(int v) {
    if (v <= 25) return AppColors.red;
    if (v <= 45) return const Color(0xFFFB923C);
    if (v <= 55) return AppColors.yellow;
    if (v <= 75) return const Color(0xFF6EE7B7);
    return AppColors.green;
  }

  Widget _moversRow(DashboardState state, String currency) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: _moversCard('Top Gainers', state.gainers, currency, true)),
        const SizedBox(width: 12),
        Expanded(
            child: _moversCard('Top Losers', state.losers, currency, false)),
      ],
    );
  }

  Widget _moversCard(
      String title, List coins, String currency, bool gainers) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(gainers ? Icons.trending_up : Icons.trending_down,
                  size: 16, color: gainers ? AppColors.green : AppColors.red),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ...coins.map((c) => InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        CoinDetailScreen(coinId: c.id, name: c.name))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(c.symbol,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      ChangeText(c.change24h, fontSize: 12),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _trendingCard(DashboardState state) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.violet, size: 20),
              const SizedBox(width: 8),
              Text('Trending', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          ...state.trending.take(7).map((t) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CoinIcon(url: t.thumb, symbol: t.symbol, size: 30),
                title: Text(t.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(t.symbol,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                trailing: t.rank != null
                    ? Text('#${t.rank}',
                        style: const TextStyle(color: AppColors.cyan))
                    : null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        CoinDetailScreen(coinId: t.id, name: t.name))),
              )),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int value;
  _GaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - 4;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi,
        math.pi, false, bg);

    final sweep = math.pi * (value.clamp(0, 100) / 100);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppColors.red, AppColors.yellow, AppColors.green],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi,
        sweep, false, fg);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}
