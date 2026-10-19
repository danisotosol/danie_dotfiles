#!/usr/bin/env python3
"""Data feed for MacShell's "claude" bar widget. Prints one JSON object on stdout.

- Plan limits (5-hour session and 7-day window) and the account email: read from the
  cache file that claude/statusline.sh writes from the `rate_limits` block Claude Code
  passes to its status line. Fresh only while some Claude Code session is running.
- Tokens used today (local midnight onwards), per model: summed from the session
  transcripts under ~/.claude/projects (subagent transcripts included). Claude Code
  logs one line per content block with the same usage, so lines are deduplicated by
  (message.id, requestId).
"""
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path

PROJECTS = Path.home() / ".claude" / "projects"
CACHE = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache") / "claude-usage.json"


def plan_limits():
    try:
        return json.loads(CACHE.read_text())
    except (OSError, ValueError):
        return {}


def pretty_model(model_id):
    # claude-opus-5-5 -> ("Opus 5.5", "opus"), claude-haiku-4-5-20251001 -> ("Haiku 4.5", "haiku")
    m = re.fullmatch(r"claude-([a-z]+)-(\d+)(?:-(\d{1,2}))?(?:-\d{8})?", model_id)
    if not m:
        return model_id, ""
    return m[1].title() + " " + m[2] + ("." + m[3] if m[3] else ""), m[1]


def tokens_today():
    midnight = datetime.now().astimezone().replace(hour=0, minute=0, second=0, microsecond=0)
    # transcript timestamps are UTC ISO-8601 ("2026-10-19T12:17:25.069Z"), so a string compare works
    cutoff = midnight.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")
    since = midnight.timestamp()
    seen = set()
    models = {}
    for path in PROJECTS.rglob("*.jsonl"):
        try:
            if path.stat().st_mtime < since:
                continue
            with path.open("rb") as f:
                for line in f:
                    if b'"usage"' not in line:
                        continue
                    try:
                        rec = json.loads(line)
                    except ValueError:
                        continue
                    msg = rec.get("message")
                    if not isinstance(msg, dict) or not isinstance(msg.get("usage"), dict):
                        continue
                    if rec.get("timestamp", "") < cutoff or msg.get("model", "<synthetic>") == "<synthetic>":
                        continue
                    key = (msg.get("id"), rec.get("requestId"))
                    if None not in key:
                        if key in seen:
                            continue
                        seen.add(key)
                    u = msg["usage"]
                    row = models.setdefault(msg["model"], {"input": 0, "output": 0, "cache_write": 0, "cache_read": 0})
                    row["input"] += u.get("input_tokens") or 0
                    row["output"] += u.get("output_tokens") or 0
                    row["cache_write"] += u.get("cache_creation_input_tokens") or 0
                    row["cache_read"] += u.get("cache_read_input_tokens") or 0
        except OSError:
            continue
    rows = []
    for k, v in models.items():
        name, family = pretty_model(k)
        rows.append({"model": name, "family": family, "total": sum(v.values()), **v})
    rows.sort(key=lambda r: r["total"], reverse=True)
    return {"models": rows, "total": sum(r["total"] for r in rows)}


def main():
    limits = plan_limits()
    print(json.dumps({
        "five_hour": limits.get("five_hour"),
        "seven_day": limits.get("seven_day"),
        "limits_updated_at": limits.get("updated_at"),
        "email": limits.get("email") or None,
        "today": tokens_today(),
    }, separators=(",", ":")))


if __name__ == "__main__":
    main()
