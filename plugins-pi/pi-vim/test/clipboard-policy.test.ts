import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  DEFAULT_CLIPBOARD_MIRROR_POLICY,
  readPiVimClipboardMirrorSetting,
  resolveClipboardMirrorPolicy,
} from "../clipboard-policy.js";

describe("clipboard mirror policy resolver", () => {
  it("defaults missing clipboard mirror policy to all", () => {
    assert.deepEqual(resolveClipboardMirrorPolicy(undefined), {
      policy: DEFAULT_CLIPBOARD_MIRROR_POLICY,
    });
  });

  it("accepts all supported clipboard mirror policy values", () => {
    assert.deepEqual(resolveClipboardMirrorPolicy("all"), { policy: "all" });
    assert.deepEqual(resolveClipboardMirrorPolicy("yank"), { policy: "yank" });
    assert.deepEqual(resolveClipboardMirrorPolicy("never"), { policy: "never" });
  });

  it("normalizes clipboard mirror policy casing and whitespace", () => {
    assert.deepEqual(resolveClipboardMirrorPolicy("YANK"), { policy: "yank" });
    assert.deepEqual(resolveClipboardMirrorPolicy(" never "), { policy: "never" });
  });

  it("falls back to all and reports invalid clipboard mirror strings", () => {
    const result = resolveClipboardMirrorPolicy("delete");

    assert.equal(result.policy, "all");
    assert.match(result.warning ?? "", /delete/);
    assert.match(result.warning ?? "", /all, yank, never/);
  });

  it("falls back to all and reports non-string clipboard mirror values safely", () => {
    const result = resolveClipboardMirrorPolicy({ mode: "yank" });

    assert.equal(result.policy, "all");
    assert.match(result.warning ?? "", /object/);
    assert.match(result.warning ?? "", /all, yank, never/);
  });
});

describe("piVim clipboard mirror settings reader", () => {
  it("returns undefined when global and project settings are missing", () => {
    assert.equal(readPiVimClipboardMirrorSetting(undefined, undefined), undefined);
    assert.equal(readPiVimClipboardMirrorSetting(null, null), undefined);
    assert.equal(readPiVimClipboardMirrorSetting("bad", 42), undefined);
  });

  it("reads global piVim clipboardMirror when project setting is missing", () => {
    assert.equal(
      readPiVimClipboardMirrorSetting(
        { piVim: { clipboardMirror: "yank" } },
        {},
      ),
      "yank",
    );
  });

  it("lets project piVim clipboardMirror override global", () => {
    assert.equal(
      readPiVimClipboardMirrorSetting(
        { piVim: { clipboardMirror: "never" } },
        { piVim: { clipboardMirror: "all" } },
      ),
      "all",
    );
  });

  it("treats invalid project clipboardMirror as an override instead of falling back to global", () => {
    assert.equal(
      readPiVimClipboardMirrorSetting(
        { piVim: { clipboardMirror: "yank" } },
        { piVim: { clipboardMirror: null } },
      ),
      null,
    );
  });

  it("treats malformed project piVim settings as an override instead of falling back to global", () => {
    const setting = readPiVimClipboardMirrorSetting(
      { piVim: { clipboardMirror: "yank" } },
      { piVim: "bad" },
    );
    const result = resolveClipboardMirrorPolicy(setting);

    assert.equal(setting, "bad");
    assert.equal(result.policy, "all");
    assert.match(result.warning ?? "", /bad/);
    assert.match(result.warning ?? "", /all, yank, never/);
  });
});
