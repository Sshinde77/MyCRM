import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';
import 'package:mycrm/models/contact_enquiry_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/app_card.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';

class ContactEnquiriesScreen extends StatefulWidget {
  const ContactEnquiriesScreen({super.key});

  @override
  State<ContactEnquiriesScreen> createState() => _ContactEnquiriesScreenState();
}

class _ContactEnquiriesScreenState extends State<ContactEnquiriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  int _rowsPerPage = 10;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _isLoading = true;
  List<ContactEnquiryModel> _items = const <ContactEnquiryModel>[];

  @override
  void initState() {
    super.initState();
    _loadContactEnquiries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContactEnquiries() async {
    setState(() => _isLoading = true);
    try {
      final page = await ApiService.instance.getContactEnquiriesPage(
        page: _currentPage,
        perPage: _rowsPerPage,
        search: _searchController.text.trim(),
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
        _messageFromError(error, fallback: 'Unable to load contact enquiries.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        'Unable to load contact enquiries.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteContact(ContactEnquiryModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete enquiry?'),
          content: Text('Delete contact enquiry #${item.id}?'),
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
      await ApiService.instance.deleteContactEnquiry(item.id);
      if (!mounted) return;
      AppSnackbar.show('Deleted', 'Contact enquiry deleted.', isSuccess: true);
      await _loadContactEnquiries();
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Delete failed',
        _messageFromError(error, fallback: 'Unable to delete contact enquiry.'),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Delete failed',
        'Unable to delete contact enquiry.',
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
      appBar: const CommonScreenAppBar(title: 'Contact Enquiries'),
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
                          'Contact Enquiries',
                          style: AppTextStyles.style(
                            color: const Color(0xFF1E2A3B),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    'Records from the contactForm on the website',
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
                      _loadContactEnquiries();
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
                        'Show',
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
                          child: DropdownButton<int>(
                            value: _rowsPerPage,
                            items: const [10, 25, 50]
                                .map(
                                  (e) => DropdownMenuItem<int>(
                                    value: e,
                                    child: Text('$e'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _rowsPerPage = value;
                                _currentPage = 1;
                              });
                              _loadContactEnquiries();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'entries',
                        style: AppTextStyles.style(
                          color: const Color(0xFF1E2A3B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
                  'No contact enquiries found.',
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              ..._items.map(
                (item) => _EnquiryCard(
                  item: item,
                  onDelete: () => _deleteContact(item),
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
                            _loadContactEnquiries();
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
                            _loadContactEnquiries();
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

class _EnquiryCard extends StatelessWidget {
  const _EnquiryCard({required this.item, required this.onDelete});

  final ContactEnquiryModel item;
  final VoidCallback onDelete;

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
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            _kv('First Name', item.firstName),
            _kv('Last Name', item.lastName),
            _kv('Contact', item.contact),
            _kv('Email', item.email),
            _kv('Message', item.message),
            _kv('Source Page', item.sourcePage),
            _kv('Created At', item.createdAt),
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
