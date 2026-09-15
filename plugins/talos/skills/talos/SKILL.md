---
name: talos
description: "Talos is the pubky team's agent. Use it to search team history (Slack, Meet transcripts, Drive, GitHub, pubky.app), to read what the team wrote down, to ask what only Talos knows, to file issues and docs, and to request PR reviews. Trigger on: where did we discuss, did anyone report, who owns, what did the call conclude, who is out, ask Talos, get a review, file an issue."
---

# Talos from the terminal

This page is a snapshot of the sheet the desk serves; `talos setup` and
`talos login` replace it with the live one.

Rule of thumb: `talos find` first, it is free and instant. Then `talos skills` for what the team already wrote down. `talos ask` only when the answer needs Talos's own memory or judgement, and `talos delegate` when the job takes minutes and you do not want to wait.

Not logged in? Run `talos login`, open the GitHub device prompt it prints and enter the code. The desk checks you are in the pubky org and gives you a token of its own; logging in again rotates that token and the old one stops working. Someone outside the org runs `talos login --token` and pastes the token @SHAcollision sent them; the token is never typed on a command line.

## Read verbs: free, seconds, no model

`talos find "<words>" [--in slack,meet,drive,github,code,pubky] [--days N] [--from who] [--limit N]`

Search Slack, Meet transcripts, Drive, GitHub and pubky.app at once. Use it for any lookup: where did we discuss X, did anyone report Y, who owns Z, what did the call conclude.

```
talos find "nexus watcher lag" --days 90
```

`talos open <slack link | C0123ABC:1712345678.123456>`

The whole Slack thread behind a link, in order, full text. Use it after a find hit whose snippet is not enough.

```
talos open https://synonym.slack.com/archives/C0BUJLZCWNB/p1712345678123456
```

`talos skill`

The capability sheet the desk serves, as markdown. Use it to refresh what the desk can do without asking Talos.

```
talos skill
```

`talos skills [<name>]`

List the knowledge skills you can read, or print one. Use it before asking Talos something the team already wrote down.

```
talos skills pubky-architecture
```

`talos whosout [--weeks N]`

Who is on holiday, from the team calendars. Use it before booking a call or assigning work.

```
talos whosout --weeks 4
```

`talos status`

Talos's own health: units, heartbeats, budgets, crons. Use it when Talos looks stuck or a scheduled job did not run.

```
talos status
```

`talos who <name | github login | slack id>`

A teammate's team, GitHub login and Slack id. Use it to turn a name into a GitHub login before mentioning them.

```
talos who ben
```

`talos inbox [--all] [--limit N]`

What you asked the desk for lately and how it went. Use it to find a run id, a filed issue or a doc link again.

```
talos inbox --limit 5
```

`talos review status <pr-url | owner/repo#num>`

Whether Talos is a requested reviewer, whether he reviewed, and if not why. Use it after `talos review` when no review showed up.

```
talos review status pubky/pubky-nexus#123
```

`talos jobs`

Your delegated runs and their state. Use it to see what you started and whether it finished.

```
talos jobs
```

`talos result <run-id> [--wait]`

The output of a delegated run. Use it when `talos jobs` says a run completed, or to block until it does.

```
talos result 8f2c1a --wait
```

`talos stop <run-id>`

Stop a delegated run you started. Use it when you delegated the wrong thing.

```
talos stop 8f2c1a
```

`talos doc read <docId>`

A Google Doc back as markdown. Use it to quote or diff a doc Talos wrote.

```
talos doc read 1AbC_defGH
```

`talos meet list`

Calls Talos has on record and their state. Use it to find an event id or check a booking went through.

```
talos meet list
```

## Write verbs: they change something, so they need --yes

`talos review <pr-url | owner/repo#num> [--yes]`

Ask Talos to review a PR; the review lands on GitHub within minutes. Use it right after opening a PR in a pubky repo.

```
talos review pubky/pubky-nexus#123 --yes
```

`talos issue <owner/repo> "<title>" [--body text | --body-file f] [--from <slack link>] [--label l] [--force] [--yes]`

File a GitHub issue in a pubky or synonymdev repo, signed with your handle. Use it when a Slack thread or a find hit turned into real work.

```
talos issue pubky/pubky-nexus "watcher lag after restart" --body-file bug.md --yes
```

`talos doc create --title "<title>" (--md <file> | stdin) [--share synonym.to | a@x,b@y] [--yes]`

Turn markdown into a formatted Google Doc and share it. Use it for anything longer than a Slack message that the team should keep.

```
talos doc create --title "Nexus watcher postmortem" --md postmortem.md --yes
```

`talos meet book --title T --start LOCAL --end LOCAL --tz Zone --with "Name,Name" [--yes]`

Book a Google Meet call and bring the summary back to Slack. Use it when a thread needs a call; the preview warns if someone is on holiday.

```
talos meet book --title "nexus sync" --start 2026-09-20T14:00 --end 2026-09-20T14:30 --tz Europe/Berlin --with "Ben Kaufman,tomos" --yes
```

`talos remember "<fact>" [--yes]`

Add one durable fact to Talos's environment skill, as a PR a human merges. Use it when Talos got something wrong that will come up again.

```
talos remember "the canonical nexus checkout is ~/pubky/pubky-nexus" --yes
```

## Agent verbs: a real Talos turn, budgeted

`talos ask "<question>" [--thread name] [--skill name]`

One Talos turn: his memory, his tools, his judgement. Use it only when find and the knowledge skills cannot answer it.

```
talos ask "why did settings leave the pubky-app spec, and who decided?"
```

`talos delegate "<task>" [--key K] [--skill name]`

Hand Talos a long job and get a run id back at once. Use it for work that takes minutes: a sweep, a comparison, a report.

```
talos delegate "compare the nexus watcher lag before and after #123" --key lag-1
```

## Knowledge you can read

`talos skills` lists them, `talos skills <name>` prints one. Read one before asking Talos.

- `pubky-architecture`: How pkarr, homeserver, nexus and pubky-app fit together.
- `pubky-nexus-codebase`: Internals of the pubky-nexus server code.
- `pubky-nexus-test-suite`: Run the pubky-nexus test suites and Docker stack.
- `pubky-passport`: Work on pubky/passport: onboarding, /authorize, Homegate.
- `pubky-vibes`: Work on pubky/vibes, vibe PRs and vibe SSO.
- `synonym-website`: Edit synonym.to content: team cards, keys, links.
- `pubky-feedback-triage`: Triage pubky-feedback posts into pubky-app issues.
- `ci-performance`: Evaluate and pilot CI speedups against real numbers.
- `talos-docs`: Google Docs written from Markdown with talos-doc, formatted properly every time.
- `talos-meet-scheduling`: Book Meet calls for teammates; summaries come back alone.
- `talos-whosout`: Who is on time off, from the calendar events HiBob writes.
- `pr-review`: Review a PR with at most six verified inline findings.
- `talos-find`: One search across Slack, Drive, transcripts, GitHub, pubky.
- `stacked-pull-requests`: Use when reviewing or extending stacked PR chains.
- `flaky-test-triage`: Use when CI is green yet a test failed earlier, or flakes.

## Don'ts

- Never paste secrets, tokens or private keys into an ask or a delegate.
- One ask per question. On `over budget` (exit 3) stop and tell the user.
- Quote the link of any hit you use; do not paraphrase a thread from memory.
- Write verbs do nothing without `--yes`. Read the preview before passing it.
- The desk does not move or cancel other people's calls, and files issues in pubky and synonymdev only.

Exit codes: 0 ok, 1 error, 2 usage, 3 over budget, 4 not logged in, 5 needs --yes, 6 not found, 7 refused by a Talos rule.

## Running it from this plugin

The CLI ships inside the plugin, so there is nothing to install:

```
python3 ${CLAUDE_PLUGIN_ROOT}/bin/talos find "nexus watcher lag"
```

If any verb answers `not logged in` (exit 4), run `python3 ${CLAUDE_PLUGIN_ROOT}/bin/talos login`,
show the user the "Open ... and enter code ..." line it prints, and wait: they open that page and
type the code. No token and no desk URL to ask for. On a machine that has `talos` on the PATH the
plain `talos` command does the same thing.
