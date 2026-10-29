#!/bin/sh
# Claude Code status line: "<model> · ctx N% · 5h N% →HH:MM · 7d N% →M/D".
# Side job: saves the plan's rate limits (5-hour session, 7-day window) and the account's
# email to a cache file that MacShell's "claude" bar widget reads through
# macshell/claude-usage.py.
input=$(cat)
cache="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage.json"
# the account config of this session: $CLAUDE_CONFIG_DIR/.claude.json when set, else ~/.claude.json
config="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}"
config="${config:-$HOME/.claude.json}"

# rate_limits only comes with a subscription login and after the session's first API
# response, so keep the last good value when it is missing. The email is saved in the
# same write, so limits and email always belong to the same account. Write to a temp
# file and rename, so the widget never reads half a file while several sessions write.
if printf '%s' "$input" | jq -e '.rate_limits' >/dev/null 2>&1; then
  mkdir -p "${cache%/*}"
  email=$(jq -r '.oauthAccount.emailAddress // empty' "$config" 2>/dev/null)
  printf '%s' "$input" | jq -c --arg email "$email" '.rate_limits + {email: $email, updated_at: (now | floor)}' >"$cache.$$" &&
    mv -f "$cache.$$" "$cache"
fi

# resets_at is epoch seconds; the 5-hour window shows the reset time, the 7-day one the date.
printf '%s' "$input" | jq -r '
  def window($label; $fmt):
    select(.used_percentage != null)
    | "\($label) \(.used_percentage | floor)%"
      + (if .resets_at then " →\(.resets_at | strflocaltime($fmt))" else "" end);
  [
    .model.display_name,
    "ctx \(.context_window.used_percentage // 0 | floor)%",
    (.rate_limits.five_hour // empty | window("5h"; "%H:%M")),
    (.rate_limits.seven_day // empty | window("7d"; "%-m/%-d"))
  ] | join(" · ")'
