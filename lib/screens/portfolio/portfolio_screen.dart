import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tick.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/ticker_provider.dart';
import '../../data/models/holding.dart';
import '../../core/utils/number_formatter.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final holdings = ref.watch(portfolioProvider);
    final portfolioSummary = ref.watch(portfolioSummaryProvider);

    // Remove duplicates
    final uniqueHoldings = holdings.fold<List<Holding>>([], (list, holding) {
      if (!list.any((h) => h.symbol == holding.symbol)) {
        list.add(holding);
      }
      return list;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddHoldingDialog(),
          ),
          if (uniqueHoldings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearAllDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Portfolio Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                _buildSummaryRow('Total Invested', NumberFormatter.formatCurrency(portfolioSummary.totalInvested)),
                const SizedBox(height: 8),
                _buildSummaryRow('Current Value', NumberFormatter.formatCurrency(portfolioSummary.totalCurrent)),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Total P&L',
                  NumberFormatter.formatCurrency(portfolioSummary.totalPnL),
                  color: portfolioSummary.totalPnL >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'P&L %',
                  NumberFormatter.formatPercentage(portfolioSummary.totalPnLPercent),
                  color: portfolioSummary.totalPnLPercent >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),

          // Holdings List
          Expanded(
            child: uniqueHoldings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No holdings yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add stocks to build your paper portfolio',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddHoldingDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Holding'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: uniqueHoldings.length,
              itemBuilder: (context, index) {
                final holding = uniqueHoldings[index];
                return _buildHoldingCard(holding);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHoldingCard(Holding holding) {
    final tick = ref.watch(tickerProvider(holding.symbol));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            holding.symbol[0],
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
        title: Text(
          holding.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: tick != null
            ? Text('LTP: ${NumberFormatter.formatCurrency(tick.ltp)}')
            : const Text('Loading...'),
        trailing: tick != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormatter.formatCurrency(holding.quantity * tick.ltp),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (holding.quantity * tick.ltp - holding.investedValue) >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _calculatePnL(holding, tick),
                style: TextStyle(
                  fontSize: 12,
                  color: (holding.quantity * tick.ltp - holding.investedValue) >= 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
          ],
        )
            : const SizedBox(width: 40, child: CircularProgressIndicator(strokeWidth: 2)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Quantity', holding.quantity.toString()),
                _buildDetailRow('Average Price', NumberFormatter.formatCurrency(holding.averageBuyPrice)),
                if (tick != null) ...[
                  _buildDetailRow('Current Price', NumberFormatter.formatCurrency(tick.ltp)),
                  _buildDetailRow('Invested Value', NumberFormatter.formatCurrency(holding.investedValue)),
                  _buildDetailRow('Current Value', NumberFormatter.formatCurrency(holding.quantity * tick.ltp)),
                  _buildDetailRow(
                    'Unrealized P&L',
                    NumberFormatter.formatCurrency(holding.quantity * tick.ltp - holding.investedValue),
                    color: (holding.quantity * tick.ltp - holding.investedValue) >= 0 ? Colors.green : Colors.red,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditHoldingDialog(holding),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmation(holding),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  String _calculatePnL(Holding holding, Tick tick) {
    final pnl = (holding.quantity * tick.ltp) - holding.investedValue;
    final pnlPercent = (pnl / holding.investedValue) * 100;
    final sign = pnl >= 0 ? '+' : '';
    return '$sign${NumberFormatter.formatCurrency(pnl)} ($sign${pnlPercent.toStringAsFixed(2)}%)';
  }

  void _showAddHoldingDialog() {
    _symbolController.clear();
    _quantityController.clear();
    _priceController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Holding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _symbolController,
              decoration: const InputDecoration(
                hintText: 'Symbol (e.g., RELIANCE)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                hintText: 'Quantity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                hintText: 'Average Buy Price',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final symbol = _symbolController.text.trim().toUpperCase();
              final quantity = int.tryParse(_quantityController.text);
              final price = double.tryParse(_priceController.text);

              if (symbol.isNotEmpty && quantity != null && price != null && quantity > 0 && price > 0) {
                final holding = Holding(
                  symbol: symbol,
                  quantity: quantity,
                  averageBuyPrice: price,
                );
                ref.read(portfolioProvider.notifier).addHolding(holding);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$symbol added to portfolio')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid values')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditHoldingDialog(Holding holding) {
    _symbolController.text = holding.symbol;
    _quantityController.text = holding.quantity.toString();
    _priceController.text = holding.averageBuyPrice.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Holding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _symbolController,
              decoration: const InputDecoration(
                hintText: 'Symbol',
                border: OutlineInputBorder(),
              ),
              enabled: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                hintText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                hintText: 'Average Buy Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(_quantityController.text);
              final price = double.tryParse(_priceController.text);

              if (quantity != null && price != null && quantity > 0 && price > 0) {
                final updatedHolding = Holding(
                  symbol: holding.symbol,
                  quantity: quantity,
                  averageBuyPrice: price,
                );
                ref.read(portfolioProvider.notifier).updateHolding(updatedHolding);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${holding.symbol} updated')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Holding holding) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Holding'),
        content: Text('Are you sure you want to remove ${holding.symbol} from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(portfolioProvider.notifier).removeHolding(holding.symbol);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${holding.symbol} removed from portfolio')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Holdings'),
        content: const Text('Are you sure you want to remove all holdings from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(portfolioProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All holdings removed')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}