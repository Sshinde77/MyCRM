import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/common_screen_app_bar.dart';

/// SEO operations workspace. The sections mirror SEO_FLOW.md in order.
class SeoScreen extends StatefulWidget {
  const SeoScreen({super.key});

  @override
  State<SeoScreen> createState() => _SeoScreenState();
}

class _SeoScreenState extends State<SeoScreen> {
  final _api = ApiService.instance;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : <String, dynamic>{};

  List<Map<String, dynamic>> _list(dynamic value) {
    final root = _map(value);
    final data = root['data'] ?? value;
    if (data is List) return data.map(_map).toList();
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).map(_map).toList();
    }
    return [];
  }

  Future<void> _loadCampaigns() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get(ApiConstants.seoCampaigns);
      if (mounted) setState(() { _campaigns = _list(response.data); _loading = false; });
    } on DioException catch (error) {
      if (mounted) setState(() { _error = error.response?.data?.toString() ?? 'Unable to load SEO campaigns.'; _loading = false; });
    }
  }

  String _value(Map<String, dynamic> item, String key, [String fallback = '']) =>
      (item[key] ?? fallback).toString();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      bottomNavigationBar: const PrimaryBottomNavigation(currentTab: AppBottomNavTab.profile),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 10),
            CommonTopBar(title: 'SEO', compact: compact),
            const SizedBox(height: 14),
            Row(children: [
              const Expanded(child: Text('SEO campaigns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF172B4D)))),
              FilledButton.icon(onPressed: _showCreateCampaign, icon: const Icon(Icons.add, size: 18), label: const Text('Campaign')),
            ]),
            const SizedBox(height: 12),
            Expanded(child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _StateCard(icon: Icons.cloud_off_rounded, title: 'Could not load campaigns', message: _error!, action: _loadCampaigns)
                    : _campaigns.isEmpty
                        ? const _StateCard(icon: Icons.travel_explore_rounded, title: 'No SEO campaigns yet', message: 'Create a campaign to start the audit, baseline and monthly delivery flow.')
                        : RefreshIndicator(onRefresh: _loadCampaigns, child: ListView.separated(padding: const EdgeInsets.only(bottom: 20), itemCount: _campaigns.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, index) => _CampaignCard(campaign: _campaigns[index], value: _value, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SeoCampaignScreen(campaign: _campaigns[index]))))))),
          ]),
        ),
      ),
    );
  }

  Future<void> _showCreateCampaign() async {
    final form = await showDialog<Map<String, dynamic>>(context: context, builder: (_) => const _CreateCampaignDialog());
    if (form == null) return;
    try {
      await _api.post(ApiConstants.seoCampaigns, data: form);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SEO campaign created'))); _loadCampaigns(); }
    } on DioException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.response?.data?.toString() ?? 'Unable to create campaign')));
    }
  }
}

class SeoCampaignScreen extends StatefulWidget {
  const SeoCampaignScreen({super.key, required this.campaign});
  final Map<String, dynamic> campaign;
  @override State<SeoCampaignScreen> createState() => _SeoCampaignScreenState();
}

class _SeoCampaignScreenState extends State<SeoCampaignScreen> {
  final _api = ApiService.instance;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};
  final _sections = const [
    ('Overview & Audit', Icons.fact_check_outlined), ('Baseline', Icons.flag_outlined), ('Dashboard', Icons.dashboard_outlined),
    ('Keywords & Rankings', Icons.key_outlined), ('Competitors', Icons.groups_outlined), ('Monthly Operations', Icons.event_note_outlined),
    ('Technical Issues', Icons.build_circle_outlined), ('On-page Optimisation', Icons.web_outlined), ('Backlinks', Icons.link_outlined),
    ('Performance', Icons.insights_outlined), ('Monthly Reports', Icons.assessment_outlined),
  ];

  String get _id => (widget.campaign['id'] ?? widget.campaign['campaign_id'] ?? '').toString();
  String _endpoint(String template) => template.replaceAll('{campaign}', _id);
  Map<String, dynamic> _map(dynamic value) => value is Map ? value.map((key, value) => MapEntry(key.toString(), value)) : {};

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.get(_endpoint(ApiConstants.seoWorkspace));
      if (mounted) setState(() { _data = _map(response.data); _loading = false; });
    } on DioException catch (error) {
      if (mounted) setState(() { _error = error.response?.data?.toString() ?? 'Unable to load campaign workspace.'; _loading = false; });
    }
  }
  @override Widget build(BuildContext context) {
    final name = (widget.campaign['name'] ?? 'SEO Campaign').toString();
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Scaffold(backgroundColor: const Color(0xFFF4F8FC), bottomNavigationBar: const PrimaryBottomNavigation(currentTab: AppBottomNavTab.profile), body: SafeArea(child: Padding(padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 10), CommonTopBar(title: name, compact: compact), const SizedBox(height: 14), _CampaignHero(campaign: widget.campaign), const SizedBox(height: 14), Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? _StateCard(icon: Icons.cloud_off_rounded, title: 'Workspace unavailable', message: _error!, action: _load) : ListView.separated(padding: const EdgeInsets.only(bottom: 20), itemCount: _sections.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, index) { final section = _sections[index]; return _FlowSection(title: section.$1, icon: section.$2, data: _data, onTap: () => _openSection(index, section.$1)); }))]))));
  }
  void _openSection(int index, String title) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SeoSectionScreen(title: title, index: index, campaign: widget.campaign, data: _data)));
  }
}

class SeoSectionScreen extends StatelessWidget {
  const SeoSectionScreen({super.key, required this.title, required this.index, required this.campaign, required this.data});
  final String title; final int index; final Map<String, dynamic> campaign; final Map<String, dynamic> data;
  String get id => (campaign['id'] ?? campaign['campaign_id'] ?? '').toString();
  @override Widget build(BuildContext context) {
    final descriptions = const ['Prepare findings, submit the audit and complete manager review.', 'Capture the starting benchmark after audit approval, then lock it.', 'Review ranking summary and top-10 performance.', 'Add keywords, import the exact Excel template and record ranking snapshots.', 'Track competitor observations and their data source.', 'Create monthly cycles, assign activities and move work through review.', 'Log issues from identified through verification or reopening.', 'Record before/after page metadata and optimisation evidence.', 'Track backlink delivery, verification and live dates.', 'Store period metrics from manual, GA4, Search Console or import.', 'Create, submit, approve and publish client reports.'];
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              CommonTopBar(title: title, compact: compact),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(text: descriptions[index]),
                    const SizedBox(height: 14),
                    _DataPreview(data: data, section: title),
                    const SizedBox(height: 14),
                    _ActionCard(index: index, campaignId: id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PrimaryBottomNavigation(currentTab: AppBottomNavTab.profile),
    );
  }
}

class _CampaignCard extends StatelessWidget { const _CampaignCard({required this.campaign, required this.value, required this.onTap}); final Map<String, dynamic> campaign; final String Function(Map<String, dynamic>, String, [String]) value; final VoidCallback onTap; @override Widget build(BuildContext context) { final status = value(campaign, 'status', 'draft').replaceAll('_', ' '); return Material(color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE0E7F1))), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.travel_explore_rounded, color: Color(0xFF0F766E), size: 22)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value(campaign, 'name', 'Unnamed campaign'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF172B4D))), const SizedBox(height: 4), Text(value(campaign, 'website_url', 'Website not provided'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))), const SizedBox(height: 7), Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)))])), const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8))])))); } }
class _CampaignHero extends StatelessWidget { const _CampaignHero({required this.campaign}); final Map<String, dynamic> campaign; @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF155E75)]), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.insights_rounded, color: Colors.white, size: 28), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((campaign['website_url'] ?? 'SEO delivery workspace').toString(), style: const TextStyle(color: Colors.white, fontSize: 13)), const SizedBox(height: 4), Text('${campaign['target_country'] ?? 'Campaign'}  •  ${(campaign['status'] ?? 'draft').toString().toUpperCase()}', style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 11, fontWeight: FontWeight.w600))]))])); }
class _FlowSection extends StatelessWidget { const _FlowSection({required this.title, required this.icon, required this.data, required this.onTap}); final String title; final IconData icon; final Map<String, dynamic> data; final VoidCallback onTap; @override Widget build(BuildContext context) => Material(color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE0E7F1))), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2), leading: Icon(icon, color: const Color(0xFF0F766E), size: 22), title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF172B4D))), subtitle: Text('Open workflow', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))), trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20)))); }
class _InfoCard extends StatelessWidget { const _InfoCard({required this.text}); final String text; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE0E7F1))), child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4))); }
class _DataPreview extends StatelessWidget { const _DataPreview({required this.data, required this.section}); final Map<String, dynamic> data; final String section; @override Widget build(BuildContext context) { final keys = data.keys.take(5).toList(); return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE0E7F1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Workspace data', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF172B4D))), const SizedBox(height: 8), if (keys.isEmpty) const Text('No records returned yet.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))) else ...keys.map((key) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('$key: ${data[key]}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))))])); } }
class _ActionCard extends StatelessWidget { const _ActionCard({required this.index, required this.campaignId}); final int index; final String campaignId; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFEFFAF8), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFB7E4DE))), child: Text(index == 0 ? 'Use the controls above to save findings, submit the audit and review it.' : 'Use this workspace stage to record evidence and move the documented workflow forward.', style: const TextStyle(fontSize: 13, color: Color(0xFF115E59), height: 1.4))); }
class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: const Color(0xFF0F766E)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172B4D),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (action != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: action, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateCampaignDialog extends StatefulWidget { const _CreateCampaignDialog(); @override State<_CreateCampaignDialog> createState() => _CreateCampaignDialogState(); }
class _CreateCampaignDialogState extends State<_CreateCampaignDialog> { final _name = TextEditingController(); final _url = TextEditingController(); final _industry = TextEditingController(); final _country = TextEditingController(); final _goals = TextEditingController(); @override void dispose() { _name.dispose(); _url.dispose(); _industry.dispose(); _country.dispose(); _goals.dispose(); super.dispose(); } Widget _field(String label, TextEditingController c, {TextInputType? type, int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, keyboardType: type, maxLines: maxLines, decoration: InputDecoration(labelText: label, isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))); @override Widget build(BuildContext context) => AlertDialog(title: const Text('Create SEO campaign'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [_field('Campaign name', _name), _field('Website URL', _url, type: TextInputType.url), _field('Industry', _industry), _field('Target country', _country), _field('SEO goals', _goals, maxLines: 3)])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (_name.text.trim().isEmpty || _url.text.trim().isEmpty) return; Navigator.pop(context, {'name': _name.text.trim(), 'website_url': _url.text.trim(), 'industry': _industry.text.trim(), 'target_country': _country.text.trim(), 'target_locations': '', 'target_language': 'English', 'search_engine': 'Google', 'devices': ['desktop', 'mobile'], 'start_date': DateTime.now().toIso8601String().split('T').first, 'goals': _goals.text.trim(), 'reporting_frequency': 'monthly', 'status': 'draft', 'members': []}); }, child: const Text('Create'))]); }
