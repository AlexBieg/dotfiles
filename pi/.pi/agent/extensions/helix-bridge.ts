import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import * as fs from "node:fs";
import * as path from "node:path";

/**
 * Helix Bridge — pi extension for integrating with the Helix editor.
 *
 * What it provides:
 *   /helix context <file>[:start-end]   — Add file context for next prompt
 *   /helix list                          — Show stored context entries
 *   /helix remove <n>                    — Remove entry by number
 *   /helix-clear                         — Clear all stored context
 *   helix_edit (tool)                    — Write files (use `space p r` to reload)
 *
 * Context flow:
 *   1. Helix keybindings call helix-pi which writes /tmp/helix-context-state.json
 *   2. Extension watches that file → updates the widget
 *   3. /helix context command also appends to the state file
 *   4. before_agent_start reads /tmp/helix-context.md and injects into LLM
 *   5. agent_end cleans up (single-use — consumed on submit)
 */

const CONTEXT_FILE = "/tmp/helix-context.md";
const STATE_FILE = "/tmp/helix-context-state.json";

interface ContextEntry {
  filePath: string;
  lineStart?: number | null;
  lineEnd?: number | null;
  hasSelection?: boolean;
}

let contextEntries: ContextEntry[] = [];

// Reference to setWidget, captured from session_start for file-watch callbacks
let setWidget: ((id: string, content: string[] | undefined) => void) | null = null;

// ──────────────────────────────────────────────────────────
// State persistence
// ──────────────────────────────────────────────────────────

function loadState(): void {
  try {
    if (fs.existsSync(STATE_FILE)) {
      const data = fs.readFileSync(STATE_FILE, "utf-8");
      const parsed = JSON.parse(data);
      if (Array.isArray(parsed)) {
        contextEntries = parsed;
      } else {
        contextEntries = [];
      }
    } else {
      contextEntries = [];
    }
  } catch {
    contextEntries = [];
  }
}

function saveState(): void {
  try {
    fs.writeFileSync(STATE_FILE, JSON.stringify(contextEntries, null, 2), "utf-8");
  } catch {
    // ignore
  }
}

// ──────────────────────────────────────────────────────────
// Context markdown generation
// ──────────────────────────────────────────────────────────

async function rebuildContextFile(cwd: string): Promise<void> {
  if (contextEntries.length === 0) {
    try {
      if (fs.existsSync(CONTEXT_FILE)) {
        await fs.promises.unlink(CONTEXT_FILE);
      }
    } catch {
      // ignore
    }
    return;
  }

  const parts: string[] = [];
  for (const entry of contextEntries) {
    try {
      const resolved = path.resolve(cwd, entry.filePath);
      const content = await fs.promises.readFile(resolved, "utf-8");
      const lines = content.split("\n");

      let context = `## File: \`${entry.filePath}\``;
      if (entry.lineStart && entry.lineEnd) {
        context += ` (lines ${entry.lineStart}-${entry.lineEnd})`;
        context += `\n\n\`\`\`\n`;
        context += lines.slice(entry.lineStart - 1, entry.lineEnd).join("\n");
        context += `\n\`\`\``;
      } else {
        context += `\n\n\`\`\`\n${content}\n\`\`\``;
      }
      if (entry.hasSelection) {
        context += `\n\n*(includes selected text)*`;
      }
      parts.push(context);
    } catch {
      parts.push(
        `## File: \`${entry.filePath}\`\n\n*(file could not be read — it may have been moved or deleted)*`
      );
    }
  }

  await fs.promises.writeFile(CONTEXT_FILE, parts.join("\n\n---\n\n"), "utf-8");
}

// ──────────────────────────────────────────────────────────
// Widget (shows above the editor)
// ──────────────────────────────────────────────────────────

function updateWidget(): void {
  if (!setWidget) return;

  if (contextEntries.length === 0) {
    setWidget("helix-context", undefined);
    return;
  }

  const lines: string[] = [];
  const count = contextEntries.length;
  lines.push(`📋 Helix Context (${count} file${count !== 1 ? "s" : ""})`);

  for (let i = 0; i < contextEntries.length; i++) {
    const e = contextEntries[i];
    let label = e.filePath;
    if (e.lineStart && e.lineEnd) {
      label += `:${e.lineStart}-${e.lineEnd}`;
    }
    if (e.hasSelection) {
      label += ` ✨`;
    }
    lines.push(`  ${i + 1}. ${label}`);
  }

  lines.push(`  /helix remove <n> to remove • /helix-clear to clear all`);

  setWidget("helix-context", lines);
}

// ──────────────────────────────────────────────────────────
// Refresh (called when entries change)
// ──────────────────────────────────────────────────────────

async function refresh(cwd: string): Promise<void> {
  isInternalUpdate = true;
  saveState();
  await rebuildContextFile(cwd);
  updateWidget();

  // Update our mtime tracker so the poll doesn't double-trigger
  try {
    if (fs.existsSync(STATE_FILE)) {
      lastStateMtime = fs.statSync(STATE_FILE).mtimeMs;
    }
  } catch {}
  isInternalUpdate = false;
}

// ──────────────────────────────────────────────────────────
// Polling (detects writes from helix-pi)
// ──────────────────────────────────────────────────────────

let pollTimer: ReturnType<typeof setInterval> | null = null;
let lastStateMtime = 0;
let isInternalUpdate = false;

function startPolling(cwd: string): void {
  if (pollTimer) return;

  // Check every 500ms whether the state file has changed.
  // This catches writes from the standalone helix-pi script.
  pollTimer = setInterval(() => {
    // Skip if we're the ones who wrote the file
    if (isInternalUpdate) return;

    try {
      if (fs.existsSync(STATE_FILE)) {
        const stat = fs.statSync(STATE_FILE);
        if (stat.mtimeMs > lastStateMtime) {
          lastStateMtime = stat.mtimeMs;
          loadState();
          rebuildContextFile(cwd).then(() => updateWidget()).catch(() => {});
        }
      } else {
        if (contextEntries.length > 0) {
          contextEntries = [];
          lastStateMtime = 0;
          updateWidget();
          try { if (fs.existsSync(CONTEXT_FILE)) fs.unlinkSync(CONTEXT_FILE); } catch {}
        }
      }
    } catch {
      // ignore poll errors
    }
  }, 500);
}

// ──────────────────────────────────────────────────────────
// Extension entry point
// ──────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  // ── session_start: restore state and show widget ──
  pi.on("session_start", async (_event, ctx) => {
    loadState();
    await rebuildContextFile(ctx.cwd);
    setWidget = (id, content) => ctx.ui.setWidget(id, content);
    updateWidget();
    startPolling(ctx.cwd);
  });

  // ── helix_edit tool ──
  pi.registerTool({
    name: "helix_edit",
    label: "Helix Edit",
    description:
      "Edit a file in the Helix editor. Writes the file to disk. " +
      "Helix auto-detects file changes when the buffer regains focus. " +
      "The user can reload manually with `space p r` (or :reload-all).",

    promptSnippet: "Edit files for Helix users",
    promptGuidelines: [
      "Use helix_edit when making file changes for users who use the Helix editor. After writing, tell the user to press `space p r` to reload.",
    ],

    parameters: Type.Object({
      file_path: Type.String({
        description: "Absolute or relative path to the file to edit",
      }),
      content: Type.String({
        description: "Complete new content for the file",
      }),
      cursor_line: Type.Optional(
        Type.Number({
          description: "Line number to position the cursor at after the edit (1-indexed)",
        })
      ),
    }),

    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const resolvedPath = path.resolve(params.file_path);
      const dir = path.dirname(resolvedPath);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      await fs.promises.writeFile(resolvedPath, params.content, "utf-8");

      return {
        content: [{
          type: "text",
          text: `Updated \`${params.file_path}\`. Reload Helix with \`:reload-all\` or \`space p r\` to see changes.`,
        }],
        details: { file_path: params.file_path },
      };
    },
  });

  // ──────────────────────────────────────────────────────────
  // Command: /helix
  // ──────────────────────────────────────────────────────────
  pi.registerCommand("helix", {
    description:
      "Manage Helix context. " +
      "Usage: /helix context <filepath>[:start-end] [selected text...]" +
      " | /helix list | /helix remove <n>",
    handler: async (args, ctx) => {
      const trimmed = args.trim();

      // ── sub: list ──────────────────────────────────
      if (trimmed === "list") {
        if (contextEntries.length === 0) {
          ctx.ui.notify("No context files stored.", "info");
          return;
        }
        const lines = contextEntries
          .map((e, i) =>
            `${i + 1}. ${e.filePath}${e.lineStart && e.lineEnd ? `:${e.lineStart}-${e.lineEnd}` : ""}${e.hasSelection ? " (selection)" : ""}`
          )
          .join("\n");
        ctx.ui.notify(`📋 Helix Context:\n${lines}`, "info");
        return;
      }

      // ── sub: remove <n> ───────────────────────────
      const removeMatch = trimmed.match(/^remove\s+(\d+)$/);
      if (removeMatch) {
        const idx = parseInt(removeMatch[1], 10) - 1;
        if (idx < 0 || idx >= contextEntries.length) {
          ctx.ui.notify(
            `Invalid index. ${contextEntries.length} entr${contextEntries.length === 1 ? "y" : "ies"} in context.`,
            "error"
          );
          return;
        }
        const removed = contextEntries.splice(idx, 1)[0];
        await refresh(ctx.cwd);
        ctx.ui.notify(`Removed \`${removed.filePath}\` from context.`, "info");
        return;
      }

      // ── sub: context ──────────────────────────────
      if (!trimmed.startsWith("context ")) {
        ctx.ui.notify(
          "Usage:\n" +
            "  /helix context <filepath>[:start-end] [selected text...]\n" +
            "  /helix list\n" +
            "  /helix remove <n>",
          "warning"
        );
        return;
      }

      const rest = trimmed.slice("context ".length).trim();
      const spaceIdx = rest.indexOf(" ");
      const fileSpec = spaceIdx === -1 ? rest : rest.slice(0, spaceIdx);
      const selectionText = spaceIdx === -1 ? "" : rest.slice(spaceIdx + 1).trim();

      let filePath: string;
      let lineStart: number | undefined;
      let lineEnd: number | undefined;

      const rangeMatch = fileSpec.match(/^(.+):(\d+)-(\d+)$/);
      if (rangeMatch) {
        filePath = rangeMatch[1];
        lineStart = parseInt(rangeMatch[2], 10);
        lineEnd = parseInt(rangeMatch[3], 10);
      } else {
        filePath = fileSpec;
      }

      const resolved = path.resolve(ctx.cwd, filePath);

      try {
        await fs.promises.access(resolved, fs.constants.R_OK);
      } catch {
        ctx.ui.notify(`Cannot read \`${filePath}\` — file not found or not readable.`, "error");
        return;
      }

      contextEntries.push({
        filePath,
        lineStart,
        lineEnd,
        hasSelection: !!selectionText,
      });

      await refresh(ctx.cwd);

      ctx.ui.notify(
        `✅ Added \`${filePath}\`${lineStart ? `:${lineStart}-${lineEnd}` : ""} to context. ${contextEntries.length} file${contextEntries.length !== 1 ? "s" : ""} in context.`,
        "info"
      );
    },
  });

  // ──────────────────────────────────────────────────────────
  // Command: /helix-clear
  // ──────────────────────────────────────────────────────────
  pi.registerCommand("helix-clear", {
    description: "Clear all stored Helix context",
    handler: async (_args, ctx) => {
      contextEntries = [];
      await refresh(ctx.cwd);
      ctx.ui.notify("🧹 Helix context cleared", "info");
    },
  });

  // ──────────────────────────────────────────────────────────
  // Event: before_agent_start — inject stored context
  // ──────────────────────────────────────────────────────────
  pi.on("before_agent_start", async (event, ctx) => {
    // Fresh rebuild to ensure content is current
    await rebuildContextFile(ctx.cwd);

    try {
      if (fs.existsSync(CONTEXT_FILE)) {
        const context = await fs.promises.readFile(CONTEXT_FILE, "utf-8");
        if (context.trim()) {
          return {
            systemPrompt: event.systemPrompt + `\n\n${context}`,
          };
        }
      }
    } catch {
      // ignore
    }
    return {};
  });

  // ──────────────────────────────────────────────────────────
  // Event: agent_end — clean up context (single-use)
  // ──────────────────────────────────────────────────────────
  pi.on("agent_end", async () => {
    contextEntries = [];
    updateWidget();

    try {
      if (fs.existsSync(CONTEXT_FILE)) await fs.promises.unlink(CONTEXT_FILE);
      if (fs.existsSync(STATE_FILE)) await fs.promises.unlink(STATE_FILE);
    } catch {
      // ignore
    }
  });
}
