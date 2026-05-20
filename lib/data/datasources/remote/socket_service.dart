import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/tick.dart';

class SocketService {
  IO.Socket? _socket;
  final Map<String, List<void Function(Tick)>> _listeners = {};
  bool _isConnected = false;
  List<String> _currentSubscriptions = [];
  List<String> _pendingSubscriptions = [];
  Timer? _mockTickerTimer;
  final Map<String, Tick> _lastTicks = {};

  void connect() {
    if (_socket != null && _isConnected) return;

    print('Connecting to socket...');

    try {
      _socket = IO.io(AppConstants.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 3,
        'reconnectionDelay': 1000,
      });

      _socket!.onConnect((_) {
        print('Socket connected successfully');
        _isConnected = true;

        if (_pendingSubscriptions.isNotEmpty) {
          _socket!.emit(AppConstants.subscribeEvent, _pendingSubscriptions);
          _currentSubscriptions = List.from(_pendingSubscriptions);
          _pendingSubscriptions.clear();
        } else if (_currentSubscriptions.isNotEmpty) {
          _socket!.emit(AppConstants.subscribeEvent, _currentSubscriptions);
        }

        // Stop mock timer if real socket is working
        _stopMockTicker();
      });

      _socket!.onConnectError((error) {
        print('Socket connection error: $error');
        _isConnected = false;
        _startMockTicker(); // Start mock data generation
      });

      _socket!.onDisconnect((_) {
        print('Socket disconnected');
        _isConnected = false;
        _startMockTicker(); // Start mock data generation
      });

      _socket!.on(AppConstants.tickerEvent, (data) {
        try {
          final tick = Tick.fromJson(data);
          _lastTicks[tick.symbol] = tick;
          _notifyListeners(tick.symbol, tick);
        } catch (e) {
          print('Error parsing tick: $e');
        }
      });

      _socket!.connect();

      // Start mock ticker as fallback
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isConnected) {
          _startMockTicker();
        }
      });
    } catch (e) {
      print('Socket creation error: $e');
      _startMockTicker();
    }
  }

  void _startMockTicker() {
    if (_mockTickerTimer != null) return;

    print('Starting mock ticker generator');
    _mockTickerTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      for (var symbol in _currentSubscriptions) {
        _generateAndSendMockTick(symbol);
      }
    });
  }

  void _stopMockTicker() {
    _mockTickerTimer?.cancel();
    _mockTickerTimer = null;
  }

  void _generateAndSendMockTick(String symbol) {
    final lastTick = _lastTicks[symbol];
    final basePrice = _getBasePrice(symbol);
    final variation = (DateTime.now().millisecondsSinceEpoch % 200 - 100) / 1000;
    final newPrice = (lastTick?.ltp ?? basePrice) * (1 + variation);

    final mockTick = Tick(
      symbolId: 1,
      token: 1001,
      symbol: symbol,
      instrument: 'EQUITY',
      lotSize: 1.0,
      timestamp: DateTime.now(),
      ltp: newPrice,
      ltq: 1000,
      atp: newPrice * 0.99,
      ttq: 100000,
      open: basePrice,
      high: newPrice * 1.01,
      low: newPrice * 0.99,
      prevClose: lastTick?.ltp ?? basePrice,
      prevVolume: 1000000,
      turnover: newPrice * 100000,
      priceDiff: 0,
      volumeDiff: 0,
      sequenceNo: (_lastTicks[symbol]?.sequenceNo ?? 0) + 1,
    );

    _lastTicks[symbol] = mockTick;
    _notifyListeners(symbol, mockTick);
  }

  double _getBasePrice(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'RELIANCE':
        return 2450.0;
      case 'TCS':
        return 3400.0;
      case 'INFY':
        return 1500.0;
      case 'HDFCBANK':
        return 1600.0;
      case 'ICICIBANK':
        return 950.0;
      default:
        return 1000.0;
    }
  }

  void disconnect() {
    _stopMockTicker();
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.clearListeners();
      _socket = null;
      _isConnected = false;
      _listeners.clear();
      _currentSubscriptions.clear();
      _pendingSubscriptions.clear();
    }
  }

  void subscribe(List<String> symbols) {
    if (symbols.isEmpty) return;

    print('Subscribe called for symbols: $symbols');

    // Update current subscriptions
    for (var symbol in symbols) {
      if (!_currentSubscriptions.contains(symbol)) {
        _currentSubscriptions.add(symbol);
      }
    }

    if (!_isConnected || _socket == null) {
      print('Socket not connected, will queue subscription');
      _pendingSubscriptions.addAll(symbols);
      _pendingSubscriptions = _pendingSubscriptions.toSet().toList();
      return;
    }

    print('Emitting subscribe for: $symbols');
    _socket!.emit(AppConstants.subscribeEvent, symbols);
  }

  void unsubscribe(List<String> symbols) {
    if (symbols.isEmpty) return;

    print('Unsubscribing from: $symbols');
    _currentSubscriptions.removeWhere((s) => symbols.contains(s));

    if (!_isConnected || _socket == null) return;
    _socket!.emit(AppConstants.unsubscribeEvent, symbols);
  }

  void addListener(String symbol, void Function(Tick) callback) {
    if (!_listeners.containsKey(symbol)) {
      _listeners[symbol] = [];
    }
    _listeners[symbol]!.add(callback);
    print('Added listener for: $symbol');

    subscribe([symbol]);
  }

  void removeListener(String symbol, void Function(Tick) callback) {
    _listeners[symbol]?.remove(callback);
    if (_listeners[symbol]?.isEmpty == true) {
      _listeners.remove(symbol);
    }
  }

  void _notifyListeners(String symbol, Tick tick) {
    final listeners = _listeners[symbol];
    if (listeners != null) {
      for (var callback in listeners) {
        callback(tick);
      }
    }
  }

  bool get isConnected => _isConnected;
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  service.connect();
  ref.onDispose(() => service.disconnect());
  return service;
});