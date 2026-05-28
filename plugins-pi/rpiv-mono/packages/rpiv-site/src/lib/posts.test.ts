import { describe, expect, it } from "vitest";
import { computeReadingTime } from "./reading-time";

describe("computeReadingTime", () => {
	it("returns 1 for an empty body (never zero)", () => {
		expect(computeReadingTime("")).toBe(1);
	});

	it("returns 1 for a single word", () => {
		expect(computeReadingTime("hello")).toBe(1);
	});

	it("returns 1 at exactly 200 words", () => {
		const body = Array.from({ length: 200 }, () => "word").join(" ");
		expect(computeReadingTime(body)).toBe(1);
	});

	it("rounds up to 2 at 201 words", () => {
		const body = Array.from({ length: 201 }, () => "word").join(" ");
		expect(computeReadingTime(body)).toBe(2);
	});

	it("returns 5 for 1000 words", () => {
		const body = Array.from({ length: 1000 }, () => "word").join(" ");
		expect(computeReadingTime(body)).toBe(5);
	});

	it("ignores collapsed whitespace runs", () => {
		expect(computeReadingTime("one   two\n\nthree\ttab")).toBe(1);
	});
});
