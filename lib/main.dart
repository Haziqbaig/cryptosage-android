import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/api_client.dart';
import 'data/repository.dart';
import 'presentation/app_state.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/watchlist_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CryptoSageApp());
}

class CryptoSageApp extends StatelessWidget {
  const CryptoSageApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CryptoRepository(ApiClient());
    return MultiProvider(
      providers: [
        Provider<CryptoRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => SettingsState()..load()),
        ChangeNotifierProxyProvider<SettingsState, DashboardState>(
          create: (ctx) => DashboardState(repo, ctx.read<SettingsState>()),
          update: (_, settings, prev) => prev ?? DashboardState(repo, settings),
        ),
        ChangeNotifierProxyProvider<SettingsState, WatchlistState>(
          create: (ctx) => WatchlistState(repo, ctx.read<SettingsState>()),
          update: (_, settings, prev) => prev ?? WatchlistState(repo, settings),
        ),
      ],
      child: Consumer<SettingsState>(
        builder: (context, settings, _) => MaterialApp(
          title: 'CryptoSage AI',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeShell(),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    WatchlistScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.cyan.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.cyan),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.star_border),
              selectedIcon: Icon(Icons.star, color: AppColors.cyan),
              label: 'Watchlist'),
          NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.search, color: AppColors.cyan),
              label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.cyan),
              label: 'Settings'),
        ],
      ),
    );
  }
}
