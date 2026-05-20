class NumberFormatter {
  static String formatCurrency(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  static String formatPercentage(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  static String formatVolume(int value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)}L';
    } else {
      return value.toString();
    }
  }
}
