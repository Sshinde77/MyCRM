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
  static const String testFcm = '$baseUrl/test-fcm';

  //Roles Api
  static const String roles = '$baseUrl/roles';

  //Staff Api
  static const String createstaff = '$baseUrl/staff-v2';
  static const String liststaff = '$baseUrl/staff-v2';
  static const String staffdetail = '$baseUrl/staff-v2/{id}';
  static const String deletestaff = '$baseUrl/staff-v2/{id}';
  static const String editstaff = '$baseUrl/staff-v2/{id}';
  static const String staffDepartments = '$baseUrl/staff-v2/departments';
  static const String staffTeams = '$baseUrl/staff-v2/teams';
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
  static const String createtodo = '$baseUrl/todos';
  static const String listtodo = '$baseUrl/todos';
  static const String tododetail = '$baseUrl/todos/{id}';
  static const String deletetodo = '$baseUrl/todos/{id}';
  static const String edittodo = '$baseUrl/todos/{id}';
  static const String statustodo = '$baseUrl/todos/{id}/status';

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
  static const String createvendorRenewals = '$baseUrl/vendor-renewals';
  static const String vendorRenewalsDetail = '$baseUrl/vendor-renewals/{id}';
  static const String updateVendorRenewal = '$baseUrl/vendor-renewals/{id}';
  static const String deleteVendorRenewal = '$baseUrl/vendor-renewals/{id}';

  //client renewals
  static const String clientRenewals = '$baseUrl/client-renewals';
  static const String createclientRenewals = '$baseUrl/client-renewals';
  static const String clientRenewalsFormOptions =
      '$baseUrl/client-renewals/form-options';
  static const String clientRenewalsDetail = '$baseUrl/client-renewals/{id}';
  static const String updateClientRenewal = '$baseUrl/client-renewals/{id}';
  static const String deleteClientRenewal = '$baseUrl/client-renewals/{id}';

  //client issues
  static const String clientIssues = '$baseUrl/client-issues';
  static const String createClientIssues = '$baseUrl/client-issues';
  static const String clientIssuesDetail = '$baseUrl/client-issues/{id}';
  static const String updateClientIssue = '$baseUrl/client-issues/{id}';
  static const String deleteClientIssue = '$baseUrl/client-issues/{id}';
  static const String clientIssueStatus = '$baseUrl/client-issues/{id}/status';
  static const String clientissueformdata =
      '$baseUrl/client-issues/form-options';
  static const String createClientIssueTask =
      '$baseUrl/client-issues/{id}/tasks';
  static const String assignClientIssueTeam =
      '$baseUrl/client-issues/{id}/assign';
  static const String clientIssueTaskDetail =
      '$baseUrl/client-issues/{issueId}/tasks/{taskId}';
  static const String clientIssueTaskStatus =
      '$baseUrl/client-issues/{issueId}/tasks/{taskId}/status';

  //settings
  static const String companyInformation = '$baseUrl/settings/company';
  static const String emailSettings = '$baseUrl/settings/email';
  static const String renewalSettings = '$baseUrl/settings/renewal';
  static const String teamSettings = '$baseUrl/settings/teams';
  static const String departmentSettings = '$baseUrl/settings/departments';

  //book a call
  static const String bookACall = '$baseUrl/book-a-call';
  static const String deleteBookACall = '$baseUrl/book-a-call/{id}';

  //google ads leads
  static const String digitalMarketingLeads = '$baseUrl/digital-marketing';
  static const String deleteDigitalMarketingLead =
      '$baseUrl/digital-marketing/{id}';
  static const String webAppsLeads = '$baseUrl/web-apps-leads';
  static const String deleteWebAppsLead = '$baseUrl/web-apps-leads/{id}';
}
