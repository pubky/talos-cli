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
that to prose. A sheet is installed only when it is at most 64 KB and starts with
`# Talos from the terminal`, and every line has one of a few shapes: a heading, a `- ` item or a
paragraph line, none of them indented and none opening a quote, an HTML block or a nested list,
or a bare ```` ``` ```` fence. A line inside a fence is `talos` followed by letters, digits, spaces,
double quotes and `#,./:?_~@=+-`, with its quotes balanced. That set has no `;`, `&`, `|`, `$`,
backtick, backslash, redirection or single quote, so a fenced line pasted into a shell runs `talos`
and nothing else. A sheet that fails any of this is dropped and the copy built into the client is
kept, with a line on stderr saying so; `talos skill` applies the same check before it prints. The
YAML frontmatter is always the client's own, never the desk's.

So a compromised desk can still change the wording of the advice your agent reads, and a sentence
or an inline code span can still ask it to run something. What it cannot do is hand your agent a
code block holding a shell command, the form an agent copies and runs as is.

**The desk, for the terminal.** Everything a verb prints is stripped of control characters
first (`\n` and `\t` survive), and of the bidi overrides and zero-width marks that make a line
display differently from its bytes. Text from `find`, `open` and `ask` is Slack messages, PR
titles and doc contents, so it is written by people well outside the team, including anyone who
can open a PR on a public pubky repo. Without the strip, that text can clear the screen, retitle
the window, reorder a line, or use a carriage return to hide what a line really says.

**The desk, for MCP.** `talos mcp` is a stdio proxy: it reads one JSON-RPC request from the
agent, posts it to the desk, and writes back exactly one reply whose `id` matches the request. A
response body with a second frame in it, an id the agent did not ask about (or one of another
type), a request of the desk's own, NaN, or more than 8 MB is dropped and reported as an error.
So is a body cut off halfway: that request fails and the proxy keeps serving. Without that check,
a desk could answer a `tools/list` with an extra frame the agent reads as a tool result. A line
from the agent that is not one JSON object with a string or integer id (a batch, a null id,
broken JSON) is answered with an error and never forwarded.

**The pointer file, to move the desk and nothing else.** `desk-url.txt` in this repo names where the
desk lives, so moving it is one commit. Three things bound what that commit can do.

It may only name a host under `pubky.app` over https, or a loopback address for whoever is testing
a desk of their own. The allowlist is in the client you installed and checksummed, so changing it
takes a release, not a commit to one line. The host comes from `urllib.parse.urlsplit`, so
`https://talos-desk.pubky.app@evil.example/` is `evil.example` here as it is to the HTTP stack.

A desk at a new address starts with no credentials. When the pointer moves the desk, the client
drops the stored token, writes the new address, prints one line saying where the desk went, and
stops: `talos login` has to run again, and it is that second run that decides to hand the new
address a GitHub device token. Neither token ever follows an address the client did not already
have.

It is read by `talos login` and `talos doctor` only, and only when the stored desk does not answer
`/health`. No other verb talks to this repo at run time.

`--url` and `TALOS_URL` are not checked this way. Those are your own choice, made on your own
command line, and `--url` applies to whatever verb you pass it to.

**Nothing is read without an end.** Every response the client reads has a cap: 1 MB for a JSON
body from the desk or from GitHub, 64 KB for the capability sheet, 8 MB for an MCP reply, 1 MB per
line and 8 MB in total for a streamed `ask`, 4 MB for a release download. Over the cap the verb
stops with one line. A desk that answers a `find` with 200 MB costs the client one error message.
The same 1 MB holds for what goes the other way: `--body-file`, `--md` and stdin are read no
further than that, so a device or an endless pipe stops with one line too.

## How an install is pinned

A release is a git tag, `v0.x.y`. `install.sh` carries two lines that `scripts/release.sh` writes:
the version and the sha256 of that version's `talos`. It downloads `talos` from
`raw.githubusercontent.com/pubky/talos-cli/v0.x.y/talos`, checks the checksum, and on a mismatch
prints both digests and installs nothing. Nothing unverified is executed, and nothing unverified is
moved into place: the download goes to a `mktemp` file in the target directory, private and
unguessable, so a second installer running at the same time cannot decide what the first one
installs.

The file it replaces is kept as `talos.prev`, so a release that misbehaves is one `talos rollback`
(or one `mv`) away from the previous one.

`talos update` is the same flow from inside the CLI: it reads the version and checksum from
`install.sh` on `main`, downloads that tag's `talos`, verifies it, and swaps it in by rename.

## Accepted risks

**`main/install.sh` is the manifest.** The install line in the README fetches `install.sh` from
`main`, so whoever can write to `main` can point a new reader at a different release. That is the
same power as writing the client itself, and it is what the tag and checksum cannot remove: a
checksum can only bind a payload to a manifest, not tell you the manifest is honest. Two things
narrow it. A reader who wants an end to end pin takes `install.sh` from a tag and compares the
checksum the README publishes, both of which are immutable once pushed. And an installed client
never re-reads `main` on its own: only `talos update`, which the person runs.

**Prose in the served sheet.** See above: the desk writes instructions your agent reads. The
structural checks stop a code block that holds anything but `talos` lines; they do not stop a
sentence.

**`talos setup` edits harness config.** It appends `[mcp_servers.talos]` to `~/.codex/config.toml`,
adds a `talos` key to the JSON configs, writes a marked block into the rules files that harnesses
read, and writes each harness's skill file. It backs every one of those up before the first change
(`<file>.bak-talos`, then `~/.config/talos/backups/<file>.<timestamp>`), writes by rename so an
interrupted run leaves no half file, and only ever replaces its own block or key. It does not read
what else is in those files.

One file is the exception, on purpose: `~/.claude.json`. Claude Code's own `claude mcp add -s user`
makes that edit, not this client, and that file holds far more than MCP servers, so a copy of it
taken at install time is a worse thing to restore than the edit is to undo. Undo it with
`claude mcp remove -s user talos`.

**The token on a command line.** `talos login` with no argument asks for the token at a prompt
(or reads one line of stdin when something pipes it in), so nothing lands in argv or the shell
history. `talos login <token>` still works for scripts that already hold one, and that form is the
accepted risk: an argument is readable in `/proc/<pid>/cmdline` by anyone on the machine.

**The desk's minimum client.** The desk sends `X-Talos-Min-Client`. Below it every verb stops with
exit 1 and the line to run `talos update`, on the MCP path too. A minimum the client cannot parse
as a version is reported on stderr and otherwise ignored: a desk that says something unreadable
should not be able to stop every client on the team.

**A local user on the same machine.** The config file is `0600` and its directory `0700`, so
another account cannot read the token. `~/.local/bin` keeps whatever mode you gave it; what the
installer guarantees there is that its own download is private and unguessable until it is
verified. Nothing defends against an attacker who is already running as you.

## Reporting

Something here that looks wrong is a PR against `pubky/talos-cli`, or a word to @SHAcollision.
Do not open a public issue with a working token in it.
