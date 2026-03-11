---
name: jw-ez-dev:jira-board
description: Display the current sprint board status for the configured JIRA project. Triggers on /jw-ez-dev:jira-board, sprint board, board status, sprint status, current sprint, show board.
argument-hint: [--all] [--mine]
allowed-tools:
  - Bash
  - Read
  - mcp__atlassian__searchJiraIssuesUsingJql
---

# Sprint Board View

Display the current sprint tickets grouped by status column.

## Step 1: Load Project Config

1. Run `git rev-parse --show-toplevel` via Bash to get the repo root (or use cwd)
2. Read `~/.claude/jw-ez-dev/projects.json`
3. Look up the directory key to get `cloudId` and `projectKey`
4. If not found: "No JIRA project configured. Run `/jw-ez-dev:jira-setup` first."

## Step 2: Query Sprint Tickets

Call `mcp__atlassian__searchJiraIssuesUsingJql`:
```json
{
  "cloudId": "<from config>",
  "jql": "project = \"<projectKey>\" AND sprint in openSprints() ORDER BY status ASC, priority DESC",
  "fields": ["summary", "status", "issuetype", "priority", "assignee", "updated"],
  "maxResults": 50
}
```

Parse `$ARGUMENTS`:
- `--mine`: add `AND assignee = currentUser()`
- `--all`: include Done tickets (default hides them)
- Default: add `AND status != Done`

## Step 3: Group by Status

Group tickets by their status column. Typical columns:
- To Do
- In Progress
- In Review
- Done (hidden by default unless `--all`)

## Step 4: Display Board View

```
## Sprint Board - RNA

### To Do (4)
| Key | Type | Summary | Priority | Assignee |
|-----|------|---------|----------|----------|
| RNA-460 | Story | User profile page | High | -- |
| RNA-459 | Task | API rate limiting | Medium | Jane D. |

### In Progress (2)
| Key | Type | Summary | Priority | Assignee |
|-----|------|---------|----------|----------|
| RNA-456 | Task | Auth middleware | High | Brian L. |

### In Review (1)
| Key | Type | Summary | Priority | Assignee |
|-----|------|---------|----------|----------|
| RNA-454 | Task | Database migrations | Medium | Brian L. |

---
**Board URL:** https://justworks-tech.atlassian.net/jira/software/c/projects/RNA/boards/496
**Sprint tickets:** 7 open | 3 done (hidden)
```

If no active sprint, fall back to:
```
No active sprint found for RNA. Showing recent backlog items instead.
```
And query: `project = "RNA" AND status != Done ORDER BY updated DESC`

## Notes

- Uses `sprint in openSprints()` JQL to find current sprint
- Status names come from the JIRA workflow and may vary
- Hides Done by default to reduce noise — use `--all` to include
