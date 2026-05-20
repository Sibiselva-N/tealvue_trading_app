import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/ticker_provider.dart';
import '../../core/utils/number_formatter.dart';
import '../symbol_detail/symbol_detail_screen.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = ref.watch(watchlistProvider);
    final symbolsAsync = ref.watch(symbolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search symbols...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : const Text('Watchlist'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showAddSymbolManuallyDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Quick filter chips
          if (watchlist.isNotEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Chip(
                    label: Text('Watchlist (${watchlist.length})'),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Watchlist'),
                          content: const Text('Are you sure you want to remove all symbols from watchlist?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                for (var symbol in watchlist) {
                                  ref.read(watchlistProvider.notifier).removeSymbol(symbol);
                                }
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Watchlist cleared')),
                                );
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Clear All'),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: _isSearching
                  ? _buildSearchResults(symbolsAsync, watchlist)
                  : _buildWatchlistContent(symbolsAsync, watchlist),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistContent(AsyncValue<List<dynamic>> symbolsAsync, List<String> watchlist) {
    return symbolsAsync.when(
      data: (allSymbols) {
        final watchlistSymbols = allSymbols
            .where((s) => watchlist.contains(s.symbol))
            .toList();

        if (watchlistSymbols.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Your watchlist is empty',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search and add symbols to track real-time prices',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Add Symbols'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showAddSymbolManuallyDialog(),
                  icon: const Icon(Icons.edit),
                  label: const Text('Add Manually'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: watchlistSymbols.length,
          itemBuilder: (context, index) {
            final symbol = watchlistSymbols[index];
            final tick = ref.watch(tickerProvider(symbol.symbol));

            return Dismissible(
              key: Key(symbol.symbol),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                ref.read(watchlistProvider.notifier).removeSymbol(symbol.symbol);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${symbol.symbol} removed from watchlist'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        ref.read(watchlistProvider.notifier).addSymbol(symbol.symbol);
                      },
                    ),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      symbol.symbol[0],
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    symbol.symbol,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    symbol.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tick.change >= 0
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${tick.change >= 0 ? '+' : ''}${NumberFormatter.formatPercentage(tick.changePercent)}',
                          style: TextStyle(
                            color: tick.change >= 0 ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                      : const SizedBox(
                    width: 40,
                    height: 40,
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
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<dynamic>> symbolsAsync, List<String> watchlist) {
    return symbolsAsync.when(
      data: (allSymbols) {
        final filteredSymbols = _searchQuery.isEmpty
            ? allSymbols
            : allSymbols.where((symbol) =>
        symbol.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            symbol.name.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();

        if (filteredSymbols.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No symbols found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching for a different symbol',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _showAddSymbolManuallyDialogWithQuery(),
                  icon: const Icon(Icons.add),
                  label: Text('Add "$_searchQuery" manually'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredSymbols.length,
          itemBuilder: (context, index) {
            final symbol = filteredSymbols[index];
            final isInWatchlist = watchlist.contains(symbol.symbol);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    symbol.symbol[0],
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                title: Text(
                  symbol.symbol,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(symbol.name),
                trailing: IconButton(
                  icon: Icon(
                    isInWatchlist ? Icons.star : Icons.star_border,
                    color: isInWatchlist ? Colors.amber : null,
                  ),
                  onPressed: () {
                    if (isInWatchlist) {
                      ref.read(watchlistProvider.notifier).removeSymbol(symbol.symbol);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${symbol.symbol} removed from watchlist')),
                      );
                    } else {
                      ref.read(watchlistProvider.notifier).addSymbol(symbol.symbol);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${symbol.symbol} added to watchlist')),
                      );
                    }
                  },
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  void _showAddSymbolManuallyDialog() {
    final TextEditingController symbolController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Symbol Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the stock symbol (e.g., RELIANCE, TCS, INFY)'),
            const SizedBox(height: 16),
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(
                hintText: 'Symbol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final symbol = symbolController.text.trim().toUpperCase();
              if (symbol.isNotEmpty) {
                ref.read(watchlistProvider.notifier).addSymbol(symbol);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$symbol added to watchlist')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddSymbolManuallyDialogWithQuery() {
    final TextEditingController symbolController = TextEditingController(text: _searchQuery.toUpperCase());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Symbol Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the stock symbol to add to watchlist'),
            const SizedBox(height: 16),
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(
                hintText: 'Symbol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final symbol = symbolController.text.trim().toUpperCase();
              if (symbol.isNotEmpty) {
                ref.read(watchlistProvider.notifier).addSymbol(symbol);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$symbol added to watchlist')),
                );
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}