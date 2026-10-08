const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { GoogleGenAI } = require("@google/genai");

initializeApp();

// Model names (verify before deploy).
const CARD_MODEL = "gemini-3.1-flash-lite-image";
const LAYOUT_MODEL = "gemini-3.1-flash-lite-image";

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
exports.generateCard = onCall(OPTIONS, async (request) => {
  const d = request.data || {};
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

// generateLayoutJson: { prompt, imageBase64, imageMime }
// returns { json } (string)
exports.generateLayoutJson = onCall(OPTIONS, async (request) => {
  const d = request.data || {};
  const prompt = requireString(d.prompt, "prompt");
  const imgB64 = requireString(d.imageBase64, "imageBase64");
  const imgMime = requireString(d.imageMime, "imageMime");

  // Image model has no JSON mode, so ask for JSON only and strip fences.
  const fullPrompt = `${prompt}\n\nReturn ONLY valid JSON. No markdown, no code fences, no explanation.`;

  try {
    const ai = getClient();
    const res = await ai.models.generateContent({
      model: LAYOUT_MODEL,
      contents: [{ role: "user", parts: [{ text: fullPrompt }, inlinePart(imgB64, imgMime)] }],
      config: { responseModalities: ["TEXT", "IMAGE"], temperature: 0.1 },
    });
    const outParts = res?.candidates?.[0]?.content?.parts || [];
    let text = outParts.filter((p) => typeof p.text === "string").map((p) => p.text).join("").trim();
    text = text.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "").trim();
    if (!text) throw new HttpsError("internal", "Empty response.");
    return { json: text };
  } catch (e) {
    throw wrapGeminiError(e);
  }
});