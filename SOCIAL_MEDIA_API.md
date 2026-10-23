# Social Media API

Base URL: `{{APP_URL}}/api/v1/social-media`  
Authentication: Laravel Sanctum. Send `Authorization: Bearer {token}` and `Accept: application/json` with every request.

## Access by user type

| User | Access |
|---|---|
| Super Admin / Admin | Full module access |
| Staff | Assigned posts plus actions granted by permissions |
| Client | Only their posts, comments and approval decision |

## Endpoints

| Method | URL | Purpose |
|---|---|---|
| GET | `/options` | Clients, staff, projects, statuses and form choices |
| GET | `/posts` | Paginated post list |
| POST | `/posts` | Create post / draft |
| GET | `/posts/{id}` | Full post detail, versions, comments, activity |
| PUT/PATCH | `/posts/{id}` | Update post details and assignments |
| POST | `/posts/{id}/start` | Start assigned work |
| POST | `/posts/{id}/versions` | Upload a creative version for internal review |
| POST | `/posts/{id}/internal-decision` | Approve or request internal changes |
| POST | `/posts/{id}/client-decision` | Client approves, requests changes or rejects |
| POST | `/posts/{id}/comments` | Add comment |
| POST | `/posts/{id}/schedule` | Schedule an approved post |
| POST | `/posts/{id}/publish` | Confirm a post is published |

## List posts

`GET /posts?status=internal_review&client_id=12&assigned_to=5&month=2026-10&search=diwali&per_page=20`

All filters are optional. Supported `status` values: `planned`, `assigned`, `in_progress`, `internal_review`, `internal_changes_requested`, `pending_client_approval`, `client_changes_requested`, `client_approved`, `ready_for_publishing`, `scheduled`, `published`, `completed`, `on_hold`, `rejected`, `cancelled`.

## Create / update a post

Use JSON for normal create/update requests.

```json
{
  "client_id": 12,
  "project_id": 8,
  "title": "Diwali greeting post",
  "content_category": "Festival",
  "post_type": "image",
  "priority": "high",
  "planned_at": "2026-11-08T10:00:00+05:30",
  "internal_deadline_at": "2026-11-05T18:00:00+05:30",
  "client_approval_deadline_at": "2026-11-07T12:00:00+05:30",
  "creative_brief": "Warm Diwali visual in brand colours.",
  "caption": "Wishing you a bright and prosperous Diwali.",
  "hashtags": "#Diwali #Festival",
  "reference_links": "https://example.com/brand-guide",
  "platforms": ["Instagram", "Facebook", "LinkedIn"],
  "assignments": [
    {"user_id": 5, "role": "designer"},
    {"user_id": 7, "role": "reviewer"},
    {"user_id": 9, "role": "publisher"}
  ]
}
```

Set `save_as_draft: true` to create a post in `planned` status. If no staff assignment is sent, it is also created as `planned`; otherwise it is `assigned`.

## Workflow actions

### Start work

`POST /posts/{id}/start` — no request body. The caller must be assigned to the post (or be an admin).

### Upload version

`POST /posts/{id}/versions` with `multipart/form-data`:

- `files[]` — required; JPG, PNG, WEBP, GIF, MP4, MOV, WEBM or PDF; maximum 50 MB per file
- `note` — optional version note

This changes the post to `internal_review`.

### Internal review

`POST /posts/{id}/internal-decision`

```json
{"decision":"approved","comment":"Creative approved; send to client."}
```

Allowed decisions: `approved`, `changes_requested`. Approved posts move to `pending_client_approval`.

### Client decision

`POST /posts/{id}/client-decision`

```json
{"decision":"approved","comment":"Looks good."}
```

Allowed decisions: `approved`, `changes_requested`, `rejected`. A comment is mandatory for changes/rejection.

### Schedule

`POST /posts/{id}/schedule`

```json
{"scheduled_at":"2026-11-08T10:00:00+05:30"}
```

Only approved posts can be scheduled.

### Publish

`POST /posts/{id}/publish` with JSON or `multipart/form-data`:

```json
{"actual_published_at":"2026-11-08T10:05:00+05:30","published_url":"https://instagram.com/p/example"}
```

Optional `proof` upload supports JPG, PNG, WEBP and PDF up to 20 MB.

## Comments

`POST /posts/{id}/comments`

```json
{"comment":"Please make the logo a little larger.","is_internal":false}
```

`is_internal` is honoured only for staff; client users cannot create internal comments.

## Response format

Successful requests return:

```json
{"success":true,"data":{}}
```

Validation errors use HTTP `422`; unauthenticated users receive `401`; access-denied requests receive `403`.
