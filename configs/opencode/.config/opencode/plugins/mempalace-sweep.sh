#!/bin/sh
# Detached coalescing sweeper + self-heal, spawned by launchDetachedSweep() in
# mempalace.ts. Inputs arrive as MP_* env vars so nothing untrusted is ever
# concatenated into a shell string.
#   MP_SESSIONS MP_LOCK MP_DIRTY MP_LOG MP_CHROMA MP_PALACE MP_ERROR_LOG

set -u

# Collapse the swarm of concurrent idle-launches to one running sweeper; losers
# bail. Held for process life, freed on death — no heartbeat/crash-detection.
exec 9>"$MP_LOCK"
flock -n 9 || exit 0

# Cap the append-only log so it can't grow unbounded. Safe to rewrite here: we
# hold the lock, so no concurrent writer. Keep the tail (recent runs matter most).
if [ -f "$MP_LOG" ]; then
  tail -n 500 "$MP_LOG" >"$MP_LOG.tmp" 2>/dev/null && mv "$MP_LOG.tmp" "$MP_LOG"
fi

# A reboot/OOM/kill mid-flush strands rows in chroma's embeddings_queue, leaving
# the vector segment far behind metadata; ChromaDB then DEADLOCKS reconciling the
# backlog on first read, hanging every sweep ~90s. sqlite is the durable ground
# truth, so rebuilding from it recovers with zero data loss. Chroma always has two
# segments (metadata + vector) whose seq_id normally differ by a handful (benign
# flush lag), so we rebuild only when the vector segment falls far enough behind to
# mean a real stranded backlog. The check is safe here only because the lock
# guarantees no concurrent mid-flush writer.
gap=$(sqlite3 "$MP_CHROMA" "SELECT COALESCE(MAX(seq_id) - MIN(seq_id), 0) FROM max_seq_id;" 2>/dev/null)
if [ "$gap" -gt 50 ] 2>/dev/null; then
  echo "[$(date -Is)] self-heal: segments diverged (gap $gap); rebuilding from sqlite" >>"$MP_LOG"

  # --archive-existing is load-bearing, not a backup: repair reads sqlite FROM
  # the archive it renames aside. The archive is the newest palace.pre-rebuild-*.
  if mempalace repair --mode from-sqlite --archive-existing --yes >>"$MP_LOG" 2>&1; then
    # Keep backups transient — drop the archive so it can't pile up.
    # shellcheck disable=SC2012  # timestamp-suffixed names are ls-safe
    archive=$(ls -dt "$MP_PALACE".pre-rebuild-* 2>/dev/null | head -1)
    [ -n "$archive" ] && rm -rf "$archive"
    # The rebuild recreates the collection without the embedder identity, so
    # re-record it — otherwise every subsequent sweep warns about it.
    mempalace palace set-embedder --model minilm >>"$MP_LOG" 2>&1
    echo "[$(date -Is)] self-heal: rebuild succeeded; archive removed" >>"$MP_LOG"
  else
    # Restore the untouched original and halt: retrying can't fix corrupt sqlite,
    # and halting forces a human to notice rather than looping silently.
    # shellcheck disable=SC2012  # timestamp-suffixed names are ls-safe
    archive=$(ls -dt "$MP_PALACE".pre-rebuild-* 2>/dev/null | head -1)
    if [ -n "$archive" ]; then rm -rf "$MP_PALACE"; mv "$archive" "$MP_PALACE"; fi
    echo "[$(date -Is)] self-heal: rebuild FAILED; palace restored; manual intervention required (see $MP_LOG)" >"$MP_ERROR_LOG"
    tail -30 "$MP_LOG" >>"$MP_ERROR_LOG" 2>/dev/null
    echo "[$(date -Is)] self-heal: rebuild FAILED; wrote $MP_ERROR_LOG and halted sweeps" >>"$MP_LOG"
    exit 0
  fi
fi

# Loop until a full pass sees no new MP_DIRTY marker, so a capture landing as the
# sweeper settles is never dropped. sleep gives readers a window between bursts.
while :; do
  rm -f "$MP_DIRTY"
  sleep 1
  mempalace sweep "$MP_SESSIONS" >>"$MP_LOG" 2>&1
  [ -e "$MP_DIRTY" ] || break
done
