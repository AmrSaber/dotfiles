import { afterEach, expect, test } from "bun:test";
import { mkdir, mkdtemp, rm, symlink, writeFile } from "node:fs/promises";
import { join } from "node:path";
import plugin, { factsDirectory, listFacts, renderCatalogue } from "../plugins/organic-facts";

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

async function write(root: string, path: string, content: string) {
  await mkdir(join(root, path, ".."), { recursive: true });
  await writeFile(join(root, path), content);
}

test("facts directory defaults to the home directory and honors an absolute or ~/ override", () => {
  expect(factsDirectory({}, "/example/home")).toBe("/example/home/.organic-facts");
  expect(factsDirectory({ ORGANIC_FACTS_DIR: "/example/notes/facts" })).toBe("/example/notes/facts");
  expect(factsDirectory({ ORGANIC_FACTS_DIR: "~/notes/facts" }, "/example/home")).toBe("/example/home/notes/facts");
  expect(() => factsDirectory({ ORGANIC_FACTS_DIR: "relative/facts" })).toThrow("absolute");
});

test("lists Markdown files with their descriptions, skipping hidden entries and symlinks", async () => {
  const root = await fixture();
  const outside = await fixture();
  await write(root, "Tools/Editor/memory.md", '---\ndescription: "When configuring the editor: keymaps."\ncreated-at: x\n---\n# Body\n');
  await write(root, "overview.MD", "---\ndescription: >-\n  Folded\n  text.\n---\n");
  await write(root, "bare.md", "# No front-matter\n");
  await write(root, "empty-description.md", "---\nother: 1\n---\n");
  await write(root, "colon.md", "---\ndescription: Unquoted text: with a colon.\n---\n");
  await write(root, "notes.txt", "ignored");
  await write(root, ".private/hidden.md", "---\ndescription: hidden\n---\n");
  await write(outside, "outside.md", "---\ndescription: outside\n---\n");
  await symlink(outside, join(root, "linked"));

  expect(await listFacts(root)).toEqual([
    { path: join(root, "bare.md"), description: undefined },
    { path: join(root, "colon.md"), description: "Unquoted text: with a colon." },
    { path: join(root, "empty-description.md"), description: undefined },
    { path: join(root, "overview.MD"), description: "Folded text." },
    { path: join(root, "Tools/Editor/memory.md"), description: "When configuring the editor: keymaps." },
  ]);
  expect(await listFacts(join(root, "not-created"))).toEqual([]);
});

test("the catalogue lists full paths, flags missing descriptions, and shows a placeholder when empty", () => {
  const text = renderCatalogue("/facts", [
    { path: "/facts/a.md", description: "When doing A." },
    { path: "/facts/b.md" },
  ]);
  expect(text).toContain("- /facts/a.md — When doing A.");
  expect(text).toMatch(/- \/facts\/b\.md — NO FRONT-MATTER DESCRIPTION/);

  const empty = renderCatalogue("/facts", []);
  expect(empty).toContain("No facts yet");
  expect(empty).toContain("/facts");
  expect(empty).toContain("user preferences");
});

test("the context hook pushes instructions first and a fresh catalogue second", async () => {
  const root = await fixture();
  process.env.ORGANIC_FACTS_DIR = root;
  let hook: ((event: any) => Promise<void>) | undefined;
  let disposed = false;
  const cleanup = await plugin.setup({
    session: { hook: async (_name: string, callback: any) => ((hook = callback), { dispose: async () => void (disposed = true) }) },
  });

  const run = async () => {
    const event = { system: [] as Array<{ text: string }> };
    await hook!(event);
    return event.system.map((part) => part.text);
  };
  const [instructions, empty] = await run();
  expect(instructions).toContain("nearly self-contained");
  expect(instructions).toContain("Add a new file only when");
  expect(instructions).toContain("must not contain facts");
  expect(empty).toContain("No facts yet");

  await write(root, "Topic/fact.md", "---\ndescription: When topic matters.\n---\n");
  expect((await run())[1]).toContain(`- ${join(root, "Topic/fact.md")} — When topic matters.`);

  process.env.ORGANIC_FACTS_DIR = "relative";
  expect((await run())[1]).toContain("catalogue is unavailable");

  await cleanup();
  expect(disposed).toBe(true);
});
