"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const usage = require("../usage");

test("AI answers store nothing: no tokens, queries or costs", async () => {
  assert.equal(await usage.trackQuery({}, { udid: "9f8e7d6c5b4a3921" }, "coachReply", { totalTokens: 500, estimatedCostUsd: 0.1 }), false);
});

test("the day key is UTC and stable", () => {
  assert.equal(usage.dayKey(new Date("2026-11-02T23:59:59Z")), "2026-11-02");
  assert.equal(usage.dayKey(new Date("2026-11-03T00:00:00Z")), "2026-11-03");
});
