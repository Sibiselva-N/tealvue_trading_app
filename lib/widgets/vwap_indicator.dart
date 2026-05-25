import 'package:flutter/material.dart';
import '../core/utils/number_formatter.dart';

class VWAPIndicator extends StatelessWidget {
  final double ltp;
  final double vwap;

  const VWAPIndicator({super.key, required this.ltp, required this.vwap});

  @override
  Widget build(BuildContext context) {
    final difference = ltp - vwap;
    final isAbove = difference >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAbove
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAbove ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: isAbove ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            'VWAP: ${NumberFormatter.formatCurrency(vwap)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
