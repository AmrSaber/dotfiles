import { afterEach, beforeEach, expect, spyOn, test } from "bun:test";
import { mkdtemp, rm } from "node:fs/promises";
import * as os from "node:os";
import plugin from "../plugins/mempalace";

const keys = ["HOME", "MEMPALACE_HOOKS_AUTO_SAVE"];
let saved: Record<string, string | undefined>;
let root: string;
let homeMock: ReturnType<typeof spyOn>;
let cleanup: (() => Promise<void>) | undefined;

beforeEach(async () => {
  saved = Object.fromEntries(keys.map((key) => [key, process.env[key]]));
  root = await mkdtemp("/tmp/opencode/mempalace-integration-");
  process.env.HOME = root;
  process.env.MEMPALACE_HOOKS_AUTO_SAVE = "false";
  homeMock = spyOn(os, "homedir").mockReturnValue(root);
});

afterEach(async () => {
  try {
    await cleanup?.();
  } finally {
    cleanup = undefined;
    homeMock?.mockRestore();
    for (const key of keys) {
      if (saved[key] === undefined) delete process.env[key];
      else process.env[key] = saved[key];
    }
    await rm(root, { recursive: true, force: true });
  }
});

test("one plugin retains memory routing, tool filtering, capture hooks, and cleanup", async () => {
  const fixture = context();
  cleanup = await plugin.setup(fixture.ctx as any) as () => Promise<void>;
  expect(plugin.id).toBe("mempalace");
  expect(fixture.hooks.get("context")).toHaveLength(1);
  expect(fixture.hooks.get("compaction")).toHaveLength(1);

  const event = { system: [] as Array<{ text: string }> };
  for (const hook of fixture.hooks.get("context")!) await hook(event);
  const text = event.system.map((part) => part.text).join("\n");
  expect(text).toContain("MemPalace Memory Protocol");
  expect(text).not.toContain("mempalace-kg-entities");
  expect(text).not.toMatch(/organic/i);

  const tools = { list: () => [{ id: "mempalace_mempalace_kg_add" }, { id: "mempalace_mempalace_add_drawer" }, { id: "mempalace_mempalace_search" }], remove: (id: string) => fixture.removed.push(id) };
  fixture.toolTransforms[0](tools);
  expect(fixture.removed).toEqual(["mempalace_mempalace_kg_add", "mempalace_mempalace_add_drawer"]);

  await fixture.hooks.get("compaction")![0]({ sessionID: "fixture" });
  expect(fixture.contextReads).toBe(0);
  await cleanup();
  cleanup = undefined;
  expect(fixture.disposals).toBe(3);
  expect(fixture.signal?.aborted).toBe(true);
});

test("a failed tool registration cleans up memory hooks and capture subscription", async () => {
  const fixture = context();
  fixture.ctx.tool.transform = async () => { throw new Error("fixture tool failure"); };
  await expect(plugin.setup(fixture.ctx)).rejects.toThrow("fixture tool failure");
  expect(fixture.signal?.aborted).toBe(true);
  expect(fixture.disposals).toBe(2);
});

test("a failed compaction registration never starts a capture subscription", async () => {
  const fixture = context();
  const original = fixture.ctx.session.hook;
  fixture.ctx.session.hook = async (name: string, hook: any) => {
    if (name === "compaction") throw new Error("fixture hook failure");
    return original(name, hook);
  };
  await expect(plugin.setup(fixture.ctx)).rejects.toThrow("fixture hook failure");
  expect(fixture.signal).toBeUndefined();
  expect(fixture.disposals).toBe(1);
});

function context() {
  const hooks = new Map<string, Array<(event: any) => Promise<void>>>();
  const fixture = {
    hooks,
    removed: [] as string[],
    toolTransforms: [] as Array<(tools: any) => void>,
    disposals: 0,
    contextReads: 0,
    signal: undefined as AbortSignal | undefined,
    ctx: {} as any,
  };
  const registration = () => ({ dispose: async () => { fixture.disposals++; } });
  fixture.ctx = {
    tool: { transform: async (callback: any) => { fixture.toolTransforms.push(callback); return registration(); } },
    session: {
      hook: async (name: string, hook: any) => { hooks.set(name, [...(hooks.get(name) ?? []), hook]); return registration(); },
      context: async () => { fixture.contextReads++; return []; },
    },
    event: {
      subscribe: async function* ({ signal }: { signal: AbortSignal }) {
        fixture.signal = signal;
        // A live stream stays open until the plugin unloads.
        if (!signal.aborted) await new Promise<void>((resolve) => signal.addEventListener("abort", () => resolve(), { once: true }));
      },
    },
  };
  return fixture;
}
