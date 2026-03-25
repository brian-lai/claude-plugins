# dev

Developer workflow toolkit for Claude Code. Manage JIRA tickets, Trello cards, create PRs with ticket references, and review PRs with automated comment resolution — all without leaving your terminal.

## Install

```
/plugin marketplace add brian-lai/claude-plugins
/plugin install dev@brian-lai-plugins
```

## Prerequisites

### Atlassian MCP Server (required for JIRA commands)

```bash
claude mcp add --transport http --global atlassian https://mcp.atlassian.com/v1/mcp
```

On first use, your browser will open for Atlassian OAuth. Authorize access to your Atlassian site.

Verify: `claude mcp list` — should show `atlassian`.

- No API keys needed — uses OAuth
- No npx, Docker, or local dependencies
- Hosted by Atlassian at mcp.atlassian.com

### trello-cli (required for Trello commands)

```bash
npm install -g trello-cli
```

Authenticate with your Trello API key and token:

```bash
trello auth:api-key YOUR_KEY    # Get key from https://trello.com/power-ups/admin
trello auth:token YOUR_TOKEN    # Visit the token URL printed by the previous command
trello sync                     # Build local name-to-ID cache
```

### GitHub CLI (required for `/dev:pr` and `/dev:review`)

```bash
brew install gh
gh auth login
```

### Automatic setup

On every session start, the plugin checks for missing dependencies and prints instructions if anything is missing. To install both in one shot:

```bash
bash ~/.claude/plugins/marketplaces/brian-lai-plugins/plugins/dev/scripts/setup.sh
```

## Getting Started

1. Install the plugin
2. Navigate to your project repository
3. Run `/dev:jira setup` to link your repo to a JIRA project, or `/dev:trello setup` to link a Trello board
4. Start managing tickets/cards, creating PRs, and running reviews

## Commands

### `/dev:jira <subcommand>`

All JIRA operations in one command.

```
/dev:jira setup                             # Link repo to JIRA project (first-time setup)
/dev:jira setup --reconfigure               # Re-link to a different project

/dev:jira create Fix login redirect bug
/dev:jira create --type=Bug --priority=High Fix login redirect bug

/dev:jira list                              # Open issues, sorted by updated
/dev:jira list --mine                       # My tickets
/dev:jira list --sprint=current             # Current sprint
/dev:jira list --status="In Progress"
/dev:jira list --backlog
/dev:jira list authentication               # Free-text search

/dev:jira view RNA-456                      # Full ticket details + transitions
/dev:jira view 456                          # Auto-prepends project key

/dev:jira update RNA-456 --status="In Review"
/dev:jira update RNA-456 --assign=Brian --comment="Starting work"
/dev:jira update RNA-456                    # Interactive

/dev:jira plan                              # Bulk-create from interactive input
/dev:jira plan --from-plan                  # Parse active Pret/Para plan
/dev:jira plan --from-file=context/plans/X.md
/dev:jira plan --epic="User Authentication"

/dev:jira board                             # Current sprint by status column
/dev:jira board --mine
/dev:jira board --all                       # Include Done tickets
```

### `/dev:trello <subcommand>`

All Trello operations in one command. Uses `trello-cli` under the hood.

```
/dev:trello setup                            # Link repo to a Trello board
/dev:trello setup --reconfigure              # Re-link to a different board

/dev:trello create Fix login redirect bug
/dev:trello create --list="In Progress" --label=Bug Fix login redirect bug

/dev:trello list                             # All cards on the board
/dev:trello list --mine                      # Cards assigned to me
/dev:trello list --list="In Progress"        # Cards in a specific list
/dev:trello list authentication              # Free-text search

/dev:trello view My Card                     # Card details + checklists + comments
/dev:trello view "In Progress/My Card"       # Disambiguate by list

/dev:trello update My Card --move="Done"
/dev:trello update My Card --assign=brian --comment="Starting work"
/dev:trello update My Card                   # Interactive

/dev:trello plan                             # Bulk-create from interactive input
/dev:trello plan --from-plan                 # Parse active PARA plan
/dev:trello plan --from-file=context/plans/X.md

/dev:trello board                            # Board overview by list
/dev:trello board --mine
```

### `/dev:pr`

Create a GitHub PR with the JIRA ticket in the title and a link in the body. Auto-detects the ticket from your branch name.

```
/dev:pr                   # Auto-detect ticket from branch name
/dev:pr RNA-456           # Specify ticket explicitly
/dev:pr RNA-456 --draft   # Create as draft
/dev:pr RNA-456 --base=develop
```

PR title format: `RNA-456 Implement auth middleware`

After creating the PR, offers to:
- Transition the JIRA ticket to "In Review"
- Post the PR URL as a comment on the JIRA ticket

### `/dev:review`

Two-phase command: deep code review + automated comment resolution.

```
/dev:review                          # Full review + address all open comments
/dev:review --post                   # Same, also posts review to GitHub
/dev:review --comments-only          # Address open comments only, skip review
/dev:review --review-only            # Deep review only, don't touch comments
/dev:review --aspects=code,tests     # Targeted review aspects
/dev:review --pr=123                 # Target a specific PR number
```

**Phase 1 — Code Review:**
Runs `pr-review-toolkit:review-pr` agents (code quality, bugs, error handling, tests, types). Produces a structured report with Critical → Important → Suggestions → Strengths. With `--post`, also runs `code-review` and posts high-confidence issues (≥80 threshold) to GitHub.

**Phase 2 — Address Open Comments:**
Fetches all open PR comments — inline review comments, top-level discussion, and bot reviews (CodeRabbit, Copilot, SonarCloud, etc.). For each: makes the code fix, replies to the thread, or notes won't-fix. Asks for confirmation before committing and pushing.

## Configuration

### JIRA

On first run of `/dev:jira setup`, you provide your Atlassian site URL and JIRA board URL:
```
Site:  mycompany.atlassian.net
Board: https://mycompany.atlassian.net/jira/software/c/projects/PROJ/boards/123
```

Persisted in `~/.claude/dev/projects.json`, keyed by git repo root.

### Trello

On first run of `/dev:trello setup`, you select a Trello board from your account.

Persisted in `~/.claude/dev/trello-projects.json`, keyed by git repo root. Different repos can map to different boards. Config persists across plugin updates.

## Version History

- **1.5.0** — Added `/dev:trello` command
- **1.4.0** — Added `/dev:review` command
- **1.6.0** — Removed Justworks-specific references; generalized for any Atlassian site
- **1.3.0** — Renamed plugin from `jw-ez-dev` to `dev` (`/dev:*` commands)
- **1.2.0** — Consolidated 7 JIRA commands into single `/dev:jira <subcommand>`
- **1.1.0** — Converted skills to commands for lazy loading (no startup token cost)
- **1.0.0** — Initial release
