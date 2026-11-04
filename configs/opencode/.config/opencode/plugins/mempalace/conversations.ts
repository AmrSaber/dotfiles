import type { Plugin } from "@opencode/plugin";
import { mkdir, writeFile, readFile, readdir, stat, unlink } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export async function registerConversations(ctx: Plugin.Context): Promise<() => Promise<void>> {
  const home = homedir();
  const sessionsDir = join(home, ".mempalace", "opencode-sessions");
  const palaceDir = join(home, ".mempalace", "palace");
  const errorLog = join(palaceDir, "repair-error.log");
  const compactionHook = await ctx.session.hook("compaction", async (event) => {
    if (!isDisabled(process.env.MEMPALACE_HOOKS_AUTO_SAVE)) await capture(event.sessionID);
  });
  const eventController = new AbortController();
  const events = (async () => {
    try {
      for await (const event of ctx.event.subscribe({ signal: eventController.signal })) {
        if (event.type !== "session.idle" || isDisabled(process.env.MEMPALACE_HOOKS_AUTO_SAVE)) continue;
        await capture(event.data.sessionID);
        await pruneOldSessions(event.data.sessionID);
      }
    } catch {
      // Capture failures must not disrupt the session.
    }
  })();

  return async () => {
    eventController.abort();
    await compactionHook.dispose();
    await events;
  };

  async function capture(sessionID: string) {
    if (!sessionID) return;
    try {
      await mkdir(sessionsDir, { recursive: true });
      const jsonl = await renderJsonl(sessionID);
      if (!jsonl) return;
      // Write first so a halted palace or a lost sweep lock cannot drop the transcript.
      await writeFile(join(sessionsDir, `${sessionID}.jsonl`), jsonl, "utf8");
      const halted = await readFile(errorLog, "utf8").catch(() => undefined);
      if (halted) return;
      await launchDetachedSweep();
    } catch {
      // Capture failures must not disrupt the session.
    }
  }

  async function renderJsonl(sessionID: string): Promise<string> {
    const messages = await ctx.session.context({ sessionID });
    const lines: string[] = [];
    for (const message of messages) {
      if (message.type !== "user" && message.type !== "assistant") continue;
      const content = message.type === "user"
        ? message.text.trim()
        : message.content.filter((part) => part.type === "text").map((part) => part.text).join("\n").trim();
      if (!content) continue;
      lines.push(JSON.stringify({
        type: message.type,
        uuid: message.id,
        timestamp: new Date(message.time.created).toISOString(),
        sessionId: sessionID,
        message: { role: message.type, content },
      }));
    }
    return lines.length ? lines.join("\n") + "\n" : "";
  }

  async function launchDetachedSweep() {
    const script = join(dirname(fileURLToPath(import.meta.url)), "mempalace-sweep.sh");
    // Mark dirty before taking the lock so the current worker also sees losing launches.
    await Bun.$`sh -c ${`touch "$MP_DIRTY"; setsid -f sh "$MP_SCRIPT" </dev/null >>"$MP_LOG" 2>&1`}`
      .env({
        ...process.env,
        MP_SCRIPT: script,
        MP_SESSIONS: sessionsDir,
        MP_LOCK: join(sessionsDir, "sweep.lock"),
        MP_DIRTY: join(sessionsDir, "sweep.dirty"),
        MP_LOG: join(sessionsDir, "sweep.log"),
        MP_CHROMA: join(palaceDir, "chroma.sqlite3"),
        MP_PALACE: palaceDir,
        MP_ERROR_LOG: errorLog,
      })
      .nothrow();
  }

  async function pruneOldSessions(activeSessionID: string) {
    const configured = Number(process.env.MEMPALACE_SESSION_TTL_DAYS);
    const ttlDays = Number.isFinite(configured) ? configured : 7;
    if (ttlDays <= 0) return;
    try {
      const cutoff = Date.now() - ttlDays * 24 * 60 * 60 * 1000;
      for (const name of await readdir(sessionsDir)) {
        if (!name.endsWith(".jsonl") || name === `${activeSessionID}.jsonl`) continue;
        const full = join(sessionsDir, name);
        try {
          if ((await stat(full)).mtimeMs < cutoff) await unlink(full);
        } catch {
          // One inaccessible file must not block pruning the others.
        }
      }
    } catch {
      // The directory might not exist yet.
    }
  }
}

function isDisabled(value: string | undefined): boolean {
  return ["false", "0", "no"].includes(value?.trim().toLowerCase() ?? "");
}
