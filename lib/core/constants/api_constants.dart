/// API configuration shared across network calls.
class ApiConstants {
  static const String baseUrl = 'https://mycrm.technofra.com/api/v1';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Endpoints
  //Authentication Api
  static const String login = '$baseUrl/login';
  static const String user = '$baseUrl/me';
  static const String logout = '$baseUrl/logout';

  //Staff Api
  static const String createstaff = '$baseUrl/staff';
  static const String liststaff = '$baseUrl/staff';
  static const String staffdetail = '$baseUrl/staff/{id}';
  static const String deletestaff = '$baseUrl/staff/{id}';
  static const String editstaff = '$baseUrl/staff/{id}';



}
