"use strict";

// Code-level helpers around the Safety check prompt: what must hold whatever
// the model says (redaction of sensitive data, a self-harm net) and clean-up of
// generated lines.

/** Replaces card, ID, account and password patterns. Never stored or repeated. */
function redactSensitive(text) {
  let out = String(text || "");
  let redacted = false;
  const sub = (re, to) => {
    out = out.replace(re, () => {
      redacted = true;
      return to;
    });
  };
  sub(/\b(?:\d[ -]?){13,19}\b/g, "[number removed]");
  sub(/\b\d{3}-\d{2}-\d{4}\b/g, "[number removed]");
  sub(/\b[A-Z]{2}\d{2}[A-Z0-9]{10,30}\b/g, "[number removed]");
  sub(/\b(pass(?:word|code)|pin|cvv|cvc)\s*(?:is|:|=)\s*\S+/gi, "$1: [removed]");
  return { text: out, redacted };
}

const CRISIS_RE = new RegExp(
  [
    "\\b(kill myself|killing myself|end my life|ending my life|take my own life)\\b",
    "\\bsuicid(e|al)\\b",
    "\\b(want|wanna|going) to die\\b",
    "\\bdon'?t want to (be alive|live|exist)\\b",
    "\\b(hurt|harm|cut) myself\\b",
    "\\bself[- ]?harm\\b",
    "\\bdon'?t see the point of living\\b",
    "\\bbetter off (dead|without me)\\b",
  ].join("|"),
  "i",
);

/** A second net for self-harm wording, in case the model misses it. */
function crisisSignal(text) {
  return CRISIS_RE.test(String(text || ""));
}

/** Cuts a line over [max] words at the last full sentence. */
function capWords(text, max) {
  const words = String(text).trim().split(/\s+/);
  if (words.length <= max) return String(text).trim();
  const cut = words.slice(0, max).join(" ");
  const idx = Math.max(cut.lastIndexOf(". "), cut.lastIndexOf("? "), cut.lastIndexOf("! "), /[.!?]$/.test(cut) ? cut.length - 1 : -1);
  return idx > cut.length * 0.4 ? cut.slice(0, idx + 1) : `${cut.replace(/[,;:\s]+$/, "")}.`;
}

/** Strips a "Name:" prefix, markdown, emojis and stage directions from a line. */
function cleanLine(text, speakerName) {
  let t = String(text || "").replace(/\r/g, "").trim();
  t = t.replace(new RegExp(`^\\s*(?:\\*\\*)?${speakerName}(?:\\*\\*)?\\s*[:\\-—]\\s*`, "i"), "");
  t = t.replace(/\*[^*\n]{1,60}\*/g, "");
  t = t.replace(/[*_`#>]+/g, "");
  t = t.replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu, "");
  t = t.replace(/^["“”]+|["“”]+$/g, "");
  return t.replace(/\s*\n+\s*/g, " ").replace(/[ \t]{2,}/g, " ").trim();
}

module.exports = { redactSensitive, crisisSignal, capWords, cleanLine };
