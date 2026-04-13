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

  //Clients Api
  static const String clients = '$baseUrl/clients';
  static const String clientDetail = '$baseUrl/clients/{id}';
  static const String updateClient = '$baseUrl/clients/{id}';
  static const String deleteClient = '$baseUrl/clients/{id}';

  //Leads Api
  static const String leads = '$baseUrl/leads';
  static const String leadDetail = '$baseUrl/leads/{id}';
  static const String leadDelete = '$baseUrl/leads/{id}';
  static const String leadformdata = '$baseUrl/leads/form-options';
  static const String createleads = '$baseUrl/leads';
  static const String editleads = '$baseUrl/leads/{id}';

  //Todo Api
  static const String createtodo = '$baseUrl/todos/create-todo';
  static const String listtodo = '$baseUrl/todos';
  static const String tododetail = '$baseUrl/todos/{id}';
  static const String deletetodo = '$baseUrl/todos/delete-todo/{id}';
  static const String edittodo = '$baseUrl/todos/update-todo/{id}';
  static const String statustodo = '$baseUrl/todos/toggle-todo-status/{id}';

  //projects
  static const String projects = '$baseUrl/projects';
  static const String createprojects = '$baseUrl/projects';
  static const String projectDetail = '$baseUrl/projects/{id}';
  static const String updateProject = '$baseUrl/projects/{id}';
  static const String deleteProject = '$baseUrl/projects/{id}';
  static const String formdataProject = '$baseUrl/projects/form-options';

}
