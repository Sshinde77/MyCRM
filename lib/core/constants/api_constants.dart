/// API configuration shared across network calls.
class ApiConstants {
  static const String appBaseUrl = 'https://mycrm.technofra.com/';
  static const String baseUrl = 'https://mycrm.technofra.com/api/v1';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Endpointss
  //Authentication Api
  static const String login = '$baseUrl/login';
  static const String forgotPassword = '$baseUrl/forgot-password';
  static const String user = '$baseUrl/me';
  static const String logout = '$baseUrl/logout';
  static const String refreshToken = '$baseUrl/refresh';
  static const String testFcm = '$baseUrl/fcm-token';
  static const String dashboard = '$baseUrl/dashboard';
  static const String quickStats = '$baseUrl/quick-stats';
  static const String notifications = '$baseUrl/notifications';
  static const String notificationRead = '$baseUrl/notifications/{id}/read';
  static const String notificationReadAll = '$baseUrl/notifications/read-all';

  //Roles Api
  static const String roles = '$baseUrl/roles';

  //Staff Api
  static const String createstaff = '$baseUrl/staff-v2';
  static const String liststaff = '$baseUrl/staff-v2';
  static const String staffdetail = '$baseUrl/staff-v2/{id}';
  static const String staffAnalytics = '$baseUrl/staff-v2/{id}/analytics';
  static const String staffLeadChart = '$baseUrl/staff-v2/{id}/lead-chart';
  static const String staffFollowupChart =
      '$baseUrl/staff-v2/{id}/followup-chart';
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
  static const String leadManagement = '$baseUrl/lead-management';
  static const String leadsDashboard = '$baseUrl/leads/dashboard';
  static const String leadDetail = '$baseUrl/leads/{id}';
  static const String leadDelete = '$baseUrl/leads/{id}';
  static const String leadformdata = '$baseUrl/leads/form-options';
  static const String createleads = '$baseUrl/leads';
  static const String editleads = '$baseUrl/leads/{id}';
  static const String leadAssign =
      '$baseUrl/lead-management/{sourceType}/{source_id}/assign';
  static const String leadStatusUpdate =
      '$baseUrl/lead-management/{sourceType}/{source_id}/status';
  static const String leadPriorityUpdate =
      '$baseUrl/lead-management/{sourceType}/{source_id}/priority';
  static const String leadBulkAssign = '$baseUrl/lead-management/bulk-assign';
  static const String leadFollowupCreate =
      '$baseUrl/lead-management/{sourceType}/{source_id}/followup';
  static const String leadManagementDetailView =
      '$baseUrl/lead-management/{sourceType}/{source_id}/view';
  static const String leadTimeline =
      '$baseUrl/lead-management/{sourceType}/{source_id}/timeline';
  static const String leadFollowups =
      '$baseUrl/lead-management/{sourceType}/{source_id}/followups';
  static const String leadNoteCreate =
      '$baseUrl/lead-management/{sourceType}/{source_id}/note';
  static const String leadReminderCreate =
      '$baseUrl/lead-management/{sourceType}/{source_id}/reminder';
  static const String leadAssignments =
      '$baseUrl/lead-management/{sourceType}/{source_id}/assignment';
  static const String leadStatusHistory =
      '$baseUrl/lead-management/{sourceType}/{source_id}/status-history';

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
  static const String projectDetails = '$baseUrl/projects/{id}/details';
  static const String projectCharts = '$baseUrl/projects/{id}/charts';
  static const String projectActivityFeed =
      '$baseUrl/projects/{id}/activity-feed';

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

  // Orders
  static const String orders = '$baseUrl/orders';
  static const String ordersFormOptions = '$baseUrl/orders/form-options';
  static const String orderDetail = '$baseUrl/orders/{id}';
  static const String orderUpdate = '$baseUrl/orders/{id}';
  static const String orderDelete = '$baseUrl/orders/{id}';
  static const String orderStatus = '$baseUrl/orders/{id}/status';
  static const String orderPurchaseOrder = '$baseUrl/orders/{id}/purchase/order';
  static const String orderPurchaseReceipt = '$baseUrl/orders/{id}/purchase/receipt';
  static const String orderPurchaseReceive = '$baseUrl/orders/{id}/purchase/receive';
  static const String orderDeliveryReady = '$baseUrl/orders/{id}/delivery/ready';
  static const String orderDeliveryDispatch = '$baseUrl/orders/{id}/delivery/dispatch';
  static const String orderDeliveryDeliver = '$baseUrl/orders/{id}/delivery/deliver';
  static const String orderHold = '$baseUrl/orders/{id}/hold';
  static const String orderCancel = '$baseUrl/orders/{id}/cancel';

  //vendor renewals
  static const String vendorRenewals = '$baseUrl/vendor-renewals';
  static const String createvendorRenewals = '$baseUrl/vendor-renewals';
  static const String vendorRenewalsFormOptions =
      '$baseUrl/vendor-renewals/form-options';
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
      '$baseUrl/client-issues/{clientIssue}/tasks';
  static const String assignClientIssueTeam =
      '$baseUrl/client-issues/{id}/assign';

  static const String clientIssueTaskDetail =
      '$baseUrl/client-issues/{issueId}/tasks/{taskId}';
  static const String clientIssueTaskStatus =
      '$baseUrl/client-issues/{issueId}/tasks/{taskId}/status';

  //settings

  static const String settings = '$baseUrl/settings';
  static const String generalSettings = '$baseUrl/settings/general';
  static const String appLogoSettings = '$baseUrl/settings/app-logo';
  static const String loginLogoSettings = '$baseUrl/settings/login-logo';
  static const String privacyPolicy = '$baseUrl/settings/privacy-policy';
  static const String termsAndConditions =
      '$baseUrl/settings/terms-and-conditions';
  static const String companyInformation = '$baseUrl/settings/company';
  static const String emailSettings = '$baseUrl/settings/email';
  static const String renewalSettings = '$baseUrl/settings/renewal';
  static const String teamSettings = '$baseUrl/settings/teams';
  static const String departmentSettings = '$baseUrl/settings/departments';
  static const String settingsTestEmail = '$baseUrl/settings/test-email';
  static const String settingsSearchTags = '$baseUrl/settings/search-tags';

  //book a call
  static const String bookACall = '$baseUrl/book-a-call';
  static const String deleteBookACall = '$baseUrl/book-a-call/{id}';

  //web enquiry careers
  static const String webEnquiryCareers = '$baseUrl/web-enquiry/careers';
  static const String webEnquiryCareerDetail =
      '$baseUrl/web-enquiry/careers/{id}';
  static const String webEnquiryCareerDelete =
      '$baseUrl/web-enquiry/careers/{id}';
  static const String webEnquiryCareerResumeUrl =
      '$baseUrl/web-enquiry/careers/{id}/resume-url';
  static const String webEnquiryContacts = '$baseUrl/web-enquiry/contacts';
  static const String webEnquiryContactDelete =
      '$baseUrl/web-enquiry/contacts/{id}';

  //google ads leads
  static const String digitalMarketingLeads = '$baseUrl/digital-marketing';
  static const String deleteDigitalMarketingLead =
      '$baseUrl/digital-marketing/{id}';
  static const String googleAdsLeads = '$baseUrl/google-ads-leads';
  static const String googleAdsLeadDetail = '$baseUrl/google-ads-leads/{id}';
  static const String webAppsLeads = '$baseUrl/web-apps-leads';
  static const String deleteWebAppsLead = '$baseUrl/web-apps-leads/{id}';
  static const String metaLeads = '$baseUrl/meta-leads';
  static const String metaLeadDetail = '$baseUrl/meta-leads/{id}';
  static const String deleteMetaLead = '$baseUrl/meta-leads/{id}';

  // Social media post management
  static const String socialMedia = '$baseUrl/social-media';
  static const String socialMediaOptions = '$socialMedia/options';
  static const String socialMediaPosts = '$socialMedia/posts';
  static const String socialMediaPost = '$socialMedia/posts/{id}';
  static const String socialMediaStart = '$socialMedia/posts/{id}/start';
  static const String socialMediaVersions = '$socialMedia/posts/{id}/versions';
  static const String socialMediaInternalDecision =
      '$socialMedia/posts/{id}/internal-decision';
  static const String socialMediaClientDecision =
      '$socialMedia/posts/{id}/client-decision';
  static const String socialMediaComments = '$socialMedia/posts/{id}/comments';
  static const String socialMediaSchedule = '$socialMedia/posts/{id}/schedule';
  static const String socialMediaPublish = '$socialMedia/posts/{id}/publish';

  // SEO campaign workspace
  static const String seoCampaigns = '$baseUrl/seo/campaigns';
  static const String seoCampaign = '$seoCampaigns/{campaign}';
  static const String seoCampaignRestore = '$seoCampaigns/{campaignId}/restore';
  static const String seoDashboard = '$seoCampaign/dashboard';
  static const String seoWorkspace = '$seoCampaign/workspace';
  static const String seoAudit = '$seoCampaign/audit';
  static const String seoAuditFindings = '$seoCampaign/audit/findings';
  static const String seoAuditFinding = '$seoCampaign/audit/findings/{finding}';
  static const String seoAuditSubmit = '$seoCampaign/audit/submit';
  static const String seoAuditReview = '$seoCampaign/audit/review';
  static const String seoBaseline = '$seoCampaign/baseline';
  static const String seoBaselineApprove = '$seoCampaign/baseline/approve';
  static const String seoKeywords = '$seoCampaign/keywords';
  static const String seoKeyword = '$seoCampaign/keywords/{keyword}';
  static const String seoKeywordRankings = '$seoCampaign/keywords/{keyword}/rankings';
  static const String seoKeywordTemplate = '$seoCampaign/keywords/template';
  static const String seoKeywordImport = '$seoCampaign/keywords/import';
  static const String seoCompetitors = '$seoCampaign/competitors';
  static const String seoCycles = '$seoCampaign/cycles';
  static const String seoActivities = '$seoCampaign/activities';
  static const String seoActivity = '$seoCampaign/activities/{activity}';
  static const String seoActivityReview = '$seoCampaign/activities/{activity}/review';
  static const String seoTechnicalIssues = '$seoCampaign/technical-issues';
  static const String seoTechnicalIssue = '$seoCampaign/technical-issues/{technicalIssue}';
  static const String seoOnPage = '$seoCampaign/on-page';
  static const String seoBacklinks = '$seoCampaign/backlinks';
  static const String seoPerformance = '$seoCampaign/performance';
  static const String seoReports = '$seoCampaign/reports';
  static const String seoReportSubmit = '$seoCampaign/reports/{report}/submit';
  static const String seoReportReview = '$seoCampaign/reports/{report}/review';
}
