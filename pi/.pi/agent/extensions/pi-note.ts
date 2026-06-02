/**
 * pi-note — Stage 1
 *
 * Pins a single note above the input editor, scoped to the current session.
 *
 * Commands:
 *   /note <content>             Set/replace the session note.
 *   /note :recap: <content>     Set a note with a custom prefix word (default: "note").
 *   /note                       If a note exists, prefill the editor with its
 *                               command for editing. Otherwise show usage.
 *   /note-clear                 Clear the note in this session only.
 *
 * The note is stored via pi.appendEntry, so it never enters the LLM context.
 * It persists across resume/fork and follows the active branch via /tree.
 *
 * Visual style:
 *   ※ note: long content that wraps across multiple
 *     lines with a 2-space hanging indent
 */

import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import type { Component } from "@earendil-works/pi-tui";
import { visibleWidth } from "@earendil-works/pi-tui";

// ----- types ---------------------------------------------------------------

type NoteEntryData = { text: string; prefix: string; createdAt: number } | { deleted: true };

type Note = { text: string; prefix: string };

// ----- constants -----------------------------------------------------------

const WIDGET_KEY = "pi-note";
const ENTRY_TYPE = "note";
const DEFAULT_PREFIX = "note";
const ICON = "※";
// Continuation indent matches the visible width of "※ " so wrapped lines
// align under the start of the prefix word.
const CONT_INDENT = "  ";

// ----- parsing -------------------------------------------------------------

/**
 * Parse the raw `/note` argument string.
 *
 *   ":recap: we picked postgres" → { prefix: "recap", text: "we picked postgres" }
 *   "remember to bump changeset" → { prefix: "note",  text: "remember to bump changeset" }
 *
 * Returns null if there is no usable content.
 */
function parseArgs(raw: string): { prefix: string; text: string } | null {
  const trimmed = raw.trim();
  if (trimmed === "") return null;

  // `:word: <content>` — word has no whitespace and no inner colons.
  // Content must contain at least one non-whitespace character.
  const match = trimmed.match(/^:([^\s:]+):\s+([\s\S]*\S)\s*$/);
  if (match) {
    return { prefix: match[1]!, text: match[2]! };
  }
  return { prefix: DEFAULT_PREFIX, text: trimmed };
}

/** Reconstruct the `/note` command string for edit mode. */
function buildPrefill(note: Note): string {
  if (note.prefix === DEFAULT_PREFIX) return `/note ${note.text}`;
  return `/note :${note.prefix}: ${note.text}`;
}

// ----- word-wrap -----------------------------------------------------------

/**
 * Word-wrap one logical paragraph. The first line may have a different
 * available width than continuation lines (because the icon + prefix only
 * appears on the first line).
 */
function wrapParagraph(text: string, firstWidth: number, contWidth: number): string[] {
  const safeFirst = Math.max(1, firstWidth);
  const safeCont = Math.max(1, contWidth);

  const words = text.split(/\s+/).filter((w) => w.length > 0);
  if (words.length === 0) return [""];

  const lines: string[] = [];
  let current = "";
  let available = safeFirst;

  const flush = () => {
    lines.push(current);
    current = "";
    available = safeCont;
  };

  const hardBreakWord = (word: string): string => {
    // Split a single word that is wider than `available` into chunks
    // that fit. Returns the unconsumed tail (always fits in `available`).
    let remaining = word;
    while (visibleWidth(remaining) > available) {
      let take = "";
      for (const ch of remaining) {
        if (visibleWidth(take + ch) > available) break;
        take += ch;
      }
      if (take === "") {
        // Safety: a single character wider than the line; give up
        // and emit it on its own line to avoid an infinite loop.
        lines.push(remaining[0] ?? "");
        remaining = remaining.slice(1);
        available = safeCont;
        continue;
      }
      lines.push(take);
      remaining = remaining.slice(take.length);
      available = safeCont;
    }
    return remaining;
  };

  for (const word of words) {
    if (visibleWidth(word) > available && current === "") {
      current = hardBreakWord(word);
      continue;
    }

    const candidate = current === "" ? word : `${current} ${word}`;
    if (visibleWidth(candidate) <= available) {
      current = candidate;
    } else {
      flush();
      if (visibleWidth(word) > available) {
        current = hardBreakWord(word);
      } else {
        current = word;
      }
    }
  }
  if (current !== "") lines.push(current);
  return lines;
}

// ----- rendering -----------------------------------------------------------

class NoteShelf implements Component {
  private cachedWidth?: number;
  private cachedLines?: string[];

  constructor(
    private readonly prefix: string,
    private readonly text: string,
    private readonly theme: Theme,
  ) {}

  render(width: number): string[] {
    if (this.cachedLines && this.cachedWidth === width) {
      return this.cachedLines;
    }

    const th = this.theme;
    const headWidth = visibleWidth(`${ICON} ${this.prefix}: `);
    const firstAvail = Math.max(1, width - headWidth);
    const contAvail = Math.max(1, width - CONT_INDENT.length);

    // Preserve user-supplied newlines as paragraph breaks.
    const paragraphs = this.text.split("\n");
    const lines: string[] = [];

    for (let i = 0; i < paragraphs.length; i++) {
      const isFirstParagraph = i === 0;
      const wrapped = wrapParagraph(
        paragraphs[i] ?? "",
        isFirstParagraph ? firstAvail : contAvail,
        contAvail,
      );
      for (let j = 0; j < wrapped.length; j++) {
        const raw = wrapped[j] ?? "";
        if (isFirstParagraph && j === 0) {
          // First line: ※  +  bold "<prefix>:"  +  text
          // Everything is dim grey; only the prefix word is also bold.
          const styled =
            th.fg("dim", `${ICON} `) +
            th.fg("dim", th.bold(`${this.prefix}:`)) +
            th.fg("dim", ` ${raw}`);
          lines.push(styled);
        } else {
          lines.push(th.fg("dim", `${CONT_INDENT}${raw}`));
        }
      }
    }

    this.cachedWidth = width;
    this.cachedLines = lines;
    return lines;
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.cachedLines = undefined;
  }
}

// ----- extension -----------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // In-memory state. Reconstructed from session entries on every
  // session_start and session_tree event.
  let currentNote: Note | null = null;

  function reconstruct(ctx: ExtensionContext): void {
    currentNote = null;
    for (const entry of ctx.sessionManager.getEntries()) {
      if (entry.type !== "custom" || entry.customType !== ENTRY_TYPE) continue;
      const data = entry.data as NoteEntryData | undefined;
      if (!data) continue;
      if ("deleted" in data && data.deleted) currentNote = null;
      else if ("text" in data) currentNote = { text: data.text, prefix: data.prefix };
    }
  }

  function renderShelf(ctx: ExtensionContext): void {
    if (!ctx.hasUI) return;
    if (currentNote === null) {
      ctx.ui.setWidget(WIDGET_KEY, undefined);
      return;
    }
    const { prefix, text } = currentNote;
    ctx.ui.setWidget(WIDGET_KEY, (_tui, theme) => new NoteShelf(prefix, text, theme), {
      placement: "aboveEditor",
    });
  }

  pi.on("session_start", async (_event, ctx) => {
    reconstruct(ctx);
    renderShelf(ctx);
  });

  pi.on("session_tree", async (_event, ctx) => {
    reconstruct(ctx);
    renderShelf(ctx);
  });

  pi.registerCommand("note", {
    description: "Pin a note above the input. Usage: /note [:prefix:] <content>",
    handler: async (args, ctx) => {
      const trimmed = (args ?? "").trim();

      if (trimmed === "") {
        // Edit mode: prefill the editor with the current note's command
        // so the user can edit it and re-submit. If there is no note,
        // show usage.
        if (currentNote !== null) {
          if (ctx.hasUI) {
            ctx.ui.setEditorText(buildPrefill(currentNote));
          } else {
            ctx.ui.notify(`Current note (${currentNote.prefix}): ${currentNote.text}`, "info");
          }
          return;
        }
        ctx.ui.notify("Usage: /note [:prefix:] <content>", "warning");
        return;
      }

      const parsed = parseArgs(trimmed);
      if (parsed === null) {
        ctx.ui.notify("Note content required", "warning");
        return;
      }

      const data: NoteEntryData = {
        text: parsed.text,
        prefix: parsed.prefix,
        createdAt: Date.now(),
      };
      pi.appendEntry(ENTRY_TYPE, data);
      currentNote = { text: parsed.text, prefix: parsed.prefix };
      renderShelf(ctx);
    },
  });

  pi.registerCommand("note-clear", {
    description: "Clear the note pinned above the input in this session.",
    handler: async (_args, ctx) => {
      if (currentNote === null) {
        ctx.ui.notify("No note to clear", "info");
        return;
      }
      pi.appendEntry(ENTRY_TYPE, { deleted: true } as NoteEntryData);
      currentNote = null;
      renderShelf(ctx);
    },
  });
}
