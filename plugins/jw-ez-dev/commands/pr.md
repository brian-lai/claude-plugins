---
description: Create a GitHub Pull Request with JIRA ticket reference in the title and body
argument-hint: [issue-key] [--draft] [--base=branch]
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
  - mcp__atlassian__getJiraIssue
  - mcp__atlassian__transitionJiraIssue
  - mcp__atlassian__getTransitionsForJiraIssue
  - mcp__atlassian__addCommentToJiraIssue
---

# Create PR with JIRA Reference

Create a GitHub Pull Request with the JIRA ticket ID in the title and a link to the ticket in the body.

## Step 1: Load JIRA Project Config

1. Read `~/.claude/jw-ez-dev/projects.json`
2. Look up the current directory (git repo root)
3. If not configured, warn: "No JIRA project configured. Run `/jw-ez-dev:jira-setup` first. You can still create a PR without JIRA linking — proceed?"

## Step 2: Resolve JIRA Ticket

Parse `$ARGUMENTS` for an explicit ticket key. Otherwise, detect automatically:

**Priority order:**
1. **Explicit argument**: e.g., `RNA-456`
2. **Branch name**: Parse current branch for `{projectKey}-\d+` (case-insensitive)
   - `pret/rna-456-feature-name` → `RNA-456`
   - `feature/RNA-456-something` → `RNA-456`
3. **Pret context**: Read `context/context.md` for a JIRA ticket key
4. **Prompt**: Ask the user — "Which JIRA ticket is this PR for? (leave blank to skip)"

## Step 3: Fetch Ticket Details (if found)

Call `mcp__atlassian__getJiraIssue` to get the ticket summary for the PR title.

## Step 4: Analyze Changes

Run via Bash:
1. `git status` — warn about uncommitted changes
2. `git log --oneline <base>..HEAD` — commits on this branch
3. `git diff <base>...HEAD --stat` — files changed

Determine base branch:
- `--base` flag if provided
- Otherwise: `git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`

## Step 5: Compose PR Title

Format: `{TICKET_ID} {description}`

- With ticket: `RNA-456 Implement auth middleware`
- Without ticket: just the description from commits

Keep under 70 characters. Ask user to confirm or edit.

## Step 6: Compose PR Body

```markdown
## Summary
<1-3 bullet points from commit history>

## Ticket
[RNA-456](https://justworks-tech.atlassian.net/browse/RNA-456)

## Test plan
<bulleted checklist based on changes>
```

Omit the Ticket section if no JIRA ticket.

## Step 7: Push and Create PR

1. Check remote tracking: `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null`
2. Push if needed: `git push -u origin HEAD`
3. Create PR:
   ```bash
   gh pr create --title "<title>" --body "$(cat <<'EOF'
   <body content>
   EOF
   )" [--draft] [--base <base>]
   ```

## Step 8: Post-PR Actions

After PR is created:

1. **Display result** with PR URL, title, ticket URL, and base/head branches

2. **Offer to transition JIRA ticket** to "In Review":
   - Fetch available transitions via `mcp__atlassian__getTransitionsForJiraIssue`
   - If a transition targets "In Review" (or similar), offer it
   - If accepted, call `mcp__atlassian__transitionJiraIssue`

3. **Offer to comment on JIRA ticket** with the PR link:
   - If accepted, call `mcp__atlassian__addCommentToJiraIssue` with the PR URL

## Edge Cases

**No JIRA ticket:** Create PR without ticket reference. Skip transition offer.

**Uncommitted changes:**
```
Warning: You have uncommitted changes (not included in PR).
1. Continue anyway
2. Cancel (commit first)
```

**No commits on branch:** Error — nothing to create a PR for.

## Notes

- Requires `gh` CLI installed and authenticated
- Reads JIRA config from `~/.claude/jw-ez-dev/projects.json` (shared with jira commands)
- Ticket browse URL: `https://{cloudId}/browse/{TICKET_KEY}`
- PR title format: `{TICKET_ID} {description}` (ticket ID first, no colon)
- Works with or without JIRA config — gracefully degrades
