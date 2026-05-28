import { describe, expect, it, vi } from "vitest";

const ctorCalls: Array<Record<string, unknown>> = [];
const MockDecibri = vi.fn(function (this: Record<string, unknown>, opts: Record<string, unknown>) {
	ctorCalls.push(opts);
	this.on = vi.fn();
	this.once = vi.fn();
	this.stop = vi.fn();
});

vi.mock("decibri", () => ({ default: MockDecibri }));

import { createMic, FRAMES_PER_BUFFER, TARGET_SAMPLE_RATE } from "./mic-source.js";

describe("createMic", () => {
	it("constructs decibri with the dictation-tuned VAD options", async () => {
		const mic = await createMic();
		expect(mic).toBeDefined();
		expect(MockDecibri).toHaveBeenCalled();
		const opts = ctorCalls.at(-1)!;
		expect(opts.sampleRate).toBe(TARGET_SAMPLE_RATE);
		expect(opts.channels).toBe(1);
		expect(opts.framesPerBuffer).toBe(FRAMES_PER_BUFFER);
		expect(opts.format).toBe("int16");
		expect(opts.vad).toBe(true);
		expect(opts.vadMode).toBe("silero");
		expect(opts.vadThreshold).toBe(0.5);
		// 500 ms — the LiveKit value documented in mic-source.ts.
		expect(opts.vadHoldoff).toBe(500);
	});

	it("returned object exposes the DecibriLike surface", async () => {
		const mic = await createMic();
		expect(typeof mic.on).toBe("function");
		expect(typeof mic.once).toBe("function");
		expect(typeof mic.stop).toBe("function");
	});
});
