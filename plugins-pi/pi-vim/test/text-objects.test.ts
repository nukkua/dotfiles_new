import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  isEscapedDelimiter,
  normalizeDelimiterKey,
  resolveDelimitedTextObjectRange,
  resolveQuoteObjectRange,
  resolveWordTextObjectRange,
} from "../text-objects.js";

describe("resolveWordTextObjectRange", () => {
  it("resolves an inner word on the current line", () => {
    assert.deepEqual(resolveWordTextObjectRange("foo bar", 0, 1, "i"), {
      startAbs: 0,
      endAbs: 3,
    });
  });

  it("prefers trailing whitespace for aw", () => {
    assert.deepEqual(resolveWordTextObjectRange("foo bar", 10, 1, "a"), {
      startAbs: 10,
      endAbs: 14,
    });
  });

  it("includes leading whitespace for aw when no trailing whitespace exists", () => {
    assert.deepEqual(resolveWordTextObjectRange("foo bar", 0, 5, "a"), {
      startAbs: 3,
      endAbs: 7,
    });
  });

  it("chooses the next word from whitespace, or the previous word when there is no next word", () => {
    assert.deepEqual(resolveWordTextObjectRange("foo   bar", 0, 3, "i"), {
      startAbs: 6,
      endAbs: 9,
    });
    assert.deepEqual(resolveWordTextObjectRange("foo   ", 0, 4, "i"), {
      startAbs: 0,
      endAbs: 3,
    });
  });

  it("includes intervening whitespace for counted inner word objects", () => {
    assert.deepEqual(resolveWordTextObjectRange("foo bar baz", 0, 1, "i", 2), {
      startAbs: 0,
      endAbs: 7,
    });
  });

  it("uses contiguous non-whitespace runs for WORD semantics", () => {
    assert.deepEqual(resolveWordTextObjectRange("path/to-file", 0, 5, "i", 1, "WORD"), {
      startAbs: 0,
      endAbs: 12,
    });
  });

  it("does not cross newline boundaries", () => {
    assert.deepEqual(resolveWordTextObjectRange("foo\nbar", 0, 1, "i", 2), {
      startAbs: 0,
      endAbs: 3,
    });
  });

  it("returns null for empty or whitespace-only lines", () => {
    assert.equal(resolveWordTextObjectRange("", 0, 0, "i"), null);
    assert.equal(resolveWordTextObjectRange("   ", 0, 1, "a"), null);
  });
});

describe("normalizeDelimiterKey", () => {
  it("normalizes quote delimiter keys", () => {
    assert.deepEqual(normalizeDelimiterKey("\""), {
      type: "quote",
      open: "\"",
      close: "\"",
    });
    assert.deepEqual(normalizeDelimiterKey("'"), {
      type: "quote",
      open: "'",
      close: "'",
    });
    assert.deepEqual(normalizeDelimiterKey("`"), {
      type: "quote",
      open: "`",
      close: "`",
    });
  });

  it("normalizes bracket delimiter aliases", () => {
    const cases = [
      { key: "(", open: "(", close: ")" },
      { key: ")", open: "(", close: ")" },
      { key: "b", open: "(", close: ")" },
      { key: "[", open: "[", close: "]" },
      { key: "]", open: "[", close: "]" },
      { key: "{", open: "{", close: "}" },
      { key: "}", open: "{", close: "}" },
      { key: "B", open: "{", close: "}" },
    ];

    for (const bracketCase of cases) {
      assert.deepEqual(normalizeDelimiterKey(bracketCase.key), {
        type: "bracket",
        open: bracketCase.open,
        close: bracketCase.close,
      }, bracketCase.key);
    }
  });

  it("returns null for unsupported delimiter keys", () => {
    assert.equal(normalizeDelimiterKey("x"), null);
    assert.equal(resolveDelimitedTextObjectRange("x", 0, "i", "x"), null);
  });
});

describe("resolveQuoteObjectRange", () => {
  const cases = [
    {
      name: "double quotes",
      text: 'say "hello" now',
      quote: "\"",
      cursorAbs: 6,
      inner: { startAbs: 5, endAbs: 10 },
      around: { startAbs: 4, endAbs: 11 },
    },
    {
      name: "single quotes",
      text: "say 'hello' now",
      quote: "'",
      cursorAbs: 6,
      inner: { startAbs: 5, endAbs: 10 },
      around: { startAbs: 4, endAbs: 11 },
    },
    {
      name: "backticks",
      text: "run `build` now",
      quote: "`",
      cursorAbs: 6,
      inner: { startAbs: 5, endAbs: 10 },
      around: { startAbs: 4, endAbs: 11 },
    },
  ];

  for (const quoteCase of cases) {
    it(`resolves inside and around ${quoteCase.name}`, () => {
      assert.deepEqual(
        resolveQuoteObjectRange(quoteCase.text, quoteCase.cursorAbs, "i", quoteCase.quote),
        quoteCase.inner,
      );
      assert.deepEqual(
        resolveDelimitedTextObjectRange(quoteCase.text, quoteCase.cursorAbs, "a", quoteCase.quote),
        quoteCase.around,
      );
    });
  }

  it("counts the cursor on either quote delimiter as contained", () => {
    const text = 'say "hello" now';

    assert.deepEqual(resolveDelimitedTextObjectRange(text, 4, "i", "\""), {
      startAbs: 5,
      endAbs: 10,
    });
    assert.deepEqual(resolveDelimitedTextObjectRange(text, 10, "a", "\""), {
      startAbs: 4,
      endAbs: 11,
    });
  });

  it("ignores escaped quotes with an odd number of preceding backslashes", () => {
    const text = String.raw`\"skip\" "yes"`;

    assert.equal(text[1], "\"");
    assert.equal(text[7], "\"");
    assert.equal(text[9], "\"");
    assert.equal(text[13], "\"");
    assert.equal(isEscapedDelimiter(text, 1), true);
    assert.equal(isEscapedDelimiter(text, 7), true);
    assert.deepEqual(resolveDelimitedTextObjectRange(text, 10, "i", "\""), {
      startAbs: 10,
      endAbs: 13,
    });
  });

  it("keeps one, two, and three preceding backslashes distinct while resolving quotes", () => {
    const cases = [
      {
        name: "one preceding backslash",
        text: String.raw`a \"skip\" "yes"`,
        firstQuoteEscaped: true,
      },
      {
        name: "two preceding backslashes",
        text: String.raw`a \\"yes" z`,
        firstQuoteEscaped: false,
      },
      {
        name: "three preceding backslashes",
        text: String.raw`a \\\"skip\\\" "yes"`,
        firstQuoteEscaped: true,
      },
    ];

    for (const quoteCase of cases) {
      const firstQuote = quoteCase.text.indexOf("\"");
      const startAbs = quoteCase.text.indexOf("yes");

      assert.notEqual(firstQuote, -1, `${quoteCase.name} first quote`);
      assert.notEqual(startAbs, -1, `${quoteCase.name} payload`);
      assert.equal(
        isEscapedDelimiter(quoteCase.text, firstQuote),
        quoteCase.firstQuoteEscaped,
        quoteCase.name,
      );
      assert.deepEqual(
        resolveDelimitedTextObjectRange(quoteCase.text, startAbs, "i", "\""),
        {
          startAbs,
          endAbs: startAbs + "yes".length,
        },
        quoteCase.name,
      );
    }
  });

  it("does not cross newline boundaries", () => {
    const text = '"one\n"two"';

    assert.equal(resolveDelimitedTextObjectRange(text, 2, "i", "\""), null);
    assert.deepEqual(resolveDelimitedTextObjectRange(text, 6, "i", "\""), {
      startAbs: 6,
      endAbs: 9,
    });
  });

  it("returns an empty inner range for empty quotes", () => {
    const text = 'say "" now';

    assert.deepEqual(resolveDelimitedTextObjectRange(text, 4, "i", "\""), {
      startAbs: 5,
      endAbs: 5,
    });
    assert.deepEqual(resolveDelimitedTextObjectRange(text, 5, "a", "\""), {
      startAbs: 4,
      endAbs: 6,
    });
  });
});

describe("resolveBracketObjectRange", () => {
  it("resolves inside and around parentheses", () => {
    const text = "call(foo) now";

    assert.deepEqual(resolveDelimitedTextObjectRange(text, 6, "i", "("), {
      startAbs: 5,
      endAbs: 8,
    });
    assert.deepEqual(resolveDelimitedTextObjectRange(text, 6, "a", "("), {
      startAbs: 4,
      endAbs: 9,
    });
  });

  it("chooses the smallest nested containing pair", () => {
    const text = "a(b(c)d)e";

    assert.deepEqual(resolveDelimitedTextObjectRange(text, 4, "a", "("), {
      startAbs: 3,
      endAbs: 6,
    });
  });

  it("resolves cross-line brace ranges", () => {
    const text = "fn {\n  x\n}";

    assert.deepEqual(resolveDelimitedTextObjectRange(text, 7, "i", "{"), {
      startAbs: 4,
      endAbs: 9,
    });
    assert.deepEqual(resolveDelimitedTextObjectRange(text, 7, "a", "{"), {
      startAbs: 3,
      endAbs: 10,
    });
  });

  it("counts the cursor on an opening or closing bracket as contained", () => {
    const text = "x(foo)";

    assert.deepEqual(resolveDelimitedTextObjectRange(text, 1, "i", "("), {
      startAbs: 2,
      endAbs: 5,
    });
    assert.deepEqual(resolveDelimitedTextObjectRange(text, 5, "i", "("), {
      startAbs: 2,
      endAbs: 5,
    });
  });

  it("resolves large buffers with many unmatched delimiters using stack-plus-best behavior", () => {
    const unmatchedClosers = "}".repeat(2_000);
    const unmatchedOpeners = "{".repeat(4_000);
    const target = "{outer {inner} tail}";
    const text = `${unmatchedClosers}${unmatchedOpeners}${target}${unmatchedOpeners}`;
    const targetStartAbs = unmatchedClosers.length + unmatchedOpeners.length;
    const innerPairStart = target.indexOf("{inner}");
    const cursorAbs = targetStartAbs + target.indexOf("inner");

    assert.deepEqual(resolveDelimitedTextObjectRange(text, cursorAbs, "a", "{"), {
      startAbs: targetStartAbs + innerPairStart,
      endAbs: targetStartAbs + innerPairStart + "{inner}".length,
    });
  });

  it("keeps mixed-bracket matching lexical for the selected delimiter type", () => {
    const text = "outer { [ value } still ]";
    const cursorAbs = text.indexOf("value");

    assert.deepEqual(resolveDelimitedTextObjectRange(text, cursorAbs, "a", "{"), {
      startAbs: text.indexOf("{"),
      endAbs: text.indexOf("}") + 1,
    });
    assert.deepEqual(resolveDelimitedTextObjectRange(text, cursorAbs, "a", "["), {
      startAbs: text.indexOf("["),
      endAbs: text.indexOf("]") + 1,
    });
  });

  it("returns an empty inner range for empty brackets", () => {
    const text = "fn()";

    assert.deepEqual(resolveDelimitedTextObjectRange(text, 2, "i", "("), {
      startAbs: 3,
      endAbs: 3,
    });
    assert.deepEqual(resolveDelimitedTextObjectRange(text, 3, "a", ")"), {
      startAbs: 2,
      endAbs: 4,
    });
  });

  it("returns null for unmatched brackets", () => {
    assert.equal(resolveDelimitedTextObjectRange("call(foo", 5, "i", "("), null);
    assert.equal(resolveDelimitedTextObjectRange("call(foo)", 5, "i", "["), null);
  });
});
