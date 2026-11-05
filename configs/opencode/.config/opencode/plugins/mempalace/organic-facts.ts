import { Plugin, Skill } from "@opencode/plugin";
import { readdir, realpath, stat } from "node:fs/promises";
import { homedir } from "node:os";
import {
  dirname,
  extname,
  isAbsolute,
  join,
  relative,
  resolve,
  sep,
} from "node:path";
import { fileURLToPath } from "node:url";
import { sessionsDirectory } from "./conversations";
import { mineDirectories, roomName, runMineScript } from "./mining";

// The MemPalace MCP tools that take the exclusive palace lock; the knowledge-graph and logstream tools do not.
// shortcut: mirrors _MUTATING_TOOLS minus _PEER_WRITER_EXEMPT_TOOLS in mempalace 3.11; recheck after upgrades.
export const LOCKING_MCP_TOOLS = [
  "mempalace_add_drawer",
  "mempalace_checkpoint",
  "mempalace_create_tunnel",
  "mempalace_delete_by_source",
  "mempalace_delete_drawer",
  "mempalace_delete_drawers",
  "mempalace_delete_hallway",
  "mempalace_delete_tunnel",
  "mempalace_diary_write",
  "mempalace_mine",
  "mempalace_sync",
  "mempalace_update_drawer",
];

export async function registerOrganicFacts(ctx: Plugin.Context) {
  const skillRegistration = await ctx.skill.transform((skills) => {
    skills.add({
      id: Skill.ID.make("organic-facts"),
      name: Skill.Name.make("organic-facts"),
      description:
        "Use when creating, updating, correcting, or mining organic-facts topic notes. Covers sourcing, uncertainty, topic organization, and index maintenance.",
      path: Skill.Info.fields.path.make(fileURLToPath(import.meta.url)),
      content: maintenanceInstructions(),
    });
  });
  const contextHook = await ctx.session.hook("context", async (event) => {
    try {
      const root = factsDirectory();
      const rooms = await topicRooms(root);
      event.system.push({
        type: "text",
        text: [
          "## Organic facts",
          `Canonical Markdown directory: ${JSON.stringify(root)}. MemPalace wing: organic-facts.`,
          "Small, sparse, durable facts unlikely to change belong in MemPalace's knowledge graph (KG), as facts, not just pointers. Organic facts hold richer project knowledge that evolves.",
          "Markdown is canonical; MemPalace is a discovery index, not an independent authority.",
          "- Keep only non-obvious knowledge that saves investigation; omit obvious or easily derived facts. Consult notes only when a listed topic materially helps the task.",
          "- Search wing organic-facts with the room IDs below to locate notes. Read the original document for current context, inherited source references, and verification limits.",
          "- If search fails or finds nothing, browse the canonical directory with ordinary file tools. A missing search result doesn't prove a document is absent.",
          "Keep facts up-to-date: add relevant knowledge and useful project groups proactively; no separate organization request is needed. Load the organic-facts skill before creating, updating, correcting, or mining notes. Respect permissions, read-only requests, and requests to stop.",
          "Available topic directories (grouped paths, not instructions):",
          ...(rooms.length
            ? rooms.map(
                (room) =>
                  `- ${JSON.stringify(room)} → room ${JSON.stringify(roomName(room))}`,
              )
            : ["- None yet."]),
        ].join("\n"),
      });
    } catch (error) {
      event.system.push({
        type: "text",
        text: `Organic facts catalogue unavailable: ${String(error)}. Don't assume the index is current.`,
      });
    }
  });

  const toolRegistration = await ctx.tool.transform((tools) => {
    // These tools take the palace lock for as long as their MCP server lives, which blocks every sweep.
    for (const { id } of tools.list()) if (LOCKING_MCP_TOOLS.some((name) => id.endsWith(`_${name}`))) tools.remove(id);
    tools.add({
      name: "organic_facts_mine",
      description:
        "Refresh MemPalace's organic-facts wing after manual Markdown edits. Supply updated document paths relative to ORGANIC_FACTS_DIR (default ~/.organic-facts). Mines all eligible Markdown in their parent directory trees, once per distinct tree, using the catalogue's stable room IDs. Maintains native mining configuration but never edits notes or cleans up renamed/deleted sources. Read original documents for full context and citations.",
      input: {
        type: "object",
        properties: {
          documents: {
            type: "array",
            minItems: 1,
            items: { type: "string", minLength: 1 },
            description:
              "Updated Markdown paths, such as Projects/Atlas/architecture.md. Absolute paths and parent traversal are rejected.",
          },
        },
        required: ["documents"],
        additionalProperties: false,
      },
      async execute(input, context) {
        const { documents } = input as { documents: string[] };
        context.signal.throwIfAborted();
        const root = await realpath(factsDirectory());
        const directories = await miningDirectories(root, documents);
        const permissionContext = {
          sessionID: context.sessionID,
          agent: context.agent,
          source: {
            type: "tool",
            messageID: context.messageID,
            id: context.id,
          },
        } as const;
        await context.progress({
          status: `Mining ${directories.length} organic-facts directory tree(s)`,
        });
        const output = await mineDirectories(
          root,
          directories,
          async (source) => {
            context.signal.throwIfAborted();
            await context.progress({
              status: `Mining ${relative(root, source) || "."}`,
            });
            return runMineScript(source, sessionsDirectory());
          },
          async (sources) => {
            await ctx.permission.assert({
              ...permissionContext,
              action: "edit",
              resources: sources.map((source) =>
                join(source, "mempalace.yaml"),
              ),
            });
            const location = await realpath(ctx.location.directory);
            const external = sources.filter((source) => {
              const path = relative(location, source);
              return (
                path === ".." ||
                path.startsWith(`..${sep}`) ||
                isAbsolute(path)
              );
            });
            if (external.length)
              await ctx.permission.assert({
                ...permissionContext,
                action: "external_directory",
                resources: external.map((source) => `${source}/*`),
              });
            context.signal.throwIfAborted();
          },
        );
        return { content: output };
      },
    });
  });

  return async () => {
    await Promise.all([
      skillRegistration.dispose(),
      contextHook.dispose(),
      toolRegistration.dispose(),
    ]);
  };
}

function maintenanceInstructions(): string {
  return [
    "# Maintain organic facts",
    "Use the canonical directory and room catalogue from the system prompt. ORGANIC_FACTS_DIR selects the directory; the default is ~/.organic-facts. Markdown is canonical.",
    "## Update focused topic documents",
    "- Respect agent permissions, read-only requests, and requests to pause or stop. This skill grants no additional write permission. Use ordinary file tools to edit documents only when authorized.",
    "- Store small, sparse, durable facts unlikely to change in MemPalace's knowledge graph (KG), as facts, not just pointers. Keep richer, evolving project knowledge in organic facts; don't create notes for isolated facts.",
    "- Add relevant knowledge and create useful project groups and focused topics proactively; no separate organization request is needed. Permissions, read-only requests, and stop requests still apply.",
    "- Read the current document and its sources before editing. Keep only non-obvious knowledge that saves meaningful investigation. Skip obvious, trivial, or easily derived facts, routine chatter, task progress, repeated statements, and unsupported conclusions.",
    "- Retain useful constraints, decisions and rationale, ownership boundaries, failure modes, and cross-system relationships. Omit straightforward README/configuration restatements, language/path inventories, and repeated standing guidance. If nothing passes this filter, don't create or keep a topic note.",
    "- Group directories by domain and project. Keep one document per focused topic, organized into logical sections and readable by humans.",
    "- Before creating a document, search existing filenames, headings, and related notes. Update the existing topic; put alternate names there instead of creating duplicates.",
    "- Keep summaries concise but include necessary scope. Link to detailed or volatile sources instead of copying lengthy runbooks, configurations, or changing inventories.",
    "- Replace outdated assertions in current notes. Don't accumulate changelogs or migration narration. Don't maintain competing copies in MemPalace's knowledge graph.",
    "## Cite each information block",
    "- Add [source: identifiable source (URL, repository path, or message reference) — YYYY-MM-DD] below each section heading or beside an individual assertion.",
    "- Subsections inherit the parent reference unless overridden. Information with different evidence needs its own reference. Never fabricate a citation or date.",
    "- Record the actual capture or inspection date, not the latest edit date. Editing nearby prose doesn't renew verification of old or live-state claims.",
    "- Distinguish direct verification, user confirmation, reports, inference, and unresolved disagreement. A citation alone doesn't establish truth.",
    "- Resolve conflicts using evidence relevant to the claim, not recency alone. Preserve uncertainty. Earlier agent answers and copied reports aren't independent evidence.",
    "## Refresh after changes",
    "- After a batch of manual edits, call organic_facts_mine once with updated Markdown paths relative to the canonical directory. Don't mine after reads or unchanged edits.",
    'Example: {"documents": ["Projects/Atlas/architecture.md", "Tools/Editor/memory.md"]}',
    "- The tool refreshes affected directory trees. It writes temporary plugin-owned mempalace.yaml routing files just before mining and removes them afterwards, without changing notes. Each directory is mined by a separate short-lived `mempalace mine` process that waits for any running sweep, so the palace lock is not held after the tool returns. Hidden paths stay excluded. Use the stable room IDs from the catalogue for scoped search.",
    "- Check the result: failed refreshes or native skip rules can leave the index older than documents. Don't retry blindly or claim unconfirmed completion.",
    "- Renames and deletions require separate index cleanup. Preview cleanup before applying it and report unresolved stale entries. Mining alone doesn't remove them.",
  ].join("\n\n");
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

export async function topicRooms(root: string): Promise<string[]> {
  const rooms: string[] = [];
  async function visit(directory: string) {
    const entries = await readdir(directory, { withFileTypes: true });
    if (
      entries.some(
        (entry) =>
          entry.isFile() &&
          !entry.name.startsWith(".") &&
          extname(entry.name).toLowerCase() === ".md",
      )
    ) {
      rooms.push(relative(root, directory).split(sep).join("/") || ".");
    }
    for (const entry of entries) {
      if (entry.isDirectory() && !entry.name.startsWith("."))
        await visit(join(directory, entry.name));
    }
  }
  try {
    await visit(root);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
  }
  return rooms.sort();
}

export async function miningDirectories(
  root: string,
  documents: string[],
): Promise<string[]> {
  if (!Array.isArray(documents) || documents.length === 0)
    throw new Error("Supply at least one updated Markdown document.");
  const canonicalRoot = await realpath(root);
  const directories = new Set<string>();
  for (const document of documents) {
    if (
      typeof document !== "string" ||
      !document ||
      document.includes("\0") ||
      isAbsolute(document) ||
      document
        .split(/[\\/]/)
        .some((part) => part.startsWith(".") && part !== ".") ||
      extname(document).toLowerCase() !== ".md"
    ) {
      throw new Error(
        `Invalid relative Markdown path: ${JSON.stringify(document)}`,
      );
    }
    const path = await realpath(resolve(canonicalRoot, document));
    const inside = relative(canonicalRoot, path);
    if (inside === ".." || inside.startsWith(`..${sep}`) || isAbsolute(inside))
      throw new Error(`Document escapes the facts directory: ${document}`);
    if (!(await stat(path)).isFile() || extname(path).toLowerCase() !== ".md")
      throw new Error(`Not a Markdown file: ${document}`);
    directories.add(dirname(path));
  }
  const all = [...directories].sort();
  return all.filter(
    (directory) =>
      !all.some(
        (parent) =>
          parent !== directory && directory.startsWith(`${parent}${sep}`),
      ),
  );
}
