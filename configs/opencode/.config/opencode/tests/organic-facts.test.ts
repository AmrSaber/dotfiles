import { afterEach, describe, expect, spyOn, test } from "bun:test";
import { chmod, mkdir, mkdtemp, readFile, rm, symlink, writeFile } from "node:fs/promises";
import * as os from "node:os";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { LOCKING_MCP_TOOLS, registerOrganicFacts, factsDirectory, miningDirectories, topicRooms } from "../plugins/mempalace/organic-facts";

const fixtures: string[] = [];
const originalDirectory = process.env.ORGANIC_FACTS_DIR;

afterEach(async () => {
  if (originalDirectory === undefined) delete process.env.ORGANIC_FACTS_DIR;
  else process.env.ORGANIC_FACTS_DIR = originalDirectory;
  await Promise.all(fixtures.splice(0).map((path) => rm(path, { recursive: true, force: true })));
});

async function fixture() {
  const root = await mkdtemp("/tmp/opencode/organic-facts-plugin-");
  fixtures.push(root);
  return root;
}

async function document(root: string, path: string) {
  const file = join(root, path);
  await mkdir(join(file, ".."), { recursive: true });
  await writeFile(file, "# A topic\n\n[source: inspected fixture — 2026-11-04]\n\nA sufficiently long, sourced fixture assertion.\n");
  return file;
}

test("the stowed single-file entrypoint imports its sibling modules", async () => {
  const deployed = await fixture();
  const source = fileURLToPath(new URL("../plugins/mempalace.ts", import.meta.url));
  const entrypoint = join(deployed, "mempalace.ts");
  await symlink(source, entrypoint);
  const { default: plugin } = await import(pathToFileURL(entrypoint).href);
  expect(plugin.id).toBe("mempalace");
  expect(typeof plugin.setup).toBe("function");
});

describe("organic facts directory", () => {
  test("defaults to the home directory and honors an absolute override", () => {
    expect(factsDirectory({}, "/example/home")).toBe("/example/home/.organic-facts");
    expect(factsDirectory({ ORGANIC_FACTS_DIR: "/example/notes/facts" })).toBe("/example/notes/facts");
    expect(factsDirectory({ ORGANIC_FACTS_DIR: "~/notes/facts" }, "/example/home")).toBe("/example/home/notes/facts");
    expect(() => factsDirectory({ ORGANIC_FACTS_DIR: "relative/facts" })).toThrow("absolute");
  });

  test("catalogues document directories, not hidden or symlinked trees", async () => {
    const root = await fixture();
    const outside = await fixture();
    await document(root, "Projects/Atlas/architecture.md");
    await document(root, "Tools/Editor/memory.MD");
    await document(root, "overview.md");
    await document(root, ".private/hidden.md");
    await document(outside, "outside.md");
    await symlink(outside, join(root, "linked"));
    expect(await topicRooms(root)).toEqual([".", "Projects/Atlas", "Tools/Editor"]);
    expect(await topicRooms(join(root, "not-created"))).toEqual([]);
  });
});

describe("mining input", () => {
  test("deduplicates parent directories and overlapping trees", async () => {
    const root = await fixture();
    await document(root, "Projects/overview.md");
    await document(root, "Projects/Atlas/architecture.md");
    await document(root, "Projects/Atlas/ownership.md");
    await document(root, "Tools/editor.md");
    expect(await miningDirectories(root, ["Projects/Atlas/architecture.md", "Projects/Atlas/ownership.md", "Projects/overview.md", "Tools/editor.md"])).toEqual([join(root, "Projects"), join(root, "Tools")]);
  });

  test("rejects absolute paths, traversal, missing files, directories, and non-Markdown", async () => {
    const root = await fixture();
    await document(root, "valid.md");
    await writeFile(join(root, "text.txt"), "text");
    await mkdir(join(root, "directory.md"));
    await document(root, ".private.md");
    for (const path of [join(root, "valid.md"), "../valid.md", "a/../valid.md", "missing.md", "text.txt", "directory.md", "nul\0.md", ".private.md"]) {
      await expect(miningDirectories(root, ["valid.md", path])).rejects.toThrow();
    }
    await expect(miningDirectories(root, [])).rejects.toThrow();
  });

  test("rejects symlink escapes and accepts canonical links inside the root", async () => {
    const root = await fixture();
    const outside = await fixture();
    await document(outside, "secret.md");
    await symlink(outside, join(root, "escape"));
    await symlink(join(outside, "secret.md"), join(root, "escape.md"));
    await expect(miningDirectories(root, ["escape/secret.md"])).rejects.toThrow("escapes");
    await expect(miningDirectories(root, ["escape.md"])).rejects.toThrow("escapes");
    await document(root, "Projects/inside.md");
    await symlink(join(root, "Projects/inside.md"), join(root, "inside.md"));
    expect(await miningDirectories(root, ["inside.md"])).toEqual([join(root, "Projects")]);
  });
});

test("plugin registers an on-demand skill, keeps the primer minimal, and disposes registrations", async () => {
  const root = await fixture();
  process.env.ORGANIC_FACTS_DIR = root;
  let hook: any;
  let tool: any;
  let skill: any;
  let disposals = 0;
  const cleanup = await registerOrganicFacts({
    skill: { transform: async (callback: any) => {
      callback({ add: (definition: any) => { skill = definition; } });
      return { dispose: async () => { disposals++; } };
    } },
    session: { hook: async (_name: string, callback: any) => {
      hook = callback;
      return { dispose: async () => { disposals++; } };
    } },
    tool: { transform: async (callback: any) => {
      callback({ add: (definition: any) => { tool = definition; }, list: () => [], remove: () => {} });
      return { dispose: async () => { disposals++; } };
    } },
  } as any);
  expect(tool.name).toBe("organic_facts_mine");
  expect(tool.input.properties.documents.minItems).toBe(1);
  expect(skill.id).toBe("organic-facts");
  expect(skill.description).toContain("updating");
  expect(skill.autoinvoke).not.toBe(false);
  expect(skill.path.endsWith("/plugins/mempalace/organic-facts.ts")).toBe(true);
  expect(skill.content).toContain("## Cite each information block");
  expect(skill.content).toContain("small, sparse, durable facts unlikely to change in MemPalace's knowledge graph (KG)");
  expect(skill.content).toContain("as facts, not just pointers");
  expect(skill.content).toContain("richer, evolving project knowledge in organic facts");
  expect(skill.content).toContain("don't create notes for isolated facts");
  expect(skill.content).toContain("create useful project groups and focused topics proactively");
  expect(skill.content).toContain("no separate organization request is needed");
  expect(skill.content).toContain("This skill grants no additional write permission");
  expect(skill.content).toContain("Permissions, read-only requests, and stop requests still apply");
  expect(skill.content).toContain("non-obvious knowledge that saves meaningful investigation");
  expect(skill.content).toContain("Skip obvious, trivial, or easily derived facts");
  expect(skill.content).toContain("don't create or keep a topic note");
  expect(skill.content).toContain("After a batch of manual edits");
  expect(skill.content).toContain("Preview cleanup before applying it");
  const first = { system: [] as any[] };
  await hook(first);
  expect(first.system[0].text).toContain("None yet");
  expect(first.system[0].text).not.toContain("Cite each information block");
  expect(first.system[0].text).not.toContain("After a batch of manual edits");
  expect(first.system[0].text).not.toContain("mempalace.yaml");
  expect(first.system[0].text).toContain("Read the original document");
  expect(first.system[0].text).toContain("ordinary file tools");
  expect(first.system[0].text).toContain("Load the organic-facts skill");
  expect(first.system[0].text).toContain("Keep facts up-to-date");
  expect(first.system[0].text).toContain("Small, sparse, durable facts unlikely to change belong in MemPalace's knowledge graph (KG)");
  expect(first.system[0].text).toContain("as facts, not just pointers");
  expect(first.system[0].text).toContain("Organic facts hold richer project knowledge that evolves");
  expect(first.system[0].text).toContain("add relevant knowledge and useful project groups proactively");
  expect(first.system[0].text).toContain("no separate organization request is needed");
  expect(first.system[0].text).toContain("Respect permissions, read-only requests, and requests to stop");
  expect(first.system[0].text).toContain("omit obvious or easily derived facts");
  expect(first.system[0].text.split(/\s+/).length).toBeLessThan(200);
  await document(root, "Projects/Atlas/architecture.md");
  const second = { system: [] as any[] };
  await hook(second);
  expect(second.system[0].text).toContain("Projects/Atlas");
  expect(second.system[0].text).toContain("Projects-Atlas-");
  expect(second.system).toHaveLength(1);
  await cleanup!();
  expect(disposals).toBe(3);
});

const permissionlessContext = (signal = new AbortController().signal) =>
  ({ sessionID: "session", agent: "agent", messageID: "message", id: "call", signal, progress: async () => {} });

async function register(root: string, actions: string[] = [], location = root) {
  process.env.ORGANIC_FACTS_DIR = root;
  let tool: any;
  await registerOrganicFacts({
    location: { directory: location },
    skill: { transform: async () => ({ dispose: async () => {} }) },
    session: { hook: async () => ({ dispose: async () => {} }) },
    permission: { assert: async (input: any) => { actions.push(input.action); } },
    tool: { transform: async (callback: any) => {
      callback({ add: (definition: any) => { tool = definition; }, list: () => [], remove: () => {} });
      return { dispose: async () => {} };
    } },
  } as any);
  return tool;
}

describe("out-of-process mining", () => {
  // A stub `mempalace` on PATH records its arguments; HOME is scratch so nothing real is touched.
  async function stub(script = 'echo "stub mined $2"') {
    const bin = await fixture();
    await writeFile(join(bin, "mempalace"), `#!/bin/sh\necho "$@" >> "${bin}/calls.log"\n${script}\n`);
    await chmod(join(bin, "mempalace"), 0o755);
    return bin;
  }

  async function withEnvironment<T>(bin: string, home: string, run: () => Promise<T>) {
    const savedPath = process.env.PATH;
    process.env.PATH = `${bin}:${savedPath}`;
    const homeMock = spyOn(os, "homedir").mockReturnValue(home);
    try { return await run(); } finally {
      process.env.PATH = savedPath;
      homeMock.mockRestore();
    }
  }

  test("mines each directory through the mempalace CLI under the sweeper's lock, with no MCP tool", async () => {
    const root = await fixture();
    const home = await fixture();
    await document(root, "Projects/Atlas/architecture.md");
    const bin = await stub();
    const actions: string[] = [];
    const tool = await register(root, actions);
    const result = await withEnvironment(bin, home, () => tool.execute({ documents: ["Projects/Atlas/architecture.md"] }, permissionlessContext()));
    expect(result.content).toContain("stub mined");
    expect(result.content).toContain(`Source: ${join(root, "Projects/Atlas")}`);
    expect(await readFile(join(bin, "calls.log"), "utf8")).toBe(`mine ${join(root, "Projects/Atlas")} --mode projects --wing organic-facts\n`);
    expect(actions).toEqual(["edit"]);
    await expect(readFile(join(root, "Projects/Atlas/mempalace.yaml"))).rejects.toThrow();
  });

  test("the miner sees the generated routing file while it runs", async () => {
    const root = await fixture();
    const home = await fixture();
    await document(root, "topic.md");
    const bin = await stub('cat "$2/mempalace.yaml" >> "' + "$BIN" + '/seen.log"');
    await writeFile(join(bin, "mempalace"), (await readFile(join(bin, "mempalace"), "utf8")).replace("$BIN", bin));
    const tool = await register(root);
    await withEnvironment(bin, home, () => tool.execute({ documents: ["topic.md"] }, permissionlessContext()));
    const seen = JSON.parse(await readFile(join(bin, "seen.log"), "utf8"));
    expect(seen).toMatchObject({ _organic_facts: 1, wing: "organic-facts" });
    await expect(readFile(join(root, "mempalace.yaml"))).rejects.toThrow();
  });

  test("a held palace lock is retried, then reported when it never frees", async () => {
    const root = await fixture();
    const home = await fixture();
    await document(root, "topic.md");
    const bin = await stub('echo "mempalace: palace /p is held by PID 1 (-); wait for it to finish" ; exit 1');
    const tool = await register(root);
    const saved = process.env.MP_RETRY_BASE;
    process.env.MP_RETRY_BASE = "0";
    try {
      await expect(withEnvironment(bin, home, () => tool.execute({ documents: ["topic.md"] }, permissionlessContext()))).rejects.toThrow(/Mining failed.*held by PID 1/s);
    } finally {
      if (saved === undefined) delete process.env.MP_RETRY_BASE; else process.env.MP_RETRY_BASE = saved;
    }
    expect((await readFile(join(bin, "calls.log"), "utf8")).trim().split("\n")).toHaveLength(5);
    await expect(readFile(join(root, "mempalace.yaml"))).rejects.toThrow();
  });

  test("a non-lock failure is reported at once without retrying", async () => {
    const root = await fixture();
    const home = await fixture();
    await document(root, "topic.md");
    const bin = await stub('echo "boom: embedding model missing"; exit 2');
    const tool = await register(root);
    await expect(withEnvironment(bin, home, () => tool.execute({ documents: ["topic.md"] }, permissionlessContext()))).rejects.toThrow(/boom: embedding model missing/);
    expect((await readFile(join(bin, "calls.log"), "utf8")).trim().split("\n")).toHaveLength(1);
  });

  test("a mine waits for a running sweep to release the shared lock", async () => {
    const root = await fixture();
    const home = await fixture();
    await document(root, "topic.md");
    const bin = await stub();
    const sessions = join(home, ".mempalace", "opencode-sessions");
    await mkdir(sessions, { recursive: true });
    const holder = Bun.spawn(["flock", join(sessions, "sweep.lock"), "sleep", "2"]);
    await Bun.sleep(300);
    const tool = await register(root);
    const started = Date.now();
    await withEnvironment(bin, home, () => tool.execute({ documents: ["topic.md"] }, permissionlessContext()));
    expect(Date.now() - started).toBeGreaterThan(1000);
    await holder.exited;
  });

  test("captures that lost the lock race during a mine are swept afterwards", async () => {
    const root = await fixture();
    const home = await fixture();
    await document(root, "topic.md");
    const bin = await stub();
    const sessions = join(home, ".mempalace", "opencode-sessions");
    await mkdir(sessions, { recursive: true });
    await writeFile(join(sessions, "sweep.dirty"), "");
    const tool = await register(root);
    await withEnvironment(bin, home, () => tool.execute({ documents: ["topic.md"] }, permissionlessContext()));
    expect((await readFile(join(bin, "calls.log"), "utf8")).trim().split("\n")).toEqual([
      `mine ${root} --mode projects --wing organic-facts`,
      `sweep ${sessions}`,
    ]);
    await expect(readFile(join(sessions, "sweep.dirty"))).rejects.toThrow();
  });
});

test("every palace-locking MCP tool is removed, and tools that take no lock are kept", async () => {
  const root = await fixture();
  process.env.ORGANIC_FACTS_DIR = root;
  // Real tool IDs are the MCP server name plus the tool name, which already starts with "mempalace_".
  const lockingIds = LOCKING_MCP_TOOLS.map((name) => `mempalace_${name}`);
  const present = [...lockingIds, "mempalace_mempalace_search", "mempalace_mempalace_kg_add", "mempalace_mempalace_status", "read"];
  const removed: string[] = [];
  await registerOrganicFacts({
    skill: { transform: async () => ({ dispose: async () => {} }) },
    session: { hook: async () => ({ dispose: async () => {} }) },
    tool: { transform: async (callback: any) => {
      callback({ add: () => {}, list: () => present.map((id) => ({ id })), remove: (id: string) => removed.push(id) });
      return { dispose: async () => {} };
    } },
  } as any);
  expect(removed.sort()).toEqual(lockingIds.sort());
  expect(LOCKING_MCP_TOOLS).toHaveLength(12);
  expect(removed).not.toContain("mempalace_mempalace_kg_add");
});
