---
description: Review a PR, address open comments, and post feedback to GitHub
argument-hint: [--pr=<number>] [--aspects=code,tests,errors] [--comments-only] [--review-only] [--post]
allowed-tools:
  - Bash
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Task
---

# PR Review & Comment Resolution

Two-phase command:
1. **Review** — Deep code review using specialized agents
2. **Address** — Fetch all open PR comments (human + bot) and resolve them

Parse `$ARGUMENTS` to determine mode. Default: run both phases.

---

## Flags

| Flag | Description |
|------|-------------|
| `--pr=<number>` | Target a specific PR number (default: current branch's PR) |
| `--aspects=X,Y` | Review aspects to run: `code`, `tests`, `errors`, `types`, `comments`, `simplify` (default: `code,errors`) |
| `--comments-only` | Skip review, only address open PR comments |
| `--review-only` | Run review only, do not address comments |
| `--post` | Post the review to GitHub as a PR comment (invokes `/code-review` behavior) |

---

## Step 1: Resolve PR Context

1. If `--pr=<number>` provided, use that PR
2. Otherwise detect from current branch: `gh pr view --json number,title,state,isDraft,headRefName`
3. If no PR found: "No open PR for this branch. Create one with `/dev:pr` first."
4. If PR is closed or draft: warn and ask the user to confirm before proceeding

---

## Phase 1: Review (skip if `--comments-only`)

Delegate to the two existing review tools in sequence:

### 1a. Local Deep Analysis (`/pr-review-toolkit:review-pr`)

Invoke the `pr-review-toolkit:review-pr` command via Task agent with the requested aspects (from `--aspects`, default `code,errors`).

This runs specialized agents against `git diff` and produces a structured report:
- **Critical Issues** — must fix before merge
- **Important Issues** — should fix
- **Suggestions** — nice to have
- **Strengths** — what's well done

Display the full report inline.

### 1b. GitHub-Posted Review (only if `--post`)

If `--post` is passed, also invoke the `code-review` command via Task agent. This runs 5 parallel Sonnet agents, confidence-scores all issues (≥80 threshold), and posts the result as a GitHub PR comment.

Display a link to the posted comment.

---

## Phase 2: Address Open Comments (skip if `--review-only`)

### Step 2a: Fetch All Open PR Comments

Run in parallel:

```bash
# Review-level comments (top-level PR discussion)
gh pr view <number> --json comments --jq '.comments[] | select(.body != "") | {author: .author.login, body: .body, createdAt: .createdAt}'

# Inline review comments (line-level)
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  --jq '.[] | select(.in_reply_to_id == null) | {id: .id, author: .user.login, body: .body, path: .path, line: .line, diffHunk: .diff_hunk}'

# Review summaries (batch review comments from tools like Copilot, CodeRabbit, etc.)
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  --jq '.[] | {id: .id, author: .user.login, state: .state, body: .body, submittedAt: .submitted_at}'
```

Detect the `{owner}/{repo}` via: `gh repo view --json nameWithOwner --jq .nameWithOwner`

### Step 2b: Filter to Actionable Comments

Group comments into:

**Bot comments** — authors matching patterns like `*[bot]`, `github-actions`, `copilot`, `coderabbit`, `sonarcloud`, `codecov`, `dependabot`, `renovate`, etc.

**Human comments** — all other authors

Filter out:
- Comments that are already resolved (check for reply threads that indicate resolution)
- Purely informational comments (e.g., coverage badges, build status, deployment URLs)
- Comments on lines not in the current diff

Display a summary:
```
## Open PR Comments — PR #<N>

### Human Comments (3)
- @jane: [jira-setup.md:45] "Should this handle the case where..."
- @bob: [pr.md:92] "This pattern was deprecated, see..."
- @alice: (top-level) "Have you considered handling X?"

### Bot Comments (5)
- CodeRabbit: [commands/jira.md:112] "Missing null check on projectKey"
- GitHub Copilot: [scripts/setup.sh:34] "Potential unbound variable"
- sonarcloud: (top-level) "3 code smells detected"

Addressing 8 comments...
```

### Step 2c: Address Each Comment

For each actionable comment, work through them in order (critical/human first, then bot):

1. **Read the referenced file and line** to understand the context
2. **Determine the appropriate action:**
   - **Code change needed** → Make the edit, stage with `git add`
   - **Question/clarification** → Answer by replying to the comment via `gh api`
   - **Disagreement/won't fix** → Note it for the summary, do not change code
   - **Already addressed** → Note it, skip
3. **For each code change made**, reply to the comment:
   ```bash
   gh api repos/{owner}/{repo}/pulls/comments/<comment_id>/replies \
     -X POST -f body="Fixed in <commit-sha-or-description>."
   ```
4. **For top-level comments**, reply via:
   ```bash
   gh pr comment <number> --body "Addressed: <summary of changes>"
   ```

### Step 2d: Commit Addressed Changes

After processing all comments, if any code was changed:

1. Show a summary of all changes made
2. Ask the user: "Commit these changes? (y/n)"
3. If yes, stage and commit:
   ```bash
   git add <modified files>
   git commit -m "address PR review comments"
   ```
4. Push: `git push`

---

## Final Summary

```
## Review Complete — PR #<N>

### Phase 1: Code Review
- Critical issues: 2 (fix required)
- Important issues: 3
- Suggestions: 4
- Review posted to GitHub: <url> (if --post)

### Phase 2: Comment Resolution
- 8 comments addressed
- 5 code changes made
- 2 questions answered
- 1 marked won't fix
- Committed and pushed: <sha>

### Remaining Action Items
- [ ] RNA-456: Address critical issue in jira.md:45 (logic bug)
- [ ] Discuss with @jane: question about error handling pattern
```

---

## Usage Examples

```
/dev:review                              # Full review + address all comments
/dev:review --post                       # Same, but also post review to GitHub
/dev:review --comments-only              # Only address open comments, skip review
/dev:review --review-only                # Deep review only, don't touch comments
/dev:review --aspects=code,tests,errors  # Targeted review + address comments
/dev:review --pr=123                     # Target a specific PR by number
```

---

## Notes

- Requires `gh` CLI installed and authenticated
- Phase 1 delegates to `pr-review-toolkit:review-pr` (local) and optionally `code-review` (GitHub post)
- Bot detection is heuristic — authors ending in `[bot]` or matching known bot names
- Does not auto-commit without confirmation
- Does not resolve GitHub's "Resolved" conversation state — only replies to comments
- Always work from the PR's head branch (current branch); don't switch branches
