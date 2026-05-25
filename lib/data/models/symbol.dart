import 'package:equatable/equatable.dart';

class Symbol extends Equatable {
  final String symbol;
  final String name;
  final String exchange;
  final String type;
  final bool isActive;

  const Symbol({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.type,
    required this.isActive,
  });

  factory Symbol.fromJson(Map<String, dynamic> json) {
    return Symbol(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      exchange: json['exchange'] as String,
      type: json['type'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  @override
  List<Object?> get props => [symbol, name];
}
