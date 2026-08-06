// mempalace — opencode plugin: deterministic conversation capture + Memory Protocol
// + a live knowledge-graph routing signal injected every turn.
//
// This is the opencode equivalent of the MemPalace Claude/Codex "Path 1" auto-save:
// the plugin itself reads the session transcript and ingests it into the palace —
// no agent involvement, deterministic, verbatim. Claude/Codex get this for free
// because their hosts persist a transcript JSONL that MemPalace can read; opencode
// does not, so we reconstruct a Claude-style JSONL from the opencode server API
// (client.session.messages) and feed it to `mempalace sweep`.
//
// Why `sweep` (not `mine --mode convos`): sweep is message-granular, cursor-based,
// and idempotent — re-running it on a transcript that has GROWN ingests only the
// new messages (keyed by per-message uuid + timestamp). That is exactly what this
// setup needs: we re-emit the FULL transcript on every idle and sweep dedups,
// so no high-water tracking, delta files, or sidecars are needed. `mine --mode
// convos` skips by source_file path (check_mtime=False) and so cannot capture a
// growing session on a stable path. Capture must not depend on message volume or
// the agent: counters reset on opencode restart and short-lived/idle-GC'd Slack
// agents rarely reach any threshold.
//
// Behaviours:
//   (A) experimental.chat.system.transform — inject the MemPalace Memory Protocol
//       (query/write-often guidance). Always on, free.
//   (B) experimental.chat.messages.transform — inject a FRESH list of the entities
//       the knowledge graph currently knows about, anchored to the last user
//       message (mirrors the jumper-inject pattern). This turns the read path from
//       "agent must remember the graph exists" into "agent can see what's in it and
//       decide to kg_query" — the routing signal the graph otherwise lacks.
//   (C) session.idle + experimental.session.compacting — deterministic capture:
//       render the session as Claude-style JSONL, write it, and poke a SINGLE
//       coalescing detached sweeper (flock + dirty-marker settle loop) that sweeps
//       the whole sessions dir. Detached so it survives opencode being GC'd/killed
//       right after idle; coalesced so many simultaneous idles collapse to one
//       chroma writer instead of starving readers. See launchDetachedSweep.
//
// Why the entity list lives in messages.transform, not system.transform: the
// system prompt is cached per session, so an entity list injected there would go
// stale as the graph changes mid-session. messages.transform fires per outgoing
// LLM request and mutates only that payload (never written back to stored history),
// so the model sees exactly ONE fresh copy per turn and nothing accumulates.
// (See the jumper-inject plugin for the same reasoning applied to bookmarks.)
//
// KG entity data source: read directly from ~/.mempalace/knowledge_graph.sqlite3.
// mempalace has NO CLI verb (no `mempalace kg`) and NO MCP tool for dumping/merging
// entities — only per-entity kg_query — so direct SQLite is the pragmatic source.
// (This same gap means canonicalizing/merging entities is a manual SQLite edit +
// mempalace_reconnect; recorded in the KG under mempalace.)
//
// State on disk under ~/.mempalace/opencode-sessions/:
//   <sessionID>.jsonl  — the rendered transcript (rewritten in full each capture;
//                        sweep ingests only new messages). Pruned by a lazy 7-day
//                        TTL sweep on idle (excluding the active session).
//
// Opt-out: MEMPALACE_HOOKS_AUTO_SAVE=false|0|no suppresses capture (A+B still run).
//          MEMPALACE_INJECT_ENTITIES=false|0|no suppresses the entity-list injection.
// Tunable: MEMPALACE_SESSION_TTL_DAYS (default 7; 0 = keep forever).

import type { Plugin } from '@opencode-ai/plugin';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';
import { mkdir, writeFile, readFile, readdir, stat, unlink } from 'node:fs/promises';

const TTL_DAYS = 7;

const SESSIONS_DIR = join(homedir(), '.mempalace', 'opencode-sessions');
const PALACE_DIR = join(homedir(), '.mempalace', 'palace');

const SWEEP_SCRIPT = join(dirname(fileURLToPath(import.meta.url)), 'mempalace-sweep.sh');
const SWEEP_LOG = join(SESSIONS_DIR, 'sweep.log');
const SWEEP_LOCK = join(SESSIONS_DIR, 'sweep.lock');
const SWEEP_DIRTY = join(SESSIONS_DIR, 'sweep.dirty');
const KG_DB = join(homedir(), '.mempalace', 'knowledge_graph.sqlite3');
const PALACE_CHROMA_DB = join(PALACE_DIR, 'chroma.sqlite3');

// Circuit breaker: the worker writes this only when a rebuild-from-sqlite fails
// (sqlite itself likely corrupt, so retrying can't help). Its presence halts all
// sweeping until a human fixes the palace and deletes it.
const PALACE_ERROR_LOG = join(PALACE_DIR, 'repair-error.log');

const ENTITIES_OPEN = '<mempalace-kg-entities>';
const ENTITIES_CLOSE = '</mempalace-kg-entities>';

// Standing behaviour guide. Mirrors the MemPalace "Memory Protocol" that
// mempalace_status returns and that the Claude Code plugin injects natively.
// Verbatim conversation capture is automatic (this plugin) and the entities the
// graph knows about are injected fresh each turn (below), so the agent-facing
// nudges are: (1) use the injected entity list to decide when to kg_query, and
// (2) actively keep the graph current — the KG is the one layer raw capture can't
// build. Because the entity list is always visible, re-adding a fact for an entity
// that is already present is cheap and adds no stale noise (kg_add dedups on
// subject+predicate+object), so the prompt encourages frequent, low-friction
// writes rather than treating KG upkeep as a rare end-of-session chore.
const MEMORY_PROTOCOL = [
  '## MemPalace Memory Protocol',
  'You have a persistent memory palace, reached through the `mempalace_*` MCP tools',
  '(these may be always available or lazy-loaded — discover them if not already in context).',
  'When starting relevant work, `mempalace_status` gives the palace overview.',
  '',
  '### Querying the knowledge graph',
  `The entities the graph currently knows about are injected fresh each turn in a \`${ENTITIES_OPEN}\` block.`,
  'Use it as a routing signal: if the user asks about a person, project, decision, or past event and',
  'a matching (or related) entity is listed, `mempalace_kg_query` it BEFORE answering — never guess.',
  'For prose/detail the graph does not hold, `mempalace_search` the verbatim drawers.',
  '',
  '### Keep the knowledge graph current (IMPORTANT)',
  'The graph is the source of truth for durable facts. Keeping it accurate is a standing,',
  'ongoing responsibility — record facts as they emerge, do not wait until the end of the session.',
  '- When a durable fact is established or learned (a relationship, ownership, config, version,',
  '  decision, setup detail, preference), add it immediately with `mempalace_kg_add`.',
  '- Prefer attaching facts to entities ALREADY in the injected list — reusing an existing entity',
  '  keeps the graph connected and adds no stale noise (kg_add dedups on subject+predicate+object,',
  '  so re-adding a fact that already exists is a harmless no-op). Write early and often.',
  '- When a fact stops being true (something changed, was replaced, or removed), call',
  '  `mempalace_kg_invalidate` on the old fact and `mempalace_kg_add` for the new one.',
  '- Record only durable, factual relationships — not transient chatter or in-progress steps.',
].join('\n');

export const MemPalace: Plugin = async ({ client, $ }) => {
  // Render the session's messages as Claude-style JSONL — one record per
  // user/assistant message, the shape mempalace's sweeper parses:
  //   {type, uuid, timestamp, sessionId, message:{role, content}}
  // Synthetic/injected parts are skipped so we never capture our own directives.
  // Returns the JSONL text (one record per line) or '' if nothing to capture.
  async function renderJsonl(sessionID: string): Promise<string> {
    const res = await client.session.messages({ path: { id: sessionID } });
    const messages = (res as any)?.data ?? [];
    const lines: string[] = [];

    for (const m of messages) {
      const info = m?.info;
      const parts = m?.parts ?? [];
      if (!info || (info.role !== 'user' && info.role !== 'assistant')) continue;

      const content = parts
        .filter((p: any) => p?.type === 'text' && !p?.synthetic && typeof p.text === 'string')
        .map((p: any) => p.text)
        .join('\n')
        .trim();
      if (!content) continue;

      const createdMs = info.time?.created ?? Date.now();
      lines.push(
        JSON.stringify({
          type: info.role,
          uuid: info.id,
          timestamp: new Date(createdMs).toISOString(),
          sessionId: info.sessionID ?? sessionID,
          message: { role: info.role, content },
        }),
      );
    }

    return lines.length ? lines.join('\n') + '\n' : '';
  }

  // Read the display names of every entity that is the SUBJECT of a currently-valid
  // fact and render them as a compact `<mempalace-kg-entities>` block. Subjects are
  // the queryable anchors — objects are mostly leaf values — so listing subjects is
  // the routing signal the agent needs. Returns '' on any failure or when empty, so
  // callers simply skip injection. Read-only sqlite3 fork; best-effort.
  async function renderEntities(): Promise<string> {
    try {
      const sql =
        'SELECT DISTINCT e.name FROM triples t JOIN entities e ON e.id = t.subject ' +
        'WHERE t.valid_to IS NULL ORDER BY e.name;';
      const res = await $`sqlite3 -readonly ${KG_DB} ${sql}`.quiet().nothrow();
      if (res.exitCode !== 0) return '';

      const names = res.stdout
        .toString()
        .split('\n')
        .map((s) => s.trim())
        .filter(Boolean);
      if (names.length === 0) return '';

      return [
        ENTITIES_OPEN,
        'The knowledge graph has current facts about these entities — mempalace_kg_query any that are relevant:',
        ...names.map((n) => `- ${n}`),
        ENTITIES_CLOSE,
      ].join('\n');
    } catch {
      return '';
    }
  }

  // Fork the detached coalescing sweeper (see mempalace-sweep.sh for the sweep/
  // self-heal logic). We await only the launcher — setsid detaches and returns in
  // ms, so the spawn is guaranteed before the handler returns while the sweep
  // outlives the session. Paths pass via .env() so nothing untrusted is
  // concatenated into a shell string.
  async function launchDetachedSweep() {
    // touch the dirty marker BEFORE the sweeper contends for the lock: a launch that
    // loses the lock still obligates the running sweeper to one more pass, so its
    // already-written JSONL is never dropped.
    await $`sh -c ${`touch "$MP_DIRTY"; setsid -f sh "$MP_SCRIPT" </dev/null >>"$MP_LOG" 2>&1`}`
      .env({
        ...process.env,
        MP_SCRIPT: SWEEP_SCRIPT,
        MP_SESSIONS: SESSIONS_DIR,
        MP_LOCK: SWEEP_LOCK,
        MP_DIRTY: SWEEP_DIRTY,
        MP_LOG: SWEEP_LOG,
        MP_CHROMA: PALACE_CHROMA_DB,
        MP_PALACE: PALACE_DIR,
        MP_ERROR_LOG: PALACE_ERROR_LOG,
      })
      .nothrow();
  }

  // Render + write the session JSONL, then poke the sweeper. JSONL is written
  // FIRST so a launch that loses the flock still leaves durable work for the next
  // sweeper. If the palace is halted (PALACE_ERROR_LOG present from a failed
  // rebuild) we still write the JSONL but skip the sweep, to avoid writing into a
  // likely-corrupt DB; the user is told via the messages.transform hook.
  // Best-effort throughout — never disrupt the session.
  async function capture(sessionID: string) {
    if (!sessionID) return;
    try {
      await mkdir(SESSIONS_DIR, { recursive: true });
      const jsonl = await renderJsonl(sessionID);
      if (!jsonl) return;
      const jsonlPath = join(SESSIONS_DIR, `${sessionID}.jsonl`);
      await writeFile(jsonlPath, jsonl, 'utf8');

      const halted = await readFile(PALACE_ERROR_LOG, 'utf8').catch(() => undefined);
      if (halted) return; // durable JSONL written; skip sweep into a bad DB

      await launchDetachedSweep();
    } catch {
      // best-effort
    }
  }

  // Lazy TTL sweep: delete <id>.jsonl files older than TTL_DAYS, never the active
  // session. Runs on idle; best-effort.
  async function pruneOldSessions(activeSessionID: string) {
    if (TTL_DAYS <= 0) return;
    try {
      const cutoff = Date.now() - TTL_DAYS * 24 * 60 * 60 * 1000;
      for (const name of await readdir(SESSIONS_DIR)) {
        if (!name.endsWith('.jsonl')) continue;
        if (name === `${activeSessionID}.jsonl`) continue;
        const full = join(SESSIONS_DIR, name);
        try {
          const st = await stat(full);
          if (st.mtimeMs < cutoff) await unlink(full);
        } catch {
          // ignore per-file errors
        }
      }
    } catch {
      // dir may not exist yet; ignore
    }
  }

  return {
    // (A) Memory Protocol — always injected (free, non-blocking).
    'experimental.chat.system.transform': async (_input, output) => {
      output.system.push(MEMORY_PROTOCOL);
    },

    // (B) Live KG entity list — fresh routing signal appended to the latest user
    // message each turn. Never persisted (messages.transform mutates only the
    // per-request payload); anchored next to current intent. Best-effort.
    'experimental.chat.messages.transform': async (_input, output) => {
      try {
        const messages = output.messages;
        if (!Array.isArray(messages) || messages.length === 0) return;

        const target = [...messages].reverse().find((m) => m?.info?.role === 'user');
        if (!target) return;

        // Surface a halted palace here (not in the capture hooks) — this is the only
        // hook with a user-facing channel.
        const halted = await readFile(PALACE_ERROR_LOG, 'utf8').catch(() => undefined);

        const block = await renderEntities();
        if (!block && !halted) return;

        const text = halted
          ? `<mempalace-alert>\nMemPalace indexing is HALTED: a rebuild-from-sqlite failed, so the palace ` +
            `sqlite is likely corrupt and sweeping is suspended. Sessions are still captured to disk and ` +
            `will index once resolved. Tell the user: manual intervention required — inspect ` +
            `${PALACE_ERROR_LOG}, repair/restore the palace sqlite, then delete that file to resume.\n</mempalace-alert>` +
            (block ? `\n${block}` : '')
          : block;

        // Append in place (reassigning output.messages is a no-op in opencode).
        target.parts.push({
          id: `mempalace-entities-${Date.now()}`,
          sessionID: target.info.sessionID,
          messageID: target.info.id,
          type: 'text',
          text,
          synthetic: true,
        } as any);
      } catch {
        // best-effort — never disrupt the request
      }
    },

    // (C) Deterministic capture on idle (the session's natural end for short-lived
    // and idle-GC'd agents), plus a TTL prune.
    event: async ({ event }) => {
      if (event.type !== 'session.idle') return;
      const sessionID = (event as any).properties?.sessionID as string | undefined;
      if (!sessionID) return;
      await capture(sessionID);
      await pruneOldSessions(sessionID);
    },

    // (C) Safety-net capture right before context is compressed.
    'experimental.session.compacting': async (input, _output) => {
      await capture(input.sessionID);
    },
  };
};

export default MemPalace;
