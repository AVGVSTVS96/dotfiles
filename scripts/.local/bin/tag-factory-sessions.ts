#!/usr/bin/env ts-node

import { promises as fs } from "node:fs";
import path from "node:path";

const HOME = process.env.HOME;

if (!HOME) {
  console.error("HOME environment variable is not set; aborting.");
  process.exit(1);
}

const sessionDir = path.join(HOME, ".factory", "sessions");

const argv = process.argv.slice(2);
const dryRun = argv.includes("--dry-run");
const targetArgs = argv.filter((arg) => arg !== "--dry-run");

const CURRENT_FOLDER_RE = /^Current folder: (?<path>.+)$/m;
const PWD_RE = /^% pwd\n(?<path>\/[^\n]+)/m;

type Result = {
  fileName: string;
  folderLabel: string;
  originalTitle: string;
  newTitle: string;
  changed: boolean;
};

async function main(): Promise<void> {
  const { files: jsonlFiles, warnings } = await resolveTargetFiles();
  warnings.forEach((message) => console.warn(message));

  if (jsonlFiles.length === 0) {
    console.log("No session files matched the given criteria.");
    return;
  }

  const results: Result[] = [];

  for (const filePath of jsonlFiles) {
    const fileName = path.basename(filePath);
    const raw = await fs.readFile(filePath, "utf8");
    const lines = raw.replace(/\n+$/, "").split("\n");
    if (lines.length === 0) continue;

    let header: unknown;
    try {
      header = JSON.parse(lines[0]);
    } catch (error) {
      console.warn(`Skipping ${fileName}: cannot parse session_start line.`, error);
      continue;
    }

    if (
      !header ||
      typeof header !== "object" ||
      (header as { type?: string }).type !== "session_start"
    ) {
      continue;
    }

    const folder = extractFolder(lines.slice(1));
    if (!folder) continue;

    const relativeLabel = path
      .relative(HOME, folder)
      .replace(/^[.][/\\]?/, "");
    const folderLabel = buildFolderLabel(relativeLabel.length > 0 ? relativeLabel : folder);
    const sessionHeader = header as {
      title?: string;
      [key: string]: unknown;
    };

    const baseTitle = sessionHeader.title ?? "(untitled)";
    const cleanedTitle = collapseWhitespace(stripExistingLabel(baseTitle));
    const newTitle = cleanedTitle.length > 0 ? `[${folderLabel}] ${cleanedTitle}` : `[${folderLabel}]`;

    const changed = baseTitle !== newTitle;
    results.push({
      fileName,
      folderLabel,
      originalTitle: baseTitle,
      newTitle,
      changed,
    });

    if (!changed) continue;

    sessionHeader.title = newTitle;
    lines[0] = JSON.stringify(sessionHeader);

    if (dryRun) continue;

    await fs.writeFile(filePath, `${lines.join("\n")}\n`, "utf8");
  }

  renderReport(results, dryRun);
}

function extractFolder(lines: string[]): string | undefined {
  for (const line of lines) {
    let parsed: unknown;
    try {
      parsed = JSON.parse(line);
    } catch {
      continue;
    }

    if (
      !parsed ||
      typeof parsed !== "object" ||
      (parsed as { type?: string }).type !== "message"
    ) {
      continue;
    }

    const message = (parsed as {
      message?: { content?: Array<{ type?: string; text?: string }> };
    }).message;
    const textChunks = message?.content ?? [];
    const blob = textChunks
      .filter((chunk) => chunk?.type === "text")
      .map((chunk) => chunk?.text ?? "")
      .join("\n");

    const match =
      blob.match(CURRENT_FOLDER_RE)?.groups?.path ??
      blob.match(PWD_RE)?.groups?.path;

    if (match) return match;
  }

  return undefined;
}

function buildFolderLabel(folder: string): string {
  const normalized = folder.replace(/^[./\\]+/, "").replace(/[\\/]+$/, "");
  if (!normalized) return folder;

  const parts = normalized.split(/[\\/]+/).filter(Boolean);
  if (parts.length === 0) return normalized || folder;

  return parts[parts.length - 1];
}

function stripExistingLabel(title: string): string {
  return title.replace(/^\[[^\]]+\]\s*/, "");
}

function collapseWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function renderReport(results: Result[], dryRun: boolean): void {
  const changed = results.filter((entry) => entry.changed);
  const unchanged = results.length - changed.length;

  if (changed.length === 0) {
    console.log(
      dryRun
        ? "Nothing to update (dry run). All titles already include directory tags."
        : "No updates written. Titles already include directory tags."
    );
    return;
  }

  const header = dryRun ? "Planned updates" : "Updated sessions";
  console.log(`${header} (${changed.length}):`);

  for (const entry of changed) {
    const marker = dryRun ? "→" : "✓";
    console.log(
      `${marker} ${entry.fileName}: ${entry.newTitle}`
    );
  }

  if (unchanged > 0) {
    console.log(`${unchanged} session(s) already tagged; skipped.`);
  }
}

async function resolveTargetFiles(): Promise<{ files: string[]; warnings: string[] }> {
  if (targetArgs.length === 0) {
    const entries = await fs.readdir(sessionDir, { withFileTypes: true });
    const files = entries
      .filter((entry) => entry.isFile() && entry.name.endsWith(".jsonl"))
      .map((entry) => path.join(sessionDir, entry.name))
      .sort();
    return { files, warnings: [] };
  }

  const files: string[] = [];
  const seen = new Set<string>();
  const warnings: string[] = [];

  for (const target of targetArgs) {
    const candidates = resolveTargetCandidates(target);
    let matched = false;

    for (const candidate of candidates) {
      try {
        const stat = await fs.stat(candidate);
        if (stat.isFile() && candidate.endsWith(".jsonl")) {
          if (!seen.has(candidate)) {
            seen.add(candidate);
            files.push(candidate);
          }
          matched = true;
        }
      } catch {
        continue;
      }
    }

    if (!matched) {
      warnings.push(`No session matched argument: ${target}`);
    }
  }

  return { files, warnings };
}

function resolveTargetCandidates(target: string): string[] {
  if (path.isAbsolute(target)) {
    return target.endsWith(".jsonl")
      ? [target]
      : [target, `${target}.jsonl`];
  }

  const direct = path.join(sessionDir, target);
  const withExt = direct.endsWith(".jsonl") ? direct : `${direct}.jsonl`;
  return direct === withExt ? [direct] : [direct, withExt];
}

void main().catch((error) => {
  console.error(error);
  process.exit(1);
});
