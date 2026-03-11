---
description: Create a new JIRA ticket in the configured Justworks project
argument-hint: [--type=Task|Story|Bug] [--parent=KEY] <summary>
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
  - mcp__atlassian__createJiraIssue
  - mcp__atlassian__getJiraProjectIssueTypesMetadata
  - mcp__atlassian__lookupJiraAccountId
---

# Create JIRA Ticket

Create a new JIRA ticket in the configured project.

## Step 1: Load Project Config

1. Run `git rev-parse --show-toplevel` via Bash to get the repo root (or use cwd)
2. Read `~/.claude/jw-ez-dev/projects.json`
3. Look up the directory key to get `cloudId` and `projectKey`
4. If not found: "No JIRA project configured. Run `/jw-ez-dev:jira-setup` first."

## Step 2: Get Issue Types (if needed)

If the user didn't specify a type, or for validation, call `mcp__atlassian__getJiraProjectIssueTypesMetadata` with the `cloudId` and `projectIdOrKey`. Default to "Task" if not specified.

## Step 3: Collect Ticket Details

Parse `$ARGUMENTS` for flags and the summary.

**Required:**
- **Summary**: One-line title for the ticket

**Optional (prompt interactively if no arguments given):**
- **Issue Type**: Task (default), Story, Bug, Sub-task, Epic
- **Description**: Detailed description (Markdown supported)
- **Priority**: Highest, High, Medium, Low, Lowest
- **Assignee**: Search by name using `mcp__atlassian__lookupJiraAccountId`
- **Parent**: Parent issue key for subtasks (e.g., RNA-100)

For quick creation (summary provided as argument), use defaults:
- Type: Task, Priority: project default, Assignee: unassigned

## Step 4: Create the Ticket

Call `mcp__atlassian__createJiraIssue` with:
```json
{
  "cloudId": "<from config>",
  "projectKey": "<from config>",
  "issueTypeName": "<selected type>",
  "summary": "<user provided>",
  "description": "<user provided, optional>",
  "parent": "<parent key, if subtask>"
}
```

## Step 5: Display Result

```
## Ticket Created

**[RNA-456](https://justworks-tech.atlassian.net/browse/RNA-456)**: <summary>
**Type:** Task | **Priority:** Medium | **Status:** To Do
```

Construct the browse URL as: `https://{cloudId}/browse/{issueKey}`

## Notes

- Subtasks require a valid parent issue key in the same project
- Description field supports Markdown formatting
- Created ticket keys can be referenced in commit messages and PR descriptions
