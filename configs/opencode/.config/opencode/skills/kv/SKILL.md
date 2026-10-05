---
name: kv
description: Use the `kv` CLI to store, retrieve, and manage key-value data (with TTL, encryption, hidden flags, history, and multiple DBs) for the user or for sharing state between tools and sessions.
---

## What `kv` is
A local CLI key-value store. Data lives under `~/.local/share/kv`, config at `~/.config/kv.yaml`. Default DB is `default`; switch with the global `--db <name>` flag. Run `kv info` to see paths, current DB, and registered DBs; `kv --version` for the version.

## Core mental model
- Keys are flat strings. Many commands accept either a single key, a list of keys, or a prefix (via `--prefix`).
- Values can be plain, **hidden** (display-only redaction in `list`/`history`, still readable via `get`), or **locked** (real AES-256-GCM encryption — needs `--password` to read).
- Every change is versioned; the `history` group lets you list, revert, prune, or interactively pick previous values.
- Multiple DBs exist. Cross-DB addressing uses the full form `key@db`. The shorthand `@db` is **only** valid as the **second argument** of `copy` and `move`, meaning "same key name in another DB". Outside that single position, always use the full `key@db` form.

## Command map (high-level)
- **Key-Value**: `get`, `set`, `list` (alias `ls`), `delete` (aliases `del`/`rm`), `copy`, `move` (aliases `mv`/`rename`)
- **TTL**: `expire` (aliases `ex`/`exp`), `ttl`
- **Security**: `hide`/`show`, `lock`/`unlock`
- **DB**: `db list`, `db backup`, `db restore`, `db delete`, `db set name`, `db set directory`
- **History**: `history list`, `history prune`, `history revert`, `history select` (group alias `h`)
- **Misc**: `info`, `completion`, `help`

## Common examples
```sh
# Read a value (use in scripts)
kv get api-key

# Write from stdin
some-cmd | kv set my-key

# Write with TTL
kv set session "abc" --expires-after 1h

# List a namespace
kv ls slack

# Encrypted write/read
kv set token "xyz" --password=hunter2
kv get token --password=hunter2

# Cross-DB copy keeping the same key name
# `@telegram` shorthand only works here because it's the second arg of copy/move.
kv copy mykey@default @telegram

# Switch DB for a single command
kv --db telegram ls

# Inspect environment / list registered DBs
kv info
kv db ls
```

## Gotchas
- `lock` / `unlock` only rewrite the **latest** history entry. Older plaintext entries persist until you run `kv history prune`.
- `delete` is soft by default (key recoverable from history, visible via `list --deleted`). Use `--prune` to permanently drop history too.
- Cross-DB `copy`/`move` are **not transactional** — avoid concurrent ops on the same keys; on crash, a moved key may exist in both DBs.
- `db` subcommands are **not thread-safe** — the caller must serialize them.
- `set` reads from stdin when no value is passed. Convenient, but easy to hang a shell if you forget you didn't pipe anything.

## Active development — verify before using
The tool changes frequently; commands and flags may be added, renamed, or have their behaviour tweaked between versions. Treat this skill as orientation, not as a spec.

- Before relying on a specific flag or subcommand, run `kv --help`, `kv <command> --help`, or `kv <group> <subcommand> --help` to confirm current syntax.
- If the user requests something not covered by the examples above, do **not** assume it's unsupported — check the relevant `--help` first.
- `kv --version` is useful when reporting bugs or comparing behaviour against docs the user references.

## When to use me
- When the user asks to read/write/list/delete/encrypt/expire/version a value via `kv`.
- When other skills or tooling reference `kv:`-style keys for credentials or shared state — `kv get <key>` (optionally with `--db`) is how to read them.
- **Not** for general filesystem persistence in project code; `kv` is the user's personal store.
