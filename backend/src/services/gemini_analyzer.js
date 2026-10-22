const { z } = require('zod');

const analysisSchema = z.object({
  itemName: z.string().trim().min(1).max(120),
  category: z.enum(['plastic', 'paper', 'cardboard', 'glass', 'metal', 'electronics', 'textiles', 'mixedMaterials', 'unknown']),
  likelyMaterials: z.array(z.string().trim().min(1).max(80)).max(8),
  visibleCondition: z.enum(['good', 'worn', 'damaged', 'unknown']),
  reusePotential: z.enum(['promising', 'uncertain', 'unlikely']),
  confidence: z.number().min(0).max(1),
  uncertaintyNotes: z.array(z.string().trim().min(1).max(240)).max(6),
  reuseSuggestions: z.array(z.object({
    title: z.string().trim().min(1).max(100),
    shortDescription: z.string().trim().min(1).max(240),
    category: z.string().trim().min(1).max(60),
    difficulty: z.enum(['Easy', 'Medium', 'Advanced']),
    timeRequired: z.string().trim().min(1).max(40),
    materialsNeeded: z.array(z.string().trim().min(1).max(100)).max(10),
    steps: z.array(z.string().trim().min(1).max(240)).max(10),
    iconName: z.string().trim().max(40),
  }).strict()).max(4),
  recyclingRecommendation: z.string().trim().min(1).max(500),
  safetyNotes: z.array(z.string().trim().min(1).max(240)).max(8),
  explanation: z.string().trim().min(1).max(500),
}).strict();

const responseSchema = {
  type: 'OBJECT',
  properties: {
    itemName: { type: 'STRING' },
    category: { type: 'STRING', enum: ['plastic', 'paper', 'cardboard', 'glass', 'metal', 'electronics', 'textiles', 'mixedMaterials', 'unknown'] },
    likelyMaterials: { type: 'ARRAY', items: { type: 'STRING' } },
    visibleCondition: { type: 'STRING', enum: ['good', 'worn', 'damaged', 'unknown'] },
    reusePotential: { type: 'STRING', enum: ['promising', 'uncertain', 'unlikely'] },
    confidence: { type: 'NUMBER' },
    uncertaintyNotes: { type: 'ARRAY', items: { type: 'STRING' } },
    reuseSuggestions: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          title: { type: 'STRING' }, shortDescription: { type: 'STRING' }, category: { type: 'STRING' },
          difficulty: { type: 'STRING', enum: ['Easy', 'Medium', 'Advanced'] }, timeRequired: { type: 'STRING' },
          materialsNeeded: { type: 'ARRAY', items: { type: 'STRING' } },
          steps: { type: 'ARRAY', items: { type: 'STRING' } }, iconName: { type: 'STRING' },
        },
        required: ['title', 'shortDescription', 'category', 'difficulty', 'timeRequired', 'materialsNeeded', 'steps', 'iconName'],
      },
    },
    recyclingRecommendation: { type: 'STRING' },
    safetyNotes: { type: 'ARRAY', items: { type: 'STRING' } },
    explanation: { type: 'STRING' },
  },
  required: ['itemName', 'category', 'likelyMaterials', 'visibleCondition', 'reusePotential', 'confidence', 'uncertaintyNotes', 'reuseSuggestions', 'recyclingRecommendation', 'safetyNotes', 'explanation'],
};

class GeminiProviderError extends Error {
  constructor(message, status = 502, category = 'provider_error', providerStatus = null, attempts = 1) {
    super(message);
    this.name = 'GeminiProviderError';
    this.status = status;
    this.category = category;
    this.providerStatus = providerStatus;
    this.attempts = attempts;
  }
}

// Two bounded attempts plus at most four seconds of backoff fit the Flutter
// client's 40-second request deadline, including response and persistence work.
const ATTEMPT_TIMEOUT_MS = 14_000;
const MAX_ATTEMPTS = 2;
const MAX_RETRY_DELAY_MS = 4_000;

function isTimeoutError(error) {
  return error?.name === 'TimeoutError' || error?.name === 'AbortError';
}

function retryAfterMilliseconds(response, now) {
  const value = response?.headers?.get?.('retry-after');
  if (!value) return null;
  const seconds = Number(value);
  if (Number.isFinite(seconds) && seconds >= 0) return seconds * 1000;
  const date = Date.parse(value);
  return Number.isFinite(date) ? Math.max(0, date - now) : null;
}

function createGeminiAnalyzer(config, fetchImpl = fetch, {
  sleep = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds)),
  now = Date.now,
  random = Math.random,
} = {}) {
  return async ({ image, mimeType, manualCategory }) => {
    if (!config.geminiApiKey) {
      throw new GeminiProviderError('Image analysis is not configured on the server.', 503, 'configuration');
    }
    const prompt = [
      'Analyze this image for ReCircle, an e-waste reuse and recycling app. Return only JSON matching the supplied schema.',
      'Identify only what is visible. A photo cannot establish hidden internal damage, electrical function, battery health, or safety.',
      'Prioritize reuse only when visibly practical; do not claim the item is electrically safe. Give cautious safety notes for batteries, CRTs, damaged cables, or unknown hazards when relevant.',
      'Materials are likely surface-visible materials, not confirmed composition. Be candid in uncertaintyNotes and set confidence between 0 and 1.',
      'Do not invent prices, rewards, pickup availability, environmental savings, or guaranteed recycling outcomes.',
      manualCategory ? `The user suggests the category is ${manualCategory}. Respect that correction if the image supports it, while keeping item identification honest.` : '',
    ].filter(Boolean).join(' ');
    const generationConfig = { responseMimeType: 'application/json', responseSchema };
    if (config.geminiModel === 'gemini-3.8-flash') {
      generationConfig.thinkingConfig = { thinkingLevel: 'low' };
    } else {
      generationConfig.temperature = 0.2;
    }
    const body = JSON.stringify({
      contents: [{ role: 'user', parts: [
        { text: prompt },
        { inline_data: { mime_type: mimeType, data: image.toString('base64') } },
      ] }],
      generationConfig,
    });
    let lastTransientError;

    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
      let response;
      try {
        response = await fetchImpl(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(config.geminiModel)}:generateContent`, {
          method: 'POST',
          headers: { 'content-type': 'application/json', 'x-goog-api-key': config.geminiApiKey },
          body,
          signal: AbortSignal.timeout(ATTEMPT_TIMEOUT_MS),
        });
      } catch (error) {
        if (!isTimeoutError(error) && error?.name !== 'TypeError') {
          throw new GeminiProviderError('The image analysis provider could not be reached.', 503, 'unavailable', null, attempt);
        }
        lastTransientError = error;
        if (attempt < MAX_ATTEMPTS && await waitBeforeRetry(null, attempt, { now, random, sleep })) continue;
        if (isTimeoutError(error)) {
          throw new GeminiProviderError('Image analysis timed out. Please retry.', 504, 'timeout', null, attempt);
        }
        throw new GeminiProviderError('The image analysis provider could not be reached.', 503, 'unavailable', null, attempt);
      }

      if (!response.ok) {
        const status = response.status;
        if ([429, 503, 504].includes(status) && attempt < MAX_ATTEMPTS && await waitBeforeRetry(response, attempt, { now, random, sleep })) continue;
        if (status === 429) throw new GeminiProviderError('Image analysis is busy. Please wait and retry.', 503, 'quota', status, attempt);
        if (status === 404) throw new GeminiProviderError('Image analysis is temporarily unavailable.', 503, 'model_unavailable', status, attempt);
        if (status === 401 || status === 403) throw new GeminiProviderError('Image analysis is not available with the current server configuration.', 503, 'configuration', status, attempt);
        if (status === 400) throw new GeminiProviderError('The image could not be analyzed. Choose a different photo and retry.', 400, 'invalid_image', status, attempt);
        if (status === 504) throw new GeminiProviderError('Image analysis timed out. Please retry.', 504, 'timeout', status, attempt);
        throw new GeminiProviderError('The image analysis provider could not complete the request.', 502, 'provider_error', status, attempt);
      }

      let payload;
      try {
        payload = await response.json();
      } catch (error) {
        if (!isTimeoutError(error)) {
          throw new GeminiProviderError('The image analysis provider returned an unreadable result.', 502, 'response_parse', null, attempt);
        }
        lastTransientError = error;
        if (attempt < MAX_ATTEMPTS && await waitBeforeRetry(null, attempt, { now, random, sleep })) continue;
        throw new GeminiProviderError('Image analysis timed out. Please retry.', 504, 'timeout', null, attempt);
      }
      try {
        const text = payload.candidates?.[0]?.content?.parts?.map((part) => part.text || '').join('');
        if (!text) throw new Error('Missing generated content');
        const parsed = analysisSchema.safeParse(JSON.parse(text));
        if (!parsed.success) throw new Error('Generated content did not match the expected schema');
        return parsed.data;
      } catch (_error) {
        throw new GeminiProviderError('The image analysis provider returned an unreadable result.', 502, 'response_parse', null, attempt);
      }
    }

    throw new GeminiProviderError('The image analysis provider could not be reached.', 503, 'unavailable', null, lastTransientError ? MAX_ATTEMPTS : 1);
  };
}

async function waitBeforeRetry(response, attempt, { now, random, sleep }) {
  const retryAfter = retryAfterMilliseconds(response, now());
  const fallbackDelay = Math.min(500 * (2 ** (attempt - 1)) + Math.floor(random() * 250), MAX_RETRY_DELAY_MS);
  const delay = retryAfter ?? fallbackDelay;
  if (delay > MAX_RETRY_DELAY_MS) return false;
  await sleep(delay);
  return true;
}

module.exports = { analysisSchema, createGeminiAnalyzer, GeminiProviderError };
