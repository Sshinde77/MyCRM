import 'package:flutter_test/flutter_test.dart';
import 'package:mycrm/core/services/lead_priority_cache.dart';
import 'package:mycrm/models/lead_flow.dart';
import 'package:mycrm/models/lead_model.dart';

void main() {
  setUp(LeadPriorityCache.clear);

  test('contactform detail uses pipeline high over profile medium', () {
    final listLead = LeadModel.fromJson({
      'source_type': 'contactform',
      'source_id': 30,
      'priority': 'medium',
    });
    expect(listLead.isHighPriority, isFalse);

    final detail = LeadModel.fromJson({
      'success': true,
      'data': {
        'lead': {
          'source_type': 'contactform',
          'source_id': 30,
          'priority': 'medium',
        },
        'leadModel': {'id': 77, 'priority': 'high'},
        'lead_resource': {'id': 77, 'priority': 'high'},
      },
    });

    expect(detail.managementSource, listLead.managementSource);
    expect(detail.managementId, listLead.managementId);
    expect(detail.priority, 'high');
    expect(detail.isHighPriority, isTrue);
  });

  for (final source in LeadFlow.sources) {
    test('$source retains high priority when profile priority is empty', () {
      for (final empty in [null, '']) {
        LeadPriorityCache.clear();
        final lead = LeadModel.fromJson({
          'source_type': source,
          'source_id': 30,
          'priority': 'high',
          'lead': {'id': 30, 'priority': empty},
          'leadModel': {'priority': empty},
        });

        expect(lead.priority, 'high');
        expect(lead.isHighPriority, isTrue);
      }
    });

    test('$source reads priority from a pipeline nested in its profile', () {
      final lead = LeadModel.fromJson({
        'source_type': source,
        'source_id': 30,
        'lead': {
          'id': 30,
          'leadModel': {'priority': 'high'},
        },
      });

      expect(lead.isHighPriority, isTrue);
    });

    test('$source uses the pipeline priority when provided', () {
      final lead = LeadModel.fromJson({
        'source_type': source,
        'source_id': 30,
        'priority': 'high',
        'leadModel': {'priority': 'low'},
      });

      expect(lead.isHighPriority, isFalse);
    });
  }
}
