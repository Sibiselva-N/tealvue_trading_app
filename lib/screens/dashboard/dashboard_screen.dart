import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/holding.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/ticker_provider.dart';
import '../../core/utils/number_formatter.dart';
import '../watchlist/watchlist_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../about/about_screen.dart';
import '../symbol_detail/symbol_detail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  bool _demoDataInitialized = false;

  final List<Widget> _screens = const [
    DashboardContent(),
    WatchlistScreen(),
    PortfolioScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final dio = Dio();
          try {
            print('\n=== DEBUGGING API ===');
            print('\n1. Testing Symbols API:');
            final symbolsResp = await dio.get('https://mock-data.tealvue.in/api/v1/symbols');
            print('Symbols response: ${symbolsResp.data}');

            print('\n2. Testing Realtime API for RELIANCE:');
            final realtimeResp = await dio.post(
              'https://mock-data.tealvue.in/api/v1/realtime-current',
              data: {'symbol': 'RELIANCE', 'limit': 10, 'offset': 0},
            );
            print('Realtime response status: ${realtimeResp.statusCode}');
            print('Realtime response data: ${realtimeResp.data}');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Check console for API debug info'),
                duration: Duration(seconds: 3),
              ),
            );
          } catch (e) {
            print('Error: $e');
          }
        },
        child: const Icon(Icons.bug_report),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.watch_later), label: 'Watchlist'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
      ),
    );
  }
}

class DashboardContent extends ConsumerStatefulWidget {
  const DashboardContent({super.key});

  @override
  ConsumerState<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<DashboardContent> {
  bool _demoDataInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDemoData();
  }

  void _initializeDemoData() async {
    // Prevent multiple initialization
    if (_demoDataInitialized) return;
    _demoDataInitialized = true;

    final holdings = ref.read(portfolioProvider);

    // Only add demo data if portfolio is empty AND we haven't added it before
    if (holdings.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));

      // Double-check again after delay to ensure no race condition
      final currentHoldings = ref.read(portfolioProvider);
      if (currentHoldings.isEmpty) {
        print('Adding demo holdings...');
        ref.read(portfolioProvider.notifier).addHolding(
          Holding(symbol: 'RELIANCE', quantity: 10, averageBuyPrice: 2450.0),
        );
        ref.read(portfolioProvider.notifier).addHolding(
          Holding(symbol: 'TCS', quantity: 5, averageBuyPrice: 3400.0),
        );
        ref.read(portfolioProvider.notifier).addHolding(
          Holding(symbol: 'INFY', quantity: 20, averageBuyPrice: 1500.0),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioSummary = ref.watch(portfolioSummaryProvider);
    final holdings = ref.watch(portfolioProvider);
    final watchlist = ref.watch(watchlistProvider);
    final symbolsAsync = ref.watch(symbolsProvider);

    // Remove duplicates from holdings by symbol
    final uniqueHoldings = holdings.fold<List<Holding>>([], (list, holding) {
      if (!list.any((h) => h.symbol == holding.symbol)) {
        list.add(holding);
      }
      return list;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Portfolio Summary Card
              Card(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Portfolio Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMetricRow(
                        'Total Invested',
                        NumberFormatter.formatCurrency(portfolioSummary.totalInvested),
                        icon: Icons.account_balance_wallet,
                      ),
                      const Divider(color: Colors.white24),
                      _buildMetricRow(
                        'Current Value',
                        NumberFormatter.formatCurrency(portfolioSummary.totalCurrent),
                        icon: Icons.trending_up,
                      ),
                      const Divider(color: Colors.white24),
                      _buildMetricRow(
                        'Total P&L',
                        NumberFormatter.formatCurrency(portfolioSummary.totalPnL),
                        color: portfolioSummary.totalPnL >= 0 ? Colors.lightGreen : Colors.redAccent,
                        icon: Icons.show_chart,
                      ),
                      const Divider(color: Colors.white24),
                      _buildMetricRow(
                        'P&L %',
                        NumberFormatter.formatPercentage(portfolioSummary.totalPnLPercent),
                        color: portfolioSummary.totalPnLPercent >= 0 ? Colors.lightGreen : Colors.redAccent,
                        icon: Icons.percent,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Holdings Breakdown Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Holdings Breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final parentState = context.findAncestorStateOfType<_DashboardScreenState>();
                      parentState?.setState(() {
                        parentState._currentIndex = 2;
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Manage'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (uniqueHoldings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No holdings yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add stocks to track your portfolio',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final parentState = context.findAncestorStateOfType<_DashboardScreenState>();
                          parentState?.setState(() {
                            parentState._currentIndex = 2;
                          });
                        },
                        child: const Text('Add Holdings'),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: uniqueHoldings.length,
                  itemBuilder: (context, index) {
                    final holding = uniqueHoldings[index];
                    final tick = ref.watch(tickerProvider(holding.symbol));

                    if (tick == null) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(holding.symbol),
                          subtitle: const Text('Loading data...'),
                          trailing: const CircularProgressIndicator(),
                        ),
                      );
                    }

                    final currentValue = holding.quantity * tick.ltp;
                    final pnl = currentValue - holding.investedValue;
                    final pnlPercent = (pnl / holding.investedValue) * 100;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SymbolDetailScreen(symbol: holding.symbol),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          holding.symbol,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Qty: ${holding.quantity} | Avg: ${NumberFormatter.formatCurrency(holding.averageBuyPrice)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        NumberFormatter.formatCurrency(currentValue),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: pnl >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${pnl >= 0 ? '+' : ''}${NumberFormatter.formatCurrency(pnl)} (${pnlPercent.toStringAsFixed(2)}%)',
                                          style: TextStyle(
                                            color: pnl >= 0 ? Colors.green : Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'LTP: ${NumberFormatter.formatCurrency(tick.ltp)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Change: ${tick.change >= 0 ? '+' : ''}${NumberFormatter.formatCurrency(tick.change)} (${tick.changePercent.toStringAsFixed(2)}%)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: tick.change >= 0 ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    Text(
                                      'VWAP: ${NumberFormatter.formatCurrency(tick.vwap)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: tick.ltp >= tick.vwap ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Watchlist Preview Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Watchlist Preview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final parentState = context.findAncestorStateOfType<_DashboardScreenState>();
                      parentState?.setState(() {
                        parentState._currentIndex = 1;
                      });
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              symbolsAsync.when(
                data: (allSymbols) {
                  final watchlistSymbols = allSymbols
                      .where((s) => watchlist.contains(s.symbol))
                      .take(5)
                      .toList();

                  if (watchlistSymbols.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No symbols in watchlist',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add symbols to track real-time prices',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              final parentState = context.findAncestorStateOfType<_DashboardScreenState>();
                              parentState?.setState(() {
                                parentState._currentIndex = 1;
                              });
                            },
                            child: const Text('Add to Watchlist'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: watchlistSymbols.length,
                    itemBuilder: (context, index) {
                      final symbol = watchlistSymbols[index];
                      final tick = ref.watch(tickerProvider(symbol.symbol));

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.trending_up,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            symbol.symbol,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            symbol.name.length > 30 ? '${symbol.name.substring(0, 30)}...' : symbol.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: tick != null
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormatter.formatCurrency(tick.ltp),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${tick.change >= 0 ? '+' : ''}${NumberFormatter.formatPercentage(tick.changePercent)}',
                                style: TextStyle(
                                  color: tick.change >= 0 ? Colors.green : Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                              : const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SymbolDetailScreen(symbol: symbol.symbol),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('Error loading symbols: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? color, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? Colors.white),
          ),
        ],
      ),
    );
  }
}