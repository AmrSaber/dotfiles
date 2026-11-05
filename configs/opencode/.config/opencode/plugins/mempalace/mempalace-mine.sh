#!/bin/sh
# Mines one organic-facts directory in its own short-lived process, so the palace lock is
# held only while mining runs. The MemPalace MCP mine tool holds that lock until its server
# exits, which makes every later sweep fail. Spawned by runMineScript() in mining.ts.
#   MP_LOCK MP_DIRTY MP_SESSIONS MP_LOG MP_WING, optional MP_WAIT and MP_RETRY_BASE (seconds);
#   the directory is the first argument.

set -u

# Share the sweeper's lock: its repair check is only safe while no writer is mid-flush.
exec 9>"$MP_LOCK"
flock -w "${MP_WAIT:-60}" 9 || { echo "Another sweep or mine holds the lock after ${MP_WAIT:-60}s." >&2; exit 75; }

# The palace lock fails fast while another writer holds it, so retry briefly.
attempt=1
while :; do
  out=$(mempalace mine "$1" --mode projects --wing "$MP_WING" 2>&1)
  code=$?
  [ "$code" -ne 0 ] && [ "$attempt" -lt 5 ] && printf '%s' "$out" | grep -q 'is held by' || break
  sleep $((attempt * ${MP_RETRY_BASE:-3}))
  attempt=$((attempt + 1))
done

# Captures that lost the lock race while this ran left the dirty marker and no worker; sweep them now.
while [ -e "$MP_DIRTY" ]; do
  rm -f "$MP_DIRTY"
  mempalace sweep "$MP_SESSIONS" >>"$MP_LOG" 2>&1
done

if [ "$code" -eq 0 ]; then
  printf '%s\n' "$out"
else
  printf '%s\nmempalace mine exited %s\n' "$out" "$code" >&2
fi
exit "$code"
