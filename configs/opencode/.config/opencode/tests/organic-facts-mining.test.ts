import { afterEach, describe, expect, spyOn, test } from "bun:test";
import { createHash } from "node:crypto";
import * as fs from "node:fs/promises";
import { mkdir, mkdtemp, readFile, readdir, rm, stat, symlink, utimes, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { mineDirectories as mineWithPermission, roomName } from "../plugins/mempalace/mining";

function mineDirectories(root: string, directories: string[], mine: Parameters<typeof mineWithPermission>[2]) {
  return mineWithPermission(root, directories, mine, async () => {});
}

const fixtures: string[] = [];
afterEach(async () => {
  await Promise.all(fixtures.splice(0).map((fixture) => rm(fixture, { recursive: true, force: true })));
});

async function fixture(): Promise<string> {
  const root = await mkdtemp("/tmp/opencode/organic-facts-mining-");
  fixtures.push(root);
  return root;
}

async function document(root: string, path: string, content = "# Generic fact\n"): Promise<string> {
  const source = join(root, path);
  await mkdir(join(source, ".."), { recursive: true });
  await writeFile(source, content);
  return source;
}

function success(output = "Mined generic facts.") {
  return { content: JSON.stringify({ success: true, output }) };
}

async function config(source: string) {
  return JSON.parse(await readFile(join(source, "mempalace.yaml"), "utf8"));
}

describe("mineDirectories", () => {
  test("mines whole selected trees, including sibling Markdown and nested rooms", async () => {
    const root = await fixture();
    const alpha = await document(root, "Projects/Atlas/alpha.md");
    const sibling = await document(root, "Projects/Atlas/unlisted.MD");
    const nested = await document(root, "Projects/Atlas/Design/details.md");
    await document(root, "Projects/Atlas/ignored.txt");
    await document(root, "Projects/Other/outside.md");
    const selected = join(root, "Projects/Atlas");
    const calls: string[] = [];
    const summary = await mineDirectories(root, [selected], async (source) => {
      calls.push(source);
      const settings = await config(source);
      expect(settings).toEqual({
        _organic_facts: 1,
        wing: "organic-facts",
        rooms: [{ name: roomName(source.slice(root.length + 1)), keywords: [""] }],
        exclude_patterns: ["*", "!*.[mM][dD]", "*/", ".*"],
      });
      return success(`Native output for ${source}`);
    });
    expect(calls).toEqual([selected, join(selected, "Design")]);
    for (const source of calls) {
      expect(summary).toContain(`Source: ${source}`);
      expect(summary).toContain(`Room: ${roomName(source.slice(root.length + 1))}`);
      expect(summary).toContain(`Native output for ${source}`);
    }
    for (const path of [alpha, sibling, nested]) expect(await readFile(path, "utf8")).toBe("# Generic fact\n");
  });

  test("collapses overlapping selections and duplicate directories", async () => {
    const root = await fixture();
    await document(root, "parent/a.md");
    await document(root, "parent/child/b.md");
    const parent = join(root, "parent");
    const child = join(parent, "child");
    const calls: string[] = [];
    await mineDirectories(root, [child, parent, parent, child], async (source) => {
      calls.push(source);
      return success();
    });
    expect(calls).toEqual([parent, child]);
  });

  test("ignores hidden paths, text-only directories, and symlink files or directories", async () => {
    const root = await fixture();
    const outside = await fixture();
    await document(outside, "private.md");
    await document(root, "visible.md");
    await document(root, ".hidden.md");
    await document(root, ".hidden/notes.md");
    await document(root, "text/notes.txt");
    await symlink(outside, join(root, "escape"));
    await symlink(join(outside, "private.md"), join(root, "linked.md"));
    await mkdir(join(root, "links"));
    await symlink(join(root, "visible.md"), join(root, "links/copy.md"));
    const calls: string[] = [];
    await mineDirectories(root, [root], async (source) => {
      calls.push(source);
      return success();
    });
    expect(calls).toEqual([root]);
    expect((await config(root)).rooms[0].name).toBe("general");
    expect((await config(root)).exclude_patterns).toEqual(["*", "!*.[mM][dD]", "*/", ".*"]);
    expect(await readFile(join(outside, "private.md"), "utf8")).toBe("# Generic fact\n");
    await expect(readFile(join(outside, "mempalace.yaml"))).rejects.toThrow();
    await expect(readFile(join(root, "text/mempalace.yaml"))).rejects.toThrow();
  });

  test("rejects selected symlink escapes and sibling paths before writing", async () => {
    const root = await fixture();
    const outside = await fixture();
    await document(root, "safe.md");
    await document(outside, "outside.md");
    await symlink(outside, join(root, "escape"));
    let calls = 0;
    for (const selected of [join(root, "escape"), outside]) {
      await expect(mineDirectories(root, [root, selected], async () => {
        calls++;
        return success();
      })).rejects.toThrow("escapes the facts root");
    }
    expect(calls).toBe(0);
    await expect(readFile(join(root, "mempalace.yaml"))).rejects.toThrow();
  });

  test("rejects selected hidden directories and internal symlink aliases", async () => {
    const root = await fixture();
    await document(root, ".hidden/a.md");
    await document(root, "visible/a.md");
    await symlink(join(root, "visible"), join(root, "alias"));
    await expect(mineDirectories(root, [join(root, ".hidden")], async () => success())).rejects.toThrow("Hidden");
    await expect(mineDirectories(root, [join(root, "alias")], async () => success())).rejects.toThrow("symlink");
  });

  for (const name of ["mempalace.yaml", "mempalace.yml", "mempal.yaml", "mempal.yml"]) {
    test(`refuses user ${name} before any mining or config writes`, async () => {
      const root = await fixture();
      await document(root, "first/a.md");
      await document(root, "last/b.md");
      const original = "wing: user-project\n";
      await document(root, `last/${name}`, original);
      let calls = 0;
      await expect(mineDirectories(root, [root], async () => {
        calls++;
        return success();
      })).rejects.toThrow("Refusing existing project config");
      expect(calls).toBe(0);
      expect(await readFile(join(root, "last", name), "utf8")).toBe(original);
      await expect(readFile(join(root, "first/mempalace.yaml"))).rejects.toThrow();
    });
  }

  test("refuses a symlink config without touching its target", async () => {
    const root = await fixture();
    const outside = await fixture();
    await document(root, "a.md");
    const target = await document(outside, "user.yaml", "wing: user-project\n");
    await symlink(target, join(root, "mempalace.yaml"));
    let calls = 0;
    await expect(mineDirectories(root, [root], async () => {
      calls++;
      return success();
    })).rejects.toThrow("Refusing existing project config");
    expect(calls).toBe(0);
    expect(await readFile(target, "utf8")).toBe("wing: user-project\n");
  });

  test("reconstructs owned configs to reroute rooms and remove stale settings", async () => {
    const root = await fixture();
    await document(root, "Projects/Atlas/a.md");
    const source = join(root, "Projects/Atlas");
    await document(source, "mempalace.yaml", JSON.stringify({ _organic_facts: 1, wing: "old", rooms: [{ name: "old" }], stale: true }));
    await mineDirectories(root, [source], async () => success());
    const settings = await config(source);
    expect(settings.wing).toBe("organic-facts");
    expect(settings.rooms).toEqual([{ name: roomName("Projects/Atlas"), keywords: [""] }]);
    expect(settings.stale).toBeUndefined();
  });

  test("checks permission for every discovered source before any writes or mining", async () => {
    const root = await fixture();
    await document(root, "root.md");
    await document(root, "topic/a.md");
    await document(root, "topic/nested/b.MD");
    const targets = [root, join(root, "topic"), join(root, "topic/nested")];
    let calls = 0;
    let permissions = 0;
    await expect(mineWithPermission(root, [root, join(root, "topic")], async () => {
      calls++;
      return success();
    }, async (sources) => {
      permissions++;
      expect(sources).toEqual(targets);
      for (const source of sources) await expect(readFile(join(source, "mempalace.yaml"))).rejects.toThrow();
      throw new Error("Permission denied.");
    })).rejects.toThrow("Permission denied.");
    expect(permissions).toBe(1);
    expect(calls).toBe(0);
    for (const source of targets) {
      await expect(readFile(join(source, "mempalace.yaml"))).rejects.toThrow();
      expect((await readdir(source)).filter((name) => name.startsWith(".organic-facts-"))).toEqual([]);
    }
  });

  test("finishes config preflight before asking for write permission", async () => {
    const root = await fixture();
    await document(root, "a.md");
    await document(root, "mempalace.yml", "wing: user-project\n");
    let permissions = 0;
    await expect(mineWithPermission(root, [root], async () => success(), async () => {
      permissions++;
    })).rejects.toThrow("Refusing existing project config");
    expect(permissions).toBe(0);
  });

  test("skips identical config writes and preserves the modification time and inode", async () => {
    const root = await fixture();
    await document(root, "a.md");
    await mineDirectories(root, [root], async () => success());
    const path = join(root, "mempalace.yaml");
    const fixedTime = new Date("2000-01-01T00:00:00Z");
    await utimes(path, fixedTime, fixedTime);
    const before = await stat(path);
    await mineDirectories(root, [root], async () => success());
    const after = await stat(path);
    expect(after.mtimeMs).toBe(before.mtimeMs);
    expect(after.ino).toBe(before.ino);
    expect((await readdir(root)).filter((name) => name.startsWith(".organic-facts-"))).toEqual([]);
  });

  test("keeps configs parseable throughout concurrent refreshes and reads", async () => {
    const root = await fixture();
    await document(root, "topic/a.md");
    const source = join(root, "topic");
    await document(source, "mempalace.yaml", JSON.stringify({ _organic_facts: 1, wing: "old" }));
    let reading = true;
    let reads = 0;
    const reader = (async () => {
      while (reading) {
        expect((await config(source))._organic_facts).toBe(1);
        reads++;
      }
    })();
    const refreshes = Promise.all(Array.from({ length: 24 }, (_, index) =>
      mineDirectories(index % 2 ? root : source, [source], async () => {
        expect((await config(source))._organic_facts).toBe(1);
        return success();
      }),
    )).finally(() => { reading = false; });
    const results = await Promise.allSettled([reader, refreshes]);
    for (const result of results) if (result.status === "rejected") throw result.reason;
    expect(reads).toBeGreaterThan(0);
    expect((await readdir(source)).filter((name) => name.startsWith(".organic-facts-"))).toEqual([]);
  });

  test("preserves the old owned config and removes its temporary file if publication fails", async () => {
    const root = await fixture();
    await document(root, "a.md");
    const old = JSON.stringify({ _organic_facts: 1, wing: "old" });
    await document(root, "mempalace.yaml", old);
    const publication = spyOn(fs, "rename").mockRejectedValueOnce(new Error("Publish failed."));
    let calls = 0;
    try {
      await expect(mineDirectories(root, [root], async () => {
        calls++;
        return success();
      })).rejects.toThrow("Publish failed.");
    } finally {
      publication.mockRestore();
    }
    expect(calls).toBe(0);
    expect(await readFile(join(root, "mempalace.yaml"), "utf8")).toBe(old);
    expect((await readdir(root)).filter((name) => name.startsWith(".organic-facts-"))).toEqual([]);
  });

  test("preserves an unrelated config that appears after the initial preflight", async () => {
    const root = await fixture();
    await document(root, "a.md");
    await document(root, "mempalace.yaml", JSON.stringify({ _organic_facts: 1, wing: "old" }));
    const userConfig = "wing: user-project\n";
    let calls = 0;
    await expect(mineWithPermission(root, [root], async () => {
      calls++;
      return success();
    }, async () => {
      await writeFile(join(root, "mempalace.yaml"), userConfig);
    })).rejects.toThrow("Refusing existing project config");
    expect(calls).toBe(0);
    expect(await readFile(join(root, "mempalace.yaml"), "utf8")).toBe(userConfig);
    expect((await readdir(root)).filter((name) => name.startsWith(".organic-facts-"))).toEqual([]);
  });

  test("revalidates config ownership immediately before atomic replacement", async () => {
    const root = await fixture();
    await document(root, "a.md");
    await document(root, "mempalace.yaml", JSON.stringify({ _organic_facts: 1, wing: "old" }));
    const userConfig = "wing: user-project\n";
    const publication = spyOn(fs, "link").mockImplementationOnce(async (_temporary, target) => {
      await writeFile(target, userConfig);
      throw Object.assign(new Error("Target already exists."), { code: "EEXIST" });
    });
    let calls = 0;
    try {
      await expect(mineDirectories(root, [root], async () => {
        calls++;
        return success();
      })).rejects.toThrow("Refusing existing project config");
    } finally {
      publication.mockRestore();
    }
    expect(calls).toBe(0);
    expect(await readFile(join(root, "mempalace.yaml"), "utf8")).toBe(userConfig);
    expect((await readdir(root)).filter((name) => name.startsWith(".organic-facts-"))).toEqual([]);
  });

  test("accepts MCP string and text-array JSON successes", async () => {
    const root = await fixture();
    await document(root, "one/a.md");
    await document(root, "two/b.md");
    let calls = 0;
    const summary = await mineDirectories(root, [root], async () => calls++ === 0
      ? success("String output.")
      : { content: [{ type: "image" }, { type: "text", text: JSON.stringify({ success: true, output: "Array output." }) }] });
    expect(summary).toContain("String output.");
    expect(summary).toContain("Array output.");
  });

  test("propagates native failure and preserves completed source outputs", async () => {
    const root = await fixture();
    await document(root, "first/a.md");
    await document(root, "second/b.md");
    await document(root, "third/c.md");
    const calls: string[] = [];
    let failure: Error | undefined;
    try {
      await mineDirectories(root, [root], async (source) => {
        calls.push(source);
        return calls.length === 1 ? success("First source completed.") : { content: JSON.stringify({ success: false, error: "Writer refused." }) };
      });
    } catch (error) {
      failure = error as Error;
    }
    expect(failure?.message).toContain("Writer refused.");
    expect(failure?.message).toContain(`Mining failed for ${join(root, "second")}`);
    expect(failure?.message).toContain(`Source: ${join(root, "first")}`);
    expect(failure?.message).toContain(`Room: ${roomName("first")}`);
    expect(failure?.message).toContain("First source completed.");
    expect(calls).toEqual([join(root, "first"), join(root, "second")]);
  });

  test("rejects refusals, malformed content, and unrecognized success shapes", async () => {
    const root = await fixture();
    await document(root, "a.md");
    for (const result of [
      {},
      { content: "Not JSON" },
      { content: JSON.stringify({ error: "Permission refused." }) },
      { content: JSON.stringify({ success: true }) },
      { content: JSON.stringify({ success: "true", output: "Not valid." }) },
    ]) {
      await expect(mineDirectories(root, [root], async () => result)).rejects.toThrow("Mining failed");
    }
  });

  test("preserves completions when the callback throws", async () => {
    const root = await fixture();
    await document(root, "first/a.md");
    await document(root, "second/b.md");
    let calls = 0;
    await expect(mineDirectories(root, [root], async () => {
      if (++calls === 2) throw new Error("Cancelled.");
      return success("First source completed.");
    })).rejects.toThrow("First source completed.");
  });

  test("returns an empty summary without invoking the miner or writing configs", async () => {
    const root = await fixture();
    await document(root, "notes.txt");
    let calls = 0;
    expect(await mineDirectories(root, [root], async () => {
      calls++;
      return success();
    })).toBe("No Markdown directories found.");
    expect(calls).toBe(0);
    await expect(readFile(join(root, "mempalace.yaml"))).rejects.toThrow();
  });
});

describe("roomName", () => {
  test("keeps readable case-sensitive slugs and a stable twelve-digit hash", () => {
    const path = "Projects/Atlas";
    const hash = createHash("sha256").update(path).digest("hex").slice(0, 12);
    expect(roomName(path)).toBe(`Projects-Atlas-${hash}`);
    expect(roomName(join("Projects", "Atlas"))).toBe(roomName(path));
    expect(roomName(path)).not.toBe(roomName("projects/atlas"));
    expect(roomName("")).toBe("general");
    expect(roomName(".")).toBe("general");
  });

  test("bounds long room names and distinguishes ambiguous path slugs", () => {
    const paths = ["A/B", "A-B", "A B", "A_B", "A/".repeat(100) + "B", "A/".repeat(100) + "C", "✦/☀"];
    const rooms = paths.map(roomName);
    expect(new Set(rooms).size).toBe(paths.length);
    for (const room of rooms) {
      expect(room.length).toBeLessThanOrEqual(128);
      expect(room).toMatch(/^[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]$/);
      expect(room).not.toContain("/");
    }
  });
});
