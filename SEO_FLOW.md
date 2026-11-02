# SEO Flow — Detailed Implementation Guide

## 1. What this SEO module does

The SEO feature is an authenticated, campaign-based workspace inside the Laravel application. It manages the delivery and approval of SEO work for a client website.

It currently acts as an internal SEO operations and reporting system. It does **not** directly crawl a website, call Google Search Console or GA4 APIs, edit the client website, generate XML sitemaps, or publish metadata to the public site. Data from those systems is entered manually, imported from Excel, or attached as evidence.

The main lifecycle is:

```text
Create campaign
      ↓
Assign SEO manager and executives
      ↓
Prepare initial audit
      ↓
Submit audit → Manager review
      ↓                 ↓
   Changes required   Approved
                         ↓
                 Capture baseline metrics
                         ↓
                   Manager locks baseline
                         ↓
             Monthly cycles and SEO activities
                         ↓
       Technical / on-page / off-page execution
                         ↓
       Rankings + performance metrics are recorded
                         ↓
              Monthly report is prepared
                         ↓
       Submit → Approve → Publish to client
```

## 2. Entry points and routes

All SEO routes are inside the `auth` middleware group in `routes/web.php`.

| Area | Route | Purpose |
|---|---|---|
| Campaign list | `GET /seo/campaigns` | List campaigns visible to the logged-in user |
| Create campaign | `GET /seo/campaigns/create` | Show campaign creation form; admin only |
| Store campaign | `POST /seo/campaigns` | Create campaign and team assignments |
| Campaign overview | `GET /seo/campaigns/{campaign}` | Audit, findings, baseline and team overview |
| Dashboard | `GET /seo/campaigns/{campaign}/dashboard` | Ranking summary and top-10 count |
| Operations workspace | `GET /seo/campaigns/{campaign}/workspace` | Monthly work, technical, on-page, backlinks, analytics and reports |
| Keywords | `GET /seo/campaigns/{campaign}/keywords` | Keyword list and ranking history |
| Competitors | `GET /seo/campaigns/{campaign}/competitors` | Competitor records |
| Audit | `PUT/POST /seo/campaigns/{campaign}/audit...` | Save, submit and review audit |
| Baseline | `PUT/POST /seo/campaigns/{campaign}/baseline...` | Save and approve the starting benchmark |

The route definitions are in [routes/web.php](../routes/web.php).

## 3. Roles and access control

Access is controlled by `App\Policies\SeoCampaignPolicy` and additional administrator checks in `SeoCampaignController`.

### Administrator

Administrators can:

- Create SEO campaigns.
- Assign the client, managers and executives.
- View all campaigns.
- Archive and restore campaigns.
- Perform privileged manager actions through the policy.

The controller recognizes administrator-like role values such as `admin`, `super-admin`, `super_admin`, `super admin`, and `super_admin2`.

### SEO manager

A campaign member assigned with `campaign_role = manager` can:

- View the campaign.
- Manage cycles and review work.
- Approve or reject audits.
- Approve the baseline.
- Verify technical issues.
- Review and publish reports.

### SEO executive

A campaign member assigned with `campaign_role = executive` can:

- View the campaign.
- Contribute audit findings.
- Add keywords, rankings, competitors and SEO activities.
- Update assigned activities and technical issues.
- Record on-page work, backlink work and performance metrics.
- Prepare and submit reports.

Executives cannot approve audits, lock baselines, verify technical issues as closed, or publish reports.

### Client/customer

The campaign client can view the campaign workspace, but is redirected to the Reports tab. Only reports with `status = published` are shown to the client. The client overview also shows selected baseline/current metrics, tracked keyword count, top-10 count and approved work count.

Authorization is campaign-specific: a user must be privileged, be the campaign client, or be an active campaign member. An unassigned member is no longer treated as an active member.

## 4. Phase 1 — Create the SEO campaign

An administrator opens `/seo/campaigns/create` and provides:

- Client/customer.
- Campaign name.
- Website URL.
- Industry.
- Country and comma-separated target locations.
- Target language.
- Search engine.
- Devices, such as desktop and mobile.
- Start date.
- SEO goals.
- Reporting frequency: weekly, monthly or quarterly.
- Campaign status: draft, active or on hold at creation time.
- One or more staff members, with at least one assigned as manager.

The controller validates that the client has a client/customer role and that team members are staff users. Campaign creation and member assignment run in one database transaction. The campaign is saved as an independent SEO record; the create view explicitly states that it does not create a CRM project or task.

The main campaign table is `seo_campaigns`. It uses soft deletes, so archive is reversible. Members are stored in `seo_campaign_members`.

## 5. Phase 2 — Initial SEO audit

The campaign overview is the audit workspace.

### Audit preparation

An executive or manager can save the audit summary and add findings. Every finding contains:

- Category: technical, on-page, performance or other.
- Title.
- Affected URL.
- Description.
- Severity: critical, high, medium or low.
- Recommended solution.
- Optional assignee.

Findings can later move through `open`, `in_progress`, `resolved`, `verified` and `closed`. Resolution notes and an evidence URL are available for findings. Only the assigned executive or a manager can update a finding; moving a finding to `verified` or `closed` requires manager authorization.

### Audit submission and review

1. The audit must contain at least one finding.
2. An executive or manager submits it.
3. The audit changes from `draft` to `submitted`.
4. A manager reviews it.
5. The manager chooses `approved` or `changes_required` and may add feedback.
6. If changes are required, the executive updates the audit and submits it again.
7. Once approved, the audit summary and findings are effectively locked from normal editing.

The audit is stored in `seo_audits`, with findings in `seo_audit_findings`.

## 6. Phase 3 — Capture and approve the baseline

The baseline is the starting benchmark used to compare later SEO performance.

The application will not allow a baseline to be saved until the initial audit is approved.

Baseline input includes:

- Capture date.
- Notes.
- At least one metric.
- Metric key, for example `organic_clicks`, `average_position` or `top_10_keywords`.
- Numeric value.
- Unit.
- Source, such as Google Search Console or GA4.

Saving a baseline replaces the current draft metric set. A manager then approves it. Approval sets `status = approved`, records the approving user and timestamp, and makes the baseline immutable. The baseline is unique per campaign and is stored in `seo_baselines`; its metrics are stored in `seo_baseline_metrics`.

This lock is important because later reports compare current performance against this fixed starting point.

## 7. Phase 4 — Keyword research and rankings

Keywords can be entered one at a time or imported through the provided Excel template.

### Keyword fields

- Keyword text.
- Target page URL.
- Location.
- Device: desktop or mobile.
- Search volume.
- Keyword difficulty.
- Optional initial rank and checked date.

The application normalizes keywords by trimming whitespace, collapsing repeated spaces and converting to lowercase. Duplicate protection is campaign-specific and also considers location, device and search engine.

### Excel import

The required headers are exactly:

```text
Keyword, Target URL, Location, Initial Rank, Checked On
```

The import validates URLs, rank values and dates. Duplicate active keywords are skipped. New keywords can receive an initial ranking snapshot during import.

### Ranking snapshots

Ranking is stored historically rather than overwritten. Each snapshot includes:

- Checked date.
- Rank position, or blank when not ranked.
- Source, such as manual or Excel import.
- Remarks.
- User who recorded it.

The UI calculates initial rank, current rank, previous rank and change from the saved snapshots. A positive change means an improved position because the earlier position was numerically larger. For example, moving from position 24 to position 12 is shown as `+12`.

Ranking records are stored in `seo_keyword_rankings`; keywords are stored in `seo_keywords`.

## 8. Phase 5 — Competitor tracking

Competitors are recorded per campaign with:

- Name and website URL.
- Services.
- Strengths.
- Weaknesses.
- Opportunities.
- Notes.
- Data source.

The data-source field is important because competitor estimates are manual or third-party observations rather than automatically verified measurements. Competitors are stored in `seo_competitors`.

## 9. Phase 6 — Monthly SEO planning

A manager creates a monthly cycle containing:

- Month.
- Objectives.
- Status: draft, active, completed or closed.

There can only be one cycle for a campaign/month combination.

Each cycle can contain activities. An activity is the operational unit of SEO work and includes:

- Category: on-page, technical, content, off-page, local, analytics, reporting or other.
- Task title and description.
- Target URL.
- Assigned campaign member.
- Start date and deadline.
- Priority.
- Work notes.
- Evidence URL.

An assignee must be an active member of the campaign. A selected monthly cycle must also belong to the same campaign.

## 10. Phase 7 — Activity execution and review

The normal activity workflow is:

```text
todo → in_progress → submitted → approved
                              ↘ changes_required → submitted
```

1. A manager or executive creates the activity.
2. The assigned executive updates status and adds work notes/evidence.
3. The executive submits the work for review.
4. A manager approves it or requests changes.
5. Approved work records the reviewer, review time and completion time.

Approved and completed activities are locked. The report snapshot counts activities with `approved` or `completed` status as completed work.

## 11. Phase 8 — Technical SEO issue flow

Technical issues can be logged from an audit finding or directly from the workspace. Supported issue types include:

- Crawl and indexing.
- Sitemap.
- Redirect and broken link.
- Canonical.
- Speed, mobile and Core Web Vitals.
- Schema and other.

The normal status flow is:

```text
identified → assigned → fix_in_progress → implemented
                                      ↓
                            verification_pending
                                      ↓
                              verified_closed
                                      ↘ reopened
```

An active campaign member can update an assigned issue. Only a manager can mark it `verified_closed`. Resolution notes, evidence URL, verifier and verification timestamp are retained.

This workflow tracks the delivery and verification of a fix; it does not itself apply the fix to the client website.

## 12. Phase 9 — On-page optimisation log

On-page work is recorded per page URL and may be linked to an SEO activity. The log supports before/after documentation for:

- Target keyword.
- Old and new meta title.
- Old and new meta description.
- H1 changes.
- Content changes.
- Image alt-tag changes.
- Internal-link changes.
- Optimisation date.
- Evidence URL.

This is an audit trail of changes made outside this application. The controller validates and stores the values but does not modify the target website.

## 13. Phase 10 — Off-page and backlink tracking

Backlink work is stored as an activity with:

- Activity type.
- Target website and target URL.
- Published URL.
- Anchor text.
- Link type: dofollow, nofollow, sponsored, UGC or unknown.
- Submitted date and live date.
- Verification status: submitted, published, verified, lost or rejected.
- Remarks.

The monthly report counts backlinks as completed only when they are `verified` and their `live_on` date falls inside the report period.

## 14. Phase 11 — Performance data collection

Performance records are entered per period and metric. Supported sources are:

- Manual.
- GA4.
- Search Console.
- Import.

Each record stores period start, period end, source, metric key, numeric value, optional dimensions, recording user and timestamp.

The database prevents duplicate records for the same campaign, period, source and metric key. The workspace uses the most recent performance period as the current view.

Typical metric keys used by the seed/demo data are:

- `organic_clicks`
- `organic_impressions`
- `organic_sessions`
- `average_ctr`
- `average_position`
- `indexed_pages`
- `top_10_keywords`

The application currently stores these values; it does not fetch them automatically from Google or GA4.

## 15. Phase 12 — Monthly report flow

A manager or executive creates a report with:

- Title.
- Reporting period.
- Observations/executive summary.
- Optional Excel or PSD attachments.

At creation time, the controller generates a snapshot containing:

- Performance metrics in the selected period.
- Baseline metrics.
- Metric changes versus baseline where both values are numeric.
- Number of tracked keywords.
- Number of keywords in the top 10.
- Top gainers and decliners based on ranking snapshots.
- Approved/completed activities in the period.
- Technical issues verified closed in the period.
- Backlinks verified live in the period.

The report workflow is:

```text
draft → submitted → approved → published
                    ↘ changes_required → submitted
```

Rules enforced by the controller:

- Only draft or changes-required reports can be submitted.
- Only submitted reports can be approved.
- A report must be approved before it can be published.
- Only published reports are exposed in the client report view.

Attachments are stored under `storage/app/public/seo-reports/{campaign_id}/{report_id}` and are displayed using the public storage URL. The report record stores attachment metadata in JSON.

Reports are stored in `seo_reports`.

## 16. Dashboard and client view calculations

The internal dashboard calculates:

- Total keywords tracked.
- Keywords currently ranking in positions 1–10.
- The latest ranking record for each keyword.

The client workspace displays:

- Keywords tracked.
- Keywords in the top 10.
- Approved SEO work.
- Baseline-versus-current values for selected metrics.
- Published reports and their attachments.

The client is intentionally not shown the internal activity, technical issue or draft-report tabs.

## 17. Database relationship map

```text
seo_campaigns
 ├── seo_campaign_members
 ├── seo_audits
 │    └── seo_audit_findings
 ├── seo_baselines
 │    └── seo_baseline_metrics
 ├── seo_keywords
 │    └── seo_keyword_rankings
 ├── seo_competitors
 ├── seo_monthly_cycles
 │    └── seo_activities
 ├── seo_technical_issues
 ├── seo_on_page_optimizations
 ├── seo_backlink_activities
 ├── seo_performance_records
 └── seo_reports
```

The corresponding Eloquent relationships are defined in `app/Models/SeoCampaign.php` and the related SEO model classes.

## 18. Important implementation observations

### Implemented

- Campaign-level authorization.
- Manager/executive separation.
- Audit review and feedback.
- Baseline approval and immutability.
- Historical keyword ranking snapshots.
- Excel keyword template and import validation.
- Monthly work planning.
- Evidence URLs for audit findings, activities, technical issues and on-page work.
- Technical issue verification workflow.
- Manual/third-party performance data recording.
- Report snapshots and report approval/publishing.
- Client-only published report visibility.
- Campaign archive and restore.

### Not implemented as an automated integration

- No Google Search Console API connection.
- No GA4 API connection.
- No automatic rank-tracking provider.
- No website crawler.
- No automatic sitemap or robots.txt generation.
- No automatic canonical, schema or meta-tag deployment.
- No automatic backlink discovery.
- No automatic scheduled report generation or data sync visible in these controllers.

Therefore, the SEO flow should be understood as a controlled workflow and evidence system around SEO work, rather than an automated search-engine integration layer.

### Current code-level considerations

- The campaign create form allows only `draft`, `active` and `on_hold`, although the database also supports `completed` and `cancelled`; those statuses can be represented in the database but are not offered by that form.
- The baseline schema includes a `submitted` status, but the current controller saves drafts and moves them directly to `approved`; there is no separate baseline-submission route.
- Activity review supports `changes_required`, while the normal executive update form submits `todo`, `in_progress` or `submitted`. This is sufficient for a return-to-executive loop, but the UI should clearly show feedback when changes are requested.
- Report snapshots are generated when a report is created. Later metric or ranking changes do not automatically refresh an existing draft/report snapshot.
- The report snapshot uses ranking history for the keyword change calculation, while the dashboard uses each keyword's latest ranking. These are related but not identical views.
- The route is authenticated, but there is no public SEO page route in this module. Public website SEO must be implemented in the website/application being promoted.

## 19. Recommended operating procedure

For a real campaign, use this order:

1. Create the campaign and assign one manager plus the required executives.
2. Add the website, locations, devices, goals and reporting frequency carefully.
3. Complete the audit with URL-level findings, severity, owner and recommended solution.
4. Submit and approve the audit.
5. Capture a complete baseline from Search Console, GA4 and other agreed sources.
6. Approve the baseline before starting monthly comparisons.
7. Add the keyword set and import historical rankings where available.
8. Add competitors and record the source of competitor observations.
9. Create the monthly cycle and break work into activities with deadlines and owners.
10. Keep evidence URLs and work notes attached to every submitted activity or issue.
11. Record performance metrics for a consistent reporting period.
12. Create the report only after the period's ranking, performance and execution data is complete.
13. Submit, review, approve and publish the report.
14. Let the client consume only the published report view.

## 20. Main source files

- [routes/web.php](../routes/web.php)
- [SeoCampaignController.php](../app/Http/Controllers/SeoCampaignController.php)
- [SeoKeywordController.php](../app/Http/Controllers/SeoKeywordController.php)
- [SeoOperationsController.php](../app/Http/Controllers/SeoOperationsController.php)
- [SeoCampaignPolicy.php](../app/Policies/SeoCampaignPolicy.php)
- [Campaign overview view](../resources/views/seo/campaigns/show.blade.php)
- [Keyword view](../resources/views/seo/keywords/index.blade.php)
- [Operations workspace view](../resources/views/seo/operations/workspace.blade.php)
- [Phase-one migration](../database/migrations/2026_10_26_120000_create_seo_phase_one_tables.php)
- [Keyword and competitor migration](../database/migrations/2026_10_26_130000_create_seo_keyword_and_competitor_tables.php)
- [Operations migration](../database/migrations/2026_10_26_140000_create_seo_operations_tables.php)

