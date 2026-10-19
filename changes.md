# Lead Management API

Base URL: `http://localhost:8000/api/v1/lead-management`

This document is the mobile app integration guide for the current Lead Management flow. The `{source}/{id}` pair identifies the original lead record. For manually created leads use `source=lead`; for imported leads use the source returned by the list API.

Auth: All endpoints require Sanctum Bearer token.

```bash
TOKEN="your_sanctum_token"
BASE_URL="http://localhost:8000/api/v1/lead-management"
```

## 1. List Leads

```bash
curl -X GET "http://localhost:8000/api/v1/lead-management?search=john&status=new" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
```

Query parameters:

- `search`: searches name, email, phone, company and source.
- `status`: filter by a status slug.
- `source`: filter by source slug.
- `page`: page number.
- `per_page`: number of records per page.

The response includes `pagination`, `sources`, `tabCounts`, `statusOptions` and `staff` for building the mobile list and filters.

## 2. Lead Details

```bash
curl -X GET "http://localhost:8000/api/v1/lead-management/lead/1/view" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
```

## 3. Lead Assignment & History

### 3.1 Lead Assignments

```bash
curl -X GET "http://localhost:8000/api/v1/lead-management/lead/1/assignment" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
```

### 3.2 Lead Status History

```bash
curl -X GET "http://localhost:8000/api/v1/lead-management/lead/1/status-history" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
```

### 3.3 Lead Notes List

```bash
curl -X GET "http://localhost:8000/api/v1/lead-management/lead/1/note" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
```

### 3.4 Lead Reminders List

```bash
curl -X GET "http://localhost:8000/api/v1/lead-management/lead/1/reminder" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
```

## 4. Assign Lead

```bash
curl -X POST "http://localhost:8000/api/v1/lead-management/lead/1/assign" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "assigned_user_ids": [3, 5],
    "assignment_note": "Assigning for quick follow-up"
  }'
```

## 5. Bulk Assign Leads

```bash
curl -X POST "http://localhost:8000/api/v1/lead-management/bulk-assign" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "assigned_user_ids": [3, 5],
    "selected_leads": [
      {"source": "lead", "id": 1},
      {"source": "meta", "id": 12}
    ]
  }'
```

## 6. Update Lead Status

```bash
curl -X PATCH "http://localhost:8000/api/v1/lead-management/lead/1/status" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "contacted",
    "remarks": "Spoke with client",
    "lost_reason": null,
    "won_value": null
  }'
```

## 7. Add Followup

```bash
curl -X POST "http://localhost:8000/api/v1/lead-management/lead/1/followup" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "followup_date": "2026-10-19 11:30:00",
    "followup_type": "call",
    "outcome": "interested",
    "discussion_notes": "Customer is interested and asked for a proposal.",
    "next_followup_date": "2026-10-22 10:00:00",
    "lead_status_after_followup": "qualified",
    "create_reminder": true,
    "reminder_type": "dashboard",
    "complete_scheduled_followup": true
  }'
```

Follow-up rules:

- `followup_date` is required and cannot be in the future.
- `followup_type`, `outcome` and `discussion_notes` are required.
- `next_followup_date` must be in the future when supplied.
- `callback_later` and `meeting_scheduled` require `next_followup_date` unless the lead is being closed.
- `converted` outcome requires `lead_status_after_followup=converted`.
- `lost` outcome requires `lead_status_after_followup=lost` and `lost_reason`.
- A closed lead (`converted`, `lost` or `junk`) cannot receive another follow-up.
- When a lead is closed, its pending next follow-up is cleared.
- `create_reminder=true` creates a normal dashboard reminder. Firebase push notifications are not used.

Allowed `followup_type` values: `call`, `whatsapp`, `email`, `meeting`, `demo`, `video_call`, `site_visit`, `proposal_sent`, `quotation_sent`.

Allowed `outcome` values: `interested`, `not_interested`, `callback_later`, `converted`, `no_response`, `meeting_scheduled`, `proposal_requested`, `negotiation`, `lost`.

## 8. Followup History

```bash
curl -X GET "http://localhost:8000/api/v1/lead-management/lead/1/followups" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
```

## 9. Add Note

```bash
curl -X POST "http://localhost:8000/api/v1/lead-management/lead/1/note" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "note": "Client requested revised timeline",
    "is_private": true
  }'
```

## 10. Add Reminder

```bash
curl -X POST "http://localhost:8000/api/v1/lead-management/lead/1/reminder" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "remind_at": "2026-05-30 09:30:00",
    "reminder_type": "dashboard"
  }'
```

## 11. Activity Timeline

```bash
curl -X GET "http://localhost:8000/api/v1/lead-management/lead/1/timeline" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
```

## 12. Convert Lead

```bash
curl -X POST "http://localhost:8000/api/v1/lead-management/lead/1/convert" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": 7,
    "conversion_value": 50000
  }'
```

## 13. Escalate Lead

```bash
curl -X POST "http://localhost:8000/api/v1/lead-management/lead/1/escalate" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "escalated_to": 4,
    "reason": "Need manager intervention"
  }'
```

## 14. Performance Stats

```bash
curl -X GET "http://localhost:8000/api/v1/lead-management/performance/stats" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
```

## 15. Delete Lead

```bash
curl -X DELETE "http://localhost:8000/api/v1/lead-management/lead/1" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
```

## Valid Source Values

- `lead`
- `digital_marketing`
- `webapp`
- `meta`
- `google`
- `contactform`
- `enquiryform`
- `indiamart`
- `justdial`

## Current Status Flow

```text
new
  -> attempted_contact
  -> contacted
  -> qualified
  -> demo_scheduled
  -> proposal_sent
  -> negotiation
  -> converted | lost | junk
```

The mobile app should send the status selected after a conversation in `lead_status_after_followup`. Use the dedicated status endpoint when changing a status without recording a conversation.

## Normal In-App Notifications and Reminders

Lead creation, assignment and follow-up events create normal database/dashboard notifications for the relevant users. The app should load them from:

```text
GET   /api/v1/notifications
PATCH /api/v1/notifications/{notification_id}/read
PATCH /api/v1/notifications/read-all
```

Follow-up reminders are stored as dashboard reminders and should be read through `GET /{source}/{id}/reminder` or the app's reminder list. Firebase configuration and FCM token registration are not required.

## Common Error Handling

Validation failures return HTTP `422` with field-level errors. Typical fields are `outcome`, `discussion_notes`, `next_followup_date`, `lead_status_after_followup` and `lost_reason`. A request against a closed lead returns a validation error instead of creating another conversation.