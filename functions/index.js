const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { GoogleGenAI } = require("@google/genai");
const panelEngine = require("./panel/engine");

initializeApp();

// Model names (verify before deploy).
const CARD_MODEL = "gemini-3.1-flash-lite-image";

const OPTIONS = {
  region: "us-central1",
  timeoutSeconds: 300,
  memory: "1GiB",
  enforceAppCheck: false, // TODO: set back to true before release.
  maxInstances: 10,
};

function getClient() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === "paste_key_here") {
    throw new HttpsError("failed-precondition", "Server key not configured.");
  }
  return new GoogleGenAI({ apiKey });
}

function requireString(value, name) {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${name} is required.`);
  }
  return value;
}

function inlinePart(b64, mime) {
  return { inlineData: { data: b64, mimeType: mime } };
}

function wrapGeminiError(e) {
  if (e instanceof HttpsError) return e;
  console.error("Gemini error:", e);
  return new HttpsError("internal", "AI request failed.");
}

// generateCard: { prompt, referenceBase64, referenceMime, logoBase64?, logoMime? }
// returns { imageBase64 }
// A `task` field still runs a text task here, for app builds from before the
// text features got their own functions (see below); new builds never send it.
exports.generateCard = onCall(OPTIONS, async (request) => {
  const d = request.data || {};
  if (d.task) return runCareerTask(d);
  const prompt = requireString(d.prompt, "prompt");
  const refB64 = requireString(d.referenceBase64, "referenceBase64");
  const refMime = requireString(d.referenceMime, "referenceMime");

  const parts = [{ text: prompt }, inlinePart(refB64, refMime)];
  if (d.logoBase64 && d.logoMime) parts.push(inlinePart(d.logoBase64, d.logoMime));

  try {
    const ai = getClient();
    const res = await ai.models.generateContent({
      model: CARD_MODEL,
      contents: [{ role: "user", parts }],
      config: { responseModalities: ["IMAGE"] },
    });
    const outParts = res?.candidates?.[0]?.content?.parts || [];
    const img = outParts.find((p) => p.inlineData && p.inlineData.data);
    if (!img) throw new HttpsError("internal", "No image returned.");
    return { imageBase64: img.inlineData.data };
  } catch (e) {
    throw wrapGeminiError(e);
  }
});

// ---------------------------------------------------------------------------
// Career Studio text AI, served by generateCard when the request has a `task`.
// { task, language?, ...task fields } -> JSON object (see TASKS)

// Model name (verify before deploy).
const TEXT_MODEL = "gemini-3.1-flash-lite";

const RULES =
  "You write LinkedIn profile copy. Use ONLY facts the user provided: never " +
  "invent employers, numbers, titles, degrees or results. Be clear, specific " +
  "and concise. Plain text only: no markdown, no emojis, no quotes around " +
  "the answer.";

function clip(v, max = 3000) {
  return typeof v === "string" ? v.trim().slice(0, max) : "";
}

async function generateJson(prompt, extraParts = [], opts = {}) {
  const ai = getClient();
  const res = await ai.models.generateContent({
    model: TEXT_MODEL,
    contents: [{ role: "user", parts: [{ text: prompt }, ...extraParts] }],
    config: { responseMimeType: "application/json", temperature: opts.temperature ?? 0.8 },
  });
  const raw = res?.candidates?.[0]?.content?.parts?.map((p) => p.text || "").join("") || "";
  try {
    return JSON.parse(raw);
  } catch (_) {
    throw new HttpsError("internal", "Bad AI response.");
  }
}

// Plain text (the Expert Panel's spoken lines).
async function generateText(prompt, opts = {}) {
  const ai = getClient();
  const res = await ai.models.generateContent({
    model: TEXT_MODEL,
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    config: { temperature: opts.temperature ?? 0.8 },
  });
  const raw = res?.candidates?.[0]?.content?.parts?.map((p) => p.text || "").join("") || "";
  if (!raw.trim()) throw new HttpsError("internal", "Empty AI response.");
  return raw;
}

// The Expert Panel workflow (see panel/engine.js).
const panel = panelEngine.create({ generateJson, generateText, HttpsError, log: console });

function needText(obj, key) {
  const t = clip(obj?.[key], 4000);
  if (!t) throw new HttpsError("internal", "Empty AI response.");
  return t;
}

function answersBlock(a = {}) {
  const list = Array.isArray(a.audience) ? a.audience.map((x) => clip(x, 60)).join(", ") : "";
  return [
    `Name: ${clip(a.name, 80)}`,
    `Current role: ${clip(a.role, 100)}`,
    `Company: ${clip(a.company, 100)}`,
    `Location: ${clip(a.location, 100)}`,
    `Years of experience: ${clip(a.experience, 10)}`,
    `Goal: ${clip(a.goal, 60)}`,
    `Audience: ${list}`,
    `Tone: ${clip(a.tone, 30)}`,
    `Achievements / wins (user's words): ${clip(a.wins, 1500) || "none given"}`,
  ].join("\n");
}

const COACH_MODES = {
  discuss:
    "Help the user sharpen a business idea. Point out what is strong and what is unclear, then ask the one question that would help most.",
  validate:
    "Validate the idea honestly. Gather, one question per turn: what they sell, to whom, what buyers would pay, what it costs them to deliver, and how much they can make or serve.",
  plan:
    "Help write a one-page business plan step by step. Ask one question at a time (business, customer, offer, price, how they get customers, costs). When you have enough, write the plan as short labelled lines.",
  numbers:
    "Work out the numbers: price, cost, margin, profit, break-even. Do the arithmetic only from the user's figures, show it briefly, and ask for any missing figure.",
  talk: "Answer business questions plainly and practically, and ask what they want to do next.",
};

const PART_IDS = ["headline", "about", "experience", "skills", "photo", "featured", "link"];


const TASKS = {
  // { answers } -> { headline, about, experience }
  async buildProfile(d, lang) {
    const out = await generateJson(
      `${RULES}\nWrite in ${lang}.\n` +
        "Create a complete LinkedIn profile from these answers.\n" +
        "- headline: one line, max 200 characters, role + who you help + value.\n" +
        "- about: 2-3 short paragraphs, max 1200 characters, first person, in the requested tone, aimed at the audience and goal.\n" +
        "- experience: the current role as a short description plus 2-4 bullet lines starting with '• ', built only from the wins given (if none, keep it to the role and responsibilities).\n" +
        'Return JSON: {"headline": "", "about": "", "experience": ""}\n\n' +
        answersBlock(d.answers),
    );
    return {
      headline: needText(out, "headline"),
      about: needText(out, "about"),
      experience: needText(out, "experience"),
    };
  },

  // { section, text, answers? } -> { text }
  async rewrite(d, lang) {
    const section = clip(d.section, 20);
    const out = await generateJson(
      `${RULES}\nWrite in ${lang}.\n` +
        `Rewrite this LinkedIn "${section}" section with fresh wording. Keep every fact, ` +
        "the tone and about the same length. Do not add new claims.\n" +
        'Return JSON: {"text": ""}\n\n' +
        `Profile answers for context:\n${answersBlock(d.answers)}\n\n` +
        `Text to rewrite:\n${clip(d.text)}`,
    );
    return { text: needText(out, "text") };
  },

  // { fixId, issue, current, avoid?, profile? } -> { text }
  async fixSuggestion(d, lang) {
    const avoid = Array.isArray(d.avoid) ? d.avoid.map((x) => clip(x, 600)).filter(Boolean) : [];
    const out = await generateJson(
      `${RULES}\nWrite in ${lang}.\n` +
        `A LinkedIn profile check found this issue in the "${clip(d.fixId, 20)}" part: ${clip(d.issue, 300)}\n` +
        "Write the improved replacement text: clearer, shorter, based only on the current " +
        "text and profile facts below. For parts that are not text (banner, link, featured, " +
        "skills) give the concrete suggestion in one or two short lines.\n" +
        (avoid.length ? `Must differ from these earlier suggestions:\n- ${avoid.join("\n- ")}\n` : "") +
        'Return JSON: {"text": ""}\n\n' +
        `Current text of this part:\n${clip(d.current) || "(empty)"}\n\n` +
        `Rest of the profile:\n${clip(d.profile, 3500) || "(not available)"}`,
    );
    return { text: needText(out, "text") };
  },

  // Clixa, the AI business coach.
  // { mode, messages: [{role: "user"|"coach", text}], about? } -> { reply, verdict? }
  async coachReply(d, lang) {
    const mode = Object.prototype.hasOwnProperty.call(COACH_MODES, d.mode) ? d.mode : "talk";
    const msgs = (Array.isArray(d.messages) ? d.messages : [])
      .filter((m) => m && typeof m.text === "string" && m.text.trim())
      .slice(-24);
    if (!msgs.length || msgs[msgs.length - 1].role !== "user") {
      throw new HttpsError("invalid-argument", "Nothing to answer.");
    }
    const userTurns = msgs.filter((m) => m.role === "user").length;
    const convo = msgs
      .map((m) => `${m.role === "user" ? "User" : "Clixa"}: ${clip(m.text, 800)}`)
      .join("\n");
    const about = clip(d.about, 200);
    const out = await generateJson(
      "You are Clixa, a warm, practical AI business coach inside a business-card app.\n" +
        `Write in ${lang}. ${COACH_MODES[mode]}\n` +
        "Rules: use ONLY facts and figures the user gave; never invent numbers, markets or competitors. " +
        "Ask at most ONE question per turn. Keep replies under 70 words (a finished plan may use up to 160). " +
        "Plain text only: no markdown, no emojis, no lists with symbols. " +
        "You give practice feedback, not financial, legal or tax advice.\n" +
        (about ? `About the user: ${about}\n` : "") +
        (mode === "validate"
          ? `The user has answered ${userTurns} time(s). Once you know what they sell, to whom, ` +
            "the price, the cost and their capacity (normally after 4 answers), set \"verdict\"; " +
            "until then set it to null and ask the next missing question. When you give a verdict, " +
            "\"reply\" is one short sentence leading into it.\n"
          : "Always set \"verdict\" to null.\n") +
        'Return JSON: {"reply": "", "verdict": null or {"badge": "one or two words, e.g. Promising, Mixed, Risky", ' +
        '"headline": "one sentence", "strengths": ["", ""], "risks": ["", ""], "next": ["", ""]}}\n\n' +
        `Conversation so far:\n${convo}\nClixa:`,
    );
    const reply = needText(out, "reply");
    let verdict = null;
    const v = out.verdict;
    if (mode === "validate" && v && typeof v === "object") {
      const list = (a) =>
        (Array.isArray(a) ? a : [])
          .map((x) => clip(x, 140))
          .filter(Boolean)
          .slice(0, 4);
      verdict = {
        badge: clip(v.badge, 24) || "Mixed",
        headline: clip(v.headline, 200),
        strengths: list(v.strengths),
        risks: list(v.risks),
        next: list(v.next),
      };
      if (!verdict.headline) verdict = null;
    }
    return { reply, verdict };
  },

  // ---- Expert panel (panel/engine.js) ----------------------------------------
  // panelTurn: one panel line plus the updated session state; the app calls it
  // again while `then` is "continue".
  async panelTurn(d, lang) {
    return panel.turn(d, lang);
  },

  // { text?, images?: [{base64,mime}], pdf?: {base64} } -> { scores, current }
  async analyze(d, lang) {
    const parts = [];
    if (d.pdf?.base64) parts.push(inlinePart(d.pdf.base64, "application/pdf"));
    for (const im of (Array.isArray(d.images) ? d.images : []).slice(0, 5)) {
      if (im?.base64) parts.push(inlinePart(im.base64, clip(im.mime, 40) || "image/jpeg"));
    }
    const text = clip(d.text, 8000);
    if (!parts.length && !text) throw new HttpsError("invalid-argument", "No profile given.");
    const out = await generateJson(
      "You audit LinkedIn profiles. Judge ONLY what is in the profile below (text/files). " +
        `Return JSON: {"isProfile": true, "scores": {${PART_IDS.map((p) => `"${p}": 0-100`).join(", ")}}, ` +
        `"current": {${PART_IDS.map((p) => `"${p}": ""`).join(", ")}}}.\n` +
        "scores: how strong each part is (0 = missing/poor, 100 = excellent). photo = profile photo and banner. " +
        "featured = the Featured section. link = a clean custom profile URL.\n" +
        `current: a short excerpt (max 140 characters, in the profile's own words) of what the profile has for that part, or "" if it is missing. ` +
        "Set isProfile to false if this is not a LinkedIn-style profile.\n" +
        (text ? `\nProfile text:\n${text}` : ""),
      parts,
    );
    if (out.isProfile === false) throw new HttpsError("invalid-argument", "Not a profile.");
    const scores = {};
    const current = {};
    for (const p of PART_IDS) {
      const n = Number(out.scores?.[p]);
      scores[p] = Number.isFinite(n) ? Math.max(0, Math.min(100, Math.round(n))) : 0;
      current[p] = clip(out.current?.[p], 160);
    }
    return { scores, current };
  },
};

async function runCareerTask(d, allowed = Object.keys(TASKS)) {
  const task = requireString(d.task, "task");
  const handler =
    allowed.includes(task) && Object.prototype.hasOwnProperty.call(TASKS, task) ? TASKS[task] : null;
  if (!handler) throw new HttpsError("invalid-argument", "Unknown task.");
  const lang = clip(d.language, 40) || "English";
  try {
    return await handler(d, lang);
  } catch (e) {
    throw wrapGeminiError(e);
  }
}

// ---------------------------------------------------------------------------
// One function per text feature: each scales, logs and bills on its own, and
// text calls don't pay for the 1 GiB the image function needs.
// Same request as before: { task, language?, ...task fields }.

const TEXT_OPTIONS = { ...OPTIONS, memory: "256MiB", timeoutSeconds: 60 };

const textFunction = (tasks, options = TEXT_OPTIONS) =>
  onCall(options, (request) => runCareerTask(request.data || {}, tasks));

// Career Studio: Profile Builder.
exports.profileBuilder = textFunction(["buildProfile", "rewrite"]);

// Career Studio: Profile Optimizer (reads PDFs and screenshots, so more room).
exports.profileOptimizer = textFunction(["analyze", "fixSuggestion"], {
  ...TEXT_OPTIONS,
  memory: "512MiB",
  timeoutSeconds: 120,
});

// Clixa, the AI business coach / analyst.
exports.businessCoach = textFunction(["coachReply"]);

// The Expert Panel.
exports.expertPanel = textFunction(["panelTurn"]);
