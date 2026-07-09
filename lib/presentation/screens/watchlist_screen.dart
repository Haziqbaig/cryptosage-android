import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';
import 'coin_detail_screen.dart';
import 'search_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchlistState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WatchlistState>();
    final settings = context.watch<SettingsState>();
    final currency = settings.currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.cyan),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const SearchScreen(fromWatchlist: true)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => state.load(silent: true),
        child: state.loading && state.entries.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(
                    6,
                    (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: SkeletonBox(height: 92),
                        )),
              )
            : state.error != null && state.entries.isEmpty
                ? ErrorRetry(message: state.error!, onRetry: state.load)
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: state.entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _row(state.entries[i], state, currency),
                  ),
      ),
    );
  }

  Widget _row(WatchlistEntry entry, WatchlistState state, String currency) {
    final c = entry.coin;
    return Dismissible(
      key: ValueKey(c.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => state.remove(c.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CoinDetailScreen(coinId: c.id, name: c.name))),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CoinIcon(url: c.image, symbol: c.symbol),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(c.symbol,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          if (entry.recommendation != null)
                            RatingBadge(entry.recommendation!.rating,
                                compact: true),
                        ],
                      ),
                      Text(
                        'MCap ${formatCompact(c.marketCap, currency)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatPrice(c.price, currency),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Row(
                      children: [
                        ChangeText(c.change24h, fontSize: 12),
                        const SizedBox(width: 8),
                        const Text('7d ',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        ChangeText(c.change7d, fontSize: 12),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip(
                    'RSI ${entry.rsi != null ? entry.rsi!.toStringAsFixed(0) : '—'}',
                    _rsiColor(entry.rsi)),
                const SizedBox(width: 8),
                _chip(entry.macd?.status ?? 'MACD —',
                    entry.macd == null
                        ? AppColors.textSecondary
                        : (entry.macd!.histogram > 0
                            ? AppColors.green
                            : AppColors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _rsiColor(double? rsi) {
    if (rsi == null) return AppColors.textSecondary;
    if (rsi < 30) return AppColors.green;
    if (rsi > 70) return AppColors.red;
    return AppColors.cyan;
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}
