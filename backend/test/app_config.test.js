const { test } = require('node:test');
const assert = require('node:assert/strict');
const { createApp } = require('../src/app');

test('trusts exactly the Render ingress hop before registering rate limiters', () => {
  const app = createApp({ config: { corsOrigins: [] }, models: {}, analyzeImage: async () => ({}) });
  assert.equal(app.get('trust proxy'), 1);
  const stack = app._router.stack;
  const authLimiterIndex = stack.findIndex((layer) => layer.regexp?.toString().includes('api\\/v1\\/auth'));
  assert.ok(authLimiterIndex > 0, 'auth rate limiter is registered after app configuration');
});
