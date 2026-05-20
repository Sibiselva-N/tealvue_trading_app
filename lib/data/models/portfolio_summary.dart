import 'package:equatable/equatable.dart';

class PortfolioSummary extends Equatable {
  final double totalInvested;
  final double totalCurrent;
  final double totalPnL;
  final double totalPnLPercent;

  const PortfolioSummary({
    required this.totalInvested,
    required this.totalCurrent,
    required this.totalPnL,
    required this.totalPnLPercent,
  });

  factory PortfolioSummary.initial() {
    return const PortfolioSummary(
      totalInvested: 0,
      totalCurrent: 0,
      totalPnL: 0,
      totalPnLPercent: 0,
    );
  }

  PortfolioSummary copyWith({
    double? totalInvested,
    double? totalCurrent,
    double? totalPnL,
    double? totalPnLPercent,
  }) {
    return PortfolioSummary(
      totalInvested: totalInvested ?? this.totalInvested,
      totalCurrent: totalCurrent ?? this.totalCurrent,
      totalPnL: totalPnL ?? this.totalPnL,
      totalPnLPercent: totalPnLPercent ?? this.totalPnLPercent,
    );
  }

  @override
  List<Object?> get props => [
    totalInvested,
    totalCurrent,
    totalPnL,
    totalPnLPercent,
  ];
}
