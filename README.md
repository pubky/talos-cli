# talos-cli

Talos, the pubky team's agent, from your terminal and from your coding agent (Claude Code,
Codex, anything that runs shell commands or MCP tools).

Give your agent this one line and it does the rest:

> Install the talos CLI with `curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh`, run `talos login` and complete the GitHub device prompt it prints, then `talos whoami`; from now on use talos for anything about this team (`talos` lists the verbs).

Until GitHub device login is switched on, that same line ends with a token @SHAcollision sends you
by DM: `talos login` asks for it at a prompt, you paste it there. It never goes on a command line,
where the shell history and every process listing on the machine would have it.

No URL to look up either: `talos login` prints an "Open ... and enter code ..." line, you open that
page, type the code, and the desk checks your pubky org membership and gives you a token of its own.
Logging in again rotates it, so the old one stops working.

```
talos                                   every verb, by tier
talos find "nexus watcher lag"          search Slack, Meet transcripts, Drive, GitHub and pubky.app
talos who ben                           a teammate's team, GitHub login and Slack id
talos issue pubky/pubky-nexus "bug"     file an issue (prints a preview first, needs --yes)
talos ask "why did we drop X?"          one Talos turn, with links
talos delegate "long job"               hand him a job, collect it later with `talos result`
```

## Install

```
curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/main/install.sh | sh
talos login
talos whoami
```

The installer also registers the MCP server and writes the skill for every coding harness it
finds on the machine, so your agent already knows when to use Talos. Tell it "use talos for
anything about the team" and it takes it from there.

Claude Code users can take the plugin route instead: `/plugin marketplace add pubky/talos-cli`,
then `/plugin install talos`. The plugin carries its own copy of the CLI, so there is nothing to
install; the agent runs `python3 ${CLAUDE_PLUGIN_ROOT}/bin/talos login` when it needs you to sign
in.

`talos setup` reruns the registration and refreshes the skill from the desk; `talos doctor`
checks the whole chain, lists every harness it found and says what to fix. `talos update` fetches
the current release, checks its sha256 and replaces the file it is running from, keeping the old one
as `talos.prev`; `talos rollback` puts that one back.

### What the install line pins

`install.sh` carries the version it installs and the sha256 of that version's `talos`. It downloads
`talos` from that release tag, checks the checksum, and installs nothing at all if it does not
match, so nothing unverified is ever executed or moved into place. The URL above says `main`
because `install.sh` is what does the pinning. To pin the installer too, take it from the tag:

```
curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/v0.4.0/install.sh | sh
```

talos 0.4.0 is sha256 `8dcc3bd9c2d2c9e3e70576f545632cd58bcc03b36070baae9d5d5f726bc23aab`, which is
what `sha256sum ~/.local/bin/talos` prints after the install. What the client trusts, what it
refuses from the desk, and where your token lives: [docs/security.md](docs/security.md).

### What setup writes, and where

A harness counts as present when its config directory or its binary is there, and only a present
one is touched. `talos setup --harness <name>` writes one anyway, installed or not. Claude Code
and Codex are the exception: their skill file and the Codex block go in either way, which is what
the installer did before the other harnesses existed.

| harness | MCP server | the sheet | from |
|---|---|---|---|
| Claude Code | `claude mcp add -s user talos -- talos mcp`, so `~/.claude.json` | `~/.claude/skills/talos/SKILL.md` | [mcp](https://code.claude.com/docs/en/mcp) |
| Codex | `[mcp_servers.talos]` appended to `~/.codex/config.toml` | `~/.codex/skills/talos/SKILL.md` | [mcp](https://learn.chatgpt.com/docs/extend/mcp?surface=cli) |
| Cursor | `mcpServers.talos` in `~/.cursor/mcp.json` | `~/.cursor/skills/talos/SKILL.md` | [mcp](https://cursor.com/docs/context/mcp), [skills](https://cursor.com/docs/skills) |
| Windsurf | `mcpServers.talos` in `~/.codeium/windsurf/mcp_config.json` | a marked block in `~/.codeium/windsurf/memories/global_rules.md` | [mcp](https://docs.devin.ai/desktop/cascade/mcp), [rules](https://docs.devin.ai/desktop/cascade/memories) |
| Gemini CLI | `mcpServers.talos` in `~/.gemini/settings.json` | a marked block in `~/.gemini/GEMINI.md` | [mcp](https://google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html), [context](https://geminicli.com/docs/cli/gemini-md/) |
| opencode | `mcp.talos` in `~/.config/opencode/opencode.json` | `~/.config/opencode/skills/talos/SKILL.md` | [mcp](https://opencode.ai/docs/mcp-servers/), [skills](https://opencode.ai/docs/skills/) |
| aider, anything without MCP | `talos setup --print-mcp` prints the block to paste | `talos setup --print-rules` prints the sheet | |

Cursor has no global rules file on disk (user rules live in its settings window), so the sheet
goes in as a global skill instead. Windsurf caps that file at 6000 characters and Gemini's
`GEMINI.md` is the user's own memory file, so those two get a short block that points at
`talos skill` rather than the whole sheet.

Nothing is ever overwritten: JSON files keep their own indentation and every other key, the Codex
block is appended only when it is absent, and the block in a rules file sits between
`<!-- talos:begin -->` and `<!-- talos:end -->` markers so the rest of the file is yours. Every file
setup modifies, skill files included, is copied to `<file>.bak-talos` the first time, and to
`~/.config/talos/backups/<file>.<timestamp>` after that. Running it again changes nothing.

A run that died between the two markers leaves a `talos:begin` with no `talos:end`. The next
`talos setup` replaces everything from that marker to the end of the file with a whole block, after
backing the file up, so a half write is repaired rather than doubled.

The one file setup does not back up is `~/.claude.json`: Claude Code's own `claude mcp add` makes
that edit, and `claude mcp remove -s user talos` undoes it.

Aider has no MCP support, so there it is `talos` as a plain shell command plus the sheet in a file
you point aider at, for example `aider --read ~/.claude/skills/talos/SKILL.md`.

### If you are not in the pubky GitHub org

Device login only works for org members. Ask @SHAcollision for a token, run `talos login --token`
and paste it at the prompt. Everything else is the same. Scripts and CI that already hold a token
can pass it as `talos login <token>` or in `TALOS_TOKEN`, but on a keyboard use the prompt: an
argument is in the shell history and in every process listing on the machine.

## Where the desk lives

The CLI takes the desk URL from `--url` (a global flag: every verb of that run uses it), then
`TALOS_URL`, then your stored config, then the built-in address. Moving the desk to a new address is
one commit to [`desk-url.txt`](desk-url.txt) in this repo: `talos login` and `talos doctor` read
that file when the stored desk stops answering and pick the new address up. No other verb reads it.

Two limits on what that one line can do. It may only name a host under `pubky.app`, over https, or
a loopback address for whoever is testing a desk of their own; anything else is ignored and the
stored address is kept. And a desk at a new address starts with nothing: the stored token is dropped
and `talos login` has to run again, so one commit to a public file can move where you work but
cannot forward your credentials anywhere. `TALOS_POINTER_URL` points the client at a different
pointer file, which is how the selftest drives this.

## Using it from an agent

The skill file tells your agent when to reach for Talos without being asked: `find`
for any "where did we discuss", "did anyone report", "who owns", "what did the call conclude";
`skills` for what the team already wrote down; `ask` only when the answer needs Talos's memory or
judgement; `review` after opening a PR. The same verbs are MCP tools (`talos_find`, `talos_who`,
`talos_issue`, and so on), and the readable knowledge skills are MCP resources
(`talos://skills/<name>`). A write tool without `yes: true` returns the preview instead of acting.

## Details

- `talos ask --thread <name>` continues a conversation; every answer prints its thread name.
- `talos delegate --key <k>` is idempotent: a retry with the same key returns the same run.
- The desk token lives in `~/.config/talos/config.json` (mode 0600); `TALOS_TOKEN` and `TALOS_URL`
  override it (CI, containers). The GitHub token from the device flow is never stored.
- `talos update` installs the release `install.sh` pins, checksum first, and keeps the file it
  replaced as `talos.prev`. `talos rollback` (or `mv ~/.local/bin/talos.prev ~/.local/bin/talos`)
  goes back to it.
- The desk names the oldest client it answers correctly. Below it every verb stops with one line
  saying to run `talos update`, in the terminal and as the MCP reply alike.
- Every write and every agent turn is logged with your handle and echoed to the team's ops
  channel. Do not paste secrets into an ask.
- An ask is a real Talos turn with his usual tools and guards, the same trust as mentioning him
  in Slack. If he posts or changes something on your request, he says exactly what.

## Layout

```
talos                       the CLI, single file, Python 3.8+ standard library only
install.sh                  curl | sh installer; it pins the release version and its sha256
desk-url.txt                where the desk is today, one line
docs/security.md            what the client trusts, what it refuses, what it accepts
scripts/selftest.sh         every CLI path against a stub desk, plus harness registration in a fake home
scripts/sync-plugin.sh      copy the CLI into the plugin and regenerate its skill and manifest
scripts/release.sh          bump the version, sync, pin the checksum, commit and tag
plugins/talos/              Claude Code plugin: the CLI, the skill, the MCP server config
  bin/talos                 a copy of the CLI, kept identical by sync-plugin.sh
  skills/talos/SKILL.md     a snapshot of the sheet the desk serves
.claude-plugin/marketplace.json
```

The desk serves the sheet at `GET /skill`, and `talos setup` and `talos login` refresh both skill
files from it. The copy embedded in `talos` and the one under `plugins/` are bootstrap snapshots,
for a machine that has not logged in yet.

The server side (`talos-desk`) lives in the private `pubky/talos-agent` repo.
