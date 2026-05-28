/**
 * Shared utilities for rpiv-core.
 *
 * Pure functions — no ExtensionAPI, no side effects, fail-soft.
 */

import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

// ---------------------------------------------------------------------------
// PI Agent Settings path
// ---------------------------------------------------------------------------

/** Path to the Pi agent settings file. Shared by package-checks and prune-legacy-siblings. */
export const PI_AGENT_SETTINGS = join(homedir(), ".pi", "agent", "settings.json");

// ---------------------------------------------------------------------------
// Type guards
// ---------------------------------------------------------------------------

/** Runtime type guard for plain objects (not null, not array). */
export function isPlainObject(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

// ---------------------------------------------------------------------------
// Error formatting
// ---------------------------------------------------------------------------

/**
 * Safely convert a caught value to an error message string.
 * Optional fallback overrides String(e) for non-Error values.
 */
export function toErrorMessage(e: unknown, fallback?: string): string {
	if (e instanceof Error) return e.message;
	return fallback ?? String(e);
}

// ---------------------------------------------------------------------------
// Settings reader
// ---------------------------------------------------------------------------

/** Parsed result from reading Pi agent settings. */
interface PiAgentSettingsResult {
	settings: Record<string, unknown>;
	packages: unknown[];
}

/**
 * Read and parse ~/.pi/agent/settings.json.
 * Returns undefined if the file is missing, has invalid JSON, or is not a plain object
 * with a packages array. Fail-soft — never throws.
 */
export function readPiAgentSettings(): PiAgentSettingsResult | undefined {
	if (!existsSync(PI_AGENT_SETTINGS)) return undefined;
	let parsed: unknown;
	try {
		parsed = JSON.parse(readFileSync(PI_AGENT_SETTINGS, "utf-8"));
	} catch {
		return undefined;
	}
	if (!isPlainObject(parsed)) return undefined;
	const settings = parsed;
	if (!Array.isArray(settings.packages)) return undefined;
	return { settings, packages: settings.packages as unknown[] };
}
