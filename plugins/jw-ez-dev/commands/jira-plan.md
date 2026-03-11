---
description: Bulk-create JIRA tickets from a plan, task list, or work description
argument-hint: [--from-plan] [--from-file=path] [--epic="Epic Name"]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - mcp__atlassian__createJiraIssue
  - mcp__atlassian__getJiraProjectIssueTypesMetadata
---

# Bulk-Create JIRA Tickets from Plan

Create multiple JIRA tickets from a Pret/Para plan, task list, or ad-hoc description.

## Step 1: Load Project Config

1. Run `git rev-parse --show-toplevel` via Bash to get the repo root (or use cwd)
2. Read `~/.claude/jw-ez-dev/projects.json`
3. Look up the directory key to get `cloudId` and `projectKey`
4. If not found: "No JIRA project configured. Run `/jw-ez-dev:jira-setup` first."

## Step 2: Get Issue Types

Call `mcp__atlassian__getJiraProjectIssueTypesMetadata` to know what types are available (Epic, Story, Task, Sub-task, Bug, etc.)

## Step 3: Gather Work Items

**From plan (`--from-plan`):**
1. Read `context/context.md` to find the active plan
2. Read the plan file
3. Extract actionable items from "Implementation Steps", "Approach", or "To-Do List" sections
4. For phased plans, create one Story/Task per phase, with sub-tasks for each step

**From specific file (`--from-file=X`):**
1. Read the specified file
2. Parse markdown lists, headers, and task items
3. Convert to ticket proposals

**Interactive (no flags):**
1. Ask the user to describe the work or paste a task list
2. Parse the input into individual work items

## Step 4: Propose Ticket Structure

Before creating anything, present the proposed tickets for approval:

```
## Proposed JIRA Tickets

| # | Type | Summary | Parent |
|---|------|---------|--------|
| 1 | Story | Set up auth middleware | Epic |
| 2 | Task | Configure JWT token generation | Story 1 |
| 3 | Task | Add login endpoint | Story 1 |

Shall I create these tickets? (You can also adjust before confirming)
```

Wait for user confirmation before creating.

## Step 5: Create Tickets

Create in dependency order (parents before children):

1. **Create Epic first** (if `--epic` or if proposed)
2. **Create Stories/Tasks** (top-level items)
3. **Create Sub-tasks** (child items)

## Step 6: Display Results

```
## Tickets Created

| Key | Type | Summary | Parent |
|-----|------|---------|--------|
| RNA-500 | Epic | Implement User Authentication | -- |
| RNA-501 | Story | Set up auth middleware | RNA-500 |
| RNA-502 | Task | Configure JWT token generation | RNA-501 |

**3 tickets created in RNA project.**

View board: https://justworks-tech.atlassian.net/jira/software/c/projects/RNA/boards/496
```

## Step 7: Update Context (if from plan)

If tickets were created from a plan, optionally update `context/context.md` to reference the JIRA ticket keys alongside the to-do items.

## Mapping Rules: Plan Items to Ticket Types

| Plan Structure | JIRA Type |
|---------------|-----------|
| Master plan title | Epic |
| Phase or major section | Story |
| Implementation step | Task |
| Sub-step or detail | Sub-task |
| Bug-related item | Bug |

## Notes

- Always propose and get confirmation before creating tickets
- Create parents before children (Epic -> Story -> Sub-task)
- Keep ticket summaries concise (under 100 chars)
- Descriptions support Markdown
