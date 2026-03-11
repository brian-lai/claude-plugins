---
description: Update fields or transition the status of a JIRA ticket
argument-hint: <issue-key> [--status="In Progress"] [--assign=name] [--priority=High] [--comment="text"]
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__editJiraIssue
  - mcp__atlassian__getTransitionsForJiraIssue
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__lookupJiraAccountId
  - mcp__atlassian__addCommentToJiraIssue
---

# Update JIRA Ticket

Update fields or transition the status of a JIRA ticket.

## Step 1: Load Project Config

1. Run `git rev-parse --show-toplevel` via Bash to get the repo root (or use cwd)
2. Read `~/.claude/jw-ez-dev/projects.json`
3. Look up the directory key to get `cloudId` and `projectKey`
4. If not found: "No JIRA project configured. Run `/jw-ez-dev:jira-setup` first."

## Step 2: Resolve Issue Key

Parse `$ARGUMENTS`:
- Full key (e.g., `RNA-456`): use as-is
- Number only (e.g., `456`): prepend project key → `RNA-456`

## Step 3: Fetch Current State

Call `mcp__atlassian__getJiraIssue` to get current fields.
Call `mcp__atlassian__getTransitionsForJiraIssue` to get available transitions.

## Step 4: Apply Changes

**If `--status` is provided:**
1. Find the matching transition by target status name (case-insensitive)
2. If no match, show available transitions and error
3. If found, call `mcp__atlassian__transitionJiraIssue`:
   ```json
   { "cloudId": "<config>", "issueIdOrKey": "<key>", "transition": { "id": "<id>" } }
   ```

**If `--assign` is provided:**
1. Call `mcp__atlassian__lookupJiraAccountId` with the name
2. If multiple matches, present options via AskUserQuestion
3. Call `mcp__atlassian__editJiraIssue`:
   ```json
   { "cloudId": "<config>", "issueIdOrKey": "<key>", "fields": { "assignee": { "accountId": "<id>" } } }
   ```

**If `--priority` is provided:**
1. Call `mcp__atlassian__editJiraIssue`:
   ```json
   { "cloudId": "<config>", "issueIdOrKey": "<key>", "fields": { "priority": { "name": "<priority>" } } }
   ```

**If `--comment` is provided:**
1. Call `mcp__atlassian__addCommentToJiraIssue`:
   ```json
   { "cloudId": "<config>", "issueIdOrKey": "<key>", "commentBody": "<text>" }
   ```

**If interactive (no flags):**
Show current ticket summary and ask what to change:
1. Transition status
2. Change assignee
3. Change priority
4. Add a comment
5. Edit summary or description

## Step 5: Confirm Changes

```
## Updated RNA-456

**Summary:** Implement auth middleware
**Status:** In Progress -> In Review
**Priority:** High (unchanged)

URL: https://justworks-tech.atlassian.net/browse/RNA-456
```

## Notes

- Multiple flags can be combined: `RNA-456 --status="In Review" --comment="Ready for review"`
- Apply in order: transition first, then field updates, then comments
- Transitions are workflow-governed — not all statuses are reachable from every state
- Always show before/after for changed fields
