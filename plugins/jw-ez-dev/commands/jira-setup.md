---
description: Set up and configure a Justworks JIRA project for the current repository
argument-hint: [--reconfigure]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - AskUserQuestion
  - mcp__atlassian__getVisibleJiraProjects
---

# JIRA Project Setup

Configure a Justworks JIRA project for the current repository. This persists the project mapping so all other `jw-ez-dev` commands know which JIRA project to target.

## Prerequisites Check

**Before anything else, verify the Atlassian MCP server is available.**

### Step 0: Check Atlassian MCP Connectivity

Attempt to call `mcp__atlassian__getVisibleJiraProjects` with:
```json
{
  "cloudId": "justworks-tech.atlassian.net"
}
```

**If the tool call succeeds:** MCP is configured. Proceed to Step 1.

**If the tool call fails or the tool is not available:** The Atlassian MCP server is not set up. Display the following setup guide and stop:

```
## Atlassian MCP Not Detected

The JIRA integration requires the Atlassian MCP server. Here's how to set it up:

### Setup (one command)

Run this in your terminal:

\`\`\`bash
claude mcp add --transport http --global atlassian https://mcp.atlassian.com/v1/mcp
\`\`\`

This adds the Atlassian remote MCP server globally (available in all projects).

### Authentication

On first use, Claude Code will open your browser to authenticate with Atlassian via OAuth.
Authorize access to **justworks-tech.atlassian.net**.

### Verification

After adding, restart Claude Code (or start a new session) and verify:

\`\`\`bash
claude mcp list
\`\`\`

You should see `atlassian` listed as an HTTP MCP server.

### Notes

- No API keys or tokens needed — uses Atlassian's OAuth flow
- No npx, Docker, or local dependencies required
- The MCP server is hosted by Atlassian at mcp.atlassian.com
- Access is scoped to whichever Atlassian sites you authorize

---

After completing setup, run `/jw-ez-dev:jira-setup` again to configure your project.
```

**Do not proceed with project setup if MCP is not available.**

## Step 1: Determine Current Directory Context

1. Run `git rev-parse --show-toplevel` via Bash to get the git repo root
2. If inside a git repo, use the repo root as the directory key
3. Otherwise, use the current working directory

## Step 2: Check for Existing Configuration

1. Read `~/.claude/jw-ez-dev/projects.json` (create the directory if it doesn't exist)
2. Look up the directory key in the JSON map
3. If found AND user did NOT pass `--reconfigure`, go to **Step 5** (show config)
4. If not found OR `--reconfigure`, go to **Step 3** (setup)

## Step 3: First-Time Setup

Ask the user using AskUserQuestion or direct prompt:

```
Welcome to JW EZ Dev! To link this repository to a JIRA project, please provide your Justworks JIRA project board URL.

Expected format: https://justworks-tech.atlassian.net/jira/software/c/projects/RNA/boards/496
```

Validate the URL. It should match:
```
https://justworks-tech.atlassian.net/jira/software/c/projects/{PROJECT_KEY}/boards/{BOARD_ID}
```

Extract:
- `cloudId`: `"justworks-tech.atlassian.net"`
- `projectKey`: The project key (e.g., `RNA`)
- `boardId`: The board ID (e.g., `496`)
- `boardUrl`: The full URL as provided

If the URL doesn't match, ask again with a helpful error showing the expected format.

## Step 4: Persist Configuration

1. Ensure `~/.claude/jw-ez-dev/` directory exists (create via Bash `mkdir -p` if needed)
2. Read current `~/.claude/jw-ez-dev/projects.json` (or start with `{}` if it doesn't exist)
3. Add/update the entry:
   ```json
   {
     "/Users/username/projects/my-repo": {
       "cloudId": "justworks-tech.atlassian.net",
       "projectKey": "RNA",
       "boardId": "496",
       "boardUrl": "https://justworks-tech.atlassian.net/jira/software/c/projects/RNA/boards/496",
       "configuredAt": "2026-03-10T12:00:00Z"
     }
   }
   ```
4. Write the updated JSON back

## Step 5: Display Configuration & Available Commands

```
## JW EZ Dev - Project Configured

**Project:** RNA
**Board:** https://justworks-tech.atlassian.net/jira/software/c/projects/RNA/boards/496
**Directory:** /Users/username/projects/my-repo

### Available Commands

| Command | Description |
|---------|-------------|
| `/jw-ez-dev:jira-setup` | Show config or reconfigure |
| `/jw-ez-dev:jira-create` | Create a new JIRA ticket |
| `/jw-ez-dev:jira-list` | List/search tickets |
| `/jw-ez-dev:jira-view` | View ticket details |
| `/jw-ez-dev:jira-update` | Update or transition a ticket |
| `/jw-ez-dev:jira-plan` | Bulk-create tickets from a plan |
| `/jw-ez-dev:jira-board` | View sprint/board status |
| `/jw-ez-dev:pr` | Create a PR with JIRA ticket reference |

Tip: Use `/jw-ez-dev:jira-setup --reconfigure` to link a different project.
```

## Configuration File

The config file at `~/.claude/jw-ez-dev/projects.json` maps git repo roots to JIRA project details. Multiple repos can map to different JIRA projects.

## Helper: Load Project Config (for all other commands)

All sibling commands should follow this pattern to load config:

1. Run `git rev-parse --show-toplevel` (or use cwd if not in a git repo)
2. Read `~/.claude/jw-ez-dev/projects.json`
3. Look up the directory key
4. If not found: "No JIRA project configured for this directory. Run `/jw-ez-dev:jira-setup` to set up."
5. If found: extract `cloudId` and `projectKey` for use with `mcp__atlassian__*` tools

## Notes

- The `cloudId` parameter for all `mcp__atlassian__*` tools is the site URL: `"justworks-tech.atlassian.net"`
- Config is stored in `~/.claude/jw-ez-dev/` (not inside the plugin itself) so it persists across plugin updates
- The browse URL for any ticket is: `https://justworks-tech.atlassian.net/browse/{ISSUE_KEY}`
