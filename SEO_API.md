# SEO Management API

Base URL:

```text
/api/v1/seo
```

Authentication uses the existing Sanctum bearer token:

```http
Authorization: Bearer {token}
Accept: application/json
```

All endpoints are protected by `auth:sanctum`. Campaign-level authorization is applied using the same SEO policy as the web module.

## Response format

Successful responses use:

```json
{
  "success": true,
  "message": "Optional message",
  "data": {}
}
```

Validation, authorization and workflow errors use Laravel's normal JSON error response. Mutation endpoints return HTTP `201` when a new resource is created and `200` for updates/actions.

## Campaigns

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| GET | `/campaigns` | Authenticated | List visible campaigns. Add `?archived=1` for archived campaigns; archived listing is admin-only. |
| POST | `/campaigns` | Admin | Create a campaign and assign members. Requires at least one manager. |
| GET | `/campaigns/{campaign}` | Campaign view | Return campaign, team, audit findings and baseline. |
| DELETE | `/campaigns/{campaign}` | Admin | Soft archive a campaign. |
| POST | `/campaigns/{campaignId}/restore` | Admin | Restore an archived campaign. |
| GET | `/campaigns/{campaign}/dashboard` | Campaign view | Return keyword count, top-10 count and latest rankings. |
| GET | `/campaigns/{campaign}/workspace` | Campaign view | Return operations workspace data. Clients receive published reports only. |

Campaign creation fields include `client_id`, `name`, `website_url`, `industry`, `target_country`, `target_locations` (comma-separated string), `target_language`, `search_engine`, `devices[]`, `start_date`, `goals`, `reporting_frequency`, `status`, and `members[]`.

Example member payload:

```json
{
  "user_id": 12,
  "campaign_role": "manager"
}
```

## Audit and baseline

| Method | Endpoint | Purpose |
|---|---|---|
| PUT | `/campaigns/{campaign}/audit` | Save audit summary draft. |
| POST | `/campaigns/{campaign}/audit/findings` | Add an audit finding. |
| PATCH | `/campaigns/{campaign}/audit/findings/{finding}` | Update finding status, resolution notes or evidence. |
| POST | `/campaigns/{campaign}/audit/submit` | Submit an audit containing at least one finding. |
| POST | `/campaigns/{campaign}/audit/review` | Manager decision: `approved` or `changes_required`. |
| PUT | `/campaigns/{campaign}/baseline` | Save/rewrite a draft baseline after audit approval. |
| POST | `/campaigns/{campaign}/baseline/approve` | Manager locks the baseline permanently. |

Baseline payload:

```json
{
  "captured_on": "2026-10-30",
  "notes": "Starting benchmark",
  "metrics": [
    {"key": "organic_clicks", "value": 420, "unit": "count", "source": "Google Search Console"},
    {"key": "average_position", "value": 29.4, "unit": "position", "source": "Google Search Console"}
  ]
}
```

## Keywords and competitors

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/campaigns/{campaign}/keywords` | List keywords with ranking history. |
| POST | `/campaigns/{campaign}/keywords` | Create a keyword, optionally with an initial ranking. |
| DELETE | `/campaigns/{campaign}/keywords/{keyword}` | Permanently delete a keyword. |
| POST | `/campaigns/{campaign}/keywords/{keyword}/rankings` | Add or replace a ranking snapshot for date/source. |
| GET | `/campaigns/{campaign}/keywords/template` | Download the Excel import template. |
| POST | `/campaigns/{campaign}/keywords/import` | Import `.xlsx` or `.xls` using the exact template headers. |
| GET | `/campaigns/{campaign}/competitors` | List competitors. |
| POST | `/campaigns/{campaign}/competitors` | Add a competitor and data source. |

Keyword import is multipart form data with field `file`. Required headers are:

```text
Keyword, Target URL, Location, Initial Rank, Checked On
```

## Monthly operations

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/campaigns/{campaign}/cycles` | Create/update a monthly cycle. |
| POST | `/campaigns/{campaign}/activities` | Assign an SEO activity. |
| PATCH | `/campaigns/{campaign}/activities/{activity}` | Save executive progress and submit work. |
| POST | `/campaigns/{campaign}/activities/{activity}/review` | Manager decision: `approved` or `changes_required`. |
| POST | `/campaigns/{campaign}/technical-issues` | Log a technical SEO issue. |
| PATCH | `/campaigns/{campaign}/technical-issues/{technicalIssue}` | Update issue status and evidence. |
| POST | `/campaigns/{campaign}/on-page` | Record on-page changes and before/after metadata. |
| POST | `/campaigns/{campaign}/backlinks` | Record off-page/backlink activity. |
| POST | `/campaigns/{campaign}/performance` | Store a period metric from manual, GA4, Search Console or import source. |

Important workflow decisions:

- Only active campaign members can be assigned work.
- Only assigned executives or managers can update assigned work.
- Only managers can verify technical issues as `verified_closed`.
- Approved activities are locked.

## Reports

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/campaigns/{campaign}/reports` | Create a report draft and generate its snapshot. |
| POST | `/campaigns/{campaign}/reports/{report}/submit` | Submit a draft or changes-required report. |
| POST | `/campaigns/{campaign}/reports/{report}/review` | Manager decision: `approved`, `changes_required` or `published`. |

Report creation accepts multipart form data. Fields are `title`, `period_start`, `period_end`, `observations`, optional `seo_monthly_cycle_id`, and repeated `attachments[]`. Attachments may be `.xlsx`, `.xls` or `.psd`, up to 50 MB each.

Reports follow:

```text
draft → submitted → approved → published
                    ↘ changes_required → submitted
```

Client users can access the workspace endpoint but receive only reports with `published` status.

## Notes for API consumers

- This API records SEO work and imported measurements; it does not automatically call Google Search Console, GA4, a rank tracker or a crawler.
- The report snapshot is generated when the report is created. Create a new draft if the underlying period data changes materially before publication.
- Use `Accept: application/json` so validation and authorization failures are returned as JSON.
- Use the campaign-specific resource IDs in nested endpoints. The controller verifies that nested resources belong to the requested campaign before changing them.

