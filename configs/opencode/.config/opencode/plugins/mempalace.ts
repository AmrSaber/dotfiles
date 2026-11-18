import { Plugin } from "@opencode/plugin";
import { registerMemoryContext } from "./mempalace/memory-context";
import { registerConversations } from "./mempalace/conversations";
import { registerToolFilter } from "./mempalace/mcp-tools";

export const MemPalace = Plugin.define({
  id: "mempalace",
  async setup(ctx) {
    const cleanups: Array<() => Promise<void>> = [];
    try {
      cleanups.push(await registerMemoryContext(ctx));
      cleanups.push(await registerConversations(ctx));
      cleanups.push(await registerToolFilter(ctx));
    } catch (error) {
      await Promise.allSettled(cleanups.map((stop) => stop()));
      throw error;
    }

    return async () => {
      await Promise.all(cleanups.map((stop) => stop()));
    };
  },
});

export default MemPalace;
