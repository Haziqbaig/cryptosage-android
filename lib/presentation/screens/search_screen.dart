import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../domain/models.dart';
import '../app_state.dart';
import '../widgets/common.dart';
import 'coin_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool fromWatchlist;
  const SearchScreen({super.key, this.fromWatchlist = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<SearchResult> results = [];
  bool loading = false;
  String? error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => results = []);
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await context.read<CryptoRepository>().search(q.trim());
      setState(() {
        results = r;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Search failed. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search coins (e.g. bitcoin, sol)...',
                prefixIcon: const Icon(Icons.search, color: AppColors.cyan),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(error!,
                  style: const TextStyle(color: AppColors.red)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) {
                final r = results[i];
                final inList = watchlist.contains(r.id);
                return ListTile(
                  leading: CoinIcon(url: r.thumb, symbol: r.symbol),
                  title: Text(r.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    r.rank != null ? '${r.symbol} · #${r.rank}' : r.symbol,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      inList
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: inList ? AppColors.green : AppColors.cyan,
                    ),
                    onPressed: () {
                      if (inList) {
                        watchlist.remove(r.id);
                      } else {
                        watchlist.add(r.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('${r.name} added to watchlist')),
                        );
                      }
                    },
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          CoinDetailScreen(coinId: r.id, name: r.name))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
