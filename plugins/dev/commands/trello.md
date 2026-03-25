---
description: Manage Trello cards for the configured board
argument-hint: <setup|create|list|view|update|plan|board> [args]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
---

# Trello Management

Unified command for all Trello operations using the `trello-cli` npm package. Parse `$ARGUMENTS` to determine the subcommand.

**CLI dependency:** All Trello operations use the `trello` CLI (`npm install -g trello-cli`). Always use `--format json` for machine-readable output when parsing results.

## Subcommand Routing

Parse the first word of `$ARGUMENTS`:

| Subcommand | Example | Description |
|------------|---------|-------------|
| `setup` | `/dev:trello setup` | Link a Trello board to this repo |
| `create` | `/dev:trello create Fix login bug` | Create a card |
| `list` | `/dev:trello list --mine` | Search/filter cards |
| `view` | `/dev:trello view My Card` | View card details |
| `update` | `/dev:trello update My Card --move="Done"` | Update a card |
| `plan` | `/dev:trello plan --from-plan` | Bulk-create from plan |
| `board` | `/dev:trello board` | Board overview |
| *(none)* | `/dev:trello` | Show config + help |

Strip the subcommand from `$ARGUMENTS` and pass the remainder as arguments to the relevant section below.

---

## Shared: Load Project Config

All subcommands (except `setup`) start with this:

1. Run `git rev-parse --show-toplevel` via Bash to get the git repo root (or use cwd)
2. Read `~/.claude/dev/trello-projects.json`
3. Look up the directory key to get `boardName`
4. If not found: "No Trello board configured. Run `/dev:trello setup` first."

## Shared: Card Resolution

Many subcommands need to locate a card. The `trello` CLI requires `--board`, `--list`, and `--card` flags (all name-based). When the user provides only a card name:

1. **If format is `ListName/CardName`**: split and use directly
2. **If a Trello card ID** (24-char hex): use `trello card:get-by-id --id <id> --format json`
3. **Otherwise**: iterate all open lists on the board (`trello list:list --board "<board>" --format json`), then for each list run `trello card:list --board "<board>" --list "<list>" --format json` and search for the card by name
4. If found in exactly one list: use that list + card name
5. If found in multiple lists: ask the user to disambiguate with `ListName/CardName` format
6. If not found: "Card not found. Check the name or use `/dev:trello list` to search."

---

## setup

Configure a Trello board for the current repository.

```
/dev:trello setup                # First-time setup or show current config
/dev:trello setup --reconfigure  # Re-link to a different board
```

### Step 0: Check trello-cli Installation

Run `which trello` via Bash.

**If not found**, display this and stop:

```
## trello-cli Not Detected

The Trello integration requires the trello-cli package:

    npm install -g trello-cli

After installing, authenticate:

    1. Get your API key:    https://trello.com/power-ups/admin (select a Power-Up or create one, then copy the API key)
    2. Store the key:       trello auth:api-key YOUR_KEY
    3. Generate a token:    Visit the token URL printed by the previous command
    4. Store the token:     trello auth:token YOUR_TOKEN
    5. Build local cache:   trello sync

After setup, run /dev:trello setup again.
```

### Step 1: Check Authentication

Run `trello board:list --format json` via Bash.

**If it fails** (auth error), display auth instructions (same as Step 0, starting from item 1) and stop.

### Step 2: Check Existing Config

1. Read `~/.claude/dev/trello-projects.json`
2. If entry exists for this directory AND no `--reconfigure` → show config and available commands
3. Otherwise → proceed to Step 3

### Step 3: Select Board

Present the list of boards from Step 1 to the user. Use **AskUserQuestion** with the board names as options (up to 4; include "Other" for URL/name input).

Alternatively, the user can paste a Trello board URL (e.g., `https://trello.com/b/abc123/my-board`). Extract the board name from the URL if needed, then verify it exists in the board list.

### Step 4: Sync Cache

Run `trello sync` via Bash to ensure the local name-to-ID cache is up to date.

### Step 5: Persist

Ensure `~/.claude/dev/` exists. Write/update `trello-projects.json`:

```json
{
  "<repo-root>": {
    "boardName": "My Project Board",
    "boardUrl": "https://trello.com/b/abc123/my-project-board",
    "configuredAt": "<ISO timestamp>"
  }
}
```

### Step 6: Show Config

```
## Trello Board Configured

**Board:** My Project Board
**URL:** https://trello.com/b/abc123/my-project-board

Commands: /dev:trello <setup|create|list|view|update|plan|board>
```

---

## create

Create a new Trello card.

```
/dev:trello create Fix login redirect bug
/dev:trello create --list="In Progress" Fix login redirect bug
/dev:trello create --label=Bug --due="next friday" Fix login redirect bug
/dev:trello create                            # Interactive
```

### Arguments
- **Name** (positional): card title (everything after flags)
- `--list=<name>` (default: first open list on the board)
- `--label=<name>`: label to apply (can specify multiple: `--label=Bug --label=Urgent`)
- `--due=<date>`: due date (natural language supported, e.g., "next friday", "2026-04-01")
- `--assign=<username>`: assign a board member
- `--description=<text>`: card description
- `--position=top|bottom` (default: top)

If no arguments, prompt interactively for name, list, and description.

### Execution

1. Load config → get `boardName`
2. If no `--list`, fetch lists via `trello list:list --board "<board>" --format json` and use the first open list, or prompt the user to choose
3. Build command: `trello card:create --board "<board>" --list "<list>" --name "<name>" --format json`
   - Add `--label`, `--due`, `--description`, `--position` flags as provided
4. If `--assign`: follow up with `trello card:assign --board "<board>" --list "<list>" --card "<name>" --user "<username>"`
5. Display: `**<card name>** created in **<list>** | Labels: <labels> | Due: <date>`
6. Include the card URL if available from the JSON output

---

## list

Search and display Trello cards.

```
/dev:trello list                       # All cards on the board
/dev:trello list --mine                # Cards assigned to me
/dev:trello list --list="In Progress"  # Cards in a specific list
/dev:trello list --label=Bug           # Cards with a specific label
/dev:trello list authentication        # Free-text search
```

### Routing by Flags

| Flag | Strategy |
|------|----------|
| `--mine` | `trello card:assigned-to --user me --format json`, filter results to configured board |
| `--list="X"` | `trello card:list --board "<board>" --list "X" --format json` |
| Free text | `trello search --query "<text>" --board "<boardName>" --type cards --format json` |
| `--label=X` | Fetch all cards (iterate lists), filter client-side by label name |
| No flags | Fetch all open lists, get cards from each, combine |

### Display

Show as a table with columns: **Card Name**, **List**, **Labels**, **Due**, **Members**.

If no cards found, display: "No cards found matching your criteria."

---

## view

View detailed card information.

```
/dev:trello view Fix login bug           # By card name (searches all lists)
/dev:trello view "In Progress/My Card"   # By list/card format
/dev:trello view 507f1f77bcf86cd799439011  # By Trello card ID
```

### Execution

1. Load config → get `boardName`
2. Resolve card using the **Card Resolution** strategy above
3. Fetch card details: `trello card:show --board "<board>" --list "<list>" --card "<card>" --format json`
4. Fetch additional data (each via separate CLI call):
   - Comments: `trello card:comments --board "<board>" --list "<list>" --card "<card>" --format json`
   - Checklists: `trello card:checklists --board "<board>" --list "<list>" --card "<card>" --format json`
   - Attachments: `trello card:attachments --board "<board>" --list "<list>" --card "<card>" --format json`
5. Display all details:
   - **Name**, **List**, **Description**
   - **Labels** (color + name)
   - **Due date** (with overdue indicator if past)
   - **Members** (assigned users)
   - **Checklists** (with completion count, e.g., "3/5 items complete")
   - **Comments** (most recent first, show author + date + text)
   - **Attachments** (name + URL)
   - **Card URL**

---

## update

Update card fields, move between lists, add comments.

```
/dev:trello update My Card                                    # Interactive
/dev:trello update My Card --move="Done"
/dev:trello update My Card --assign=brian
/dev:trello update My Card --comment="Started implementation"
/dev:trello update My Card --label=Urgent
/dev:trello update My Card --due="next friday"
/dev:trello update My Card --name="Renamed Card"
/dev:trello update My Card --archive
/dev:trello update "In Progress/My Card" --move="Done" --comment="All done"
```

### Execution

1. Load config, resolve card using **Card Resolution** strategy
2. Apply flags in order:
   - **`--move="List Name"`**: `trello card:move --board "<board>" --list "<current-list>" --card "<card>" --to "List Name"`
   - **`--assign=user`**: `trello card:assign --board "<board>" --list "<list>" --card "<card>" --user "<user>"`
   - **`--comment="text"`**: `trello card:comment --board "<board>" --list "<list>" --card "<card>" --text "<text>"`
   - **`--label=name`**: `trello card:label --board "<board>" --list "<list>" --card "<card>" --label "<name>"`
   - **`--due=date`**: `trello card:update --board "<board>" --list "<list>" --card "<card>" --due "<date>"`
   - **`--name="new name"`**: `trello card:update --board "<board>" --list "<list>" --card "<card>" --name "<new name>"`
   - **`--archive`**: `trello card:archive --board "<board>" --list "<list>" --card "<card>"`
3. **Interactive** (no flags): fetch current state via `card:show`, display it, then ask what to change using **AskUserQuestion**
4. After `--move`, update the `--list` reference for subsequent commands in the same invocation
5. Show summary of all changes made

---

## plan

Bulk-create cards from a plan or task list.

```
/dev:trello plan                              # Interactive
/dev:trello plan --from-plan                  # Parse active PARA plan
/dev:trello plan --from-file=context/plans/X.md
```

### Mapping Strategy

Trello doesn't have JIRA's issue-type hierarchy (Epic → Story → Task → Sub-task). Instead, map plan structure to Trello's model:

| Plan Element | Trello Equivalent |
|-------------|-------------------|
| Phase / Section heading | **List** on the board (create if it doesn't exist) |
| Step / Task | **Card** in the corresponding list |
| Sub-step / Sub-task | **Checklist item** on the card |

### Execution

1. Load config → get `boardName`
2. Gather work items from:
   - `--from-plan`: read active plan from `context/context.md` → parse the referenced plan file
   - `--from-file=<path>`: read the specified file
   - No flags: prompt interactively for items (one per line, indented lines become checklist items)
3. Parse the plan structure:
   - H2/H3 headings or numbered sections → lists
   - Bullet points or numbered steps → cards
   - Indented sub-bullets → checklist items on the parent card
4. **Propose the structure as a table and wait for confirmation before creating anything**
   - Show: List → Card → Checklist items
   - Use **AskUserQuestion** to confirm or adjust
5. Create in order:
   - Lists first: `trello list:create --board "<board>" --name "<name>" --position bottom`
   - Cards: `trello card:create --board "<board>" --list "<list>" --name "<name>"`
   - Checklists: `trello card:checklist --board "<board>" --list "<list>" --card "<card>" --name "Tasks"`
   - Note: checklist items cannot be added via trello-cli (limitation) — mention this to user and suggest adding them manually or via the Trello UI
6. Display created items with count summary

---

## board

Board overview showing all lists and cards.

```
/dev:trello board           # All lists and cards
/dev:trello board --mine    # Only cards assigned to me
```

### Execution

1. Load config → get `boardName`
2. Fetch all open lists: `trello list:list --board "<board>" --format json`
3. For each list, fetch cards: `trello card:list --board "<board>" --list "<list>" --format json`
4. If `--mine`: filter to cards where the current user is a member
5. Display as columnar board view:

```
## My Project Board

### To Do (3 cards)
| Card | Labels | Due | Members |
|------|--------|-----|---------|
| Fix login bug | Bug | Mar 28 | @brian |
| Add search | Feature | — | — |
| Update docs | — | Apr 1 | @brian |

### In Progress (1 card)
| Card | Labels | Due | Members |
|------|--------|-----|---------|
| Auth refactor | Tech Debt | — | @brian |

### Done (0 cards)
_No cards_

**Board:** https://trello.com/b/abc123/my-project-board
**Total:** 4 cards across 3 lists
```

6. Show board URL and total card counts
