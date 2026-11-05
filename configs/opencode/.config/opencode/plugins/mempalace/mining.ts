import { createHash, randomUUID } from "node:crypto";
import { constants } from "node:fs";
import { link, mkdir, open, readdir, realpath, rename, rm } from "node:fs/promises";
import { dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const WING = "organic-facts";

export async function mineDirectories(
  root: string,
  directories: string[],
  mine: (source: string) => Promise<string>,
  beforeWrite: (sources: string[]) => Promise<void>,
): Promise<string> {
  root = await realpath(root);
  const selected = [...new Set(directories.map((directory) => resolve(directory)))].sort();
  for (const directory of selected) await validateDirectory(root, directory);
  const trees = selected.filter(
    (directory) => !selected.some((other) => other !== directory && contains(other, directory)),
  );
  const sources: string[] = [];
  for (const directory of trees) await collectSources(root, directory, sources);
  sources.sort();
  if (sources.length === 0) return "No Markdown directories found.";

  for (const source of sources) await preflightConfig(source);
  await beforeWrite([...sources]);

  // The configs are generated routing input only; remove them even if writing or mining fails.
  try {
    for (const source of sources) await preflightConfig(source);
    for (const source of sources) {
      await validateDirectory(root, source);
      await writeConfig(source, roomName(relative(root, source)));
    }

    const completed: string[] = [];
    for (const source of sources) {
      const room = roomName(relative(root, source));
      try {
        await validateDirectory(root, source);
        const output = await mine(source);
        completed.push(`Source: ${source}\nRoom: ${room}\n${output}`);
      } catch (error) {
        throw new Error(
          `Mining failed for ${source} (room ${room}): ${error instanceof Error ? error.message : String(error)}\n\nCompleted sources:\n${completed.join("\n\n") || "None."}`,
          { cause: error },
        );
      }
    }
    return completed.join("\n\n") || "No Markdown directories found.";
  } finally {
    await Promise.all(sources.map(removeConfig));
  }
}

// Run `mempalace mine` as its own process: the MCP mine tool would hold the palace lock until its server exits.
// The script also takes the sweeper's lock, so a mine and a sweep or repair never overlap.
export async function runMineScript(source: string, sessionsDir: string): Promise<string> {
  await mkdir(sessionsDir, { recursive: true });
  const child = Bun.spawn(["sh", join(dirname(fileURLToPath(import.meta.url)), "mempalace-mine.sh"), source], {
    env: {
      ...process.env,
      MP_WING: WING,
      MP_LOCK: join(sessionsDir, "sweep.lock"),
      MP_DIRTY: join(sessionsDir, "sweep.dirty"),
      MP_LOG: join(sessionsDir, "sweep.log"),
      MP_SESSIONS: sessionsDir,
    },
    stdout: "pipe",
    stderr: "pipe",
  });
  // A started mine runs to completion: killing it mid-write could leave a partial index.
  const [output, errors, code] = await Promise.all([
    new Response(child.stdout).text(),
    new Response(child.stderr).text(),
    child.exited,
  ]);
  if (code !== 0) throw new Error(errors.trim() || output.trim() || `mempalace-mine.sh exited ${code}`);
  return output.trim();
}

async function validateDirectory(root: string, directory: string): Promise<void> {
  const canonical = await realpath(directory);
  if (!contains(root, directory) || !contains(root, canonical) || directory !== canonical) {
    throw new Error(`Directory escapes the facts root or uses a symlink: ${directory}`);
  }
  if (relative(root, directory).split(sep).some((part) => part.startsWith("."))) {
    throw new Error(`Hidden facts directories are not mined: ${directory}`);
  }
}

function contains(root: string, directory: string): boolean {
  const path = relative(root, directory);
  return path === "" || (!isAbsolute(path) && path !== ".." && !path.startsWith(`..${sep}`));
}

async function collectSources(root: string, directory: string, sources: string[]): Promise<void> {
  await validateDirectory(root, directory);
  const entries = (await readdir(directory, { withFileTypes: true }))
    .filter((entry) => !entry.name.startsWith("."))
    .sort((a, b) => a.name < b.name ? -1 : a.name > b.name ? 1 : 0);
  if (entries.some((entry) => entry.isFile() && /\.md$/i.test(entry.name))) sources.push(directory);
  for (const entry of entries) {
    if (entry.isDirectory()) await collectSources(root, join(directory, entry.name), sources);
  }
}

async function preflightConfig(source: string): Promise<void> {
  for (const name of ["mempalace.yaml", "mempalace.yml", "mempal.yaml", "mempal.yml"]) {
    await readOwnedConfig(join(source, name));
  }
}

async function readOwnedConfig(path: string): Promise<string | undefined> {
  let file;
  try {
    file = await open(path, constants.O_RDONLY | constants.O_NOFOLLOW | constants.O_NONBLOCK);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return;
    throw new Error(`Refusing existing project config: ${path}`, { cause: error });
  }
  try {
    if ((await file.stat()).isFile()) {
      const content = await file.readFile("utf8");
      let owned = false;
      try {
        owned = JSON.parse(content)?._organic_facts === 1;
      } catch {
        owned = false;
      }
      if (owned) return content;
    }
    throw new Error(`Refusing existing project config: ${path}`);
  } finally {
    await file.close();
  }
}

async function writeConfig(source: string, room: string): Promise<void> {
  const path = join(source, "mempalace.yaml");
  const config = {
    _organic_facts: 1,
    wing: WING,
    // shortcut: an empty keyword forces native room routing; replace when mine accepts a room override.
    rooms: [{ name: room, keywords: [""] }],
    exclude_patterns: ["*", "!*.[mM][dD]", "*/", ".*"],
  };
  const content = JSON.stringify(config, null, 2) + "\n";
  if (await readOwnedConfig(path) === content) return;

  const temporary = join(source, `.organic-facts-${randomUUID()}.tmp`);
  const file = await open(temporary, "wx", 0o600);
  try {
    try {
      await file.writeFile(content, "utf8");
    } finally {
      await file.close();
    }
    await preflightConfig(source);
    try {
      await link(temporary, path);
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "EEXIST") throw error;
      const existing = await readOwnedConfig(path);
      if (existing === undefined) await link(temporary, path);
      else if (existing !== content) await rename(temporary, path);
    }
  } finally {
    await rm(temporary, { force: true });
  }
}

async function removeConfig(source: string): Promise<void> {
  const path = join(source, "mempalace.yaml");
  try {
    if ((await readOwnedConfig(path)) !== undefined) await rm(path);
  } catch {
    // Best effort: leave anything not provably plugin-owned, and never mask the mining result.
  }
}

export function roomName(relativePath: string): string {
  relativePath = relativePath.split(sep).join("/");
  if (relativePath === "" || relativePath === ".") return "general";
  const slug = relativePath.replace(/[^A-Za-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "facts";
  const hash = createHash("sha256").update(relativePath).digest("hex").slice(0, 12);
  return `${slug.slice(0, 115).replace(/-+$/, "")}-${hash}`;
}
