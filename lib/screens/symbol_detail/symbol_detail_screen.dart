import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ticker_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../data/repositories/market_data_repository.dart';
import '../../data/models/tick.dart';
import '../../core/utils/number_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../widgets/custom_chart.dart';

class SymbolDetailScreen extends ConsumerStatefulWidget {
  final String symbol;

  const SymbolDetailScreen({super.key, required this.symbol});

  @override
  ConsumerState<SymbolDetailScreen> createState() => _SymbolDetailScreenState();
}

class _SymbolDetailScreenState extends ConsumerState<SymbolDetailScreen> {
  List<Tick> _ticks = [];
  bool _isLoading = true;
  bool _isHistorical = false;
  String? _error;
  String _selectedRange = '1D';
  final List<String> _ranges = ['1D', '1W', '1M', '3M'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isHistorical = false;
    });

    try {
      final repository = ref.read(marketDataRepositoryProvider);
      final ticks = await repository.getRealtimeCurrent(widget.symbol);

      setState(() {
        _ticks = ticks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistoricalData(String range) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isHistorical = true;
    });

    try {
      final repository = ref.read(marketDataRepositoryProvider);
      final endDate = DateTime.now();
      DateTime startDate;

      switch (range) {
        case '1W':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case '1M':
          startDate = endDate.subtract(const Duration(days: 30));
          break;
        case '3M':
          startDate = endDate.subtract(const Duration(days: 90));
          break;
        default:
          startDate = endDate.subtract(const Duration(days: 1));
      }

      final ticks = await repository.getHistoricalData(
        symbol: widget.symbol,
        startDate: DateFormatter.toISODate(startDate),
        endDate: DateFormatter.toISODate(endDate),
      );

      setState(() {
        _ticks = ticks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleHistorical() {
    if (_isHistorical) {
      _loadInitialData();
    } else {
      _loadHistoricalData(_selectedRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tick = ref.watch(tickerProvider(widget.symbol));
    final isInWatchlist = ref.watch(watchlistProvider).contains(widget.symbol);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.symbol),
            if (tick != null)
              Text(
                NumberFormatter.formatCurrency(tick.ltp),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isInWatchlist ? Icons.star : Icons.star_border),
            onPressed: () {
              if (isInWatchlist) {
                ref
                    .read(watchlistProvider.notifier)
                    .removeSymbol(widget.symbol);
              } else {
                ref.read(watchlistProvider.notifier).addSymbol(widget.symbol);
              }
            },
          ),
          IconButton(
            icon: Icon(_isHistorical ? Icons.timeline : Icons.history),
            onPressed: _toggleHistorical,
            tooltip: _isHistorical ? 'View Live' : 'View Historical',
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildFullScreenChart();
          }
          return _buildPortraitLayout(tick);
        },
      ),
    );
  }

  Widget _buildPortraitLayout(Tick? tick) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Price Info Card
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tick != null
                            ? NumberFormatter.formatCurrency(tick.ltp)
                            : 'N/A',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (tick != null)
                        Text(
                          'Prev Close: ${NumberFormatter.formatCurrency(tick.prevClose)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  if (tick != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tick.change >= 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${tick.change >= 0 ? '+' : ''}${NumberFormatter.formatCurrency(tick.change)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: tick.change >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Text(
                            '(${NumberFormatter.formatPercentage(tick.changePercent)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: tick.change >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip('Open', tick?.open),
                  _buildInfoChip('High', tick?.high),
                  _buildInfoChip('Low', tick?.low),
                  _buildInfoChip('VWAP', tick?.vwap),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(
                    'Volume',
                    tick?.ttq?.toDouble(),
                    isCurrency: false,
                  ),
                  _buildInfoChip('Turnover', tick?.turnover),
                ],
              ),
            ],
          ),
        ),

        // Historical range selector
        if (_isHistorical)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _ranges.map((range) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(range),
                    selected: _selectedRange == range,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedRange = range);
                        _loadHistoricalData(range);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

        // Chart
        Expanded(
          child: CustomChart(
            ticks: _ticks,
            symbol: widget.symbol,
            isHistorical: _isHistorical,
          ),
        ),

        // Additional Stats
        if (tick != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Day Range',
                  '${NumberFormatter.formatCurrency(tick.low)} - ${NumberFormatter.formatCurrency(tick.high)}',
                ),
                _buildStatItem(
                  'Volume',
                  NumberFormatter.formatVolume(tick.ttq),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip(String label, double? value, {bool isCurrency = true}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value != null
              ? (isCurrency
                    ? NumberFormatter.formatCurrency(value)
                    : value.toString())
              : 'N/A',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFullScreenChart() {
    return Scaffold(
      body: CustomChart(
        ticks: _ticks,
        symbol: widget.symbol,
        isFullScreen: true,
        isHistorical: _isHistorical,
      ),
    );
  }
}
