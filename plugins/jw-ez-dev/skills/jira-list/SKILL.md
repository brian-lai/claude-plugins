---
name: jw-ez-dev:jira-list
description: List and search JIRA tickets in the configured Justworks project. Triggers on /jw-ez-dev:jira-list, list jira tickets, show my tickets, search jira, jira issues.
argument-hint: [--mine] [--status="In Progress"] [--type=Bug] [--sprint=current] [search terms]
allowed-tools:
  - Bash
  - Read
  - mcp__atlassian__searchJiraIssuesUsingJql
---

# List JIRA Tickets

Query and display JIRA tickets from the configured project.

## Step 1: Load Project Config

1. Run `git rev-parse --show-toplevel` via Bash to get the repo root (or use cwd)
2. Read `~/.claude/jw-ez-dev/projects.json`
3. Look up the directory key to get `cloudId` and `projectKey`
4. If not found: "No JIRA project configured. Run `/jw-ez-dev:jira-setup` first."

## Step 2: Build JQL Query

Start with base: `project = "<projectKey>"`

Add filters from `$ARGUMENTS`:
- `--mine` → `AND assignee = currentUser()`
- `--status="X"` → `AND status = "X"`
- `--type=X` → `AND issuetype = "X"`
- `--sprint=current` → `AND sprint in openSprints()`
- `--backlog` → `AND status = "To Do" AND sprint is EMPTY`
- `--blockers` → `AND priority in (Highest, High) AND status != Done`
- Free text → `AND (summary ~ "text" OR description ~ "text")`
- Default (no filters): `AND status != Done ORDER BY updated DESC`

Always append `ORDER BY updated DESC` unless already specified.

## Step 3: Execute Query

Call `mcp__atlassian__searchJiraIssuesUsingJql`:
```json
{
  "cloudId": "<from config>",
  "jql": "<constructed JQL>",
  "fields": ["summary", "status", "issuetype", "priority", "assignee", "updated"],
  "maxResults": 20
}
```

## Step 4: Display Results

```
## JIRA Tickets - RNA (12 results)

| Key | Type | Summary | Status | Priority | Assignee | Updated |
|-----|------|---------|--------|----------|----------|---------|
| RNA-456 | Task | Implement auth middleware | In Progress | High | Brian L. | 2h ago |
| RNA-455 | Bug | Login fails on Safari | To Do | Highest | -- | 1d ago |
```

If no results: "No tickets found matching your query."

## Quick Filter Reference

| Shortcut | JQL Equivalent |
|----------|---------------|
| `--mine` | `assignee = currentUser()` |
| `--sprint=current` | `sprint in openSprints()` |
| `--backlog` | `status = "To Do" AND sprint is EMPTY` |
| `--blockers` | `priority in (Highest, High) AND status != Done` |

## Notes

- Default shows open (non-Done) issues sorted by last update
- Max 100 results per query (Atlassian MCP limit)
- Use relative timestamps ("2h ago", "1d ago") for readability
