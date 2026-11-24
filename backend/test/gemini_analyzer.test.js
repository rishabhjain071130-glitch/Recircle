const { test } = require('node:test');
const assert = require('node:assert/strict');
const { analysisSchema, createGeminiAnalyzer } = require('../src/services/gemini_analyzer');
const { getConfig } = require('../src/config');

const result = {
  itemName: 'Laptop', category: 'electronics', likelyMaterials: ['metal'],
  visibleCondition: 'worn', reusePotential: 'uncertain', confidence: 0.7,
  uncertaintyNotes: ['Function cannot be established from an image.'],
  reuseSuggestions: [], recyclingRecommendation: 'Check local e-waste guidance.',
  safetyNotes: [], explanation: 'A laptop is visible.',
};
const response = (body, status = 200, headers = {}) => ({ ok: status >= 200 && status < 300, status, headers: { get: (name) => headers[name.toLowerCase()] ?? null }, json: async () => body });

test('reads Gemini settings from the documented environment variable names', () => {
  const config = getConfig({ GEMINI_API_KEY: 'test-only-key', GEMINI_MODEL: 'gemini-3.6-flash' });
  assert.equal(config.geminiApiKey, 'test-only-key');
  assert.equal(config.geminiModel, 'gemini-3.6-flash');
});

test('sends inline image data to the configured Gemini model and parses structured output', async () => {
  let request;
  const analyze = createGeminiAnalyzer({ geminiApiKey: 'test-key', geminiModel: 'gemini-3.6-flash' }, async (url, options) => {
    request = { url, options };
    return response({ candidates: [{ content: { parts: [{ text: JSON.stringify(result) }] } }] });
  });
  const actual = await analyze({ image: Buffer.from([1, 2, 3]), mimeType: 'image/jpeg' });
  assert.deepEqual(actual, result);
  assert.match(request.url, /models\/gemini-3\.6-flash:generateContent$/);
  assert.equal(request.options.headers['x-goog-api-key'], 'test-key');
  const payload = JSON.parse(request.options.body);
  assert.equal(payload.contents[0].parts[1].inline_data.data, Buffer.from([1, 2, 3]).toString('base64'));
  assert.equal(payload.generationConfig.responseMimeType, 'application/json');
  assert.deepEqual(payload.generationConfig.thinkingConfig, { thinkingLevel: 'low' });
  assert.equal(Object.hasOwn(payload.generationConfig, 'temperature'), false);
});

test('accepts fenced JSON and supplies only conservative defaults for omitted optional fields', async () => {
  const minimal = {
    itemName: 'Laptop',
    category: 'electronics',
    recyclingRecommendation: 'Check local e-waste guidance.',
    explanation: 'A laptop is visible.',
  };
  const analyze = createGeminiAnalyzer(
    { geminiApiKey: 'test-key', geminiModel: 'gemini-3.6-flash' },
    async () => response({ candidates: [{ content: { parts: [{ text: `\`\`\`json\n${JSON.stringify(minimal)}\n\`\`\`` }] } }] }),
  );

  const actual = await analyze({ image: Buffer.from([1]), mimeType: 'image/jpeg' });
  assert.equal(actual.itemName, 'Laptop');
  assert.deepEqual(actual.likelyMaterials, []);
  assert.equal(actual.visibleCondition, 'unknown');
  assert.equal(actual.reusePotential, 'uncertain');
  assert.equal(actual.confidence, undefined);
  assert.deepEqual(actual.reuseSuggestions, []);
  assert.match(actual.uncertaintyNotes[0], /omitted/);
  assert.match(actual.safetyNotes[0], /could not be assessed/);
});

test('safety-blocked Gemini responses become a specific safe result error', async () => {
  const analyze = createGeminiAnalyzer(
    { geminiApiKey: 'test-key', geminiModel: 'gemini-3.6-flash' },
    async () => response({ promptFeedback: { blockReason: 'SAFETY' } }),
  );
  await assert.rejects(
    analyze({ image: Buffer.from([1]), mimeType: 'image/jpeg' }),
    (error) => error.status === 422 && error.category === 'safety_blocked' && /safety filter/.test(error.message),
  );
});

test('missing key and provider failures become safe, actionable errors', async () => {
  await assert.rejects(
    createGeminiAnalyzer({ geminiApiKey: '', geminiModel: 'gemini-3.6-flash' })({ image: Buffer.from([1]), mimeType: 'image/png' }),
    (error) => error.status === 503 && error.message === 'Image analysis is not configured on the server.',
  );
  const limited = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'gemini-3.6-flash' }, async () => response({ error: { message: 'private provider detail' } }, 429));
  await assert.rejects(limited({ image: Buffer.from([1]), mimeType: 'image/png' }), (error) => error.status === 503 && error.category === 'quota' && !error.message.includes('private'));
  const missingModel = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'missing-model' }, async () => response({}, 404));
  await assert.rejects(missingModel({ image: Buffer.from([1]), mimeType: 'image/png' }), (error) => error.status === 503 && error.category === 'model_unavailable');
  const invalid = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'gemini-3.6-flash' }, async () => response({ candidates: [{ content: { parts: [{ text: '{bad json' }] } }] }));
  await assert.rejects(invalid({ image: Buffer.from([1]), mimeType: 'image/png' }), /unreadable result/);
});

test('provider timeout falls back to the secondary model after bounded retries', async () => {
  const timeout = new Error('timeout');
  timeout.name = 'TimeoutError';
  let calls = 0;
  const models = [];
  const delays = [];
  const analyze = createGeminiAnalyzer(
    { geminiApiKey: 'secret', geminiModel: 'gemini-3.6-flash', geminiFallbackModel: 'gemini-3.5-flash-lite' },
    async (url) => {
      calls += 1;
      models.push(url);
      if (calls <= 2) throw timeout;
      return response({ candidates: [{ content: { parts: [{ text: JSON.stringify(result) }] } }] });
    },
    { sleep: async (delay) => delays.push(delay), random: () => 0 },
  );
  assert.deepEqual(await analyze({ image: Buffer.from([1]), mimeType: 'image/webp' }), result);
  assert.equal(calls, 3);
  assert.equal(models[0].includes('gemini-3.6-flash'), true);
  assert.equal(models[2].includes('gemini-3.5-flash-lite'), true);
  assert.deepEqual(delays, [500]);
});

test('retries a transient 503 once on the primary model', async () => {
  let calls = 0;
  const delays = [];
  const analyze = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'gemini-3.6-flash' }, async () => {
    calls += 1;
    return calls === 1 ? response({}, 503) : response({ candidates: [{ content: { parts: [{ text: JSON.stringify(result) }] } }] });
  }, { sleep: async (delay) => delays.push(delay), random: () => 0 });
  assert.deepEqual(await analyze({ image: Buffer.from([1]), mimeType: 'image/jpeg' }), result);
  assert.equal(calls, 2);
  assert.deepEqual(delays, [500]);
});

test('honors Retry-After for 429 and does not retry unsupported-model errors', async () => {
  let calls = 0;
  const delays = [];
  const throttled = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'gemini-3.6-flash' }, async () => {
    calls += 1;
    return response({}, 429, { 'retry-after': '2' });
  }, { sleep: async (delay) => delays.push(delay), random: () => 0 });
  await assert.rejects(throttled({ image: Buffer.from([1]), mimeType: 'image/jpeg' }), (error) => error.category === 'quota' && error.attempts === 2);
  assert.equal(calls, 2);
  assert.deepEqual(delays, [2000]);

  calls = 0;
  const missingModel = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'missing-model' }, async () => { calls += 1; return response({}, 404); }, { sleep: async () => assert.fail('unsupported model must not retry') });
  await assert.rejects(missingModel({ image: Buffer.from([1]), mimeType: 'image/jpeg' }), (error) => error.category === 'model_unavailable' && error.attempts === 1);
  assert.equal(calls, 1);
});

test('does not retry authentication or invalid-request provider failures', async () => {
  for (const status of [400, 401, 403]) {
    let calls = 0;
    const analyze = createGeminiAnalyzer({ geminiApiKey: 'secret', geminiModel: 'gemini-3.6-flash' }, async () => { calls += 1; return response({}, status); }, { sleep: async () => assert.fail('permanent provider errors must not retry') });
    await assert.rejects(analyze({ image: Buffer.from([1]), mimeType: 'image/jpeg' }));
    assert.equal(calls, 1);
  }
});

test('schema rejects incomplete or unsafe claims from generated content', () => {
  assert.equal(analysisSchema.safeParse(result).success, true);
  assert.equal(analysisSchema.safeParse({ ...result, confidence: 1.4 }).success, false);
  assert.equal(analysisSchema.safeParse({ ...result, visibleCondition: 'electrically safe' }).success, false);
});
