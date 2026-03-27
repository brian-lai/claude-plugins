---
description: Manage JIRA tickets for the configured project
argument-hint: <setup|create|list|view|update|plan|board|groom> [args]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - mcp__atlassian__getVisibleJiraProjects
  - mcp__atlassian__createJiraIssue
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__getJiraProjectIssueTypesMetadata
  - mcp__atlassian__searchJiraIssuesUsingJql
  - mcp__atlassian__getTransitionsForJiraIssue
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__lookupJiraAccountId
  - mcp__atlassian__addCommentToJiraIssue
---

# JIRA Management

Unified command for all JIRA operations. Parse `$ARGUMENTS` to determine the subcommand.

## Subcommand Routing

Parse the first word of `$ARGUMENTS`:

| Subcommand | Example | Description |
|------------|---------|-------------|
| `setup` | `/dev:jira setup` | Link a JIRA project to this repo |
| `create` | `/dev:jira create Fix login bug` | Create a ticket |
| `list` | `/dev:jira list --mine` | Search/filter tickets |
| `view` | `/dev:jira view RNA-456` | View ticket details |
| `update` | `/dev:jira update RNA-456 --status="In Review"` | Update a ticket |
| `plan` | `/dev:jira plan --from-plan` | Bulk-create from plan |
| `board` | `/dev:jira board` | Sprint board view |
| `groom` | `/dev:jira groom` | Sprint grooming report |
| *(none)* | `/dev:jira` | Show config + help |

Strip the subcommand from `$ARGUMENTS` and pass the remainder as arguments to the relevant section below.

---

## Shared: Load Project Config

All subcommands (except `setup`) start with this:

1. Run `git rev-parse --show-toplevel` via Bash to get the git repo root (or use cwd)
2. Read `~/.claude/dev/projects.json`
3. Look up the directory key to get `cloudId` and `projectKey`
4. If not found: "No JIRA project configured. Run `/dev:jira setup` first."

The `cloudId` for all `mcp__atlassian__*` tools is the Atlassian site URL from config (e.g., `"mycompany.atlassian.net"`).
The browse URL for any ticket is: `https://{cloudId}/browse/{ISSUE_KEY}`.

---

## setup

Configure a JIRA project for the current repository.

```
/dev:jira setup                # First-time setup or show current config
/dev:jira setup --reconfigure  # Re-link to a different project
```

### Step 0: Check Atlassian MCP Connectivity

Check that the `mcp__atlassian__getVisibleJiraProjects` tool is available. If an existing `cloudId` is in config, use it; if this is a fresh setup, simply verify the tool exists (the tool being absent means the MCP server is not configured, while an auth or cloudId error means the MCP server is present but needs setup — handle each case differently).

**If it fails or the tool is unavailable**, display this and stop:

```
## Atlassian MCP Not Detected

The JIRA integration requires the Atlassian MCP server:

    claude mcp add --transport http --global atlassian https://mcp.atlassian.com/v1/mcp

On first use, your browser will open for Atlassian OAuth.
Authorize access to your Atlassian site.

Verify:  claude mcp list  (should show 'atlassian')

After setup, run /dev:jira setup again.
```

### Step 1: Migrate Legacy Config (if needed)

If `~/.claude/dev/projects.json` does not exist but `~/.claude/jw-ez-dev/projects.json` does:
1. Create `~/.claude/dev/` directory
2. Copy `~/.claude/jw-ez-dev/projects.json` → `~/.claude/dev/projects.json`
3. If `~/.claude/jw-ez-dev/trello-projects.json` exists, copy it too
4. Display: "Migrated config from `~/.claude/jw-ez-dev/` to `~/.claude/dev/`."

### Step 2: Check Existing Config

1. Read `~/.claude/dev/projects.json`
2. If entry exists for this directory AND no `--reconfigure` → show config and available commands
3. Otherwise → prompt for setup

### Step 3: Prompt for Atlassian Site URL

```
Provide your Atlassian site URL (e.g., mycompany.atlassian.net):
```

Use **AskUserQuestion** to collect the site URL. Validate it by calling `mcp__atlassian__getVisibleJiraProjects` with the provided `cloudId`.

### Step 4: Prompt for Board URL

```
Provide your JIRA project board URL.
Format: https://<site>.atlassian.net/jira/software/c/projects/<KEY>/boards/<ID>
```

Extract `projectKey`, `boardId`, `boardUrl` from the URL. The `cloudId` comes from Step 3.

### Step 5: Persist

Ensure `~/.claude/dev/` exists. Write/update `projects.json`:
```json
{
  "<repo-root>": {
    "cloudId": "<site>.atlassian.net",
    "projectKey": "<KEY>",
    "boardId": "<ID>",
    "boardUrl": "https://<site>.atlassian.net/jira/software/c/projects/<KEY>/boards/<ID>",
    "configuredAt": "<ISO timestamp>"
  }
}
```

### Step 6: Show Config

```
## JIRA Project Configured

**Site:** <cloudId>
**Project:** <projectKey>
**Board:** <boardUrl>

Commands: /dev:jira <setup|create|list|view|update|plan|board>
PR:       /dev:pr
```

---

## create

Create a new JIRA ticket.

```
/dev:jira create Fix login redirect bug
/dev:jira create --type=Bug --priority=High Fix login redirect bug
/dev:jira create --description="quick note" Fix something
/dev:jira create                            # Interactive
```

### Arguments
- **Summary** (positional): one-line ticket title
- `--type=Task|Story|Bug|Sub-task|Epic` (default: Task)
- `--priority=Highest|High|Medium|Low|Lowest`
- `--assign=<name>`: search via `mcp__atlassian__lookupJiraAccountId`
- `--parent=<KEY>`: parent issue key for subtasks
- `--description=<text>`: verbatim description (bypasses structured flow)

### Description Collection

Ticket descriptions use structured sections. Which sections apply depends on the issue type:

| Section | Purpose | Bug | Story | Task | Sub-task | Epic |
|---------|---------|-----|-------|------|----------|------|
| **Description** | What this is about | required | required | required | required | required |
| **Problem** | Why this work is needed | required | required | optional | -- | required |
| **Solution** | How to address it | required | required | optional | -- | -- |
| **Acceptance Criteria** | Definition of done | recommended | recommended | optional | -- | recommended |
| **Technical Notes** | Impl details, links, constraints | optional | optional | optional | optional | -- |

**Three modes determine how the description is collected:**

1. **No arguments** → Fully interactive: prompt for type and summary first, then walk through each applicable section one at a time using **AskUserQuestion**. Mark required sections clearly; allow skipping optional/recommended ones. Omit sections marked `--` for the chosen type.

2. **Summary provided, no `--description`** → AI-assisted: use the summary text and any available context (repo name, recent commits, active plan) to draft a structured description with the applicable sections pre-filled. Present the draft to the user for review/editing via **AskUserQuestion** before creating the ticket.

3. **`--description` provided** → Use the value verbatim as the ticket description. No structured sections are added (escape hatch for quick tickets).

Empty or skipped sections are omitted from the final description. The rendered format is:

```markdown
## Description
<text>

## Problem
<text>

## Solution
<text>

## Acceptance Criteria
- [ ] <criterion>

## Technical Notes
<text>
```

### Execution

1. Determine description mode and collect/generate the description per the rules above
2. Optionally call `mcp__atlassian__getJiraProjectIssueTypesMetadata` for validation
3. Call `mcp__atlassian__createJiraIssue` with `cloudId`, `projectKey`, `issueTypeName`, `summary`, `description`, `parent`, and `contentFormat: "markdown"`
4. Display: `**[RNA-456](https://...browse/RNA-456)**: <summary> | Type: Task | Status: To Do`

---

## list

Search and display JIRA tickets.

```
/dev:jira list                       # Open issues, sorted by updated
/dev:jira list --mine                # My tickets
/dev:jira list --sprint=current      # Current sprint
/dev:jira list --status="In Progress"
/dev:jira list --type=Bug
/dev:jira list --backlog
/dev:jira list --blockers
/dev:jira list authentication        # Free-text search
```

### JQL Construction

Base: `project = "<projectKey>"`

| Flag | Appended JQL |
|------|-------------|
| `--mine` | `AND assignee = currentUser()` |
| `--sprint=current` | `AND sprint in openSprints()` |
| `--status="X"` | `AND status = "X"` |
| `--type=X` | `AND issuetype = "X"` |
| `--backlog` | `AND status = "To Do" AND sprint is EMPTY` |
| `--blockers` | `AND priority in (Highest, High) AND status != Done` |
| Free text | `AND (summary ~ "text" OR description ~ "text")` |
| Default | `AND status != Done` |

Always append `ORDER BY updated DESC`.

### Execution

Call `mcp__atlassian__searchJiraIssuesUsingJql` with `maxResults: 20`. Display as table with Key, Type, Summary, Status, Priority, Assignee, Updated.

---

## view

View detailed ticket information.

```
/dev:jira view RNA-456
/dev:jira view 456        # Auto-prepends project key
```

### Execution

1. Resolve key (prepend project key if number-only)
2. Call `mcp__atlassian__getJiraIssue`
3. Call `mcp__atlassian__getTransitionsForJiraIssue`
4. Display: status, type, priority, assignee, reporter, sprint, labels, components, description, available transitions, subtasks, linked issues, browse URL

---

## update

Update fields or transition a ticket.

```
/dev:jira update RNA-456                                    # Interactive
/dev:jira update RNA-456 --status="In Review"
/dev:jira update RNA-456 --assign=Brian
/dev:jira update RNA-456 --priority=High
/dev:jira update RNA-456 --comment="Started implementation"
/dev:jira update 456 --status="In Review" --comment="PR up"  # Combined
```

### Execution

1. Resolve key, fetch current state + available transitions
2. **`--status`**: Match transition by target name (case-insensitive), call `mcp__atlassian__transitionJiraIssue`
3. **`--assign`**: Lookup via `mcp__atlassian__lookupJiraAccountId`, set via `mcp__atlassian__editJiraIssue`
4. **`--priority`**: Set via `mcp__atlassian__editJiraIssue`
5. **`--comment`**: Add via `mcp__atlassian__addCommentToJiraIssue`
6. **Interactive** (no flags): Show current state, ask what to change
7. Apply in order: transitions → field updates → comments
8. Show before/after for changed fields

---

## plan

Bulk-create tickets from a plan or task list.

```
/dev:jira plan                              # Interactive
/dev:jira plan --from-plan                   # Parse active Pret/Para plan
/dev:jira plan --from-file=context/plans/X.md
/dev:jira plan --epic="User Authentication"  # Wrap in an Epic
```

### Execution

1. Gather work items from plan file, specified file, or interactive input
2. Map items to ticket types: master plan title → Epic, phase/section → Story, step → Task, sub-step → Sub-task
3. **Propose structure as a table and wait for confirmation before creating**
4. Create in dependency order: Epic → Story → Task → Sub-task
5. Display created tickets with keys and browse URL
6. Optionally update `context/context.md` with ticket keys

---

## board

Sprint board view.

```
/dev:jira board           # Current sprint, hide Done
/dev:jira board --mine    # Only my tickets
/dev:jira board --all     # Include Done tickets
```

### Execution

1. Query: `project = "<key>" AND sprint in openSprints() ORDER BY status ASC, priority DESC`
   - `--mine`: add `AND assignee = currentUser()`
   - Default: add `AND status != Done` (unless `--all`)
2. Group results by status column (To Do, In Progress, In Review, Done)
3. Display each group as a table with Key, Type, Summary, Priority, Assignee
4. Show board URL and ticket counts
5. If no active sprint, fall back to backlog view

---

## groom

Analyze open tickets for anomalies and produce a grooming report with AI-generated action items. Works with both sprint-based and kanban boards.

```
/dev:jira groom              # Analyze current sprint (or all open tickets for kanban)
/dev:jira groom --stale=5    # Override stale threshold (default: 7 days)
```

### Arguments

- `--stale=<days>` (default: 7): Calendar days with no update before a ticket is considered stale

### Board Detection

The command auto-detects the board style:

1. **Sprint board:** Query with `sprint in openSprints()` first. If results are returned, scope the report to the active sprint.
2. **Kanban (no sprint):** If the sprint query returns no results, fall back to all open tickets: `project = "<key>" AND status != Done`. Note this in the report header ("**Board:** kanban" instead of "**Sprint:** <name>").

### Anomaly Categories

Evaluate every in-scope ticket (excluding Done) against these four categories. A ticket can appear in multiple categories.

| Category | Condition | Applies to |
|----------|-----------|------------|
| **Stale** | No update in N days (per `--stale` threshold) | In Progress, In Review |
| **Unassigned in-flight** | No assignee on active work | In Progress, In Review |
| **Missing metadata** | No description OR no priority set | All statuses (except Done) |
| **Priority mismatch** | High/Highest priority in To Do for 5+ days; Epic as a sprint item; Sub-task with no parent | To Do, In Progress |

**Design notes:**
- Stale only applies to active statuses — a To Do ticket sitting untouched is normal.
- Missing metadata checks description and priority only, not estimates or labels (those vary by team).
- Priority mismatch is opinionated: high-priority items languishing in To Do is almost always a planning failure.

### Execution

1. Load project config (shared step)
2. Detect board style and query tickets:
   - First, try sprint-scoped: `project = "<key>" AND sprint in openSprints() AND status != Done ORDER BY priority DESC, status ASC`
   - If that returns results → sprint mode. Note the sprint name for the report header.
   - If that returns no results → kanban fallback: `project = "<key>" AND status != Done ORDER BY priority DESC, status ASC`
   - `maxResults: 100`. If results are truncated, note the count in the report header.
   - Request fields: `summary`, `status`, `issuetype`, `priority`, `assignee`, `updated`, `description`, `parent`
3. For each ticket, evaluate against all four anomaly categories using the returned fields
4. For each finding, generate a **specific, concrete action item** based on the anomaly and ticket context:
   - Stale → "No updates in [N] days — follow up with [assignee] or flag as blocked"
   - Unassigned → "Assign an owner or move back to To Do"
   - Missing metadata → "Add [missing field(s)] before next standup"
   - Priority mismatch → "High priority idle for [N] days — pull into In Progress or re-prioritize"
5. Render the report (see format below)

### Report Format

```markdown
## Grooming Report
**Sprint:** <name> (or **Board:** kanban) | **Scanned:** <N> tickets | **Findings:** <N>

### Stale Tickets (N)
| Ticket | Summary | Assignee | Status | Days Since Update | Action |
|--------|---------|----------|--------|-------------------|--------|
| [RNA-123](https://...) | Fix OAuth redirect | @brian | In Progress | 12 days | No updates in 12 days — ask @brian for status or flag as blocked |

### Unassigned In-Flight Work (N)
| Ticket | Summary | Status | Action |
|--------|---------|--------|--------|
| [RNA-189](https://...) | API rate limiting | In Review | In Review with no owner — assign a reviewer |

### Missing Metadata (N)
| Ticket | Summary | Assignee | Missing | Action |
|--------|---------|----------|---------|--------|
| [RNA-201](https://...) | Login bug | @brian | description, priority | Bug with no description or priority — can't be triaged |

### Priority Mismatches (N)
| Ticket | Summary | Type | Priority | Status | Days in Status | Action |
|--------|---------|------|----------|--------|---------------|--------|
| [RNA-210](https://...) | Security patch | Bug | Highest | To Do | 12 days | Highest priority but not started — should be picked up immediately |

---
**Clean tickets:** <N>/<total> (<pct>%)
```

Omit any category section with zero findings. If all tickets are clean:

```markdown
## Grooming Report
**Sprint:** <name> (or **Board:** kanban) | **Scanned:** <N> tickets

All tickets look good — no anomalies found.
```

Ticket links use the browse URL format: `https://{cloudId}/browse/{ISSUE_KEY}`.
