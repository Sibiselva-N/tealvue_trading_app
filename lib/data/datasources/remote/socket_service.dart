import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/tick.dart';

class SocketService {
  IO.Socket? _socket;
  final Map<String, List<void Function(Tick)>> _listeners = {};
  final Map<String, List<void Function(bool)>> _connectionListeners = {};
  bool _isConnected = false;
  List<String> _currentSubscriptions = [];
  List<String> _pendingSubscriptions = [];
  Timer? _mockTickerTimer;
  final Map<String, Tick> _lastTicks = {};
  String? _lastError;
  final Map<String, double> _basePrices = {}; // Store real base prices

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  void connect() {
    if (_socket != null && _isConnected) return;

    print('Connecting to socket...');

    try {
      _socket = IO.io(AppConstants.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'timeout': 10000,
      });

      _socket!.onConnect((_) {
        print('Socket connected successfully');
        _isConnected = true;
        _lastError = null;
        _notifyConnectionStatus(true);
        _connectionStatusController.add(true);
        if (_pendingSubscriptions.isNotEmpty) {
          print('Processing pending subscriptions: $_pendingSubscriptions');
          _socket!.emit(AppConstants.subscribeEvent, _pendingSubscriptions);
          _currentSubscriptions = List.from(_pendingSubscriptions);
          _pendingSubscriptions.clear();
        } else if (_currentSubscriptions.isNotEmpty) {
          print('Resubscribing to: $_currentSubscriptions');
          _socket!.emit(AppConstants.subscribeEvent, _currentSubscriptions);
        }

        _stopMockTicker();
      });

      _socket!.onConnectError((error) {
        print('Socket connection error: $error');
        _isConnected = false;
        _lastError = error.toString();
        _notifyConnectionStatus(false);
        _connectionStatusController.add(false);
        _startMockTicker();
      });

      _socket!.onDisconnect((_) {
        print('Socket disconnected');
        _isConnected = false;
        _notifyConnectionStatus(false);
        _connectionStatusController.add(false);
        _startMockTicker();
      });

      _socket!.onReconnecting((attempt) {
        print('Socket reconnecting attempt: $attempt');
        _connectionStatusController.add(false);
        _notifyConnectionStatus(false);
      });

      _socket!.onReconnect((attempt) {
        print('Socket reconnected after $attempt attempts');
        _isConnected = true;
        _lastError = null;
        _connectionStatusController.add(true);
        _notifyConnectionStatus(true);

        if (_currentSubscriptions.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _socket!.emit(AppConstants.subscribeEvent, _currentSubscriptions);
          });
        }
      });

      _socket!.onReconnectError((error) {
        print('Socket reconnection error: $error');
        _lastError = error.toString();
        _connectionStatusController.add(false);
        _notifyConnectionStatus(false);
      });

      _socket!.on(AppConstants.tickerEvent, (data) {
        try {
          final tick = Tick.fromJson(data);
          _lastTicks[tick.symbol] = tick;
          // Store the real base price from the tick data
          if (!_basePrices.containsKey(tick.symbol)) {
            _basePrices[tick.symbol] = tick.prevClose;
          }
          _notifyListeners(tick.symbol, tick);
        } catch (e) {
          print('Error parsing tick: $e');
        }
      });

      _socket!.connect();

      Future.delayed(const Duration(seconds: 3), () {
        if (!_isConnected) {
          print('Real socket not connected, starting mock ticker');
          _startMockTicker();
          _connectionStatusController.add(false);
        }
      });
    } catch (e) {
      print('Socket creation error: $e');
      _lastError = e.toString();
      _connectionStatusController.add(false);
      _startMockTicker();
    }
  }

  void _startMockTicker() {
    if (_mockTickerTimer != null) return;
    _connectionStatusController.add(false);
    print('Starting mock ticker generator (fallback mode)');
    _mockTickerTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      for (var symbol in _currentSubscriptions) {
        _generateAndSendMockTick(symbol);
      }
    });
  }

  void _stopMockTicker() {
    if (_mockTickerTimer != null) {
      print('Stopping mock ticker generator');
      _mockTickerTimer?.cancel();
      _connectionStatusController.add(true);
      _mockTickerTimer = null;
    }
  }

  void _generateAndSendMockTick(String symbol) {
    final lastTick = _lastTicks[symbol];
    // Use real base price if available, otherwise try to fetch from API
    final basePrice = _basePrices[symbol] ?? _getCachedBasePrice(symbol);

    if (basePrice == 0) {
      // If no base price available, don't generate mock tick
      return;
    }

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

  double _getCachedBasePrice(String symbol) {
    // Try to get from last tick if available
    if (_lastTicks.containsKey(symbol)) {
      return _lastTicks[symbol]!.prevClose;
    }
    return 0; // Return 0 if no price available
  }

  // Method to set base price from API data
  void setBasePrice(String symbol, double price) {
    _basePrices[symbol] = price;
    print('Base price set for $symbol: $price');
  }

  void disconnect() {
    print('Disconnecting socket...');
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
    print('Added listener for: $symbol, total: ${_listeners[symbol]!.length}');

    subscribe([symbol]);
  }

  void removeListener(String symbol, void Function(Tick) callback) {
    _listeners[symbol]?.remove(callback);
    if (_listeners[symbol]?.isEmpty == true) {
      _listeners.remove(symbol);
    }
    print('Removed listener for: $symbol');
  }

  void addConnectionListener(String id, void Function(bool) callback) {
    if (!_connectionListeners.containsKey(id)) {
      _connectionListeners[id] = [];
    }
    _connectionListeners[id]!.add(callback);
  }

  void removeConnectionListener(String id) {
    _connectionListeners.remove(id);
  }

  void _notifyConnectionStatus(bool connected) {
    for (var listeners in _connectionListeners.values) {
      for (var callback in listeners) {
        callback(connected);
      }
    }
  }

  void _notifyListeners(String symbol, Tick tick) {
    final listeners = _listeners[symbol];
    if (listeners != null && listeners.isNotEmpty) {
      for (var callback in listeners) {
        callback(tick);
      }
    }
  }

  bool get isConnected => _isConnected;
  String? get lastError => _lastError;
  List<String> get currentSubscriptions => List.unmodifiable(_currentSubscriptions);
  bool get isUsingMockData => _mockTickerTimer != null;
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  service.connect();
  ref.onDispose(() => service.disconnect());
  return service;
});