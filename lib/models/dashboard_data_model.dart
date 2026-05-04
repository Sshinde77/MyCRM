import 'client_issue_model.dart';
import 'renewal_model.dart';

class DashboardDataModel {
  const DashboardDataModel({
    required this.totalProjects,
    required this.totalTasks,
    required this.projectMonthlySeries,
    required this.taskMonthlySeries,
    required this.monthLabels,
    required this.taskStatusCounts,
    required this.clientRenewals,
    required this.vendorRenewals,
    required this.clientIssues,
  });

  final int totalProjects;
  final int totalTasks;
  final List<int> projectMonthlySeries;
  final List<int> taskMonthlySeries;
  final List<String> monthLabels;
  final Map<String, int> taskStatusCounts;
  final List<RenewalModel> clientRenewals;
  final List<RenewalModel> vendorRenewals;
  final List<ClientIssueModel> clientIssues;
}
