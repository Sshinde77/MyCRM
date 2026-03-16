/// API configuration shared across network calls.
class ApiConstants {
  static const String baseUrl = 'https://api.example.com/v1';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Endpoints
  static const String login = '/login';
  static const String dashboard = '/dashboard';
}
