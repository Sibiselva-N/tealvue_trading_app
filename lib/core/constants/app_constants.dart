class AppConstants {
  // API Endpoints
  static const String baseUrl = 'https://mock-data.tealvue.in/api/v1';
  static const String socketUrl = 'https://mock-data.tealvue.in';

  // Build Tag (Required for about screen)
  static const String buildTag = 'TV-WL-2026-Q3';

  // API Endpoints
  static const String symbolsEndpoint = '/symbols';
  static const String realtimeCurrentEndpoint = '/realtime-current';
  static const String historicalEndpoint = '/historical';

  // Socket Events
  static const String subscribeEvent = 'subscribe';
  static const String unsubscribeEvent = 'unsubscribe';
  static const String tickerEvent = 'ticker';

  // Trading Hours (IST)
  static const int marketOpenHour = 9;
  static const int marketOpenMinute = 15;
  static const int marketCloseHour = 15;
  static const int marketCloseMinute = 30;

  // Pagination
  static const int defaultLimit = 5000;

  // Cache Keys
  static const String watchlistKey = 'watchlist';
  static const String themeKey = 'theme_mode';
}
