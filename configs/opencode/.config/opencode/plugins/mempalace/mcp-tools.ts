import type { Plugin } from "@opencode/plugin";

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

// Removes the tools the plugin disables: the locking tools, and the knowledge graph (`mempalace_kg_*`).
export async function registerToolFilter(ctx: Plugin.Context): Promise<() => Promise<void>> {
  const registration = await ctx.tool.transform((tools) => {
    // Locking tools hold the palace lock for as long as their MCP server lives, which blocks every sweep.
    for (const { id } of tools.list())
      if (LOCKING_MCP_TOOLS.some((name) => id.endsWith(`_${name}`)) || id.includes("mempalace_kg_"))
        tools.remove(id);
  });
  return async () => {
    await registration.dispose();
  };
}
