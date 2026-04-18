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
  static const String refreshToken = '$baseUrl/refresh';

  //Staff Api
  static const String createstaff = '$baseUrl/staff';
  static const String liststaff = '$baseUrl/staff';
  static const String staffdetail = '$baseUrl/staff/{id}';
  static const String deletestaff = '$baseUrl/staff/{id}';
  static const String editstaff = '$baseUrl/staff/{id}';
  static const String staffprojects = '$baseUrl/staff/{id}/projects';
  static const String stafftasks = '$baseUrl/staff/{id}/tasks';

  //Clients Api
  static const String clients = '$baseUrl/clients';
  static const String clientDetail = '$baseUrl/clients/{id}';
  static const String updateClient = '$baseUrl/clients/{id}';
  static const String deleteClient = '$baseUrl/clients/{id}';
  static const String clientsprojects = '$baseUrl/clients/{id}/projects';
  static const String clientstasks = '$baseUrl/clients/{id}/tasks';

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
  static const String projectfiles = '$baseUrl/projects/{id}/files';
  static const String deleteProjectFile =
      '$baseUrl/projects/{projectId}/files/{fileId}';
  static const String projectmilestones = '$baseUrl/projects/{id}/milestones';
  static const String createprojectmilestones =
      '$baseUrl/projects/{id}/milestones';
  static const String updateprojectmilestones =
      '$baseUrl/projects/{projectId}/milestones/{milestoneId}';
  static const String deleteProjectMilestone =
      '$baseUrl/projects/{projectId}/milestones/{milestoneId}';
  static const String projectissues = '$baseUrl/projects/{id}/issues';
  static const String createprojectissues = '$baseUrl/projects/{id}/issues';
  static const String updateprojectissues =
      '$baseUrl/projects/{projectId}/issues/{issueId}';
  static const String deleteProjectIssue =
      '$baseUrl/projects/{projectId}/issues/{issueId}';
  static const String projectcomments = '$baseUrl/projects/{id}/comments';
  static const String createprojectcomments = '$baseUrl/projects/{id}/comments';
  static const String projectussage = '$baseUrl/projects/{id}/usage';

  //task
  static const String tasks = '$baseUrl/tasks';
  static const String createTask = '$baseUrl/tasks';
  static const String taskDetail = '$baseUrl/tasks/{id}';
  static const String updateTask = '$baseUrl/tasks/{id}';
  static const String deleteTask = '$baseUrl/tasks/{id}';
  static const String taskformdata = '$baseUrl/tasks/form-options';
  static const String taskcomments = '$baseUrl/tasks/{id}/comments';
  static const String createtaskcomments = '$baseUrl/tasks/{id}/comments';

  //calendar
  static const String calendar = '$baseUrl/calendar/events';
  static const String calendarDetail = '$baseUrl/calendar/events/{id}';
  static const String updateCalendar = '$baseUrl/calendar/events/{id}';
  static const String deleteCalendar = '$baseUrl/calendar/events/{id}';
  static const String createcalendar = '$baseUrl/calendar/events';

  //vendor
  static const String vendors = '$baseUrl/vendors';
  static const String createvendors = '$baseUrl/vendors';
  static const String vendorDetail = '$baseUrl/vendors/{id}';
  static const String updateVendor = '$baseUrl/vendors/{id}';
  static const String deleteVendor = '$baseUrl/vendors/{id}';

  //vendor renewals
  static const String vendorRenewals = '$baseUrl/vendor-renewals';
  static const String vendorRenewalsDetail = '$baseUrl/vendor-renewals/{id}';
  static const String updateVendorRenewal = '$baseUrl/vendor-renewals/{id}';
  static const String deleteVendorRenewal = '$baseUrl/vendor-renewals/{id}';

  //client renewals
  static const String clientRenewals = '$baseUrl/client-renewals';
  static const String clientRenewalsDetail = '$baseUrl/client-renewals/{id}';
  static const String updateClientRenewal = '$baseUrl/client-renewals/{id}';
  static const String deleteClientRenewal = '$baseUrl/client-renewals/{id}';
}
