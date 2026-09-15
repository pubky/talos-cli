# Security

What the `talos` client trusts, what it refuses to trust, and what is left open on purpose.

The desk side of this (tokens, budgets, the audit log, what the server refuses) is documented in
the `talos-desk` skill in `pubky/talos-agent`.

## What the client holds

| thing | where | mode |
|---|---|---|
| your desk token | `$XDG_CONFIG_HOME/talos/config.json`, default `~/.config/talos/config.json` | dir `0700`, file `0600` |
| the desk URL | the same file | |
| the capability sheet | one file per coding harness, see the table in the README | |

The token is a bearer token for one person. Anyone who reads that file can act as you: file
issues, book calls, spend your agent turns. Rotate it by running `talos login` again, which makes
the previous one stop working. `TALOS_TOKEN` in the environment overrides the file, which is how
CI or a container gets one without writing it to disk.

The GitHub token from `talos login` is never written anywhere. It goes to the desk once, in
exchange for a desk token, and is dropped.

## Who the client trusts

**The desk, for instructions.** `talos setup` and `talos login` fetch `GET /skill` and install it
where every coding harness on the machine reads it as instructions. That is the point of the
desk, and it means whoever controls the desk can tell your agent what to do. The client narrows
that to prose: a sheet is installed only when it is at most 64 KB, starts with
`# Talos from the terminal`, and has nothing but `talos ...` command lines inside its fenced code
blocks. A sheet that fails any of those is dropped and the copy built into the client is kept,
with a line on stderr saying so. The YAML frontmatter is always the client's own, never the
desk's.

So a compromised desk can still change the wording of the advice your agent reads. It cannot
hand your agent a shell command, a URL to fetch, or a payload, which is what turns one
compromised service into code running on every teammate's laptop.

**The desk, for the terminal.** Everything a verb prints is stripped of control characters
first (`\n` and `\t` survive). Text from `find`, `open` and `ask` is Slack messages, PR titles and
doc contents, so it is written by people well outside the team, including anyone who can open a
PR on a public pubky repo. Without the strip, that text can clear the screen, retitle the window,
or use a carriage return to hide what a line really says.

**The desk, for MCP.** `talos mcp` is a stdio proxy: it reads one JSON-RPC request from the
agent, posts it to the desk, and writes back exactly one reply whose `id` matches the request. A
response body with a second frame in it, or with an id the agent did not ask about, is dropped
and reported as an error. Without that check, a desk could answer a `tools/list` with an extra
frame the agent reads as a tool result.

**The pointer file, only to move the desk to https.** `desk-url.txt` in this repo names where the
desk lives, so moving it is one commit. The client follows that line only when it is an `https://`
URL (or a loopback address, for whoever is testing a desk of their own). A line naming a plain
`http://` desk is ignored and the stored address is kept, because a URL that the client both
trusts and sends your token to must not be readable in transit.

`--url` and `TALOS_URL` are not checked this way. Those are your own choice, made on your own
command line.

## Accepted risks

**`curl | sh` from raw.githubusercontent.com.** The install line fetches `install.sh` and runs it,
and `install.sh` fetches `talos` and runs `talos setup`. Both come from `main` of this repo over
TLS with no integrity check of their own. What this buys an attacker requires write access to
`main` (in which case the next `talos setup` is theirs anyway) or a forged certificate for
raw.githubusercontent.com. What it costs to close: pin a commit SHA in the install line so a
later force-push to `main` cannot change what a reader of the README installs:

```
curl -fsSL https://raw.githubusercontent.com/pubky/talos-cli/<sha>/install.sh | sh
```

Today the README carries the `main` line, so a person following it gets whatever `main` holds.
Anyone who wants the stronger guarantee pins the SHA by hand.

**Prose in the served sheet.** See above: the desk writes instructions your agent reads. The
structural checks stop a command block; they do not stop a sentence.

**`talos setup` edits harness config.** It appends `[mcp_servers.talos]` to `~/.codex/config.toml`,
adds a `talos` key to the JSON configs, and writes a marked block into the rules files that
harnesses read. It backs each file up once (`<file>.bak-talos`) before the first change and only
ever replaces its own block or key. It does not read what else is in those files.

**The token in shell history.** `talos login <token>` puts a bearer token on a command line.
Org members use `talos login` with no argument and never see a token. Someone outside the org gets
one by Slack DM and pastes it once.

**A local user on the same machine.** The config file is `0600` and its directory `0700`, so
another account cannot read the token. Nothing defends against an attacker who is already running
as you.

## Reporting

Something here that looks wrong is a PR against `pubky/talos-cli`, or a word to @SHAcollision.
Do not open a public issue with a working token in it.
