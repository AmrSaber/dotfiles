import { afterEach, beforeEach, expect, spyOn, test } from "bun:test";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import * as os from "node:os";
import { join } from "node:path";
import plugin from "../plugins/mempalace";

const keys = ["HOME", "ORGANIC_FACTS_DIR", "MEMPALACE_HOOKS_AUTO_SAVE", "MEMPALACE_INJECT_ENTITIES"];
const originalShell = Bun.$;
let saved: Record<string, string | undefined>;
let root: string;
let homeMock: ReturnType<typeof spyOn>;
let cleanup: (() => Promise<void>) | undefined;

beforeEach(async () => {
  saved = Object.fromEntries(keys.map((key) => [key, process.env[key]]));
  root = await mkdtemp("/tmp/opencode/mempalace-integration-");
  process.env.HOME = root;
  process.env.ORGANIC_FACTS_DIR = join(root, "facts");
  process.env.MEMPALACE_HOOKS_AUTO_SAVE = "false";
  delete process.env.MEMPALACE_INJECT_ENTITIES;
  homeMock = spyOn(os, "homedir").mockReturnValue(root);
  Bun.$ = (() => ({
    quiet() { return this; },
    async nothrow() { return { exitCode: 0, stdout: Buffer.from("Atlas\n") }; },
  })) as any;
  await mkdir(join(root, "facts", "Projects", "Atlas"), { recursive: true });
  await writeFile(join(root, "facts", "Projects", "Atlas", "architecture.md"), "# Architecture\n");
});

afterEach(async () => {
  try {
    await cleanup?.();
  } finally {
    cleanup = undefined;
    Bun.$ = originalShell;
    homeMock?.mockRestore();
    for (const key of keys) {
      if (saved[key] === undefined) delete process.env[key];
      else process.env[key] = saved[key];
    }
    await rm(root, { recursive: true, force: true });
  }
});

test("one plugin retains memory routing, organic facts, capture hooks, and cleanup", async () => {
  const fixture = context();
  cleanup = await plugin.setup(fixture.ctx as any) as () => Promise<void>;
  expect(plugin.id).toBe("mempalace");
  expect(fixture.skills.map((skill) => skill.id)).toEqual(["organic-facts"]);
  expect(fixture.tools.map((tool) => tool.name)).toEqual(["organic_facts_mine"]);
  expect(fixture.hooks.get("context")).toHaveLength(2);
  expect(fixture.hooks.get("compaction")).toHaveLength(1);

  const event = { system: [] as Array<{ text: string }> };
  for (const hook of fixture.hooks.get("context")!) await hook(event);
  const text = event.system.map((part) => part.text).join("\n");
  expect(text).toContain("MemPalace Memory Protocol");
  expect(text).toContain("<mempalace-kg-entities>");
  expect(text).toContain("Projects/Atlas");
  expect(text).toContain("Load the organic-facts skill");
  expect(text).not.toContain("Cite each information block");
  expect(fixture.skills[0].content).toContain("Cite each information block");

  await fixture.hooks.get("compaction")![0]({ sessionID: "fixture" });
  expect(fixture.contextReads).toBe(0);
  await cleanup();
  cleanup = undefined;
  expect(fixture.disposals).toBe(5);
  expect(fixture.signal?.aborted).toBe(true);
});

test("an invalid facts directory does not remove memory guidance or capture hooks", async () => {
  process.env.ORGANIC_FACTS_DIR = "invalid/relative/path";
  const fixture = context();
  cleanup = await plugin.setup(fixture.ctx as any) as () => Promise<void>;
  const event = { system: [] as Array<{ text: string }> };
  for (const hook of fixture.hooks.get("context")!) await hook(event);
  const text = event.system.map((part) => part.text).join("\n");
  expect(text).toContain("MemPalace Memory Protocol");
  expect(text).toContain("Organic facts catalogue unavailable");
  expect(fixture.hooks.get("compaction")).toHaveLength(1);
  expect(fixture.tools).toHaveLength(1);
});

test("a failed facts registration cleans up memory hooks and capture subscription", async () => {
  const fixture = context();
  fixture.ctx.skill.transform = async () => { throw new Error("fixture skill failure"); };
  await expect(plugin.setup(fixture.ctx)).rejects.toThrow("fixture skill failure");
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
    skills: [] as any[],
    tools: [] as any[],
    disposals: 0,
    contextReads: 0,
    signal: undefined as AbortSignal | undefined,
    ctx: {} as any,
  };
  const registration = () => ({ dispose: async () => { fixture.disposals++; } });
  fixture.ctx = {
    skill: { transform: async (callback: any) => { callback({ add: (skill: any) => fixture.skills.push(skill) }); return registration(); } },
    tool: { transform: async (callback: any) => { callback({ add: (tool: any) => fixture.tools.push(tool), list: () => [], remove: () => {} }); return registration(); } },
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
