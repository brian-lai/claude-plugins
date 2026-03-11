---
description: View detailed information about a specific JIRA ticket
argument-hint: <issue-key or number>
allowed-tools:
  - Bash
  - Read
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__getTransitionsForJiraIssue
---

# View JIRA Ticket

Display comprehensive details for a specific JIRA ticket.

## Step 1: Load Project Config

1. Run `git rev-parse --show-toplevel` via Bash to get the repo root (or use cwd)
2. Read `~/.claude/jw-ez-dev/projects.json`
3. Look up the directory key to get `cloudId` and `projectKey`
4. If not found: "No JIRA project configured. Run `/jw-ez-dev:jira-setup` first."

## Step 2: Resolve Issue Key

Parse `$ARGUMENTS`:
- Full key (e.g., `RNA-456`): use as-is
- Number only (e.g., `456`): prepend project key → `RNA-456`

## Step 3: Fetch Issue Details

Call `mcp__atlassian__getJiraIssue`:
```json
{
  "cloudId": "<from config>",
  "issueIdOrKey": "<resolved key>"
}
```

## Step 4: Fetch Available Transitions

Call `mcp__atlassian__getTransitionsForJiraIssue`:
```json
{
  "cloudId": "<from config>",
  "issueIdOrKey": "<resolved key>"
}
```

## Step 5: Display Ticket Details

```
## RNA-456: Implement auth middleware

**Status:** In Progress | **Type:** Task | **Priority:** High
**Assignee:** Brian Lai | **Reporter:** Jane Doe
**Sprint:** Sprint 42 | **Created:** 2026-03-08 | **Updated:** 2h ago

**Labels:** backend, auth
**Components:** API

---

### Description

<ticket description in markdown>

---

### Available Transitions

| Action | Target Status |
|--------|---------------|
| Move to Review | In Review |
| Done | Done |
| Back to To Do | To Do |

---

**URL:** https://justworks-tech.atlassian.net/browse/RNA-456

Use `/jw-ez-dev:jira-update RNA-456` to update this ticket.
```

## Notes

- Shorthand number-only input auto-prepends the configured project key
- Shows available transitions so the user knows what status changes are possible
- Displays subtasks and linked issues if they exist
- Browse URL: `https://{cloudId}/browse/{issueKey}`
