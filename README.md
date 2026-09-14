# talos-cli

Talos, the pubky team's agent, from your terminal and from your coding agent (Claude Code,
Codex, anything that runs shell commands or MCP tools).

```
talos                                   every verb, by tier
talos find "nexus watcher lag"          search Slack, Meet transcripts, Drive, GitHub and pubky.app
talos who ben                           a teammate's team, GitHub login and Slack id
talos issue pubky/pubky-nexus "bug"     file an issue (prints a preview first, needs --yes)
talos ask "why did we drop X?"          one Talos turn, with links
talos delegate "long job"               hand him a job, collect it later with `talos result`
```

## Install

1. Ask @SHAcollision for a token (one per person, revocable). It comes with the desk URL.
2. Install the CLI. It registers itself with Claude Code and Codex when they are present:

   ```
   curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh
   talos login <token> --url <desk url>
   ```

   Claude Code users can also take the plugin route: `/plugin marketplace add pubky/talos-cli`,
   then `/plugin install talos`. The plugin's MCP server runs `talos mcp`, so step 2 is still
   needed once for the binary.

3. Check: `talos doctor`. It reports the config file, the desk URL, the token, whether the desk
   answers, whether the token is valid, whether the skill is installed, whether the MCP server is
   registered and whether this client is current, with the fix for anything that failed.

## The verbs

Read verbs are free and take seconds. Write verbs change something, so they print exactly what
they would do and exit 5 until you pass `--yes`. Agent verbs spend one of Talos's turns and are
budgeted.

| tier | verb | what it does |
|---|---|---|
| read | `find "<words>"` | search Slack, Meet transcripts, Drive, GitHub, pubky.app |
| read | `open <slack link>` | the whole thread behind a hit |
| read | `skill` | the capability sheet the desk serves |
| read | `skills [<name>]` | the knowledge the team wrote down, readable in full |
| read | `whosout [--weeks N]` | who is on holiday |
| read | `status` | Talos's own health |
| read | `who <name>` | team, GitHub login, Slack id |
| read | `inbox [--all]` | what you asked the desk for lately |
| read | `review status <pr>` | did Talos review it, and if not why |
| read | `jobs`, `result <id> [--wait]`, `stop <id>` | your delegated runs |
| read | `doc read <id>`, `meet list` | a doc back as markdown, calls on record |
| write | `review <pr>` | ask Talos to review a PR |
| write | `issue <owner/repo> "<title>"` | file an issue, signed with your handle |
| write | `doc create --title T --md f` | markdown into a formatted Google Doc |
| write | `meet book ...` | book a call; the preview warns who is on holiday |
| write | `remember "<fact>"` | one durable fact, as a PR a human merges |
| agent | `ask "<question>"` | one Talos turn, 30 per person per day |
| agent | `delegate "<task>" [--key K]` | a run id at once, 5 per day |

`talos <verb> --help` prints the usage, the tier and an example. Global flags: `--json` (the
desk's JSON, documented per verb), `--yes`, `--quiet`, `--url`.

## Exit codes

| code | meaning |
|---|---|
| 0 | ok |
| 1 | error (the message says what, and what to do) |
| 2 | usage; the usage line for that verb comes with it |
| 3 | over budget; the reset time comes with it |
| 4 | not logged in, or the token was revoked |
| 5 | a write verb without `--yes`; the preview is on stdout |
| 6 | not found: an unknown skill, run or PR, or a verb this desk does not have yet |
| 7 | refused by a Talos rule; the rule is quoted |

The result goes to stdout, progress and hints to stderr, so `talos find x > hits.txt` is clean.

## Using it from an agent

The skill file tells Claude Code and Codex when to reach for Talos without being asked: `find`
for any "where did we discuss", "did anyone report", "who owns", "what did the call conclude";
`skills` for what the team already wrote down; `ask` only when the answer needs Talos's memory or
judgement; `review` after opening a PR. The same verbs are MCP tools (`talos_find`, `talos_who`,
`talos_issue`, and so on), and the readable knowledge skills are MCP resources
(`talos://skills/<name>`). A write tool without `yes: true` returns the preview instead of acting.

## Details

- `talos ask --thread <name>` continues a conversation; every answer prints its thread name.
- `talos delegate --key <k>` is idempotent: a retry with the same key returns the same run.
- The token lives in `~/.config/talos/config.json` (mode 0600); `TALOS_TOKEN` and `TALOS_URL`
  override it (CI, containers).
- Every write and every agent turn is logged with your handle and echoed to the team's ops
  channel. Do not paste secrets into an ask.
- An ask is a real Talos turn with his usual tools and guards, the same trust as mentioning him
  in Slack. If he posts or changes something on your request, he says exactly what.

## Layout

```
talos                       the CLI, single file, Python 3.8+ standard library only
install.sh                  curl | sh installer
scripts/selftest.sh         every CLI path against a stub desk, including the v0.1 fallback
plugins/talos/              Claude Code plugin: skill + MCP server config
  skills/talos/SKILL.md     a snapshot of the sheet the desk serves
.claude-plugin/marketplace.json
```

The desk serves the sheet at `GET /skill`, and `talos setup` and `talos login` refresh both skill
files from it. The copy embedded in `talos` and the one under `plugins/` are bootstrap snapshots,
for a machine that has not logged in yet.

The server side (`talos-desk`) lives in the private `pubky/talos-agent` repo.
