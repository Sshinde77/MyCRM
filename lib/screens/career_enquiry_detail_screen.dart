import '../widgets/skeletons/app_skeletons.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';
import 'package:mycrm/models/career_enquiry_model.dart';
import 'package:mycrm/services/api_service.dart';
import 'package:mycrm/widgets/app_card.dart';
import 'package:mycrm/widgets/common_screen_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class CareerEnquiryDetailScreen extends StatefulWidget {
  const CareerEnquiryDetailScreen({super.key, required this.recordId});
  final String recordId;
  @override
  State<CareerEnquiryDetailScreen> createState() =>
      _CareerEnquiryDetailScreenState();
}

class _CareerEnquiryDetailScreenState extends State<CareerEnquiryDetailScreen> {
  bool _isLoading = true;
  CareerEnquiryModel? _item;
  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final item = await ApiService.instance.getCareerEnquiryDetail(
        widget.recordId,
      );
      if (!mounted) return;
      setState(() => _item = item);
    } on DioException catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        _messageFromError(
          error,
          fallback: 'Unable to load career enquiry detail.',
        ),
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(
        'Load failed',
        'Unable to load career enquiry detail.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openResume() async {
    final item = _item;
    if (item == null) return;
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
        AppSnackbar.show(
          'Invalid URL',
          'Resume link is invalid.',
          isError: true,
        );
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
      AppSnackbar.show(
        'Resume failed',
        'Unable to fetch resume URL.',
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
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;
    final splitLayout = width >= 840;
    final sectionGap = compact ? 8.0 : 10.0;
    final item = _item;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: const CommonScreenAppBar(title: 'Career Detail'),
      body: SafeArea(
        child: _isLoading
            ? const ScreenSkeleton()
            : item == null
            ? Center(
                child: Text(
                  'No detail found.',
                  style: AppTextStyles.style(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ListView(
                padding: EdgeInsets.all(compact ? 10 : 12),
                children: [
                  AppCard(
                    padding: EdgeInsets.all(compact ? 12 : 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: compact ? 38 : 42,
                          height: compact ? 38 : 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F0FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.work_outline_rounded,
                            color: Color(0xFF1D6FEA),
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Career Enquiry Detail',
                                style: AppTextStyles.style(
                                  color: const Color(0xFF1E2A3B),
                                  fontSize: compact ? 16 : 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Record #${item.id}',
                                style: AppTextStyles.style(
                                  color: const Color(0xFF64748B),
                                  fontSize: compact ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D6FEA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.sourceLabel.isEmpty ? '-' : item.sourceLabel,
                            style: AppTextStyles.style(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  if (splitLayout)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _SectionCard(
                            title: 'Candidate Information',
                            icon: Icons.badge_outlined,
                            children: [
                              _DetailRow(label: 'Name', value: item.name),
                              _DetailRow(label: 'Email', value: item.email),
                              _DetailRow(label: 'Contact', value: item.contact),
                              _DetailRow(label: 'Role', value: item.role),
                              _DetailRow(
                                label: 'Applicant Type',
                                value: item.applicantType,
                              ),
                              _DetailRow(
                                label: 'Experience',
                                value: item.experience,
                              ),
                              _DetailRow(
                                label: 'Location',
                                value: item.location,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: sectionGap),
                        Expanded(
                          child: _SectionCard(
                            title: 'Compensation & Joining',
                            icon: Icons.payments_outlined,
                            children: [
                              _DetailRow(
                                label: 'Current CTC',
                                value: item.currentCtc,
                              ),
                              _DetailRow(
                                label: 'Expected CTC',
                                value: item.expectedCtc,
                              ),
                              _DetailRow(
                                label: 'Notice Period',
                                value: item.noticePeriod,
                              ),
                              _DetailRow(
                                label: 'Reference Name',
                                value: item.referenceName,
                              ),
                              _DetailRow(
                                label: 'Reference',
                                value: item.reference,
                              ),
                              _DetailRow(
                                label: 'Created At',
                                value: item.createdAt,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _SectionCard(
                      title: 'Candidate Information',
                      icon: Icons.badge_outlined,
                      children: [
                        _DetailRow(label: 'Name', value: item.name),
                        _DetailRow(label: 'Email', value: item.email),
                        _DetailRow(label: 'Contact', value: item.contact),
                        _DetailRow(label: 'Role', value: item.role),
                        _DetailRow(
                          label: 'Applicant Type',
                          value: item.applicantType,
                        ),
                        _DetailRow(label: 'Experience', value: item.experience),
                        _DetailRow(label: 'Location', value: item.location),
                      ],
                    ),
                    SizedBox(height: sectionGap),
                    _SectionCard(
                      title: 'Compensation & Joining',
                      icon: Icons.payments_outlined,
                      children: [
                        _DetailRow(
                          label: 'Current CTC',
                          value: item.currentCtc,
                        ),
                        _DetailRow(
                          label: 'Expected CTC',
                          value: item.expectedCtc,
                        ),
                        _DetailRow(
                          label: 'Notice Period',
                          value: item.noticePeriod,
                        ),
                        _DetailRow(
                          label: 'Reference Name',
                          value: item.referenceName,
                        ),
                        _DetailRow(label: 'Reference', value: item.reference),
                        _DetailRow(label: 'Created At', value: item.createdAt),
                      ],
                    ),
                  ],
                  SizedBox(height: sectionGap),
                  _SectionCard(
                    title: 'Files & Links',
                    icon: Icons.folder_open_outlined,
                    children: [
                      _DetailRow(label: 'Resume File', value: item.resumeFile),
                      _DetailRow(label: 'Resume URL', value: item.resumeUrl),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _openResume,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download Resume'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D6FEA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(label: 'Portfolio', value: item.portfolioLink),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  _SectionCard(
                    title: 'Skills (Text)',
                    icon: Icons.psychology_alt_outlined,
                    children: [_PillText(value: item.skillsText)],
                  ),
                  SizedBox(height: sectionGap),
                  _SectionCard(
                    title: 'AI Tools (Text)',
                    icon: Icons.auto_awesome_outlined,
                    children: [_PillText(value: item.aiToolsText)],
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1D6FEA), size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.style(
                    color: const Color(0xFF1E2A3B),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 380;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 98 : 114,
            child: Text(
              '$label:',
              style: AppTextStyles.style(
                color: const Color(0xFF475569),
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: AppTextStyles.style(
                color: const Color(0xFF0F172A),
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillText extends StatelessWidget {
  const _PillText({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 380;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value.isEmpty ? '-' : value,
        style: AppTextStyles.style(
          color: const Color(0xFF1E293B),
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
