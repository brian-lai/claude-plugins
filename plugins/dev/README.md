# JW EZ Dev

Justworks developer workflow toolkit for Claude Code. Manage JIRA tickets, view sprint boards, and create PRs with JIRA references — all without leaving your terminal.

## Setup

### Automatic (recommended)

On every new Claude Code session, the plugin checks for missing dependencies and prints setup instructions if anything is missing. To install everything at once, run the setup script:

```bash
bash ~/.claude/plugins/marketplaces/*/plugins/jw-ez-dev/scripts/setup.sh
```

This installs/configures:
- **Atlassian MCP server** — for all JIRA skills
- **GitHub CLI (`gh`)** — for PR creation

### Manual

If you prefer to set things up yourself:

**Atlassian MCP Server:**
```bash
claude mcp add --transport http --global atlassian https://mcp.atlassian.com/v1/mcp
```
On first use, your browser will open for Atlassian OAuth. Authorize access to **justworks-tech.atlassian.net**.

**GitHub CLI:**
```bash
brew install gh
gh auth login
```

**Verify:**
```bash
claude mcp list    # should show 'atlassian'
gh auth status     # should show authenticated
```

**Notes:**
- No API keys or tokens needed — Atlassian uses OAuth
- No npx, Docker, or local dependencies required
- The MCP server is hosted by Atlassian at mcp.atlassian.com

## Getting Started

1. Install the plugin from the Justworks marketplace
2. The session hook will check dependencies — follow any setup prompts
3. Navigate to your project repository
4. Run `/jw-ez-dev:jira-setup` to link your repo to a JIRA project
5. Start managing tickets and creating PRs

## Commands

### Project Setup

| Command | Description |
|---------|-------------|
| `/jw-ez-dev:jira-setup` | Link a JIRA project to the current repo |
| `/jw-ez-dev:jira-setup --reconfigure` | Re-link to a different project |

### Ticket Management

| Command | Description |
|---------|-------------|
| `/jw-ez-dev:jira-create` | Create a new JIRA ticket |
| `/jw-ez-dev:jira-list` | List/search tickets with filters |
| `/jw-ez-dev:jira-view <KEY>` | View full ticket details |
| `/jw-ez-dev:jira-update <KEY>` | Update fields or transition status |
| `/jw-ez-dev:jira-plan` | Bulk-create tickets from a plan |
| `/jw-ez-dev:jira-board` | View current sprint board |

### Pull Requests

| Command | Description |
|---------|-------------|
| `/jw-ez-dev:pr` | Create PR with JIRA ticket reference |
| `/jw-ez-dev:pr RNA-456` | Create PR linked to specific ticket |
| `/jw-ez-dev:pr --draft` | Create as draft PR |

## Usage Examples

### Quick ticket creation
```
/jw-ez-dev:jira-create --type=Bug Login button unresponsive on Safari
```

### View your sprint work
```
/jw-ez-dev:jira-board --mine
```

### Search for tickets
```
/jw-ez-dev:jira-list --sprint=current --mine
/jw-ez-dev:jira-list authentication
```

### Update ticket status
```
/jw-ez-dev:jira-update RNA-456 --status="In Progress"
/jw-ez-dev:jira-update RNA-456 --status="In Review" --comment="PR submitted"
```

### Create PR with JIRA link
```
/jw-ez-dev:pr RNA-456
```
This creates a PR with:
- Title: `RNA-456 Implement auth middleware`
- Body includes a link to the JIRA ticket
- Optionally transitions the ticket to "In Review"

### Bulk-create from a plan
```
/jw-ez-dev:jira-plan --from-plan --epic="User Authentication"
```

## How Configuration Works

On first run of `/jw-ez-dev:jira-setup`, you provide your JIRA board URL:
```
https://justworks-tech.atlassian.net/jira/software/c/projects/RNA/boards/496
```

This is persisted in `~/.claude/jw-ez-dev/projects.json`, keyed by git repo root. Different repos can map to different JIRA projects. The config persists across plugin updates.

## Version

1.0.0 - Initial release
