# Lead Management: Current Flow and Mobile App Handoff

This document describes the current Lead Management implementation after the latest web and API updates. It is intended for the mobile app developer.

## API basics

All API routes below use the `/api/v1` prefix and require a Sanctum bearer token.

```text
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

The Lead Management API base path is:

```text
/api/v1/lead-management
```

Manual lead creation and basic lead CRUD use:

```text
/api/v1/leads
```

## Current end-to-end flow

```text
Create lead
  -> New
  -> Assign sales employee
  -> Contact customer
  -> Log conversation and outcome
  -> Set next follow-up
  -> Qualify
  -> Demo / Meeting
  -> Proposal Sent
  -> Negotiation
  -> Converted / Lost / Junk
```

Every completed customer interaction should create a follow-up record. Every open lead should have a next action or should be intentionally marked as having no next action.

## 1. New lead creation form

The web form is available at:

```text
/add-lead
```

The form currently contains these fields:

| Field | Request key | Type | Current behavior |
|---|---|---|---|
| Source | `source` | string | Optional free-text source |
| Status | `status` | select | Defaults to `new` |
| Assigned | `assigned[]` | array of user IDs | Optional multi-select |
| Tags | `tags[]` | array of strings | Optional multi-select |
| Name | `name` | string | Optional in current backend validation |
| Email Address | `email` | email | Optional; must be a valid email when supplied |
| Company | `company` | string | Optional |
| Position | `position` | string | Optional |
| Phone | `phone` | string | Optional |
| Website | `website` | URL | Optional; must be a valid URL when supplied |
| Address | `address` | string | Optional |
| City | `city` | string | Optional |
| State | `state` | string | Optional |
| Country | `country` | string | Optional |
| Zip Code | `zipCode` | string | Optional |
| Lead Value | `lead_value` | number | Optional; minimum is `0` |
| Description | `description` | text | Optional |

The current database migration and web validator allow all lead identity fields to be nullable. The app must therefore not assume that name, phone or email is always present. The UI should display a safe fallback such as `Unnamed lead` when the name is empty.

### Create lead API

```http
POST /api/v1/leads
```

Example body:

```json
{
  "source": "website",
  "status": "new",
  "assigned": [12],
  "tags": ["warm", "follow-up"],
  "name": "Rahul Sharma",
  "email": "rahul@example.com",
  "company": "Example Industries",
  "position": "Purchase Manager",
  "phone": "+919876543210",
  "website": "https://example.com",
  "address": "12 Main Road",
  "city": "Delhi",
  "state": "Delhi",
  "country": "India",
  "zipCode": "110001",
  "lead_value": 50000,
  "description": "Interested in an annual service plan."
}
```

Successful response: HTTP `201`.

The response contains:

```json
{
  "success": true,
  "message": "Lead created successfully.",
  "data": {}
}
```

After creation, the lead appears in the unified Lead Management list with `source_type=lead` and its database ID as `source_id`.

## 2. Lead Management list

```http
GET /api/v1/lead-management
```

Supported query parameters:

| Parameter | Example | Purpose |
|---|---|---|
| `search` | `rahul` | Searches name, email, phone, company and source |
| `status` | `qualified` | Filters by status slug |
| `source` | `meta` | Filters by source type |
| `page` | `1` | Page number |
| `per_page` | `25` | Page size |

The response includes `leads`, `pagination`, `staff`, `filters`, `sources`, `tabCounts` and `statusOptions`.

Each list item includes the unified source identity:

```json
{
  "source_type": "lead",
  "source_id": 79,
  "name": "Rahul Sharma",
  "email": "rahul@example.com",
  "number": "+919876543210",
  "company": "Example Industries",
  "source": "website",
  "lead_value": 50000,
  "status": "new",
  "assigned_to": "Sales User",
  "created_at": "19 Oct 2026 10:30 AM"
}
```

Use `source_type` and `source_id` in every subsequent detail, assignment, status and follow-up request. Do not use only the pipeline lead ID for imported sources.

## 3. Lead details screen

```http
GET /api/v1/lead-management/{source}/{id}/view
```

Example:

```http
GET /api/v1/lead-management/lead/79/view
```

The response contains the lead profile, pipeline model, timeline, follow-ups, notes, reminders, assignments, status history, staff list and status options.

The web page displays these areas:

1. Lead identity and source.
2. Current status.
3. Contact details, assigned team, created date and latest conversation.
4. Pipeline stage track.
5. Lead journey timeline.
6. Conversation history.
7. Notes.
8. Lead details and tags.
9. Next action card.
10. Latest outcome.
11. Status update form.

## 4. Assignment flow

List assignments:

```http
GET /api/v1/lead-management/{source}/{id}/assignment
```

Assign one or more staff members:

```http
POST /api/v1/lead-management/{source}/{id}/assign
```

```json
{
  "assigned_user_ids": [12, 15],
  "assignment_note": "Follow up within one business day."
}
```

Bulk assignment:

```http
POST /api/v1/lead-management/bulk-assign
```

```json
{
  "assigned_user_ids": [12],
  "selected_leads": [
    {"source": "lead", "id": 79},
    {"source": "meta", "id": 23}
  ]
}
```

Assignment is added to the existing team assignment. The app should show all assigned staff and should not replace existing staff unless a separate replacement workflow is introduced.

## 5. Contact and follow-up flow

Add a completed conversation:

```http
POST /api/v1/lead-management/{source}/{id}/followup
```

Example:

```json
{
  "followup_date": "2026-10-19 11:30:00",
  "followup_type": "call",
  "outcome": "interested",
  "discussion_notes": "Customer is interested and asked for a proposal.",
  "next_followup_date": "2026-10-22 10:00:00",
  "lead_status_after_followup": "qualified",
  "create_reminder": true,
  "reminder_type": "dashboard",
  "complete_scheduled_followup": true
}
```

### Follow-up fields

| Field | Required | Rules |
|---|---:|---|
| `followup_date` | Yes | Must be current or in the past |
| `followup_type` | Yes | `call`, `whatsapp`, `email`, `meeting`, `demo`, `video_call`, `site_visit`, `proposal_sent`, `quotation_sent` |
| `outcome` | Yes | See allowed outcomes below |
| `discussion_notes` | Yes | String, maximum 5000 characters |
| `next_followup_date` | No | If supplied, must be in the future |
| `lead_status_after_followup` | No | Must be a valid status slug |
| `lost_reason` | Conditional | Required when next status is `lost` |
| `won_value` | No | Numeric, minimum `0` |
| `create_reminder` | No | Boolean |
| `reminder_type` | No | `email`, `whatsapp` or `dashboard` |
| `complete_scheduled_followup` | No | Boolean; clears the current pending action when no new date is supplied |

Allowed outcomes:

```text
interested
not_interested
callback_later
converted
no_response
meeting_scheduled
proposal_requested
negotiation
lost
```

Follow-up behavior:

- `callback_later` requires a future `next_followup_date`.
- `meeting_scheduled` requires a future `next_followup_date`.
- `converted` requires `lead_status_after_followup=converted`.
- `lost` requires `lead_status_after_followup=lost` and `lost_reason`.
- A converted, lost or junk lead cannot receive another follow-up.
- Closing a lead clears its pending next action.
- A new next date replaces the previous pending next action.
- Completing a conversation without a new date clears the pending next action.

Follow-up history:

```http
GET /api/v1/lead-management/{source}/{id}/followups
```

## 6. Current status flow

The current configured status list is:

```text
new
attempted_contact
contacted
qualified
demo_scheduled
proposal_sent
negotiation
converted
lost
junk
```

Update status without logging a conversation:

```http
PATCH /api/v1/lead-management/{source}/{id}/status
```

```json
{
  "status": "proposal_sent",
  "remarks": "Proposal shared by email."
}
```

For a lost lead:

```json
{
  "status": "lost",
  "remarks": "Customer selected another vendor.",
  "lost_reason": "Competitor selected"
}
```

For a converted lead, send `won_value` when available. Status history is available at:

```http
GET /api/v1/lead-management/{source}/{id}/status-history
```

## 7. Notes, reminders and timeline

Notes:

```http
GET  /api/v1/lead-management/{source}/{id}/note
POST /api/v1/lead-management/{source}/{id}/note
```

```json
{
  "note": "Customer requested a revised timeline.",
  "is_private": false
}
```

Reminders:

```http
GET  /api/v1/lead-management/{source}/{id}/reminder
POST /api/v1/lead-management/{source}/{id}/reminder
```

```json
{
  "remind_at": "2026-10-22 09:30:00",
  "reminder_type": "dashboard"
}
```

Timeline:

```http
GET /api/v1/lead-management/{source}/{id}/timeline
```

The timeline preserves lead creation, assignment, status changes, conversations, notes and scheduled actions.

## 8. Normal in-app notifications

Firebase push notifications are no longer part of the current flow. The app should use the normal database notification API:

```http
GET   /api/v1/notifications
PATCH /api/v1/notifications/{notification_id}/read
PATCH /api/v1/notifications/read-all
```

The notification list returns `id`, `title`, `body`, `type`, `data`, `read_at`, `created_at` and pagination metadata including `unread_count`.

Lead notification types include:

```text
lead_created
lead_assigned
lead_followup_created
```

Follow-up reminders are dashboard reminders and do not require Firebase configuration or FCM token registration.

## 9. Old flow versus current flow

| Area | Old flow | Current flow |
|---|---|---|
| Lead list | Separate or legacy lead views | Unified list combines manual and external source leads |
| Lead identity | Often used only database lead ID | Uses `source_type` plus `source_id` |
| Status list | Basic form commonly exposed `new`, `contacted`, `qualified`, `converted`, `lost` | Full pipeline exposes `new`, `attempted_contact`, `contacted`, `qualified`, `demo_scheduled`, `proposal_sent`, `negotiation`, `converted`, `lost`, `junk` |
| Follow-up outcome | Outcome and notes could be omitted by API | Outcome and discussion notes are required |
| Follow-up date | API accepted a general date | Completed activity must be current/past; next action must be future |
| Callback/meeting | Could be submitted without a next date | Next date is required for callback and scheduled meeting |
| Closed leads | API could continue processing activity | Closed leads reject new follow-ups |
| Status change in follow-up | API directly assigned status | Uses the status transition action and records status history |
| Closed lead action | Pending next date could remain | Pending next action is cleared on close |
| Lead journey | Partial activity context | Timeline preserves conversations, assignments, notes, status and scheduling |
| Notifications | Firebase push was attempted and could fail when configuration was missing | Normal database/dashboard notifications are used |
| Mobile reminders | Push-oriented naming and Firebase dependency | Dashboard reminders are stored and read through the reminder API |
| API documentation | Basic endpoint list | This document defines payloads, rules, status flow and behavior |

## 10. Error handling

Validation errors return HTTP `422` with field-level messages. The app should show the returned error beside the related field.

Common validation fields:

```text
followup_date
followup_type
outcome
discussion_notes
next_followup_date
lead_status_after_followup
lost_reason
won_value
```

Unauthorized actions return HTTP `401` or `403`. Missing leads return HTTP `404`. The app should use the response `message` and `errors` values instead of displaying a generic success message.

## 11. App implementation checklist

- Use `source_type` and `source_id` for every lead action.
- Render the status list from `statusOptions` instead of hard-coding only five statuses.
- Require outcome and discussion notes on the follow-up screen.
- Show the next date field when the outcome is callback or meeting scheduled.
- Require lost reason when closing as lost.
- Clear or hide the next-action card when the lead is converted, lost or junk.
- Refresh lead detail, timeline, follow-ups and notifications after a successful mutation.
- Poll or refresh `/api/v1/notifications` for normal in-app notifications.
- Do not add Firebase or FCM token setup to the new lead management flow.

