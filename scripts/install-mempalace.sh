#!/usr/bin/env bash
# Install and bootstrap MemPalace for the opencode plugin. Idempotent (upgrades in
# place). Installs MemPalace only — not base tooling, the opencode config, or plugin
# deps. The plugin + MCP config are stowed separately (from machine-config).
set -euo pipefail

# Must match the embedder the plugin assumes, else it warns on every sweep.
EMBEDDER_MODEL=minilm

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
require() { command -v "$1" >/dev/null 2>&1 || die "missing '$1' — $2"; }

require uv      "install base tooling first"
require sqlite3 "needed by the sweeper (sqlite)"
require flock   "needed by the sweeper (flock)"
require setsid  "needed by the sweeper (util-linux)"

uv tool install --force mempalace
command -v mempalace >/dev/null 2>&1 || die "mempalace not on PATH — is ~/.local/bin on PATH?"

# Also bootstraps the palace if absent.
mempalace palace set-embedder --model "$EMBEDDER_MODEL"
