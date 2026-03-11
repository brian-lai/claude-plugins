---
name: jw-ez-dev:jira-plan
description: Bulk-create JIRA tickets from a plan, task list, or work description. Triggers on /jw-ez-dev:jira-plan, bulk create tickets, create tickets from plan, plan to jira, break down work into tickets.
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

# Bulk Create JIRA Tickets from a Plan

Parse a plan, task list, or work description into structured JIRA tickets and create them.

## Step 1: Load Project Config

1. Run `git rev-parse --show-toplevel` via Bash to get the repo root (or use cwd)
2. Read `~/.claude/jw-ez-dev/projects.json`
3. Look up the directory key to get `cloudId` and `projectKey`
4. If not found: "No JIRA project configured. Run `/jw-ez-dev:jira-setup` first."

## Step 2: Get Issue Types

Call `mcp__atlassian__getJiraProjectIssueTypesMetadata` to know what types are available (Epic, Story, Task, Sub-task, Bug, etc.)

## Step 3: Gather Work Items

Parse `$ARGUMENTS`:

**From Pret plan (`--from-plan`):**
1. Read `context/context.md` to find the active plan
2. Read the plan file
3. Extract actionable items from "Implementation Steps", "Approach", or "To-Do List" sections
4. For phased plans: one Story/Task per phase, sub-tasks for each step

**From specific file (`--from-file=X`):**
1. Read the specified file
2. Parse markdown lists, headers, and task items
3. Convert to ticket proposals

**Interactive (no flags):**
1. Ask the user to describe the work or paste a task list
2. Parse into individual work items

## Step 4: Propose Ticket Structure

**Always present and get confirmation before creating anything:**

```
## Proposed JIRA Tickets

Based on your plan, I'll create the following:

### Epic: Implement User Authentication (optional)

| # | Type | Summary | Parent |
|---|------|---------|--------|
| 1 | Story | Set up auth middleware | Epic |
| 2 | Task | Configure JWT token generation | Story 1 |
| 3 | Task | Add login endpoint | Story 1 |
| 4 | Story | Implement user registration | Epic |
| 5 | Task | Create registration form | Story 4 |
| 6 | Task | Add email verification | Story 4 |

Shall I create these tickets? (You can also adjust before confirming)
```

## Step 5: Create Tickets

Create in dependency order (parents before children):

1. **Epic first** (if `--epic` or proposed)
2. **Stories/Tasks** (top-level items, linked to Epic if applicable)
3. **Sub-tasks** (child items, linked to parent Story/Task)

## Step 6: Display Results

```
## Tickets Created

| Key | Type | Summary | Parent |
|-----|------|---------|--------|
| RNA-500 | Epic | Implement User Authentication | -- |
| RNA-501 | Story | Set up auth middleware | RNA-500 |
| RNA-502 | Task | Configure JWT token generation | RNA-501 |

**6 tickets created in RNA project.**

Board: https://justworks-tech.atlassian.net/jira/software/c/projects/RNA/boards/496
```

## Step 7: Update Context (if from plan)

If tickets were created from a Pret plan, offer to update `context/context.md` with ticket keys:
```markdown
## To-Do List
- [ ] Set up auth middleware (RNA-501)
- [ ] Configure JWT token generation (RNA-502)
```

## Mapping Rules: Plan Items to Ticket Types

| Plan Structure | JIRA Type |
|---------------|-----------|
| Master plan title | Epic |
| Phase or major section | Story |
| Implementation step | Task |
| Sub-step or detail | Sub-task |
| Bug-related item | Bug |

## Notes

- Always propose and get confirmation before creating
- Create parents before children
- Keep summaries concise (under 100 chars)
- Pairs naturally with the Pret-a-Program planning workflow
