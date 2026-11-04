# MemPalace integration

One MemPalace plugin captures conversations, provides memory routing, and connects a human-readable Markdown knowledge base to MemPalace. Conversation archives preserve historical evidence. The knowledge graph stores small, sparse durable facts and relationships that rarely need updates. Organic-facts Markdown holds richer, detailed knowledge about larger projects that evolves over time.

The system prompt contains reading guidance, an upkeep reminder, and fresh entity/topic catalogues. The plugin registers an on-demand `organic-facts` skill for updating, sourcing, and mining notes. No standalone skill file is required.

## Module structure

| File | Responsibility |
| --- | --- |
| `plugins/mempalace.ts` | Register the integration and clean it up. |
| `conversations.ts` | Capture transcripts on idle and before compaction; prune old transcript files. |
| `memory-context.ts` | Inject the memory protocol, current KG entities, and repair alerts. |
| `organic-facts.ts` | Register the maintenance skill, topic catalogue, and mining tool. |
| `mining.ts` | Validate directory trees, route rooms, and publish owned mining configuration. |
| `mempalace-sweep.sh` | Coalesce detached sweeps and preserve repair/recovery safeguards. |

Implementation modules and the sweeper live under `plugins/mempalace/`. That directory has no separate entrypoint or package manifest.

## Capture conversations

Capture writes full user/assistant text to `~/.mempalace/opencode-sessions/<session-id>.jsonl`. MemPalace sweep deduplicates messages, so repeated captures add only new content. A detached, coalesced sweeper continues after session shutdown. Pruning removes old transcript files, not archived palace content.

| Environment variable | Behavior |
| --- | --- |
| `MEMPALACE_HOOKS_AUTO_SAVE` | `false`, `0`, or `no` disables capture without disabling memory guidance or organic facts. |
| `MEMPALACE_INJECT_ENTITIES` | `false`, `0`, or `no` hides the KG catalogue without disabling other guidance. |
| `MEMPALACE_SESSION_TTL_DAYS` | Defaults to 7. Set 0 to retain transcripts indefinitely. The active session is never pruned. |
| `ORGANIC_FACTS_DIR` | Select the canonical Markdown directory; defaults to `~/.organic-facts`. |

The sweeper keeps its dirty-marker handoff, writer lock, bounded log, and segment-divergence repair. If repair fails, capture still writes transcripts but skips indexing. The context hook reports the halt. Capture and catalogue failures remain best-effort; a missing facts directory doesn't prevent transcript capture.

## Choose the facts directory

Set an absolute path in your local shell configuration:

```sh
export ORGANIC_FACTS_DIR="$HOME/notes/facts"
```

Without this variable, the plugin uses `~/.organic-facts`. It also accepts `~/` paths. Make the variable available to the OpenCode service process; changing a shell file doesn't change an already-running process's environment.

Keep private knowledge outside this public repository. For example:

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

Use ordinary file tools to create or update these notes. Keep one document per topic, cite each information block, and preserve verification limits. Source labels include identifiable evidence and its capture or inspection date. Subsections inherit parent references unless overridden. Load the plugin-provided `organic-facts` skill for these maintenance rules; reading notes doesn't require loading it.

Retain only non-obvious knowledge that saves meaningful investigation: constraints, decisions and rationale, ownership boundaries, failure modes, and cross-system relationships. Skip trivial or easily derived information, straightforward README/configuration restatements, language/path inventories, and repeated guidance. Don't create or keep a topic note when nothing passes this filter.

Agents can add relevant knowledge and create useful new project groups when authorized, without a separate organization request. Don't fill organic facts with small isolated facts; those belong in the knowledge graph.

## Refresh changed topics

Call the tool after a batch of edits:

```json
{"documents": ["Projects/Atlas/architecture.md", "Tools/Editor/memory.md"]}
```

`organic_facts_mine` accepts existing Markdown paths relative to the facts directory. It validates the entire list, rejects escapes and hidden inputs, and scans the affected parent directory trees. Every document-containing directory gets a shallow Markdown-only mining pass, so nested topics keep their own rooms. Hidden files and directories stay out of the index. The tool calls the existing MemPalace MCP mining tool and respects its permission and writer locks. It also checks `edit` and applicable `external_directory` permissions before writing routing files. Connect exactly one MemPalace mining tool.

The tool creates plugin-owned `mempalace.yaml` routing files beside notes. It never rewrites Markdown or replaces unrelated project configuration. MemPalace room filters reject slashes, so the catalogue maps grouped paths to readable room IDs with stable hashes. Use those IDs with `wing="organic-facts"` for scoped search; root-level documents use `general`.

Read original documents for context and citations. Mining does not clean up deleted or renamed sources. Review MemPalace's cleanup preview separately. Failed refreshes can leave the index older than the documents, and successful mining can skip files under MemPalace's size, ignore, or minimum-content rules.

## Install and check

Run the dotfiles stow task to expose the integration files. OpenCode watches plugin changes; `/reload` forces configuration reload if needed. No new package dependency is required beyond the existing OpenCode plugin SDK and MemPalace connection.

OpenCode discovers the stowed `~/.config/opencode/plugins/mempalace.ts` automatically. The file imports its sibling implementation modules; no explicit directory entry belongs in the config's `plugins` list. This avoids the directory-entrypoint containment check. Bun can still retain a symlinked module across reloads; verify the running behavior after code changes rather than assuming a reload replaced it.

Run focused tests from this directory:

```sh
sh tests/run.sh
```

The runner starts Bun with a scratch home directory before imports. Capture tests also mock the home resolver and shell, so test pruning and launchers cannot operate on your real transcript cache or palace.
