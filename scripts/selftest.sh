#!/usr/bin/env bash
# Every CLI path against a stub desk with canned answers: exit codes, output streams, previews,
# and the fallback to a desk that is still on v0.1. No network, no token, nothing installed.
#
#   scripts/selftest.sh
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$HERE/talos"
T="$(mktemp -d)"
trap 'kill ${V2:-0} ${V1:-0} 2>/dev/null; rm -rf "$T"' EXIT
P2=$((17600 + RANDOM % 400)); P1=$((18100 + RANDOM % 400))

cat > "$T/stub.py" <<'EOF'
"""A desk with canned answers. argv: <port> <v01|v02>."""
import json, sys
from http.server import BaseHTTPRequestHandler, HTTPServer
MODE = sys.argv[2]
CANNED = {
    "/v/find": {"results": {"slack": [{"date": "2026-09-01", "who": "alice", "where": "#dev",
                                       "snippet": "watcher lag", "link": "https://slack/x"}]},
                "text": "== slack\n2026-09-01  alice  #dev\n    watcher lag"},
    "/v/who": {"text": "Ben Kaufman  (nexus)  github b-kaufman  slack U02BEN"},
    "/v/whosout": {"out": [], "text": "nobody is out"},
    "/v/review": {"confirmed": False, "preview": "request a review from @talosmachina\n  pubky/x#1",
                  "text": "request a review from @talosmachina"},
    "/v/issue": {"confirmed": False, "preview": "file a GitHub issue\n  repo:   pubky/x"},
    "/v/jobs": {"jobs": [], "text": "no delegated jobs in the last 30 days"},
    "/v/stop": {"text": "stopping run abc"},
    "/find": {"results": {"slack": []}, "errors": {}},
    "/review": {"status": "queued", "url": "https://github.com/pubky/x/pull/1", "note": "on it"},
}
ERRORS = {
    "/v/skills": (404, {"error": "nope is not a readable knowledge skill", "hint": "readable: a, b", "code": "not_found"}),
    "/v/status": (409, {"error": "refused by a rule", "hint": "ask in Slack", "code": "refused"}),
    "/v/open": (429, {"error": "61 read calls in the last minute (cap 60)", "hint": "wait", "code": "over_budget"}),
    "/v/result": (400, {"error": "run_id does not look right", "hint": "talos result <run-id>", "code": "bad_args"}),
    "/v/delegate": (500, {"error": "the desk fell over", "hint": "tell @SHAcollision", "code": "error"}),
    "/v/meet_list": (401, {"error": "no or unknown token", "hint": "talos login <token>", "code": "no_token"}),
}
class H(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    def log_message(self, *a): pass
    def reply(self, code, body, ctype="application/json"):
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
        self.send_response(code); self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("X-Talos-Min-Client", "0.2.0" if MODE == "v02" else "0.1.0")
        self.end_headers(); self.wfile.write(data)
    def missing(self):
        self.reply(404, {"error": "no route", "hint": "rerun install.sh", "code": "no_such_route"})
    def do_GET(self):
        if self.path == "/health":
            return self.reply(200, {"status": "ok", "version": "0.2.0" if MODE == "v02" else "0.1.0"})
        if self.path == "/me":
            return self.reply(200, {"handle": "tester", "asks_today": 1, "asks_per_day": 30,
                                    "asks_global_today": 3, "asks_global_per_day": 200,
                                    "resets_at": "2026-09-15T00:00:00Z", "writes_today": 0, "writes_per_day": 20,
                                    "delegates_today": 0, "delegates_per_day": 5, "admin": False})
        if MODE == "v01":
            return self.missing()
        if self.path == "/skill":
            return self.reply(200, b"# Talos from the terminal\n\nthe served sheet\n", "text/markdown")
        if self.path == "/verbs":
            return self.reply(200, {"version": "0.2.0", "verbs": [{"name": "find", "tier": "read", "usage": "talos find"}]})
        self.missing()
    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        body = json.loads(self.rfile.read(n) or b"{}")
        path = self.path
        if MODE == "v01" and path.startswith("/v/"):
            return self.missing()
        if path in ("/v/ask", "/ask"):
            self.send_response(200); self.send_header("Content-Type", "text/event-stream")
            self.send_header("Connection", "close"); self.end_headers()
            self.wfile.write(b'event: run.started\ndata: {"thread":"t1"}\n\n')
            self.wfile.write(b'event: tool.started\ndata: {"tool":"talos-find"}\n\n')
            self.wfile.write(b'event: run.completed\ndata: {"answer":"the stub answer","thread":"t1","seconds":1}\n\n')
            self.close_connection = True; return
        if path in ERRORS:
            code, payload = ERRORS[path]; return self.reply(code, payload)
        if path in ("/v/review", "/v/issue") and body.get("yes"):
            return self.reply(200, {"status": "queued", "link": "https://github.com/pubky/x/pull/1",
                                    "text": "queued: https://github.com/pubky/x/pull/1"})
        if path in CANNED:
            return self.reply(200, CANNED[path])
        self.missing()
HTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
EOF

python3 "$T/stub.py" "$P2" v02 & V2=$!
python3 "$T/stub.py" "$P1" v01 & V1=$!
for _ in $(seq 40); do curl -fsS "http://127.0.0.1:$P2/health" >/dev/null 2>&1 && break; sleep 0.25; done

export XDG_CONFIG_HOME="$T/config" TALOS_TOKEN=tdk_stub TALOS_URL="http://127.0.0.1:$P2"
PASS=0; FAIL=0
t() { # t <name> <expected exit> <grep pattern> -- <args...>
  name="$1"; want="$2"; pat="$3"; shift 4
  out=$("$CLI" "$@" 2>&1); got=$?
  if [ "$got" != "$want" ] || { [ -n "$pat" ] && ! printf '%s' "$out" | grep -q -- "$pat"; }; then
    echo "FAIL $name: exit $got (want $want)"; printf '%s\n' "$out" | sed 's/^/    /'; FAIL=$((FAIL+1))
  else PASS=$((PASS+1)); fi
}

# help and discovery, no desk needed
t no-args 0 "read     free" --
t version 0 "talos 0.2.0" -- --version
t help-verb 0 "needs --yes" -- help issue
t help-flag 0 "exit codes" -- issue --help
t unknown 2 "unknown command" -- nosuchverb
t unknown-flag 2 "does not take" -- find x --bogus 1
t no-arg 2 "usage: talos who" -- who

# the happy paths
t find 0 "watcher lag" -- find watcher lag
t find-json 0 '"results"' -- find watcher --json
t who 0 b-kaufman -- who ben
t whoami 0 "1/30 asks today" -- whoami
t whoami-writes 0 "writes 0/20" -- whoami
t skill 0 "the served sheet" -- skill
t verbs 0 "talos find" -- verbs
t ask 0 "the stub answer" -- ask what is up
t ask-json 0 '"thread"' -- ask what --json
t jobs 0 "no delegated jobs" -- jobs

# one error path per exit code
t e-400 2 "does not look right" -- result abc
t e-401 4 "no or unknown token" -- meet list
t e-404 6 "not a readable" -- skills nope
t e-409 7 "refused by a rule" -- status
t e-429 3 "cap 60" -- open "C1:1712345678.1"
t e-500 1 "fell over" -- delegate a job

# previews: exit 5, preview on stdout, the hint on stderr
t preview-review 5 "add --yes to do it" -- review pubky/x#1
t preview-issue 5 "file a GitHub issue" -- issue pubky/x "a title" --body hi
t confirmed 0 "queued" -- review pubky/x#1 --yes
out=$("$CLI" review pubky/x#1 2>/dev/null); [ -n "$out" ] && ! printf '%s' "$out" | grep -q "add --yes" \
  && PASS=$((PASS+1)) || { echo "FAIL preview stdout/stderr split"; FAIL=$((FAIL+1)); }

# --quiet keeps stderr out of the way
[ -z "$("$CLI" --quiet ask hello 2>&1 >/dev/null)" ] \
  && PASS=$((PASS+1)) || { echo "FAIL --quiet still wrote to stderr"; FAIL=$((FAIL+1)); }

# not logged in, and a desk that is not there
( unset TALOS_TOKEN; unset TALOS_URL; XDG_CONFIG_HOME="$T/empty" "$CLI" find x >/dev/null 2>&1 )
[ $? = 4 ] && PASS=$((PASS+1)) || { echo "FAIL not-logged-in exit"; FAIL=$((FAIL+1)); }
( TALOS_URL="http://127.0.0.1:1" "$CLI" find x >/dev/null 2>&1 )
[ $? = 1 ] && PASS=$((PASS+1)) || { echo "FAIL unreachable-desk exit"; FAIL=$((FAIL+1)); }

# against a desk still on v0.1: find and ask fall back, a v0.2 verb says so
export TALOS_URL="http://127.0.0.1:$P1"
t legacy-find 0 '"results"' -- find watcher --json
t legacy-find-text 0 "no hits" -- find watcher
t legacy-ask 0 "the stub answer" -- ask what is up
t legacy-review-preview 5 "add --yes to do it" -- review pubky/x#1
t legacy-review-yes 0 "queued\|on it" -- review pubky/x#1 --yes
t legacy-missing 6 "does not have who yet" -- who ben
t legacy-missing-remember 6 "ask Chris to deploy v0.2" -- remember "a fact" --yes

# login writes a 0600 config and refreshes the skill from the desk
export TALOS_URL="http://127.0.0.1:$P2" HOME="$T/fakehome"
mkdir -p "$T/fakehome"
"$CLI" login tdk_stub --url "http://127.0.0.1:$P2" >/dev/null 2>&1
[ "$(stat -c %a "$T/config/talos/config.json" 2>/dev/null)" = 600 ] \
  && PASS=$((PASS+1)) || { echo "FAIL config mode"; FAIL=$((FAIL+1)); }
grep -q "the served sheet" "$T/fakehome/.claude/skills/talos/SKILL.md" 2>/dev/null \
  && PASS=$((PASS+1)) || { echo "FAIL skill not refreshed from the desk"; FAIL=$((FAIL+1)); }
grep -q "^name: talos" "$T/fakehome/.claude/skills/talos/SKILL.md" 2>/dev/null \
  && PASS=$((PASS+1)) || { echo "FAIL skill frontmatter"; FAIL=$((FAIL+1)); }

# doctor passes every check against a healthy desk once setup has run
"$CLI" setup >/dev/null 2>&1
"$CLI" doctor >/dev/null 2>&1
[ $? = 0 ] && PASS=$((PASS+1)) || { echo "FAIL doctor on a healthy desk"; "$CLI" doctor; FAIL=$((FAIL+1)); }

# the MCP proxy forwards a request and answers when logged out
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | "$CLI" mcp 2>/dev/null | grep -q '"id": *1' \
  && PASS=$((PASS+1)) || { echo "FAIL mcp proxy"; FAIL=$((FAIL+1)); }
echo '{"jsonrpc":"2.0","id":1,"method":"ping"}' | env -u TALOS_TOKEN -u TALOS_URL XDG_CONFIG_HOME="$T/empty" \
  "$CLI" mcp 2>/dev/null | grep -q "not logged in" \
  && PASS=$((PASS+1)) || { echo "FAIL mcp logged-out error"; FAIL=$((FAIL+1)); }

echo "$PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
