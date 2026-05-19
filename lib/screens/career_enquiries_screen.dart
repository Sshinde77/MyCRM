import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';
import 'package:mycrm/models/career_enquiry_model.dart';
import 'package:mycrm/screens/career_enquiry_detail_screen.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/app_card.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class CareerEnquiriesScreen extends StatefulWidget {
  const CareerEnquiriesScreen({super.key});

  @override
  State<CareerEnquiriesScreen> createState() => _CareerEnquiriesScreenState();
}

class _CareerEnquiriesScreenState extends State<CareerEnquiriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _rowsPerPage = 10;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  String _applicantType = 'all';
  bool _isLoading = true;
  List<CareerEnquiryModel> _items = const <CareerEnquiryModel>[];

  @override
  void initState() {
    super.initState();
    _loadCareerEnquiries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCareerEnquiries() async {
    setState(() => _isLoading = true);
    try {
      final page = await ApiService.instance.getCareerEnquiriesPage(
        page: _currentPage,
        perPage: _rowsPerPage,
        search: _searchController.text.trim(),
        applicantType: _applicantType,
        sortBy: 'created_at',
        sortOrder: 'desc',
      );
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _total = page.total;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        _messageFromError(error, fallback: 'Unable to load career enquiries.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        'Unable to load career enquiries.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openResume(CareerEnquiryModel item) async {
    try {
      final payload = await ApiService.instance.getCareerResumeUrl(item.id);
      final url = (payload['resume_url'] ?? '').trim();
      if (url.isEmpty) {
        if (!mounted) return;
        AppSnackbar.show('No file', 'Resume URL is not available.');
        return;
      }
      final uri = Uri.tryParse(url);
      if (uri == null) {
        if (!mounted) return;
        AppSnackbar.show('Invalid URL', 'Resume link is invalid.', isError: true);
        return;
      }
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      AppSnackbar.show(
        opened ? 'Opening' : 'Unable to open',
        opened ? 'Opening resume link...' : 'Could not open resume link.',
        isError: !opened,
      );
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Resume failed',
        _messageFromError(error, fallback: 'Unable to fetch resume URL.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show('Resume failed', 'Unable to fetch resume URL.', isError: true);
    }
  }

  Future<void> _deleteCareer(CareerEnquiryModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete enquiry?'),
          content: Text('Delete career enquiry #${item.id}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.instance.deleteCareerEnquiry(item.id);
      if (!mounted) return;
      AppSnackbar.show('Deleted', 'Career enquiry deleted.', isSuccess: true);
      await _loadCareerEnquiries();
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Delete failed',
        _messageFromError(error, fallback: 'Unable to delete career enquiry.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Delete failed',
        'Unable to delete career enquiry.',
        isError: true,
      );
    }
  }

  String _messageFromError(DioException error, {required String fallback}) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    final message = error.message?.trim() ?? '';
    return message.isEmpty ? fallback : message;
  }

  @override
  Widget build(BuildContext context) {
    final start = _total == 0 ? 0 : ((_currentPage - 1) * _rowsPerPage) + 1;
    final end = _total == 0 ? 0 : start + _items.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: const CommonScreenAppBar(title: 'Career Enquiries'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Career Enquiries',
                          style: AppTextStyles.style(
                            color: const Color(0xFF1E2A3B),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D6FEA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Total: $_total',
                          style: AppTextStyles.style(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Records from the jobapplication on the website',
                    style: AppTextStyles.style(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) {
                      setState(() => _currentPage = 1);
                      _loadCareerEnquiries();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Applicant',
                        style: AppTextStyles.style(
                          color: const Color(0xFF1E2A3B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD2DDEA)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _applicantType,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All')),
                              DropdownMenuItem(
                                value: 'fresher',
                                child: Text('Fresher'),
                              ),
                              DropdownMenuItem(
                                value: 'experience',
                                child: Text('Experience'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _applicantType = value;
                                _currentPage = 1;
                              });
                              _loadCareerEnquiries();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
            else if (_items.isEmpty)
              AppCard(
                child: Text(
                  'No career enquiries found.',
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              ..._items.map(
                (item) => _CareerEnquiryCard(
                  item: item,
                  onView: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CareerEnquiryDetailScreen(recordId: item.id),
                      ),
                    );
                  },
                  onDelete: () => _deleteCareer(item),
                  onDownload: () => _openResume(item),
                ),
              ),
            const SizedBox(height: 6),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _total == 0
                          ? 'Showing 0 to 0 of 0 entries'
                          : 'Showing $start to $end of $_total entries',
                      style: AppTextStyles.style(
                        color: const Color(0xFF334155),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage -= 1);
                            _loadCareerEnquiries();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    '$_currentPage/${_lastPage < 1 ? 1 : _lastPage}',
                    style: AppTextStyles.style(
                      color: const Color(0xFF1E2A3B),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < _lastPage
                        ? () {
                            setState(() => _currentPage += 1);
                            _loadCareerEnquiries();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareerEnquiryCard extends StatelessWidget {
  const _CareerEnquiryCard({
    required this.item,
    required this.onView,
    required this.onDelete,
    required this.onDownload,
  });

  final CareerEnquiryModel item;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${item.id}',
                  style: AppTextStyles.style(
                    color: const Color(0xFF1D6FEA),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('Download'),
                ),
              ],
            ),
            _kv('Name', item.name),
            _kv('Email', item.email),
            _kv('Contact', item.contact),
            _kv('Role', item.role),
            _kv('Applicant Type', item.applicantType),
            _kv('Experience', item.experience),
            _kv('CTC', item.currentCtc),
            _kv('ECTC', item.expectedCtc),
            _kv('Location', item.location),
            _kv('Reference', item.reference),
            const SizedBox(height: 2),
            Row(
              children: [
                OutlinedButton(
                  onPressed: onView,
                  child: const Icon(Icons.visibility_rounded, size: 16),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Icon(Icons.delete_rounded, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              '$label:',
              style: AppTextStyles.style(
                color: const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: AppTextStyles.style(
                color: const Color(0xFF1E2A3B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
