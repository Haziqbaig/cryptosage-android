import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../app_state.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preferences',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.attach_money, color: AppColors.cyan),
                  title: const Text('Currency'),
                  trailing: DropdownButton<String>(
                    value: settings.currency,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'usd', child: Text('USD')),
                      DropdownMenuItem(value: 'eur', child: Text('EUR')),
                      DropdownMenuItem(value: 'pkr', child: Text('PKR')),
                    ],
                    onChanged: (v) {
                      if (v != null) settings.setCurrency(v);
                    },
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary:
                      const Icon(Icons.dark_mode, color: AppColors.violet),
                  title: const Text('Dark mode'),
                  value: settings.darkMode,
                  onChanged: settings.setDarkMode,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.refresh, color: AppColors.green),
                  title: const Text('Auto-refresh interval'),
                  trailing: DropdownButton<int>(
                    value: settings.refreshIntervalSec,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30s')),
                      DropdownMenuItem(value: 60, child: Text('60s')),
                      DropdownMenuItem(value: 120, child: Text('2m')),
                      DropdownMenuItem(value: 300, child: Text('5m')),
                    ],
                    onChanged: (v) {
                      if (v != null) settings.setRefreshInterval(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'CryptoSage AI v1.0.0\n\n'
                  'AI-powered crypto market analysis using technical indicators '
                  '(RSI, MACD, EMA) and market sentiment. Data from CoinGecko '
                  'and Alternative.me free APIs.\n\n'
                  'Not financial advice. Always do your own research.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
