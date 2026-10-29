"use strict";

// Token usage and estimated cost of every Gemini call. Each call writes one
// console line (visible in Cloud Logging / `firebase functions:log`):
//
//   AI_USAGE {"task":"coachReply","label":"coachReply","model":"...","promptTokens":...}
//
// and the total for a request is returned to the app as `_usage` (the app
// prints it in debug builds). Logging only: nothing here changes a result.
//
// PRICES ARE ASSUMPTIONS, not read from Google: the real rates for these model
// names are not known to this code. Override them without a deploy-time edit by
// setting GEMINI_PRICES_JSON on the function, e.g.
//   {"gemini-3.1-flash-lite":{"inPerM":0.10,"outPerM":0.40}}
// (US dollars per 1,000,000 tokens; output includes "thinking" tokens).

const { AsyncLocalStorage } = require("node:async_hooks");

const DEFAULT_PRICES = {
  // Third-party price listings for Gemini 3.1 Flash-Lite (text): $0.25 in, $1.50 out per 1M
  // tokens. NOT confirmed against Google's own pricing page.
  "gemini-3.1-flash-lite": { inPerM: 0.25, outPerM: 1.5 },
  // Image output is billed per image: listings for the Flash image model say about $0.045
  // per ~1,290-token image, i.e. about $34.88 per 1M output tokens. Unconfirmed, and the
  // exact model ID used here has no listing found.
  "gemini-3.1-flash-lite-image": { inPerM: 0.25, outPerM: 34.88 },
};

function prices() {
  try {
    if (process.env.GEMINI_PRICES_JSON) {
      return { ...DEFAULT_PRICES, ...JSON.parse(process.env.GEMINI_PRICES_JSON) };
    }
  } catch (_) {
    // A bad override falls back to the defaults.
  }
  return DEFAULT_PRICES;
}

const store = new AsyncLocalStorage();

/** Cost in USD for [model] from Gemini's `usageMetadata`. */
function costOf(model, u) {
  const p = prices()[model];
  if (!p) return null;
  const input = u.promptTokens || 0;
  const output = (u.outputTokens || 0) + (u.thoughtsTokens || 0);
  return (input * p.inPerM + output * p.outPerM) / 1e6;
}

/** Runs [fn] collecting every AI call it makes; returns [result, summary]. */
async function withUsage(task, fn) {
  const ctx = { task, calls: [] };
  const result = await store.run(ctx, fn);
  const summary = summarise(ctx);
  const { breakdown, ...totals } = summary;
  console.log("AI_TASK_TOTAL", JSON.stringify({ task, ...totals }));
  return [result, summary];
}

function summarise(ctx) {
  const sum = (k) => ctx.calls.reduce((a, c) => a + (c[k] || 0), 0);
  const cost = ctx.calls.reduce((a, c) => a + (c.estimatedCostUsd || 0), 0);
  return {
    calls: ctx.calls.length,
    models: [...new Set(ctx.calls.map((c) => c.model))],
    promptTokens: sum("promptTokens"),
    outputTokens: sum("outputTokens") + sum("thoughtsTokens"),
    totalTokens: sum("totalTokens"),
    estimatedCostUsd: Number(cost.toFixed(6)),
    // One entry per model response, so the app can show each one.
    breakdown: ctx.calls.map((c) => ({
      label: c.label,
      model: c.model,
      promptTokens: c.promptTokens,
      outputTokens: (c.outputTokens || 0) + (c.thoughtsTokens || 0),
      totalTokens: c.totalTokens,
      estimatedCostUsd: c.estimatedCostUsd,
      ms: c.ms,
    })),
  };
}

/** Logs one model response's usage and adds it to the running request total. */
function record({ label, model, res, ms }) {
  const m = res?.usageMetadata || {};
  const u = {
    promptTokens: m.promptTokenCount || 0,
    outputTokens: m.candidatesTokenCount || 0,
    thoughtsTokens: m.thoughtsTokenCount || 0,
    totalTokens: m.totalTokenCount || 0,
  };
  const entry = {
    task: store.getStore()?.task || null,
    label: label || store.getStore()?.task || "unlabelled",
    model,
    ...u,
    estimatedCostUsd: costOf(model, u),
    ms,
  };
  store.getStore()?.calls.push(entry);
  console.log("AI_USAGE", JSON.stringify(entry));
  return entry;
}

module.exports = { withUsage, record, costOf, prices };
