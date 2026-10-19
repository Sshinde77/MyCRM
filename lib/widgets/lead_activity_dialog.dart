import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/lead_flow.dart';
import '../models/lead_model.dart';
import '../services/api_service.dart';
import '../core/utils/app_error_handler.dart';

/// One form for completed conversations and standalone status changes.
class LeadActivityDialog extends StatefulWidget {
  const LeadActivityDialog({
    super.key,
    required this.lead,
    this.conversation = true,
    this.statusOptions = const {},
  });
  final LeadModel lead;
  final bool conversation;
  final Map<String, String> statusOptions;
  @override
  State<LeadActivityDialog> createState() => _LeadActivityDialogState();
}

class _LeadActivityDialogState extends State<LeadActivityDialog> {
  final _notes = TextEditingController();
  final _reason = TextEditingController();
  final _value = TextEditingController();
  late String _status;
  String _type = 'call';
  String? _outcome;
  DateTime _date = DateTime.now();
  DateTime? _next;
  bool _reminder = false;
  bool _complete = true;
  bool _saving = false;
  Map<String, String> _errors = {};
  String? _error;
  Map<String, String> get _statuses => widget.statusOptions.isNotEmpty
      ? widget.statusOptions
      : widget.lead.statusOptions.isNotEmpty
      ? widget.lead.statusOptions
      : {for (final s in LeadFlow.statuses) s: LeadFlow.label(s)};
  bool get _closed => LeadFlow.isClosed(_effectiveStatus);
  String get _effectiveStatus =>
      _status == 'no_change' ? (widget.lead.status ?? 'new') : _status;
  @override
  void initState() {
    super.initState();
    _status = widget.conversation ? 'no_change' : widget.lead.status ?? 'new';
  }

  @override
  void dispose() {
    _notes.dispose();
    _reason.dispose();
    _value.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, String key) => InputDecoration(
    labelText: label,
    errorText: _errors[key],
    border: const OutlineInputBorder(),
    errorMaxLines: 3,
  );
  Future<void> _pick(bool next) async {
    final now = DateTime.now();
    final initial = next ? _next ?? now : _date;
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: next ? DateTime(now.year, now.month, now.day) : DateTime(2000),
      lastDate: next ? DateTime(2100) : now,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      final date = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
      if (next) {
        _next = date;
      } else {
        _date = date;
      }
    });
  }

  Widget _dateField(bool next) {
    final value = next ? _next : _date;
    return InkWell(
      onTap: _saving ? null : () => _pick(next),
      child: InputDecorator(
        decoration: _dec(
          next ? 'Next follow-up date' : 'Conversation date *',
          next ? 'next_followup_date' : 'followup_date',
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null
                    ? 'Choose date and time'
                    : DateFormat('dd MMM yyyy, hh:mm a').format(value),
              ),
            ),
            if (next && value != null)
              IconButton(
                tooltip: 'Clear next date',
                onPressed: _saving
                    ? null
                    : () => setState(() {
                        _next = null;
                        _reminder = false;
                      }),
                icon: const Icon(Icons.clear),
              )
            else
              const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final errors = widget.conversation
        ? LeadFlow.validateConversation(
            now: DateTime.now(),
            date: _date,
            type: _type,
            outcome: _outcome ?? '',
            notes: _notes.text,
            status: _effectiveStatus,
            nextDate: _next,
            lostReason: _reason.text,
            wonValue: _effectiveStatus == 'converted' ? _value.text : '',
            createReminder: _reminder,
          )
        : <String, String>{};
    if (_effectiveStatus == 'lost' && _reason.text.trim().isEmpty)
      errors['lost_reason'] = 'Lost reason is required.';
    final amount = double.tryParse(_value.text.trim());
    if (_effectiveStatus == 'converted' &&
        _value.text.trim().isNotEmpty &&
        (amount == null || !amount.isFinite || amount < 0)) {
      errors['won_value'] = 'Enter a valid value of zero or more.';
    }
    if (widget.conversation && !_closed && _next == null && !_complete)
      errors['next_followup_date'] =
          'Choose a next date or complete the pending action.';
    setState(() {
      _errors = errors;
      _error = null;
    });
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    try {
      final api = ApiService.instance;
      if (widget.conversation) {
        if (widget.lead.isClosed)
          throw Exception('Closed leads cannot receive another conversation.');
        await api.createLeadFollowup(
          sourceType: widget.lead.managementSource,
          leadId: widget.lead.managementId,
          followupDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(_date),
          followupType: _type,
          outcome: _outcome!,
          discussionNotes: _notes.text,
          nextFollowupDate: _closed || _next == null
              ? null
              : DateFormat('yyyy-MM-dd HH:mm:ss').format(_next!),
          leadStatusAfterFollowup: _status == 'no_change' ? null : _status,
          lostReason: _effectiveStatus == 'lost' ? _reason.text.trim() : null,
          wonValue: _effectiveStatus == 'converted' ? amount : null,
          createReminder: !_closed && _reminder,
          reminderType: 'dashboard',
          completeScheduledFollowup: _complete,
        );
      } else {
        await api.updateLeadStatus(
          sourceType: widget.lead.managementSource,
          leadId: widget.lead.managementId,
          status: _status,
          remarks: _notes.text,
          lostReason: _status == 'lost' ? _reason.text.trim() : null,
          wonValue: _status == 'converted' ? amount : null,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final fields = error is DioException && error.response?.data is Map
          ? (error.response!.data as Map)['errors']
          : null;
      setState(() {
        _saving = false;
        _error = AppErrorHandler.messageFromError(error);
        if (fields is Map)
          _errors = {
            for (final e in fields.entries)
              e.key.toString(): e.value is List
                  ? (e.value as List).join('\n')
                  : e.value.toString(),
          };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = {..._statuses};
    if (_status != 'no_change')
      statuses.putIfAbsent(_status, () => LeadFlow.label(_status));
    final fields = <Widget>[
      Text(
        widget.lead.displayName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.red)),
      if (widget.conversation) ...[
        _dateField(false),
        DropdownButtonFormField<String>(
          initialValue: _type,
          isExpanded: true,
          decoration: _dec('Conversation type *', 'followup_type'),
          items: [
            for (final t in LeadFlow.types)
              DropdownMenuItem(value: t, child: Text(LeadFlow.label(t))),
          ],
          onChanged: _saving ? null : (v) => setState(() => _type = v!),
        ),
        DropdownButtonFormField<String>(
          initialValue: _outcome,
          isExpanded: true,
          decoration: _dec('Outcome *', 'outcome'),
          items: [
            for (final o in LeadFlow.outcomes)
              DropdownMenuItem(value: o, child: Text(LeadFlow.label(o))),
          ],
          onChanged: _saving
              ? null
              : (v) => setState(() {
                  _outcome = v;
                  if (v == 'lost' || v == 'converted') _status = v!;
                }),
        ),
      ],
      DropdownButtonFormField<String>(
        key: ValueKey(_status),
        initialValue: _status,
        isExpanded: true,
        decoration: _dec(
          widget.conversation ? 'Status after conversation' : 'Status',
          widget.conversation ? 'lead_status_after_followup' : 'status',
        ),
        items: [
          if (widget.conversation)
            const DropdownMenuItem(
              value: 'no_change',
              child: Text('No change'),
            ),
          for (final e in statuses.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: _saving ? null : (v) => setState(() => _status = v!),
      ),
      if (_effectiveStatus == 'lost')
        TextField(
          controller: _reason,
          enabled: !_saving,
          maxLines: 2,
          decoration: _dec('Lost reason *', 'lost_reason'),
        ),
      if (_effectiveStatus == 'converted')
        TextField(
          controller: _value,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _dec('Won value (optional)', 'won_value'),
        ),
      TextField(
        controller: _notes,
        enabled: !_saving,
        minLines: 3,
        maxLines: 5,
        maxLength: widget.conversation ? 5000 : null,
        decoration: _dec(
          widget.conversation ? 'Discussion notes *' : 'Remarks',
          widget.conversation ? 'discussion_notes' : 'remarks',
        ),
      ),
      if (widget.conversation && !_closed) ...[
        _dateField(true),
        if (_next == null)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Complete pending action without scheduling another',
            ),
            value: _complete,
            onChanged: _saving ? null : (v) => setState(() => _complete = v!),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Create dashboard reminder'),
          value: _reminder,
          onChanged: _saving ? null : (v) => setState(() => _reminder = v),
        ),
      ],
      if (widget.conversation && _closed)
        const Text('Closing this lead clears its pending next action.'),
    ];
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          widget.conversation ? 'Log Conversation' : 'Update Lead Status',
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final field in fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: field,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }
}
