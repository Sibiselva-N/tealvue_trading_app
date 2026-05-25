import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard/dashboard_screen.dart';
import '../data/repositories/market_data_repository.dart';
import '../providers/watchlist_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _status = 'Initializing...';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _status = 'Loading watchlist...');

    // Load watchlist - this will now load from persistent storage
    final watchlistNotifier = ref.read(watchlistProvider.notifier);
    // The watchlist will be loaded automatically when the provider initializes

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _status = 'Connecting to market data...');

    final marketRepo = ref.read(marketDataRepositoryProvider);
    final watchlist = ref.read(watchlistProvider);

    // Wait for socket connection
    int attempts = 0;
    while (!marketRepo.isSocketConnected && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
      setState(() => _status = 'Connecting... (${attempts * 0.5}s)');
    }

    if (marketRepo.isSocketConnected) {
      setState(() => _status = 'Connected! Loading data...');

      if (watchlist.isNotEmpty) {
        marketRepo.subscribeSymbols(watchlist);
      } else {
        const defaultSymbols = ['RELIANCE', 'TCS', 'INFY', 'HDFCBANK', 'ICICIBANK'];
        marketRepo.subscribeSymbols(defaultSymbols);
      }

      await Future.delayed(const Duration(seconds: 1));
    } else {
      setState(() => _status = 'Connection timeout, continuing...');
      await Future.delayed(const Duration(seconds: 1));
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'TealVue Trading',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              _status,
              style: TextStyle(
                fontSize: 14,
                color: _isConnected ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, child) {
                final isConnected = ref.watch(marketDataRepositoryProvider).isSocketConnected;
                if (isConnected != _isConnected) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _isConnected = isConnected);
                  });
                }
                return Text(
                  isConnected ? '🟢 Live data active' : '🟡 Connecting...',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
