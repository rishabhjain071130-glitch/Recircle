const { test } = require('node:test');
const assert = require('node:assert/strict');
const { analysisSchema, createGeminiAnalyzer } = require('../src/services/gemini_analyzer');

const result = {
  itemName: 'Laptop', category: 'electronics', likelyMaterials: ['metal'],
  visibleCondition: 'worn', reusePotential: 'uncertain', confidence: 0.7,
  uncertaintyNotes: ['Function cannot be established from an image.'],
  reuseSuggestions: [], recyclingRecommendation: 'Check local e-waste guidance.',
  safetyNotes: [], explanation: 'A laptop is visible.',
};
const response = (body, status = 200) => ({ ok: status >= 200 && status < 300, status, json: async () => body });

test('sends inline image data to the configured Gemini model and parses structured output', async () => {
  let request;
  const analyze = createGeminiAnalyzer({ geminiApiKey: 'test-key', geminiModel: 'gemini-3.8-flash' }, async (url, options) => {
    request = { url, options };
    return response({ candidates: [{ content: { parts: [{ text: JSON.stringify(result) }] } }] });
  });
  const actual = await analyze({ image: Buffer.from([1, 2, 3]), mimeType: 'image/jpeg' });
  assert.deepEqual(actual, result);
  assert.match(request.url, /models\/gemini-3\.8-flash:generateContent$/);
  assert.equal(request.options.headers['x-goog-api-key'], 'test-key');
  const payload = JSON.parse(request.options.body);
  assert.equal(payload.contents[0].parts[1].inline_data.data, Buffer.from([1, 2, 3]).toString('base64'));
  assert.equal(payload.generationConfig.responseMimeType, 'application/json');
});

test('missing key and provider failures become safe, actionable errors', async () => {
  await assert.rejects(
    createGeminiAnalyzer({ geminiApiKey: '', geminiModel: 'gemini-3.8-flash' })({ image: Buffer.from([1]), mimeType: 'image/png' }),
    (error) => error.status === 503 && error.message === 'Image analysis is not configured on the server.',
  );
  const limited = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'gemini-3.8-flash' }, async () => response({ error: { message: 'private provider detail' } }, 429));
  await assert.rejects(limited({ image: Buffer.from([1]), mimeType: 'image/png' }), (error) => error.status === 503 && error.category === 'quota' && !error.message.includes('private'));
  const missingModel = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'missing-model' }, async () => response({}, 404));
  await assert.rejects(missingModel({ image: Buffer.from([1]), mimeType: 'image/png' }), (error) => error.status === 503 && error.category === 'model_unavailable');
  const invalid = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'gemini-3.8-flash' }, async () => response({ candidates: [{ content: { parts: [{ text: '{bad json' }] } }] }));
  await assert.rejects(invalid({ image: Buffer.from([1]), mimeType: 'image/png' }), /unreadable result/);
});

test('provider timeout reports a retryable timeout', async () => {
  const timeout = new Error('timeout');
  timeout.name = 'TimeoutError';
  const analyze = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'gemini-3.8-flash' }, async () => { throw timeout; });
  await assert.rejects(analyze({ image: Buffer.from([1]), mimeType: 'image/webp' }), (error) => error.status === 504 && /timed out/.test(error.message));
});

test('schema rejects incomplete or unsafe claims from generated content', () => {
  assert.equal(analysisSchema.safeParse(result).success, true);
  assert.equal(analysisSchema.safeParse({ ...result, confidence: 1.4 }).success, false);
  assert.equal(analysisSchema.safeParse({ ...result, visibleCondition: 'electrically safe' }).success, false);
});
