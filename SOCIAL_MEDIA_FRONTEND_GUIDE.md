# Social Media Frontend Guide

This guide defines the frontend flow and UI expectations for the Social Media Post Management module.

## API and authentication

- Base API: `/api/v1/social-media`
- Authentication: `Authorization: Bearer {Sanctum token}`
- Send `Accept: application/json` on every request.
- API payloads and endpoint details: see [SOCIAL_MEDIA_API.md](SOCIAL_MEDIA_API.md).

## User roles and navigation

### Super Admin / Admin

Show all Social Media navigation items:

1. Overview
2. Post Calendar
3. All Posts
4. My Assigned Posts
5. Monthly Plans
6. Internal Review
7. Client Approvals
8. Publishing Tracker
9. Festival Master
10. Monthly Reports

Do not show a separate **Create Post** sidebar item. Put the primary **Create Post** button on Overview and All Posts pages.

### Staff

Always show **My Assigned Posts**. Show Calendar, All Posts, Review, Publishing, Plans, Reports and Festival Master only when the API/user permissions allow it. A staff user should never see posts outside their assigned queue unless they have view permission.

### Client

Show only:

1. Overview
2. My Posts
3. My Monthly Plan
4. My Approvals

Do not show Post Calendar, staff assignment, internal review, publishing, festival master, reports or create-post actions to a client.

## Primary workflow

```text
Create draft / plan
        ↓
Assign staff
        ↓
Assigned staff starts work
        ↓
Upload creative version
        ↓
Internal review
        ↓
Client approval
        ↓
Schedule publishing
        ↓
Confirm published
```

### Status mapping

| Status | Meaning | Main frontend action |
|---|---|---|
| `planned` | Draft or no staff assigned | Edit / assign |
| `assigned` | Team members assigned | Start work |
| `in_progress` | Creative work underway | Upload version |
| `internal_review` | Waiting for reviewer | Approve / request changes |
| `internal_changes_requested` | Reviewer asked for changes | Upload revised version |
| `pending_client_approval` | Client needs to decide | Approve / request changes / reject |
| `client_changes_requested` | Client requested revision | Upload revised version |
| `client_approved` | Client approved | Schedule publishing |
| `scheduled` | Publishing date set | Confirm published |
| `published` | Publication confirmed | Read-only history and performance |
| `rejected`, `cancelled`, `on_hold` | Closed or paused work | Show reason / activity history |

## Screens and behaviour

### 1. Overview

Purpose: show a high-level snapshot and entry points.

- Display count cards: Planned, In Design, Internal Review, Client Approvals, Scheduled and Published.
- Show a month selector and a small client/month post table.
- Main CTA: **Create Post** for staff/admin only.
- Quick links: All Posts, Pending Approvals, Publishing Tracker.
- For clients, show only their planned posts and approval count.

### 2. All Posts / My Posts

Data: `GET /posts`

- Use a desktop table and mobile cards.
- Filters: client (staff/admin only), status, assigned staff (staff/admin only), month and free-text search.
- Columns: title/type, client, platforms, planned date, status and action.
- Show `Open` action for every visible post.
- Use server pagination metadata; do not fetch the full list at once.

### 3. Create / Edit Post

Data: `GET /options`, `POST /posts`, `PATCH /posts/{id}`

Group the form into sections:

1. **Post basics** — client, project, title, category, type, priority.
2. **Schedule** — planned date, internal deadline, client approval deadline.
3. **Content** — creative brief, caption, hashtags, reference links and platforms.
4. **Team** — designer, writer, reviewer and publisher.

Actions:

- **Save as Draft**: send `save_as_draft: true`.
- **Create & Assign**: create with assignments.
- Keep buttons sticky at the bottom on long mobile forms.
- Use clear inline validation messages from API `422` responses.

### 4. Post Detail

Data: `GET /posts/{id}`

Header:

- Back button, title, status badge and Edit action for eligible staff.
- Horizontal workflow stepper: Plan & Assign → Create → Internal Review → Client Approval → Schedule → Published.
- Completed steps are green; current step is blue; future steps are muted.

Main column:

- Creative brief, caption, hashtags and platforms.
- Creative version gallery. Images should open in a lightbox; videos need controls; files need a download action.
- Shared discussion thread with author, time and internal note badge.

Sidebar:

- Client, planned date, deadlines and priority.
- Contextual action card: start work, upload version, internal review, client decision, schedule or publish.
- Activity/history timeline.

Only show the action that matches the current status and logged-in user role.

### 5. Post Calendar

- Staff/admin only.
- Month grid plus optional list view.
- Month selector and previous/next navigation must reload/fetch posts for the selected month.
- Event colour legend:

  - Gray: planned
  - Orange: internal review
  - Cyan: client approval
  - Purple: scheduled
  - Green: published

- Clicking an event opens post detail.
- Never derive a selected month from the first visible calendar-grid day; use the calendar view’s actual current month.

### 6. My Assigned Posts

- Staff only.
- Sort overdue internal deadlines first, then nearest deadline.
- Display title, client, assigned role, deadline, status and one contextual action.
- Highlight overdue deadlines in red.

### 7. Review and approval queues

Internal Review: show only `internal_review` and `internal_changes_requested` posts.

Client Approvals:

- Staff view: posts awaiting client decision.
- Client view: only that client’s posts in `pending_client_approval`.

Keep queue cards/table compact; the actual decision should happen from Post Detail to preserve context.

### 8. Publishing Tracker

- Staff/admin users with publishing permission.
- Show client-approved, scheduled and published posts.
- Display scheduled date, actual published date (if applicable), publishing URL and status.
- Schedule action requires `scheduled_at`.
- Publish action requires `actual_published_at`; allow optional URL and proof upload.

## Visual design system

### Style

- Use a clean, light CRM layout with white cards on `#f7f9fd` page background.
- Primary blue: `#176ee2`.
- Main text: `#172b4d`.
- Muted text: `#6c7a91`.
- Border: `#e8eef7`.
- Card radius: `14–16px`; input/button radius: `8px`.
- Keep cards spacious but compact: `20px` inner padding desktop, `16px` mobile.

### Status badges

Use short labels and consistent colours. Do not use one blue badge for every status.

| Group | Colour |
|---|---|
| Planned / Assigned | Gray or blue-gray |
| In progress | Blue |
| Internal review / changes | Orange |
| Client approval | Cyan |
| Approved / Published | Green |
| Scheduled | Purple |
| Rejected / overdue | Red |

### Responsive requirements

- Desktop tables may scroll horizontally on small screens.
- On phone widths, convert key post rows into cards with title, status, date and primary action.
- Keep primary actions full-width in side panels on mobile.
- Use a horizontally scrollable workflow stepper; do not wrap workflow labels into multiple lines.
- All upload controls must support mobile file picking.

## Error, loading and empty states

- Show skeleton cards/table rows while list data is loading.
- On `401`, redirect to login or refresh token flow.
- On `403`, show “You don’t have access to this post.” with a safe back link.
- On `422`, map API validation errors to relevant form fields.
- Empty queues should use a short message and a relevant CTA, e.g. “No posts are waiting for review.”
- For destructive actions (reject/cancel), always use a confirmation modal and require a reason where applicable.
