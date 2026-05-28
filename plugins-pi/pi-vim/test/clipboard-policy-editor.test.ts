import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { createEditorWithSpy, sendKeys } from "./harness.js";

function nextImmediate(): Promise<void> {
  return new Promise<void>((resolve) => setImmediate(resolve));
}

describe("clipboard mirror policy", () => {
  it("all clipboard mirror policy mirrors mutation and yank writes", async () => {
    const { editor, clipboardWrites } = createEditorWithSpy("foo bar");
    editor.setClipboardMirrorPolicy("all");

    sendKeys(editor, ["d", "w", "y", "w"]);
    await nextImmediate();

    assert.equal(editor.getRegister(), "bar");
    assert.deepEqual(clipboardWrites, ["foo ", "bar"]);
  });

  it("all clipboard mirror policy mirrors change writes", async () => {
    const { editor, clipboardWrites } = createEditorWithSpy("foo bar");
    editor.setClipboardMirrorPolicy("all");

    sendKeys(editor, ["c", "w"]);
    await nextImmediate();

    assert.equal(editor.getRegister(), "foo ");
    assert.deepEqual(clipboardWrites, ["foo "]);
  });

  it("yank clipboard mirror policy skips delete writes but updates the register", () => {
    const { editor, clipboardWrites } = createEditorWithSpy("foo bar");
    editor.setClipboardMirrorPolicy("yank");

    sendKeys(editor, ["d", "w"]);

    assert.equal(editor.getRegister(), "foo ");
    assert.deepEqual(clipboardWrites, []);
  });

  it("yank clipboard mirror policy skips change writes but updates the register", () => {
    const { editor, clipboardWrites } = createEditorWithSpy("foo bar");
    editor.setClipboardMirrorPolicy("yank");

    sendKeys(editor, ["c", "w"]);

    assert.equal(editor.getRegister(), "foo ");
    assert.deepEqual(clipboardWrites, []);
  });

  it("yank clipboard mirror policy skips mutation writes", async () => {
    const { editor, clipboardWrites } = createEditorWithSpy("foo bar");
    editor.setClipboardMirrorPolicy("yank");

    sendKeys(editor, ["d", "w", "y", "w", "c", "w"]);
    await nextImmediate();

    assert.equal(editor.getRegister(), "bar");
    assert.deepEqual(clipboardWrites, ["bar"]);
  });

  it("never clipboard mirror policy keeps mutation and yank writes internal", () => {
    const { editor, clipboardWrites } = createEditorWithSpy("foo bar");
    editor.setClipboardMirrorPolicy("never");

    sendKeys(editor, ["y", "y"]);

    assert.equal(editor.getRegister(), "foo bar\n");
    assert.deepEqual(clipboardWrites, []);

    sendKeys(editor, ["d", "w"]);

    assert.equal(editor.getRegister(), "foo ");
    assert.deepEqual(clipboardWrites, []);
  });

  it("never clipboard mirror policy keeps change writes internal", () => {
    const { editor, clipboardWrites } = createEditorWithSpy("foo bar");
    editor.setClipboardMirrorPolicy("never");

    sendKeys(editor, ["c", "w"]);

    assert.equal(editor.getRegister(), "foo ");
    assert.deepEqual(clipboardWrites, []);
  });

  for (const policy of ["all", "yank", "never"] as const) {
    it(`${policy} clipboard mirror policy keeps p reading OS clipboard`, () => {
      const { editor } = createEditorWithSpy("ab");
      editor.setClipboardMirrorPolicy(policy);
      editor.setRegister("shadow");
      editor.setClipboardReadFn(() => "SYS");

      sendKeys(editor, ["p"]);

      assert.equal(editor.getText(), "aSYSb");
      assert.equal(editor.getRegister(), "shadow");
    });

    it(`${policy} clipboard mirror policy keeps P reading OS clipboard`, () => {
      const { editor } = createEditorWithSpy("ab");
      editor.setClipboardMirrorPolicy(policy);
      editor.setRegister("shadow");
      editor.setClipboardReadFn(() => "SYS");

      sendKeys(editor, ["P"]);

      assert.equal(editor.getText(), "SYSab");
      assert.equal(editor.getRegister(), "shadow");
    });
  }
});
