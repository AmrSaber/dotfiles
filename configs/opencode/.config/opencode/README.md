# MemPalace and organic facts

Two independent OpenCode plugins live here.

- `mempalace` captures conversations into MemPalace and injects the memory protocol.
- `organic-facts` injects a file-based knowledge base into the system prompt. It doesn't use MemPalace.

## Module structure

| File | Responsibility |
| --- | --- |
| `plugins/mempalace.ts` | Register the MemPalace integration and clean it up. |
| `plugins/mempalace/conversations.ts` | Capture transcripts when a turn ends, is interrupted, or fails, and before compaction; resubscribe if the event stream drops; prune old transcript files. |
| `plugins/mempalace/memory-context.ts` | Inject the memory protocol and repair alerts. |
| `plugins/mempalace/mcp-tools.ts` | Remove the locking MCP tools and the knowledge-graph tools. |
| `plugins/mempalace/mempalace-sweep.sh` | Coalesce detached sweeps and preserve repair/recovery safeguards. |
| `plugins/organic-facts.ts` | Inject the organic-facts instructions and the file catalogue. |

Implementation modules and the sweeper live under `plugins/mempalace/`. That directory has no separate entrypoint or package manifest.

## Capture conversations

Capture writes full user/assistant text to `~/.mempalace/opencode-sessions/<session-id>.jsonl`. MemPalace sweep deduplicates messages, so repeated captures add only new content. A detached, coalesced sweeper continues after session shutdown. Pruning removes old transcript files, not archived palace content.

| Environment variable | Behavior |
| --- | --- |
| `MEMPALACE_HOOKS_AUTO_SAVE` | `false`, `0`, or `no` disables capture without disabling memory guidance. |
| `MEMPALACE_SESSION_TTL_DAYS` | Defaults to 7. Set 0 to retain transcripts indefinitely. The active session is never pruned. |

The sweeper keeps its dirty-marker handoff, writer lock, bounded log, and segment-divergence repair. If repair fails, capture still writes transcripts but skips indexing. The context hook reports the halt. Capture failures remain best-effort.

The event stream is volatile. If it ends or fails, capture resubscribes with a backoff (1 second, doubling to 60 seconds) and appends the reason to `~/.mempalace/opencode-sessions/capture.log`. Plugins have no logger, and console output is dropped, so check that file when transcripts stop appearing.

## Disabled MemPalace MCP tools

The plugin removes two groups of MemPalace MCP tools.

- **Locking tools.** The MemPalace MCP server takes an exclusive palace lock on its first non-exempt write and keeps it until the server exits. Every sweep after that fails with "palace is held by PID ...". The plugin removes the 12 tools that take the lock: the drawer writes, updates and deletes, `mempalace_checkpoint`, `mempalace_diary_write`, `mempalace_mine`, `mempalace_sync`, and the tunnel and hallway writes. The list lives in `LOCKING_MCP_TOOLS` in `mcp-tools.ts` and mirrors `_MUTATING_TOOLS` minus `_PEER_WRITER_EXEMPT_TOOLS` in mempalace 3.11. Recheck it after upgrades.
- **Knowledge graph.** Every `mempalace_kg_*` tool. Durable knowledge lives in [organic facts](#organic-facts) instead.

The injected memory protocol tells agents the tools are disabled and to discuss a lock-free alternative with you. Add one the way conversation capture works: run short-lived `mempalace` commands under the sweeper's lock.

## Organic facts

Organic facts are Markdown files that hold knowledge an agent would otherwise rediscover: user preferences, project and tool knowledge, and findings from research. They work like skills: the plugin injects one entry per file, and the agent reads a file when it might help.

| Setting | Behavior |
| --- | --- |
| `ORGANIC_FACTS_DIR` | Absolute or `~/` path of the facts directory. Defaults to `~/.organic-facts`. |

Make the variable available to the OpenCode service process. Changing a shell file doesn't change an already-running process's environment.

Each model request gets two extra system parts:

1. **Instructions.** Static text that tells the agent how to read, write, group, and cite facts.
2. **Catalogue.** An `<organic-facts>` block with one line per Markdown file: the full path and the `description` from its front-matter. The plugin rescans the directory on every request, so new files appear immediately. A file without a description is listed with a hint to add one. An empty directory produces a placeholder that asks the agent to populate it.

Conventions the instructions enforce:

- Each file is a nearly self-contained reference. If an agent has to search or ask for context a file should have held, it updates that file.
- Group facts. Add a new file only when nothing existing fits. Directories represent topics and subtopics.
- Front-matter `description` says when the file is relevant and contains no facts.
- Every information block carries a `[source: ... — YYYY-MM-DD]` citation.

Keep private knowledge outside this public repository. Hidden entries, non-Markdown files, and symlinked directories are ignored.

```text
facts/
  Projects/
    Atlas/
      architecture.md
      ownership.md
  Tools/
    Editor/
      memory.md
```

## Install and check

Run the dotfiles stow task (`just stow opencode`) to expose the plugins. OpenCode watches plugin changes; `/reload` forces configuration reload if needed. No new package dependency is required beyond the existing OpenCode plugin SDK and MemPalace connection.

OpenCode discovers the stowed `~/.config/opencode/plugins/mempalace.ts` and `organic-facts.ts` automatically. `mempalace.ts` imports its sibling implementation modules; no explicit directory entry belongs in the config's `plugins` list. This avoids the directory-entrypoint containment check. Bun can still retain a symlinked module across reloads; verify the running behavior after code changes rather than assuming a reload replaced it.

Run focused tests from this directory:

```sh
sh tests/run.sh
```

The runner starts Bun with a scratch home directory before imports. Capture tests also mock the home resolver and shell, so test pruning and launchers cannot operate on your real transcript cache or palace.
