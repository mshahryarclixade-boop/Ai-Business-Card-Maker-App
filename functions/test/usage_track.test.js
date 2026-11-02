"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const usage = require("../usage");

/** A tiny Firestore stand-in that records set() calls. */
function fakeEnv({ fail = false, hang = false } = {}) {
  const writes = [];
  const FieldValue = { increment: (n) => ({ inc: n }), serverTimestamp: () => ({ ts: true }) };
  const db = {
    collection: (c) => ({
      doc: (id) => ({
        set: (data, opts) => {
          if (hang) return new Promise(() => {});
          if (fail) return Promise.reject(new Error("permission-denied"));
          writes.push({ c, id, data, opts });
          return Promise.resolve();
        },
      }),
    }),
  };
  return { env: { db, FieldValue }, writes };
}

const summary = { totalTokens: 500, estimatedCostUsd: 0.0003 };
const UDID = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890";

test("each task maps to the feature it is counted under", () => {
  assert.equal(usage.FEATURE_OF.coachReply, "clixa");
  for (const t of ["buildProfile", "rewrite", "analyze", "fixSuggestion"]) assert.equal(usage.FEATURE_OF[t], "career");
  for (const t of ["panelTurn", "panelReport"]) assert.equal(usage.FEATURE_OF[t], "panel");
  assert.equal(usage.FEATURE_OF["generateCard.image"], "ai_card");
});

test("a query is stored under the user's id with feature, day, tokens and cost", async () => {
  const { env, writes } = fakeEnv();
  const ok = await usage.trackQuery(env, { udid: UDID }, "coachReply", summary, { now: new Date("2026-11-02T10:00:00Z") });
  assert.equal(ok, true);
  assert.equal(writes.length, 1);
  const w = writes[0];
  assert.deepEqual([w.c, w.id, w.opts], ["ai_usage", UDID, { merge: true }]);
  assert.equal(w.data.udid, UDID);
  assert.deepEqual(w.data.total.queries, { inc: 1 });
  assert.deepEqual(w.data.total.tokens, { inc: 500 });
  assert.deepEqual(w.data.features.clixa.queries, { inc: 1 });
  assert.deepEqual(w.data.days["2026-11-02"].clixa, { inc: 1 });
  assert.equal(w.data.lastFeature, "clixa");
});

test("career and panel queries are counted under their own feature", async () => {
  for (const [task, feature] of [["analyze", "career"], ["panelTurn", "panel"], ["panelReport", "panel"], ["generateCard.image", "ai_card"]]) {
    const { env, writes } = fakeEnv();
    await usage.trackQuery(env, { udid: UDID }, task, summary);
    assert.ok(writes[0].data.features[feature], `${task} -> ${feature}`);
  }
});

test("nothing is stored without a plausible user id or for an unknown task", async () => {
  for (const data of [{}, { udid: "" }, { udid: "short" }, { udid: "bad id with spaces!!" }, { udid: 5 }, null]) {
    const { env, writes } = fakeEnv();
    assert.equal(await usage.trackQuery(env, data, "coachReply", summary), false);
    assert.equal(writes.length, 0);
  }
  const { env, writes } = fakeEnv();
  assert.equal(await usage.trackQuery(env, { udid: UDID }, "somethingElse", summary), false);
  assert.equal(writes.length, 0);
});

test("a Firestore failure or a hang never breaks or delays the AI answer for long", async () => {
  const bad = fakeEnv({ fail: true });
  assert.equal(await usage.trackQuery(bad.env, { udid: UDID }, "coachReply", summary), false);
  const slow = fakeEnv({ hang: true });
  const t0 = Date.now();
  assert.equal(await usage.trackQuery(slow.env, { udid: UDID }, "coachReply", summary, { timeoutMs: 50 }), false);
  assert.ok(Date.now() - t0 < 1000);
});

test("the day key is UTC and stable", () => {
  assert.equal(usage.dayKey(new Date("2026-11-02T23:59:59Z")), "2026-11-02");
  assert.equal(usage.dayKey(new Date("2026-11-03T00:00:00Z")), "2026-11-03");
});
