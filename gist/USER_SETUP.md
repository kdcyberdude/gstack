# USER_SETUP.md — Automated AI Toolchain Setup

> Give this file to any AI coding agent. It will detect your environment, install gstack + GBrain + Compound Engineering for every available provider, and ask you questions when it needs input.

---

## Mission

Set up three toolchains for **every AI provider detected on this system**:

| Tool | What It Does | Source |
|------|-------------|--------|
| **gstack** | 23 engineering skills (CEO, designer, eng manager, QA, security, release) | `https://github.com/kdcyberdude/gstack` |
| **GBrain** | Persistent knowledge base / memory for AI agents | `https://github.com/garrytan/gbrain` |
| **Compound Engineering** | Planning, review, and compounding engineering workflow skills | `https://github.com/EveryInc/compound-engineering-plugin` |

---

## Phase 0 — Environment Detection

Run these commands and record results:

```bash
# Detect AI providers
echo "=== Providers ==="
which claude 2>/dev/null && echo "DETECTED: claude_code" || true
which codex 2>/dev/null && echo "DETECTED: codex" || true
ls -d ~/.cursor 2>/dev/null && echo "DETECTED: cursor" || true
which opencode 2>/dev/null && echo "DETECTED: opencode" || true
which droid 2>/dev/null && echo "DETECTED: factory_droid" || true
which qwen 2>/dev/null && echo "DETECTED: qwen" || true

# Detect prerequisites
echo "=== Prerequisites ==="
which git 2>/dev/null && echo "GIT: $(git --version)" || echo "GIT: MISSING"
which bun 2>/dev/null && echo "BUN: $(bun --version)" || echo "BUN: MISSING"
which node 2>/dev/null && echo "NODE: $(node --version)" || echo "NODE: MISSING"

# Detect existing installations
echo "=== Existing gstack ==="
ls -d ~/.claude/skills/gstack 2>/dev/null && echo "  claude: EXISTS" || echo "  claude: NOT FOUND"
ls -d ~/.codex/skills/gstack 2>/dev/null && echo "  codex: EXISTS" || echo "  codex: NOT FOUND"
ls -d ~/.cursor/skills/gstack 2>/dev/null && echo "  cursor: EXISTS" || echo "  cursor: NOT FOUND"

echo "=== Existing GBrain ==="
which gbrain 2>/dev/null && echo "  binary: $(which gbrain)" || echo "  binary: NOT FOUND"
ls -d ~/.gbrain 2>/dev/null && echo "  data: EXISTS" || echo "  data: NOT FOUND"

echo "=== Existing Compound Engineering ==="
ls -d ~/.claude/skills/compound* 2>/dev/null && echo "  claude: EXISTS" || echo "  claude: NOT FOUND"
ls -d ~/.codex/skills/compound* 2>/dev/null && echo "  codex: EXISTS" || echo "  codex: NOT FOUND"
ls -d ~/.cursor/skills/compound* 2>/dev/null && echo "  cursor: EXISTS" || echo "  cursor: NOT FOUND"
```

### Decision Gate — Prerequisites

Ask the user if anything is missing:

- **Git missing?** → "Git is not installed. Install via `brew install git`?"
- **Bun missing?** → "Bun is required for gstack browser tools and Compound Engineering installs. Install via `curl -fsSL https://bun.sh/install | bash`?"
- **Node missing?** → "Node.js is needed. Install via nvm or Homebrew?"

Wait for user confirmation before installing any prerequisite.

---

## Phase 1 — Install gstack

### Step 1.1 — Clone or update gstack

```bash
# Clone to the canonical location
if [ ! -d "$HOME/.claude/skills/gstack" ]; then
  git clone --single-branch --depth 1 https://github.com/kdcyberdude/gstack.git "$HOME/.claude/skills/gstack"
else
  cd "$HOME/.claude/skills/gstack" && git pull --rebase || true
fi
```

**Cursor dedup rule:** keep the checkout at `~/.claude/skills/gstack` only. Do **not** copy or clone the full gstack repo into `~/.agents/skills/gstack` or `~/.cursor/skills/gstack`. Cursor walks `~/.claude/skills`, `~/.cursor/skills`, and `~/.agents/skills` recursively; extra copies of generated host skill trees register the same slash command many times.

### Step 1.2 — Run `./setup` for each detected provider

Execute each sequentially. The `./setup` script auto-detects providers, but use `--host` to be explicit.

```bash
cd "$HOME/.claude/skills/gstack"

# Run setup for ALL detected hosts (auto-detect mode)
./setup

# Then explicitly target each detected provider if auto-detect misses any:
# ./setup --host claude    # Claude Code
# ./setup --host codex     # OpenAI Codex CLI
# ./setup --host cursor    # Cursor
# ./setup --host opencode  # OpenCode
# ./setup --host factory   # Factory Droid
# ./setup --host kiro      # Kiro
# ./setup --host slate     # Slate
# ./setup --host hermes    # Hermes
```

### Step 1.3 — Verify gstack installation

After setup, verify skills were installed for each provider:

```bash
echo "=== gstack verification ==="
ls ~/.claude/skills/gstack/browse/SKILL.md 2>/dev/null && echo "Claude: browse skill OK" || echo "Claude: browse skill MISSING"
ls ~/.codex/skills/gstack-browse/SKILL.md 2>/dev/null && echo "Codex: browse skill OK" || echo "Codex: browse skill MISSING"
ls ~/.cursor/skills/gstack-browse/SKILL.md 2>/dev/null && echo "Cursor: browse skill OK" || echo "Cursor: browse skill MISSING"
```

If any provider is MISSING, ask the user whether to troubleshoot or skip that provider.

### Step 1.4 — Verify Cursor slash commands are not duplicated

After `./setup --host cursor` (or `./setup` with Cursor detected), each `gstack-*` command should appear once in Agent chat. Generated Cursor/Codex skill trees live under `~/.gstack/generated/`; the checkout should not retain `.cursor/skills` or `.agents/skills` caches when installed under `~/.claude/skills/gstack`.

```bash
python3 - <<'PY'
import os
from collections import Counter

def count(root, folder):
    if not os.path.isdir(root):
        return 0
    total = 0
    for dp, _, fs in os.walk(root, followlinks=True):
        if "SKILL.md" in fs and os.path.basename(dp) == folder:
            total += 1
    return total

roots = [
    os.path.expanduser("~/.cursor/skills"),
    os.path.expanduser("~/.claude/skills"),
    os.path.expanduser("~/.agents/skills"),
]
for root in roots:
    print(root, "gstack-scrape", count(root, "gstack-scrape"))
repo = os.path.expanduser("~/.claude/skills/gstack")
for sub in (".cursor/skills", ".agents/skills"):
    print(repo + "/" + sub, count(repo + "/" + sub, "gstack-scrape"))
PY
```

Expected: one `gstack-scrape` under `~/.cursor/skills`, zero under the checkout's `.cursor/skills` and `.agents/skills`. Start a **new Agent chat** after setup so Cursor reloads skills.

---

## Phase 2 — Install GBrain

### Step 2.1 — Clone and install GBrain

```bash
git clone https://github.com/garrytan/gbrain.git "$HOME/.gbrain"
cd "$HOME/.gbrain" && bun install && bun link
```

**IMPORTANT — Do NOT use `bun install -g github:garrytan/gbrain`.** Bun blocks the postinstall hook on global installs, so schema migrations never run and the CLI aborts with `Aborted()`. The `git clone + bun install && bun link` path above is the only reliable method.

**IMPORTANT — Do NOT use `bun add -g gbrain` or `npm install -g gbrain`.** An unrelated package squats that name on npm (`gbrain@1.3.x`) and you'd silently install the wrong binary.

### Step 2.2 — Initialize GBrain

Ask the user which initialization path they prefer:

```
Which GBrain initialization path would you like?
1. PGLite local (zero accounts, zero network, isolated brain on this Mac only — fastest)
2. Supabase with existing URL (you already have a cloud brain)
3. Supabase auto-provision (requires a Supabase Personal Access Token)
```

Based on the answer:

**Option 1 — PGLite (local, fastest):**
```bash
gbrain init
```

**Option 2 — Supabase existing URL:**
```
Ask user: "What is your Supabase Session Pooler URL?"
```
Then:
```bash
gbrain init --url "<user-provided-url>"
```

**Option 3 — Supabase auto-provision:**
```
Ask user: "What is your Supabase Personal Access Token?"
```
Then:
```bash
gbrain init --auto-provision --token "<user-provided-token>"
```

### Step 2.3 — Register GBrain as MCP server for each provider

#### Claude Code
```bash
claude mcp add gbrain -- gbrain serve
```

#### Cursor
Add to Cursor's MCP server settings (Settings > MCP Servers):
```json
{
  "mcpServers": {
    "gbrain": { "command": "gbrain", "args": ["serve"] }
  }
}
```

#### Codex CLI
Add to `~/.codex/settings.yaml` or equivalent MCP config:
```yaml
mcp_servers:
  gbrain:
    command: gbrain
    args: ["serve"]
```

### Step 2.4 — Verify GBrain

```bash
gbrain query "test" && echo "GBrain query: OK" || echo "GBrain query: FAILED"
```

### Step 2.5 — Ask about GBrain trust policy

For each project repository, ask the user to set a trust tier:
- `read-write` — agent can search AND write pages
- `read-only` — agent can search but never writes
- `deny` — no gbrain interaction

This is sticky across worktrees and branches.

---

## Phase 3 — Install Compound Engineering

### Step 3.1 — Detect providers and install via native paths

Run only the commands for detected providers.

#### Claude Code (native plugin marketplace)
```bash
claude --print-config 2>/dev/null
# Then inside Claude Code session, or via CLI:
# /plugin marketplace add EveryInc/compound-engineering-plugin
# /plugin install compound-engineering
```

#### Cursor (native plugin marketplace)
In Cursor Agent chat:
```
/add-plugin compound-engineering
```
Or search for "compound engineering" in the plugin marketplace.

#### Codex CLI (three steps — all required)

**Step A — Register marketplace:**
```bash
codex plugin marketplace add EveryInc/compound-engineering-plugin
```

**Step B — Install agents (required for Codex — skills alone aren't enough):**
```bash
bunx @every-env/compound-plugin install compound-engineering --to codex
```

**Step C — Install via Codex TUI:** Launch `codex`, run `/plugins`, find **Compound Engineering** marketplace, select **compound-engineering** plugin, choose **Install**. Restart Codex after.

#### Other providers (Bun installer)

```bash
# OpenCode
bunx @every-env/compound-plugin install compound-engineering --to opencode

# Factory Droid (native)
droid plugin marketplace add https://github.com/EveryInc/compound-engineering-plugin
droid plugin install compound-engineering@compound-engineering-plugin

# Qwen Code (native)
qwen extensions install EveryInc/compound-engineering-plugin:compound-engineering

# Install to ALL detected custom targets at once
bunx @every-env/compound-plugin install compound-engineering --to all
```

### Step 3.2 — Verify Compound Engineering

After installation, verify each provider can discover CE skills. The agent should see `/ce-setup`, `/ce-brainstorm`, `/ce-plan`, `/ce-work`, `/ce-code-review`, `/ce-compound`, etc.

Run `/ce-setup` in a test project to confirm everything works.

---

## Phase 4 — Cross-Cutting Configuration

### Step 4.1 — Update project-level config files

For each provider, ensure project config files reference the installed tools.

#### CLAUDE.md (Claude Code / OpenClaw)

Add to project root `CLAUDE.md`:

```markdown
## gstack

Use the `/browse` skill from gstack for all web browsing. Never use `mcp__claude-in-chrome__*` tools.

Available gstack skills:
/office-hours, /plan-ceo-review, /plan-eng-review, /plan-design-review,
/design-consultation, /design-shotgun, /design-html, /review, /ship,
/land-and-deploy, /canary, /benchmark, /browse, /open-gstack-browser,
/qa, /qa-only, /design-review, /setup-browser-cookies, /setup-deploy,
/setup-gbrain, /sync-gbrain, /retro, /investigate, /document-release,
/codex, /cso, /autoplan, /pair-agent, /careful, /freeze, /guard,
/unfreeze, /gstack-upgrade, /learn.

## compound-engineering

Available CE skills: /ce-setup, /ce-strategy, /ce-ideate, /ce-brainstorm,
/ce-plan, /ce-work, /ce-debug, /ce-code-review, /ce-doc-review,
/ce-compound, /ce-product-pulse.

## gbrain

GBrain MCP tools are available for persistent memory. Use `gbrain search`
and `gbrain query` for knowledge lookups. Follow the trust policy for this
repo (currently: [read-write | read-only | deny]).
```

#### AGENTS.md (Codex / Cursor / OpenCode)

Add to project root `AGENTS.md`:

```markdown
## gstack

Use the browse skill from gstack for all web browsing.

Available gstack skills: /office-hours, /plan-ceo-review, /plan-eng-review,
/plan-design-review, /design-consultation, /design-shotgun, /design-html,
/review, /ship, /land-and-deploy, /canary, /benchmark, /browse,
/open-gstack-browser, /qa, /qa-only, /design-review, /setup-browser-cookies,
/setup-deploy, /retro, /investigate, /document-release, /codex, /cso,
/autoplan, /pair-agent, /careful, /freeze, /guard, /unfreeze,
/gstack-upgrade, /learn.

## compound-engineering

Available CE skills: /ce-setup, /ce-strategy, /ce-ideate, /ce-brainstorm,
/ce-plan, /ce-work, /ce-debug, /ce-code-review, /ce-doc-review,
/ce-compound, /ce-product-pulse.
```

### Step 4.2 — Verify gstack browse daemon works

```bash
# Start the browse daemon and verify it launches
cd ~/.claude/skills/gstack && bun run build 2>&1 | tail -5
```

### Step 4.3 — Final verification checklist

Run through this checklist and report status:

- [ ] gstack skills installed for Claude Code
- [ ] gstack skills installed for Codex
- [ ] gstack skills installed for Cursor
- [ ] gstack skills installed for other detected providers
- [ ] GBrain cloned, built, and linked
- [ ] GBrain initialized (PGLite or Supabase)
- [ ] GBrain registered as MCP server for Claude Code
- [ ] GBrain registered as MCP server for Cursor
- [ ] GBrain registered as MCP server for Codex
- [ ] Compound Engineering installed for Claude Code
- [ ] Compound Engineering installed for Codex
- [ ] Compound Engineering installed for Cursor
- [ ] CLAUDE.md updated with gstack + CE + GBrain sections
- [ ] AGENTS.md updated with gstack + CE sections
- [ ] Browse daemon builds successfully
- [ ] `gbrain query "test"` returns without error

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Skill not showing up in Claude Code | `cd ~/.claude/skills/gstack && ./setup` |
| `/browse` fails | `cd ~/.claude/skills/gstack && bun install && bun run build` |
| Codex says "invalid SKILL.md" | `cd ~/.codex/skills/gstack && git pull && ./setup --host codex` |
| CE skills work but delegation fails (Codex) | Run `bunx @every-env/compound-plugin install compound-engineering --to codex` |
| GBrain `Aborted()` on first run | Reinstall: `git clone + bun install && bun link` (not `bun install -g`) |
| Wrong `gbrain` binary installed | You got the npm squat package. Remove it and use `git clone + bun link` |
| Claude can't see skills | Check that project's `CLAUDE.md` has a gstack section |
| Stale CE skills | Run `bunx @every-env/compound-plugin cleanup --target <provider>` |
| Cursor shows duplicate `gstack-*` slash commands | Remove any full checkout under `~/.agents/skills/gstack`, rerun `cd ~/.claude/skills/gstack && ./setup --host cursor`, then open a new Agent chat |

---

## Questions to Ask the User During Setup

Ask these during the relevant phases. Don't ask all at once — ask contextually.

1. **Prerequisites:** "Bun is missing. Install it via `curl -fsSL https://bun.sh/install | bash`?"
2. **GBrain init path:** "Which GBrain init: (1) PGLite local, (2) Supabase existing URL, (3) Supabase auto-provision?"
3. **Supabase URL:** "What's your Supabase Session Pooler URL?" (if option 2)
4. **Supabase token:** "What's your Supabase Personal Access Token?" (if option 3)
5. **Trust policy:** "What trust level for this repo? (read-write | read-only | deny)"
6. **Skip provider:** "[Provider] wasn't detected or install failed. Skip it?"
7. **gstack skill naming:** "Use short skill names (`/qa`, `/ship`) or namespaced (`/gstack-qa`, `/gstack-ship`)?"

---

## Notes

- **Order matters:** Install gstack first, then GBrain, then Compound Engineering. gstack's `./setup` builds the browse daemon which takes time.
- **Codex is special:** CE requires 3 steps for Codex (marketplace register + Bun agent install + TUI install). All three are required.
- **GBrain MCP registration is per-provider:** Each AI tool needs its own MCP server registration.
- **This file is idempotent:** Safe to re-run. Existing installations are detected and skipped/upgraded.
- **Cursor dedup:** `./setup --host cursor` links one `~/.cursor/skills/gstack-*` entry per skill and keeps generated caches in `~/.gstack/generated/`.
- **User interaction:** When blocked on a question, ASK the user and wait. Don't make assumptions about API keys, trust policies, or initialization paths.
