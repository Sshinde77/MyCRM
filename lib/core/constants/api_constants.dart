/// API configuration shared across network calls.
class ApiConstants {
  static const String baseUrl = 'https://mycrm.technofra.com/api/v1';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Endpoints

  // static const String login = '$baseUrl/login';
  static const String login = 'local-login-bypass';
  static const String user = '$baseUrl/me';
  static const String logout = '$baseUrl/logout';

  // Temporary local login credentials while the API is bypassed.
  static const String dummyLoginEmail = 'demo@mycrm.com';
  static const String dummyLoginPassword = '123456';
}
