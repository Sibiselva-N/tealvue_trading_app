import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'holding.g.dart';

@HiveType(typeId: 0)
class Holding extends Equatable {
  @HiveField(0)
  final String symbol;

  @HiveField(1)
  final int quantity;

  @HiveField(2)
  final double averageBuyPrice;

  const Holding({
    required this.symbol,
    required this.quantity,
    required this.averageBuyPrice,
  });

  double get investedValue => quantity * averageBuyPrice;

  @override
  List<Object?> get props => [symbol];
}

// Note: You'll need to run `flutter pub run build_runner build` to generate holding.g.dart
