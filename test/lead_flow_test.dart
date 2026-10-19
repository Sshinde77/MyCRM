import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycrm/models/lead_flow.dart';
import 'package:mycrm/models/lead_model.dart';
import 'package:mycrm/widgets/lead_activity_dialog.dart';

void main() {
  final now = DateTime(2026, 10, 19, 12);
  Map<String, String> validate({
    String outcome = 'interested',
    String status = 'qualified',
    DateTime? date,
    DateTime? next,
    String notes = 'Customer requested a proposal.',
    String reason = '',
    String value = '',
    bool reminder = false,
  }) => LeadFlow.validateConversation(
    now: now,
    date: date ?? now,
    type: 'call',
    outcome: outcome,
    notes: notes,
    status: status,
    nextDate: next,
    lostReason: reason,
    wonValue: value,
    createReminder: reminder,
  );

  test('completed interactions require notes and cannot be future dated', () {
    expect(validate(notes: '   '), contains('discussion_notes'));
    expect(
      validate(notes: List.filled(5001, 'a').join()),
      contains('discussion_notes'),
    );
    expect(
      validate(date: now.add(const Duration(minutes: 1))),
      contains('followup_date'),
    );
    expect(validate(date: now.subtract(const Duration(days: 1))), isEmpty);
  });
  for (final outcome in ['callback_later', 'meeting_scheduled']) {
    test('$outcome requires a future next action for open leads', () {
      expect(validate(outcome: outcome), contains('next_followup_date'));
      expect(
        validate(outcome: outcome, next: now),
        contains('next_followup_date'),
      );
      expect(
        validate(outcome: outcome, next: now.add(const Duration(days: 1))),
        isEmpty,
      );
    });
  }
  test('conversion and loss must select their matching status', () {
    expect(
      validate(outcome: 'converted'),
      contains('lead_status_after_followup'),
    );
    expect(validate(outcome: 'lost'), contains('lead_status_after_followup'));
    expect(validate(outcome: 'lost', status: 'lost'), contains('lost_reason'));
    expect(
      validate(outcome: 'lost', status: 'lost', reason: 'Competitor selected'),
      isEmpty,
    );
    expect(
      validate(outcome: 'converted', status: 'converted', value: '0'),
      isEmpty,
    );
    expect(
      validate(outcome: 'converted', status: 'converted', value: '-1'),
      contains('won_value'),
    );
    expect(
      validate(outcome: 'converted', status: 'converted', value: 'NaN'),
      contains('won_value'),
    );
  });
  test('closing removes the need to schedule another callback', () {
    expect(validate(outcome: 'callback_later', status: 'junk'), isEmpty);
    expect(validate(reminder: true), contains('next_followup_date'));
  });
  test('imported identity survives profile and pipeline merging', () {
    final lead = LeadModel.fromJson({
      'source_type': 'meta',
      'source_id': 23,
      'lead': {
        'id': 23,
        'name': null,
        'email': null,
        'number': null,
        'source': 'Facebook Campaign',
      },
      'leadModel': {
        'id': 999,
        'status': 'qualified',
        'next_followup_date': '2026-10-22 10:00:00',
      },
      'statusOptions': {'new': 'New', 'qualified': 'Qualified'},
      'followups': [
        {'followup_date': '2026-10-17 10:00:00', 'outcome': 'no_response'},
        {'followup_date': '2026-10-19 11:00:00', 'outcome': 'interested'},
      ],
    });
    expect(lead.managementSource, 'meta');
    expect(lead.managementId, '23');
    expect(lead.id, '23');
    expect(lead.displayName, 'Unnamed Lead');
    expect(lead.status, 'qualified');
    expect(lead.nextFollowupDate, '2026-10-22 10:00:00');
    expect(lead.latestConversation['outcome'], 'interested');
    expect(lead.statusOptions['qualified'], 'Qualified');
  });
  test(
    'manual free-text source is never used as the management source type',
    () {
      final lead = LeadModel.fromJson({
        'id': 79,
        'source': 'website',
        'name': '',
      });
      expect(lead.managementSource, 'lead');
      expect(lead.managementId, '79');
    },
  );
  test('configured statuses and source options retain API slugs', () {
    expect(
      LeadFlow.options([
        {'value': 'proposal_sent', 'label': 'Proposal Sent'},
      ]),
      {'proposal_sent': 'Proposal Sent'},
    );
    expect(
      LeadFlow.options({'contactform': 'Contact Form'})['contactform'],
      'Contact Form',
    );
  });
  for (final status in ['converted', 'lost', 'junk']) {
    test('$status is a closed lead', () {
      expect(LeadModel.fromJson({'id': 1, 'status': status}).isClosed, isTrue);
    });
  }
  testWidgets(
    'conversation form requires notes and shows loss fields conditionally',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const LeadActivityDialog(
                    lead: LeadModel(id: '1', name: 'Customer', status: 'new'),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Log Conversation'), findsOneWidget);
      expect(find.text('Lost reason *'), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Select an outcome.'), findsOneWidget);
      expect(
        find.text('Enter discussion notes (maximum 5000 characters).'),
        findsOneWidget,
      );
      final statusDropdown = find.byType(DropdownButtonFormField<String>).at(2);
      await tester.ensureVisible(statusDropdown);
      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lost').last);
      await tester.pumpAndSettle();
      expect(find.text('Lost reason *'), findsOneWidget);
      expect(find.text('Next follow-up date'), findsNothing);
    },
  );
}
