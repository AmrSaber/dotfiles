import { afterEach, beforeEach, expect, spyOn, test } from "bun:test";
import { mkdir, mkdtemp, readFile, rm, utimes, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import * as os from "node:os";
import { registerConversations } from "../plugins/mempalace/conversations";
import { registerMemoryContext } from "../plugins/mempalace/memory-context";

const environmentKeys = ["HOME", "MEMPALACE_HOOKS_AUTO_SAVE", "MEMPALACE_SESSION_TTL_DAYS", "MEMPALACE_INJECT_ENTITIES"];
const originalShell = Bun.$;
let environment: Record<string, string | undefined>;
let root: string;
let home: string;
let calls: Array<{ strings: string[]; values: unknown[]; env?: Record<string, string | undefined>; quiet?: boolean }>;
let cleanups: Array<() => Promise<void>>;
let sqliteOutput: string;
let sqliteExitCode: number;
let shellFailure: boolean;
let homeMock: ReturnType<typeof spyOn>;

beforeEach(async () => {
  environment = Object.fromEntries(environmentKeys.map((key) => [key, process.env[key]]));
  root = await mkdtemp("/tmp/opencode/mempalace-plugin-");
  home = join(root, "home 'quoted' $name; [space]");
  await mkdir(home);
  process.env.HOME = home;
  homeMock = spyOn(os, "homedir").mockReturnValue(home);
  expect(os.homedir()).toBe(home);
  for (const key of environmentKeys.slice(1)) delete process.env[key];
  calls = [];
  cleanups = [];
  sqliteOutput = "";
  sqliteExitCode = 0;
  shellFailure = false;
  Bun.$ = ((strings: TemplateStringsArray, ...values: unknown[]) => {
    const call: (typeof calls)[number] = { strings: [...strings], values };
    calls.push(call);
    return {
      env(env: Record<string, string | undefined>) { call.env = env; return this; },
      quiet() { call.quiet = true; return this; },
      async nothrow() {
        if (shellFailure) throw new Error("fixture shell failure");
        return { exitCode: sqliteExitCode, stdout: Buffer.from(sqliteOutput) };
      },
    };
  }) as any;
});

afterEach(async () => {
  try {
    await Promise.all(cleanups.splice(0).map((cleanup) => cleanup()));
  } finally {
    Bun.$ = originalShell;
    homeMock?.mockRestore();
    for (const key of environmentKeys) {
      if (environment[key] === undefined) delete process.env[key];
      else process.env[key] = environment[key];
    }
    await rm(root, { recursive: true, force: true });
  }
});

test("compaction writes deterministic full user and assistant JSONL, with timestamps and IDs", async () => {
  const messages = [
    { type: "user", id: "user-1", time: { created: 1000 }, text: "  First line\nSecond line  " },
    { type: "synthetic", text: "Injected directive" },
    { type: "system", text: "System directive" },
    { type: "compaction", text: "Generated summary" },
    { type: "assistant", id: "assistant-1", time: { created: 2000 }, content: [
      { type: "reasoning", text: "Private reasoning" },
      { type: "text", text: "  Answer one" },
      { type: "tool", text: "Tool output" },
      { type: "text", text: "Answer two  " },
    ] },
    { type: "user", text: " \n " },
    { type: "assistant", content: [{ type: "tool", text: "Not conversation text" }] },
  ];
  const ctx = fakeContext(messages);
  cleanups.push(await registerConversations(ctx as any));
  await ctx.hooks.get("compaction")!({ sessionID: "session-1" });
  const first = await readFile(sessionFile("session-1"), "utf8");
  expect(first.endsWith("\n")).toBe(true);
  expect(first.trim().split("\n").map((line) => JSON.parse(line))).toEqual([
    { type: "user", uuid: "user-1", timestamp: "1970-01-01T00:00:01.000Z", sessionId: "session-1", message: { role: "user", content: "First line\nSecond line" } },
    { type: "assistant", uuid: "assistant-1", timestamp: "1970-01-01T00:00:02.000Z", sessionId: "session-1", message: { role: "assistant", content: "Answer one\nAnswer two" } },
  ]);
  await ctx.hooks.get("compaction")!({ sessionID: "session-1" });
  expect(await readFile(sessionFile("session-1"), "utf8")).toBe(first);
  messages.push({ type: "user", id: "user-2", time: { created: 3000 }, text: "Next turn" });
  await ctx.hooks.get("compaction")!({ sessionID: "session-1" });
  const updated = await readFile(sessionFile("session-1"), "utf8");
  expect(updated.startsWith(first)).toBe(true);
  expect(updated.trim().split("\n")).toHaveLength(3);
  expect(ctx.reads).toEqual(["session-1", "session-1", "session-1"]);
});

test("idle captures the transcript and ignores unrelated events", async () => {
  const ctx = fakeContext([userMessage()]);
  cleanups.push(await registerConversations(ctx as any));
  await ctx.emit({ type: "session.renamed", data: { sessionID: "session-1" } });
  expect(ctx.reads).toEqual([]);
  await ctx.emit({ type: "session.idle", data: { sessionID: "session-1" } });
  expect(await readFile(sessionFile("session-1"), "utf8")).toContain("Fixture question");
  expect(calls).toHaveLength(1);
});

test.each([" FALSE ", "0", "No"])("auto-save opt-out %s leaves memory context active", async (disabled) => {
  process.env.MEMPALACE_HOOKS_AUTO_SAVE = disabled;
  sqliteOutput = "Editor\n";
  const ctx = fakeContext([userMessage()]);
  cleanups.push(await registerConversations(ctx as any), await registerMemoryContext(ctx as any));
  await oldSession("old-session", 8);
  await ctx.emit({ type: "session.idle", data: { sessionID: "session-1" } });
  await ctx.hooks.get("compaction")!({ sessionID: "session-1" });
  expect(ctx.reads).toEqual([]);
  expect(await readFile(sessionFile("old-session"), "utf8")).toBe("fixture");
  await expect(readFile(sessionFile("session-1"))).rejects.toThrow();
  const system = await contextText(ctx);
  expect(system).toContain("MemPalace Memory Protocol");
  expect(system).toContain("- Editor");
  expect(calls).toHaveLength(1);
  expect(calls[0].strings[0]).toBe("sqlite3 -readonly ");
});

test.each([undefined, "invalid"])("TTL %s defaults to seven days and never prunes the active session", async (ttl) => {
  if (ttl !== undefined) process.env.MEMPALACE_SESSION_TTL_DAYS = ttl;
  const ctx = fakeContext();
  cleanups.push(await registerConversations(ctx as any));
  await oldSession("active", 8);
  await oldSession("expired", 8);
  await oldSession("recent", 6);
  await writeFile(join(home, ".mempalace", "opencode-sessions", "sweep.log"), "keep log");
  await ctx.emit({ type: "session.idle", data: { sessionID: "active" } });
  await expect(readFile(sessionFile("expired"))).rejects.toThrow();
  expect(await readFile(sessionFile("active"), "utf8")).toBe("fixture");
  expect(await readFile(sessionFile("recent"), "utf8")).toBe("fixture");
  expect(await readFile(join(home, ".mempalace", "opencode-sessions", "sweep.log"), "utf8")).toBe("keep log");
  expect(calls).toHaveLength(0);
});

test("zero TTL keeps expired and active transcripts", async () => {
  process.env.MEMPALACE_SESSION_TTL_DAYS = "0";
  const ctx = fakeContext();
  cleanups.push(await registerConversations(ctx as any));
  await oldSession("active", 20);
  await oldSession("expired", 20);
  await ctx.emit({ type: "session.idle", data: { sessionID: "active" } });
  expect(await readFile(sessionFile("active"), "utf8")).toBe("fixture");
  expect(await readFile(sessionFile("expired"), "utf8")).toBe("fixture");
});

test("a halted palace still receives full JSONL without launching the sweeper", async () => {
  await repairError();
  const messages = [userMessage()];
  const ctx = fakeContext(messages);
  cleanups.push(await registerConversations(ctx as any));
  await ctx.hooks.get("compaction")!({ sessionID: "session-1" });
  expect(await readFile(sessionFile("session-1"), "utf8")).toContain("Fixture question");
  messages.push({ ...userMessage(), id: "user-2", text: "Another turn" });
  await ctx.emit({ type: "session.idle", data: { sessionID: "session-1" } });
  expect((await readFile(sessionFile("session-1"), "utf8")).trim().split("\n")).toHaveLength(2);
  expect(calls).toHaveLength(0);
});

test("launchers keep paths in environment values and share coalescing markers", async () => {
  const ctx = fakeContext([userMessage()]);
  cleanups.push(await registerConversations(ctx as any));
  await ctx.hooks.get("compaction")!({ sessionID: "session-1" });
  await ctx.hooks.get("compaction")!({ sessionID: "session-2" });
  expect(calls).toHaveLength(2);
  const sessions = join(home, ".mempalace", "opencode-sessions");
  const palace = join(home, ".mempalace", "palace");
  for (const call of calls) {
    expect(call.strings).toEqual(["sh -c ", ""]);
    expect(call.values).toEqual(['touch "$MP_DIRTY"; setsid -f sh "$MP_SCRIPT" </dev/null >>"$MP_LOG" 2>&1']);
    expect(call.values[0]).not.toContain(home);
    expect(call.env).toMatchObject({
      MP_SCRIPT: fileURLToPath(new URL("../plugins/mempalace/mempalace-sweep.sh", import.meta.url)),
      MP_SESSIONS: sessions,
      MP_LOCK: join(sessions, "sweep.lock"),
      MP_DIRTY: join(sessions, "sweep.dirty"),
      MP_LOG: join(sessions, "sweep.log"),
      MP_CHROMA: join(palace, "chroma.sqlite3"),
      MP_PALACE: palace,
      MP_ERROR_LOG: join(palace, "repair-error.log"),
    });
  }
  expect(calls[0].env).toEqual(calls[1].env);
});

test("entity routing refreshes each request through the same read-only subject SQL", async () => {
  const ctx = fakeContext();
  cleanups.push(await registerMemoryContext(ctx as any));
  sqliteOutput = " Editor \n\nWorkspace\n";
  const first = await contextText(ctx);
  expect(first).toContain("- Editor\n- Workspace");
  sqliteOutput = "Terminal\n";
  const second = await contextText(ctx);
  expect(second).toContain("- Terminal");
  expect(second).not.toContain("- Editor");
  for (const call of calls) {
    expect(call.strings).toEqual(["sqlite3 -readonly ", " ", ""]);
    expect(call.values).toEqual([
      join(home, ".mempalace", "knowledge_graph.sqlite3"),
      "SELECT DISTINCT e.name FROM triples t JOIN entities e ON e.id = t.subject WHERE t.valid_to IS NULL ORDER BY e.name;",
    ]);
    expect(call.quiet).toBe(true);
  }
  expect(calls).toHaveLength(2);
});

test.each([" false ", "0", "NO"])("entity opt-out %s does not hide the repair alert", async (disabled) => {
  process.env.MEMPALACE_INJECT_ENTITIES = disabled;
  await repairError();
  const ctx = fakeContext();
  cleanups.push(await registerMemoryContext(ctx as any));
  const system = await contextText(ctx);
  expect(system).toContain("<mempalace-alert>");
  expect(system).toContain("indexing is HALTED");
  expect(system).toContain(join(home, ".mempalace", "palace", "repair-error.log"));
  expect(system).not.toContain("The knowledge graph has current facts");
  expect(calls).toHaveLength(0);
});

test("repair alerts survive empty, failed, and throwing SQLite reads", async () => {
  await repairError();
  const ctx = fakeContext();
  cleanups.push(await registerMemoryContext(ctx as any));
  expect(await contextText(ctx)).toContain("indexing is HALTED");
  sqliteOutput = "Must not inject on failure\n";
  sqliteExitCode = 1;
  expect(await contextText(ctx)).not.toContain("- Must not inject");
  shellFailure = true;
  expect(await contextText(ctx)).toContain("indexing is HALTED");
});

test("the protocol separates historical evidence, sparse graph facts, and evolving project notes", async () => {
  const ctx = fakeContext();
  cleanups.push(await registerMemoryContext(ctx as any));
  const system = await contextText(ctx);
  for (const text of [
    "Conversations are captured automatically",
    "No skill is needed for raw capture",
    "historical evidence, not unquestioned current truth",
    "not independent verification",
    "Historical conversation claims are not confirmed facts",
    "Organic-facts Markdown is canonical",
    "small, sparse durable facts and relationships",
    "less prone to staleness and need infrequent updates",
    "Small isolated facts belong in the graph, not organic facts",
    "richer, detailed knowledge about larger projects that evolves over time",
    "Create useful organic-facts notes and new project groups",
    "agent permissions and explicit read-only or stop requests",
    "Do not duplicate full project-document assertions in the graph",
    "Link to topic documents where useful",
    "the graph is not limited to pointers",
    "Reuse existing entities",
    "provenance and temporal validity",
    "mempalace_kg_add",
    "mempalace_kg_invalidate",
    "mempalace_kg_supersede",
    "When authorized",
  ]) expect(system).toContain(text);
  expect(system).not.toContain("source of truth for durable facts");
  expect(system).not.toContain("kg_add` instead");
  expect(system).not.toContain("writer lease");
});

test("capture and memory failures remain best-effort and do not remove durable JSONL", async () => {
  const ctx = fakeContext([userMessage()]);
  cleanups.push(await registerConversations(ctx as any), await registerMemoryContext(ctx as any));
  shellFailure = true;
  await ctx.hooks.get("compaction")!({ sessionID: "session-1" });
  expect(await readFile(sessionFile("session-1"), "utf8")).toContain("Fixture question");
  expect(await contextText(ctx)).toContain("MemPalace Memory Protocol");
  ctx.failContext = true;
  await ctx.emit({ type: "session.idle", data: { sessionID: "session-2" } });
  await expect(readFile(sessionFile("session-2"))).rejects.toThrow();
  await ctx.hooks.get("compaction")!({ sessionID: "" });
  expect(ctx.reads).toEqual(["session-1", "session-2"]);
});

test("cleanup disposes each helper's hooks and stops the idle subscription", async () => {
  const ctx = fakeContext();
  const conversations = await registerConversations(ctx as any);
  const memoryContext = await registerMemoryContext(ctx as any);
  cleanups.push(conversations, memoryContext);
  expect([...ctx.hooks.keys()]).toEqual(["compaction", "context"]);
  await conversations();
  await memoryContext();
  cleanups = [];
  expect(ctx.hooks.size).toBe(0);
  expect(ctx.disposals).toEqual(["compaction", "context"]);
  expect(ctx.signal?.aborted).toBe(true);
  expect(ctx.subscriptionEnded).toBe(true);
});

function fakeContext(messages: any[] = []) {
  const queue: Array<{ event: any; done: () => void }> = [];
  let wake: (() => void) | undefined;
  const hooks = new Map<string, (event: any) => Promise<void>>();
  const ctx = {
    hooks,
    reads: [] as string[],
    disposals: [] as string[],
    signal: undefined as AbortSignal | undefined,
    subscriptionEnded: false,
    failContext: false,
    session: {
      context: async ({ sessionID }: { sessionID: string }) => {
        ctx.reads.push(sessionID);
        if (ctx.failContext) throw new Error("fixture context failure");
        return messages;
      },
      hook: async (name: string, callback: (event: any) => Promise<void>) => {
        hooks.set(name, callback);
        return { dispose: async () => { hooks.delete(name); ctx.disposals.push(name); } };
      },
    },
    event: {
      subscribe: async function* ({ signal }: { signal: AbortSignal }) {
        ctx.signal = signal;
        const abort = () => wake?.();
        signal.addEventListener("abort", abort, { once: true });
        try {
          while (!signal.aborted) {
            if (!queue.length) await new Promise<void>((resolve) => { wake = resolve; });
            if (signal.aborted) break;
            const item = queue.shift()!;
            yield item.event;
            item.done();
          }
        } finally {
          signal.removeEventListener("abort", abort);
          ctx.subscriptionEnded = true;
        }
      },
    },
    emit: (event: any) => new Promise<void>((done) => { queue.push({ event, done }); wake?.(); }),
  };
  return ctx;
}

function userMessage() {
  return { type: "user", id: "user-1", time: { created: 1000 }, text: "Fixture question" };
}

function sessionFile(sessionID: string): string {
  return join(home, ".mempalace", "opencode-sessions", `${sessionID}.jsonl`);
}

async function oldSession(sessionID: string, ageDays: number) {
  const path = sessionFile(sessionID);
  await mkdir(join(path, ".."), { recursive: true });
  await writeFile(path, "fixture");
  const date = new Date(Date.now() - ageDays * 24 * 60 * 60 * 1000);
  await utimes(path, date, date);
}

async function contextText(ctx: ReturnType<typeof fakeContext>): Promise<string> {
  const event = { system: [] as Array<{ type: string; text: string }> };
  await ctx.hooks.get("context")!(event);
  expect(event.system.length).toBeLessThanOrEqual(2);
  return event.system.map((part) => part.text).join("\n");
}

async function repairError() {
  const palace = join(home, ".mempalace", "palace");
  await mkdir(palace, { recursive: true });
  await writeFile(join(palace, "repair-error.log"), "Fixture rebuild failure");
}
