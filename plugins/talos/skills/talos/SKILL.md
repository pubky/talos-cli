---
name: talos
description: "Talos is the pubky team's agent. Use it to search team history (Slack, Meet transcripts, Drive, GitHub, pubky.app), to ask what only Talos knows, and to request PR reviews. Trigger on: where did we discuss, did anyone report, who owns, what did the call conclude, who is out, ask Talos, get a review."
---

# Talos from the terminal

`talos` is on PATH once installed (`talos --version`). Same three verbs as MCP tools
(`talos_find`, `talos_ask`, `talos_review`) if the MCP server is registered; use whichever is
available, never both for the same question.

## find: any lookup, first

```
talos find "nexus watcher lag"                      # every source, last 30 days
talos find "release checklist" --in drive,meet      # sources: slack,meet,drive,github,code,pubky
talos find "signup token" --days 90 --from ok300    # window and author (Slack name or GitHub login)
talos find "mbx" --json                             # for scripting
```

Seconds, no model, no budget. Results carry date, who, where, a snippet and a link. Quote the
link when you use a hit. When the user asks "where did we decide X", "did anyone file Y", "who
owns Z", "what did the call about W conclude", "is there a doc on V": run `talos find` before
answering from memory.

## ask: what only Talos knows

```
talos ask "why did settings leave the pubky-app spec, and who decided?"
talos ask --thread t1 "and what replaced it?"       # follow-up, same conversation
```

One Talos turn: 30 to 180 seconds, a budget of 30 per person per day. Use it when the answer
needs Talos's memory, cross-repo context, who is out (HiBob), Sentry, CI history, or a
judgement from the team's side. Do not use it for lookups (`find` does that) or to make Talos
do work you can do yourself. One ask per question; on `over budget` stop and tell the user.
Every ask is logged with your handle and shows up in the team's ops channel.

## review: after opening a PR in a pubky repo

```
talos review https://github.com/pubky/pubky-nexus/pull/123
```

Returns at once; the review lands on the PR within minutes. One review per PR head; for a
second look, mention @talosmachina on the PR.

## Rules

- Never paste secrets, tokens or private keys into an ask.
- Exit 3 means over budget, 4 means the token is missing or revoked (`talos login <token>`).
- `talos whoami` shows the handle and the asks left today.
