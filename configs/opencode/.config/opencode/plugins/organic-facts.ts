// organic-facts gives agents a file-based knowledge base, injected like skills:
// one entry per Markdown file (path + front-matter description) in the facts directory.
//
// The instructions go into their own static system part. The file list goes into a
// separate, later part, because it changes whenever a fact file changes.
//
// Facts directory: ORGANIC_FACTS_DIR (absolute or ~/ path), default ~/.organic-facts.

import { readdir } from "node:fs/promises";
import { homedir } from "node:os";
import { extname, isAbsolute, join, relative, resolve, sep } from "node:path";

export interface Fact {
  /** Absolute path of the Markdown file. */
  path: string;
  /** Front-matter description, or undefined when the file has none. */
  description?: string;
}

export default {
  id: "organic-facts",
  async setup(ctx: any) {
    const hook = await ctx.session.hook("context", async (event: any) => {
      event.system.push({ type: "text", text: instructions() });
      event.system.push({ type: "text", text: await renderFacts() });
    });
    return async () => {
      await hook.dispose();
    };
  },
};

async function renderFacts(): Promise<string> {
  try {
    const root = factsDirectory();
    return renderCatalogue(root, await listFacts(root));
  } catch (error) {
    return `<organic-facts>\nThe facts catalogue is unavailable: ${String(error)}\n</organic-facts>`;
  }
}

export function renderCatalogue(root: string, facts: Fact[]): string {
  const lines = facts.length
    ? [
        `Facts directory: ${root}`,
        ...facts.map(
          ({ path, description }) =>
            `- ${path} — ${description ?? "NO FRONT-MATTER DESCRIPTION: add one when you next touch this file"}`,
        ),
      ]
    : [
        `No facts yet. The facts directory is ${root}.`,
        "Populate it as you learn things: user preferences, project knowledge, and answers you had to research or dig for.",
      ];
  return ["<organic-facts>", ...lines, "</organic-facts>"].join("\n");
}

function instructions(): string {
  return [
    "## Organic facts",
    "Organic facts are Markdown files that hold knowledge you would otherwise have to rediscover: user preferences, project and tool knowledge, and findings from research or digging. Each entry in the `<organic-facts>` block is one file: its full path and a description of when it is relevant. Think of facts as factual skills that only contain information about certain topic.",
    "### Reading",
    "- When an entry might be relevant to what you are doing, read the file before you act or search elsewhere.",
    "- The facts are plain Markdown files under the facts directory named in the block. You can use ordinary search (grep, ripgrep, glob, ...) there to find facts that descriptions don't point to, for example by keyword.",
    "- Treat each file as a nearly self-contained reference for one topic, fact, or group of facts. Common facts can live in their own files and be referenced from others.",
    "- If you had to search, ask the user, or dig for information that a fact file should have covered, the file is incomplete. Update it with the missing context.",
    "### Writing",
    "- Record non-obvious knowledge that saves investigation: constraints, decisions and their rationale, ownership boundaries, failure modes, cross-system relationships, user preferences. Skip anything obvious, trivial, or easy to derive.",
    "- Don't record volatile facts (package versions, build numbers).",
    "- Group facts. Add a new file only when what you want to write fits no existing file. Search existing files first and update them.",
    "- Directories matter. Keep files of the same topic in the same directory, and use subdirectories for subtopics.",
    "- Start every file with front-matter containing a `description`. It says when the file is needed or relevant, so that you can decide whether to read it. It must not contain facts itself.",
    "- Cite each block of information: `[source: URL, repository path, or message reference — YYYY-MM-DD]` below a heading or beside an assertion. Use the real capture date and never invent a source. Subsections inherit the parent source.",
    "- Replace outdated statements in place. Don't keep changelogs or migration narration. Preserve uncertainty and conflicting evidence instead of picking a side by recency.",
    "- Facts describe what is not what was, unless the history is important for the context (e.g. something that was tried and caused problems, so we don't try it again)",
    "- Write only where the user's permissions and requests allow it.",
  ].join("\n");
}

export function factsDirectory(env = process.env, home = homedir()): string {
  const configured = env.ORGANIC_FACTS_DIR?.trim();
  if (!configured) return join(home, ".organic-facts");
  const path =
    configured === "~"
      ? home
      : configured.startsWith("~/")
        ? join(home, configured.slice(2))
        : configured;
  if (!isAbsolute(path))
    throw new Error(
      "ORGANIC_FACTS_DIR must be an absolute path or start with ~/",
    );
  return resolve(path);
}

/** List Markdown files under root, sorted by path. Hidden entries and symlinked directories are skipped. */
export async function listFacts(root: string): Promise<Fact[]> {
  const files: string[] = [];
  async function visit(directory: string) {
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      if (entry.name.startsWith(".")) continue;
      const path = join(directory, entry.name);
      if (entry.isDirectory()) await visit(path);
      else if (entry.isFile() && extname(entry.name).toLowerCase() === ".md")
        files.push(path);
    }
  }
  try {
    await visit(root);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
  }
  files.sort((a, b) =>
    relative(root, a)
      .split(sep)
      .join("/")
      .localeCompare(relative(root, b).split(sep).join("/")),
  );
  return Promise.all(
    files.map(async (path) => ({
      path,
      description: await readDescription(path),
    })),
  );
}

// Front-matter sits at the top of the file, so read only the head.
async function readDescription(path: string): Promise<string | undefined> {
  const head = await Bun.file(path).slice(0, 8192).text();
  const block = head.match(/^---\r?\n([\s\S]*?)\r?\n---/)?.[1];
  if (!block) return undefined;
  let description: unknown;
  try {
    description = (Bun.YAML.parse(block) as { description?: unknown } | null)
      ?.description;
  } catch {
    // Agents often write an unquoted `: ` in the text, which is invalid YAML; take the line as written.
    description = block
      .match(/^description:[ \t]*(.+)$/m)?.[1]
      ?.replace(/^(["'])(.*)\1$/, "$2");
  }
  if (typeof description !== "string") return undefined;
  return description.replace(/\s+/g, " ").trim() || undefined;
}
