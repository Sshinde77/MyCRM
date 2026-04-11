import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';

class VendorRenewalScreen extends StatelessWidget {
  const VendorRenewalScreen({super.key});

  static const List<_ServiceItem> _services = [
    _ServiceItem(
      title: 'Hosting Infrastructure',
      client: 'Roshan Yadav',
      vendor: 'Hostinger India',
      startDate: '15 Feb 2024',
      endDate: '14 Feb 2025',
      billing: 'Annual',
      status: 'Active',
      expiryNote: 'Renews tomorrow',
      showExpiryAlert: true,
    ),
    _ServiceItem(
      title: 'Email Service Suite',
      client: 'Priya Sharma',
      vendor: 'Google Workspace',
      startDate: '08 Apr 2024',
      endDate: '07 Apr 2025',
      billing: 'Monthly',
      status: 'Active',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width <= 360;
    final side = compact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(compact: compact),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(side, compact ? 16 : 18, side, 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        _FilterCard(compact: compact),
                        SizedBox(height: compact ? 16 : 18),
                        _AddServiceButton(compact: compact),
                        SizedBox(height: compact ? 16 : 18),
                        ..._services.map(
                          (service) => Padding(
                            padding: EdgeInsets.only(bottom: compact ? 14 : 16),
                            child: _ServiceCard(
                              service: service,
                              compact: compact,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 72 : 78,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: const Color(0xFF475569),
              size: compact ? 30 : 32,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Vendor Renewal',
              style: AppTextStyles.style(
                color: const Color(0xFF17213A),
                fontSize: compact ? 21 : 23,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.search_rounded,
            color: const Color(0xFF475569),
            size: compact ? 31 : 33,
          ),
          SizedBox(width: compact ? 16 : 18),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: const Color(0xFF475569),
                size: compact ? 31 : 33,
              ),
              const Positioned(
                right: 1,
                top: 2,
                child: CircleAvatar(
                  radius: 3.5,
                  backgroundColor: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 24 : 28),
        border: Border.all(color: const Color(0xFFDCE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                color: const Color(0xFF475569),
                size: compact ? 21 : 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Filter Renewal Period',
                style: AppTextStyles.style(
                  color: const Color(0xFF334155),
                  fontSize: compact ? 16 : 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 16 : 18),
          Row(
            children: [
              Expanded(
                child: _DateField(label: 'From Date', compact: compact),
              ),
              SizedBox(width: compact ? 12 : 14),
              Expanded(
                child: _DateField(label: 'To Date', compact: compact),
              ),
            ],
          ),
          SizedBox(height: compact ? 16 : 18),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Filter',
                  filled: true,
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 12 : 14),
              Expanded(
                child: _ActionButton(
                  label: 'Clear',
                  filled: false,
                  compact: compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF64748B),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: compact ? 8 : 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 13 : 14,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(color: const Color(0xFFDCE6F2)),
          ),
          child: Text(
            'mm/dd/yyyy',
            style: AppTextStyles.style(
              color: const Color(0xFF17213A),
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.compact,
  });

  final String label;
  final bool filled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 52 : 56,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF156CF1) : Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(
          color: filled ? const Color(0xFF156CF1) : const Color(0xFFDCE6F2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.style(
          color: filled ? Colors.white : const Color(0xFF334155),
          fontSize: compact ? 16 : 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddServiceButton extends StatelessWidget {
  const _AddServiceButton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: compact ? 18 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF156CF1),
        borderRadius: BorderRadius.circular(compact ? 20 : 22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22156CF1),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, color: Colors.white, size: compact ? 28 : 32),
          SizedBox(width: compact ? 10 : 12),
          Text(
            'Add New Vendor',
            style: AppTextStyles.style(
              color: Colors.white,
              fontSize: compact ? 17 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.compact});

  final _ServiceItem service;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 22 : 24),
        border: Border.all(color: const Color(0xFFDCE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 18,
              compact ? 16 : 18,
              compact ? 16 : 18,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VENDOR DETAILS',
                            style: AppTextStyles.style(
                              color: const Color(0xFF94A3B8),
                              fontSize: compact ? 11 : 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: compact ? 8 : 10),
                          Text(
                            service.title,
                            style: AppTextStyles.style(
                              color: const Color(0xFF17213A),
                              fontSize: compact ? 19 : 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 14,
                        vertical: compact ? 6 : 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        service.status,
                        style: AppTextStyles.style(
                          color: const Color(0xFF15803D),
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 14 : 16),
                _InfoRow(
                  icon: Icons.storefront_outlined,
                  text: 'Vendor: ${service.vendor}',
                  compact: compact,
                ),
                SizedBox(height: compact ? 10 : 12),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  text: 'Client: ${service.client}',
                  compact: compact,
                ),
                SizedBox(height: compact ? 16 : 18),
                const Divider(height: 1, color: Color(0xFFEAF0F6)),
                SizedBox(height: compact ? 12 : 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetaColumn(
                        label: 'Start',
                        value: service.startDate,
                        compact: compact,
                      ),
                    ),
                    _VerticalDivider(compact: compact),
                    Expanded(
                      child: _MetaColumn(
                        label: 'End',
                        value: service.endDate,
                        compact: compact,
                      ),
                    ),
                    _VerticalDivider(compact: compact),
                    Expanded(
                      child: _MetaColumn(
                        label: 'Billing',
                        value: service.billing,
                        compact: compact,
                      ),
                    ),
                  ],
                ),
                if (service.showExpiryAlert) ...[
                  SizedBox(height: compact ? 14 : 16),
                  const Divider(height: 1, color: Color(0xFFEAF0F6)),
                  SizedBox(height: compact ? 12 : 14),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFEF4444),
                        size: compact ? 20 : 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        service.expiryNote!,
                        style: AppTextStyles.style(
                          color: const Color(0xFFEF4444),
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: compact ? 14 : 16),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAF0F6)),
          SizedBox(
            height: compact ? 58 : 62,
            child: Row(
              children: const [
                Expanded(
                  child: _CardAction(icon: Icons.remove_red_eye_outlined),
                ),
                _ActionDivider(),
                Expanded(child: _CardAction(icon: Icons.edit_outlined)),
                _ActionDivider(),
                Expanded(child: _CardAction(icon: Icons.mail_outline_rounded)),
                _ActionDivider(),
                Expanded(
                  child: _CardAction(icon: Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.compact,
  });

  final IconData icon;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: compact ? 23 : 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.style(
              color: const Color(0xFF334155),
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaColumn extends StatelessWidget {
  const _MetaColumn({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            color: const Color(0xFF94A3B8),
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.style(
            color: const Color(0xFF17213A),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 50 : 56,
      width: 1,
      color: const Color(0xFFEAF0F6),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, color: const Color(0xFF64748B), size: 28));
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: const Color(0xFFEAF0F6));
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.title,
    required this.client,
    required this.vendor,
    required this.startDate,
    required this.endDate,
    required this.billing,
    required this.status,
    this.expiryNote,
    this.showExpiryAlert = false,
  });

  final String title;
  final String client;
  final String vendor;
  final String startDate;
  final String endDate;
  final String billing;
  final String status;
  final String? expiryNote;
  final bool showExpiryAlert;
}

