import 'package:mycrm/providers/lead_provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycrm/services/api_service.dart';

class _Adapter implements HttpClientAdapter {
  dynamic body = <String, dynamic>{'success': true};
  int status = 200;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Adapter adapter;
  late ApiService api;
  setUp(() {
    adapter = _Adapter();
    final client = Dio(
      BaseOptions(headers: {'Authorization': 'Bearer test-token'}),
    );
    client.httpClientAdapter = adapter;
    api = ApiService.withClient(client);
  });
  test('unified list sends filters and reads documented metadata', () async {
    adapter.body = {
      'leads': [
        {
          'source_type': 'meta',
          'source_id': 23,
          'name': null,
          'number': '+919876543210',
        },
      ],
      'pagination': {
        'current_page': 2,
        'last_page': 4,
        'total': 79,
        'per_page': 25,
      },
      'statusOptions': {'new': 'New', 'qualified': 'Qualified'},
      'sources': {'meta': 'Meta', 'contactform': 'Contact Form'},
      'tabCounts': {'meta': 43},
      'staff': [
        {'id': 12, 'name': 'Sales User'},
      ],
    };
    final page = await api.getLeadsListPage(
      page: 2,
      perPage: 25,
      search: 'john',
      status: 'qualified',
      source: 'meta',
    );
    expect(adapter.requests.single.queryParameters, {
      'page': 2,
      'per_page': 25,
      'search': 'john',
      'status': 'qualified',
      'source': 'meta',
    });
    expect(page.currentPage, 2);
    expect(page.lastPage, 4);
    expect(page.total, 79);
    expect(page.items.single.managementId, '23');
    expect(page.statusOptions['qualified'], 'Qualified');
    expect(page.sources['contactform'], 'Contact Form');
    expect(page.tabCounts['meta'], 43);
    expect(page.staff.single['id'], 12);
  });
  test(
    'nested pagination remains compatible with the existing list response',
    () async {
      adapter.body = {
        'data': {
          'leads': {
            'data': [
              {'id': 79, 'source_type': 'lead', 'source_id': 79},
            ],
            'current_page': 1,
            'last_page': 3,
            'total': 51,
            'per_page': 25,
          },
          'statusOptions': ['new', 'qualified'],
        },
      };
      final page = await api.getLeadsListPage();
      expect(page.items.single.managementId, '79');
      expect(page.total, 51);
      expect(page.lastPage, 3);
    },
  );
  test('detail keeps pipeline, profile and source identity', () async {
    adapter.body = {
      'data': {
        'lead': {'id': 23, 'name': 'Customer'},
        'leadModel': {'id': 900, 'status': 'qualified'},
        'statusOptions': {'qualified': 'Qualified'},
      },
    };
    final lead = await api.getLeadManagementDetailView(
      sourceType: 'meta',
      sourceId: '23',
    );
    expect(adapter.requests.single.path, endsWith('/meta/23/view'));
    expect(lead.name, 'Customer');
    expect(lead.managementId, '23');
    expect(lead.status, 'qualified');
    expect(lead.statusOptions['qualified'], 'Qualified');
  });
  test('history accepts bare arrays and named paginated lists', () async {
    adapter.body = {
      'data': [
        {'id': 1, 'outcome': 'interested'},
      ],
    };
    expect(
      (await api.getLeadFollowups(
        sourceType: 'meta',
        sourceId: '23',
      )).single['outcome'],
      'interested',
    );
    adapter.body = {
      'data': {
        'timeline': {
          'data': [
            {'id': 2, 'type': 'lead_created'},
          ],
        },
      },
    };
    expect(
      (await api.getLeadTimeline(
        sourceType: 'meta',
        sourceId: '23',
      )).single['type'],
      'lead_created',
    );
  });
  test(
    'lost conversation sends closure and scheduled-action payload',
    () async {
      await api.createLeadFollowup(
        sourceType: 'meta',
        leadId: '23',
        followupDate: '2026-10-19 11:30:00',
        followupType: 'call',
        outcome: 'lost',
        discussionNotes: 'Customer chose another vendor.',
        leadStatusAfterFollowup: 'lost',
        lostReason: 'Competitor selected',
      );
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, endsWith('/meta/23/followup'));
      expect(request.data['complete_scheduled_followup'], true);
      expect(request.data['lost_reason'], 'Competitor selected');
      expect(request.data['lead_status_after_followup'], 'lost');
      expect(request.data.containsKey('next_followup_date'), false);
    },
  );
  test('bulk assignment and deletion use original source IDs', () async {
    await api.bulkAssignLeads(
      assignedUserIds: ['12', '15'],
      selectedLeads: [
        {'source_type': 'meta', 'source_id': '23', 'id': '900'},
      ],
    );
    expect(adapter.requests.last.data['selected_leads'], [
      {'source': 'meta', 'id': 23},
    ]);
    expect(adapter.requests.last.data['assigned_user_ids'], [12, 15]);
    await api.deleteManagedLead(source: 'meta', id: '23');
    expect(adapter.requests.last.method, 'DELETE');
    expect(adapter.requests.last.path, endsWith('/lead-management/meta/23'));
  });
  test(
    'server validation errors remain available for inline display',
    () async {
      adapter.status = 422;
      adapter.body = {
        'message': 'Validation failed.',
        'errors': {
          'discussion_notes': ['Notes are required.'],
        },
      };
      await expectLater(
        api.createLeadFollowup(
          sourceType: 'lead',
          leadId: '1',
          followupDate: '2026-10-19 11:30:00',
          followupType: 'call',
          outcome: 'interested',
          discussionNotes: '',
        ),
        throwsA(
          isA<DioException>()
              .having((e) => e.response?.statusCode, 'status', 422)
              .having(
                (e) => e.response?.data['errors']['discussion_notes'],
                'field errors',
                ['Notes are required.'],
              ),
        ),
      );
    },
  );
  test(
    'database notification arrays retain pagination and unread count',
    () async {
      adapter.body = {
        'data': [
          {'id': 'n1', 'title': 'Lead assigned', 'type': 'lead_assigned'},
        ],
        'meta': {
          'current_page': 1,
          'last_page': 2,
          'per_page': 20,
          'total': 25,
          'unread_count': 8,
        },
      };
      final page = await api.getNotificationsPage();
      expect(page.items.single['type'], 'lead_assigned');
      expect(page.total, 25);
      expect(page.unreadCount, 8);
      await api.markNotificationAsRead('n1');
      expect(adapter.requests.last.method, 'PATCH');
      expect(adapter.requests.last.path, endsWith('/notifications/n1/read'));
    },
  );
  test(
    'manual lead permits empty identity and multiple assignments and tags',
    () async {
      await api.createLead(
        name: '',
        source: '',
        status: 'new',
        assigned: [12, 15],
        tags: ['warm', 'follow-up'],
      );
      expect(adapter.requests.single.path, endsWith('/leads'));
      expect(adapter.requests.single.data['assigned'], [12, 15]);
      expect(adapter.requests.single.data['tags'], ['warm', 'follow-up']);
      expect(adapter.requests.single.data['name'], '');
    },
  );
  test(
    'deleting an imported lead preserves a manual lead with the same numeric ID',
    () async {
      adapter.body = {
        'leads': [
          {'id': 23, 'source_type': 'lead', 'source_id': 23, 'name': 'Manual'},
          {
            'id': 23,
            'source_type': 'meta',
            'source_id': 23,
            'name': 'Imported',
          },
        ],
        'pagination': {'current_page': 1, 'last_page': 1, 'total': 2},
      };
      final provider = LeadProvider(apiService: api);
      await provider.loadLeads();
      final imported = provider.leads.last;
      adapter.body = {'success': true};
      await provider.deleteLead(imported);
      expect(provider.leads.single.name, 'Manual');
      expect(provider.totalLeads, 1);
      expect(adapter.requests.last.path, endsWith('/lead-management/meta/23'));
      provider.dispose();
    },
  );
}
