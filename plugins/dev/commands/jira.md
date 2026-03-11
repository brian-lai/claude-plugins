---
description: Manage JIRA tickets for the configured Justworks project
argument-hint: <setup|create|list|view|update|plan|board> [args]
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
| *(none)* | `/dev:jira` | Show config + help |

Strip the subcommand from `$ARGUMENTS` and pass the remainder as arguments to the relevant section below.

---

## Shared: Load Project Config

All subcommands (except `setup`) start with this:

1. Run `git rev-parse --show-toplevel` via Bash to get the git repo root (or use cwd)
2. Read `~/.claude/jw-ez-dev/projects.json`
3. Look up the directory key to get `cloudId` and `projectKey`
4. If not found: "No JIRA project configured. Run `/dev:jira setup` first."

The `cloudId` for all `mcp__atlassian__*` tools is the site URL: `"justworks-tech.atlassian.net"`.
The browse URL for any ticket is: `https://justworks-tech.atlassian.net/browse/{ISSUE_KEY}`.

---

## setup

Configure a Justworks JIRA project for the current repository.

```
/dev:jira setup                # First-time setup or show current config
/dev:jira setup --reconfigure  # Re-link to a different project
```

### Step 0: Check Atlassian MCP Connectivity

Attempt to call `mcp__atlassian__getVisibleJiraProjects` with `cloudId: "justworks-tech.atlassian.net"`.

**If it fails or the tool is unavailable**, display this and stop:

```
## Atlassian MCP Not Detected

The JIRA integration requires the Atlassian MCP server:

    claude mcp add --transport http --global atlassian https://mcp.atlassian.com/v1/mcp

On first use, your browser will open for Atlassian OAuth.
Authorize access to justworks-tech.atlassian.net.

Verify:  claude mcp list  (should show 'atlassian')

After setup, run /dev:jira setup again.
```

### Step 1: Check Existing Config

1. Read `~/.claude/jw-ez-dev/projects.json`
2. If entry exists for this directory AND no `--reconfigure` → show config and available commands
3. Otherwise → prompt for setup

### Step 2: Prompt for Board URL

```
Welcome to JW EZ Dev! Provide your JIRA project board URL.
Format: https://justworks-tech.atlassian.net/jira/software/c/projects/RNA/boards/496
```

Extract `cloudId`, `projectKey`, `boardId`, `boardUrl` from the URL.

### Step 3: Persist

Ensure `~/.claude/jw-ez-dev/` exists. Write/update `projects.json`:
```json
{
  "<repo-root>": {
    "cloudId": "justworks-tech.atlassian.net",
    "projectKey": "RNA",
    "boardId": "496",
    "boardUrl": "https://justworks-tech.atlassian.net/jira/software/c/projects/RNA/boards/496",
    "configuredAt": "<ISO timestamp>"
  }
}
```

### Step 4: Show Config

```
## JW EZ Dev - Project Configured

**Project:** RNA
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
/dev:jira create                            # Interactive
```

### Arguments
- **Summary** (positional): one-line ticket title
- `--type=Task|Story|Bug|Sub-task|Epic` (default: Task)
- `--priority=Highest|High|Medium|Low|Lowest`
- `--assign=<name>`: search via `mcp__atlassian__lookupJiraAccountId`
- `--parent=<KEY>`: parent issue key for subtasks

If no arguments, prompt interactively for summary, type, and description.

### Execution

1. Optionally call `mcp__atlassian__getJiraProjectIssueTypesMetadata` for validation
2. Call `mcp__atlassian__createJiraIssue` with `cloudId`, `projectKey`, `issueTypeName`, `summary`, `description`, `parent`
3. Display: `**[RNA-456](https://...browse/RNA-456)**: <summary> | Type: Task | Status: To Do`

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
