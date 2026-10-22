const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const request = require('supertest');
const jwt = require('jsonwebtoken');
const { User, PickupRequest, AnalysisRecord } = require('../src/models');
const { createApp } = require('../src/app');
const { getConfig, validateConfig } = require('../src/config');

process.env.MONGOMS_DOWNLOAD_DIR = require('node:path').join(__dirname, '..', '.mongo-cache');

let mongo;
let testDbPath;
let app;
let providerBehavior;
const analysisFixture = {
  itemName: 'Old laptop', category: 'electronics', likelyMaterials: ['metal', 'plastic'],
  visibleCondition: 'worn', reusePotential: 'uncertain', confidence: 0.72,
  uncertaintyNotes: ['Internal function cannot be determined from a photo.'],
  reuseSuggestions: [], recyclingRecommendation: 'Check local e-waste guidance.',
  safetyNotes: ['Do not use a visibly damaged battery.'], explanation: 'A laptop is visible.',
};
const config = { jwtSecret: 'test-only-secret-that-is-longer-than-thirty-two-chars', jwtExpiresIn: '1h', corsOrigins: [], partnerSetupKey: 'test-setup-key' };

before(async () => {
  testDbPath = await require('node:fs/promises').mkdtemp(require('node:path').join(__dirname, '..', '.mongo-cache', 'api-test-'));
  mongo = await MongoMemoryServer.create({ instance: { dbPath: testDbPath } });
  await mongoose.connect(mongo.getUri());
  providerBehavior = async () => analysisFixture;
  app = createApp({ config, models: { User, PickupRequest, AnalysisRecord }, analyzeImage: (...args) => providerBehavior(...args) });
});
after(async () => {
  await mongoose.disconnect();
  if (mongo) await mongo.stop();
  if (testDbPath) await require('node:fs/promises').rm(testDbPath, { recursive: true, force: true });
});
beforeEach(async () => { providerBehavior = async () => analysisFixture; await User.deleteMany({}); await PickupRequest.deleteMany({}); await AnalysisRecord.deleteMany({}); });

async function register(name, email, role = 'customer') {
  if (role === 'partner') {
    const result = await request(app).post('/api/v1/auth/partner-setup').set('x-partner-setup-key', config.partnerSetupKey).send({ name, email, password: 'secure-pass-123' });
    assert.equal(result.status, 201);
  } else {
    const result = await request(app).post('/api/v1/auth/register').send({ name, email, password: 'secure-pass-123' });
    assert.equal(result.status, 201);
  }
  const login = await request(app).post('/api/v1/auth/login').send({ email, password: 'secure-pass-123' });
  assert.equal(login.status, 200);
  return login.body.data.token;
}

test('health endpoint reports database connectivity', async () => {
  assert.equal(app.get('trust proxy'), 1);
  const response = await request(app).get('/api/v1/health');
  assert.equal(response.status, 200);
  assert.deepEqual(response.body.data, { status: 'ok', database: 'connected' });
});

test('startup rejects missing database and weak JWT configuration', () => {
  assert.throws(() => validateConfig(getConfig({})), /MONGODB_URI/);
  assert.throws(() => validateConfig({ mongoUri: 'mongodb://localhost/test', jwtSecret: 'short', port: 3000 }), /JWT_SECRET/);
});

test('analysis requires authentication and validates actual image type and size', async () => {
  const jpeg = Buffer.from([0xff, 0xd8, 0xff, 1, 2, 3]);
  assert.equal((await request(app).post('/api/v1/analysis').set('Content-Type', 'image/jpeg').send(jpeg)).status, 401);
  const token = await register('Scan User', 'scan@example.com');
  const missing = await request(app).post('/api/v1/analysis').set('Authorization', `Bearer ${token}`).set('Content-Type', 'image/jpeg').send(Buffer.alloc(0));
  assert.equal(missing.status, 400);
  assert.equal(missing.body.error.code, 'INVALID_IMAGE');
  assert.equal(missing.headers['x-request-id'], missing.body.requestId);
  const mismatch = await request(app).post('/api/v1/analysis').set('Authorization', `Bearer ${token}`).set('Content-Type', 'image/png').send(jpeg);
  assert.equal(mismatch.status, 400);
  const tooLarge = await request(app).post('/api/v1/analysis').set('Authorization', `Bearer ${token}`).set('Content-Type', 'image/jpeg').send(Buffer.concat([jpeg, Buffer.alloc(8 * 1024 * 1024)]));
  assert.equal(tooLarge.status, 413);
});

test('analysis validates provider output, saves result without image, and scopes history to caller', async () => {
  const token = await register('Scan User', 'scan@example.com');
  let received;
  providerBehavior = async (input) => { received = input; return analysisFixture; };
  const response = await request(app).post('/api/v1/analysis').set('Authorization', `Bearer ${token}`).set('Content-Type', 'image/jpeg').send(Buffer.from([0xff, 0xd8, 0xff, 1]));
  assert.equal(response.status, 201);
  assert.equal(response.body.data.itemName, 'Old laptop');
  assert.equal(received.mimeType, 'image/jpeg');
  assert.equal(received.image.length, 4);
  const record = await AnalysisRecord.findById(response.body.data.analysisId).lean();
  assert.equal(record.result.itemName, 'Old laptop');
  assert.equal(Object.hasOwn(record, 'image'), false);
  const otherToken = await register('Other User', 'other-scan@example.com');
  const history = await request(app).get('/api/v1/analysis/history').set('Authorization', `Bearer ${otherToken}`);
  assert.equal(history.status, 200);
  assert.deepEqual(history.body.data.items, []);
  assert.equal(history.body.data.pagination.total, 0);
  const ownHistory = await request(app).get('/api/v1/analysis/history').set('Authorization', `Bearer ${token}`);
  assert.equal(ownHistory.body.data.items.length, 1);
  assert.equal(ownHistory.body.data.items[0].id, response.body.data.analysisId);
  const detail = await request(app).get(`/api/v1/analysis/history/${response.body.data.analysisId}`).set('Authorization', `Bearer ${token}`);
  assert.equal(detail.status, 200);
  assert.equal(detail.body.data.itemName, 'Old laptop');
  assert.equal((await request(app).get(`/api/v1/analysis/history/${response.body.data.analysisId}`).set('Authorization', `Bearer ${otherToken}`)).status, 404);
  assert.equal((await request(app).get(`/api/v1/analysis/history/${response.body.data.analysisId}`)).status, 401);
  assert.equal((await request(app).get('/api/v1/analysis/history/not-an-id').set('Authorization', `Bearer ${token}`)).status, 400);
  assert.equal((await request(app).get('/api/v1/analysis/history')).status, 401);
});

test('analysis history validates pagination and returns only the requested page', async () => {
  const token = await register('History User', 'history@example.com');
  for (let index = 0; index < 3; index += 1) {
    await AnalysisRecord.create({ user: (await User.findOne({ email: 'history@example.com' })).id, result: { ...analysisFixture, itemName: `Item ${index}` } });
  }
  const first = await request(app).get('/api/v1/analysis/history?page=1&limit=2').set('Authorization', `Bearer ${token}`);
  assert.equal(first.status, 200);
  assert.equal(first.body.data.items.length, 2);
  assert.deepEqual(first.body.data.pagination, { page: 1, limit: 2, total: 3, totalPages: 2 });
  const second = await request(app).get('/api/v1/analysis/history?page=2&limit=2').set('Authorization', `Bearer ${token}`);
  assert.equal(second.body.data.items.length, 1);
  assert.equal(second.body.data.items[0].itemName, 'Item 0');
  assert.equal((await request(app).get('/api/v1/analysis/history?page=0').set('Authorization', `Bearer ${token}`)).status, 400);
  assert.equal((await request(app).get('/api/v1/analysis/history?limit=51').set('Authorization', `Bearer ${token}`)).status, 400);
  assert.equal((await request(app).get('/api/v1/analysis/history?extra=true').set('Authorization', `Bearer ${token}`)).status, 400);
});

test('malformed provider schema is returned as a sanitized error and is not saved', async () => {
  const token = await register('Scan User', 'bad-result@example.com');
  providerBehavior = async () => ({ itemName: 'untrusted raw provider output' });
  const response = await request(app).post('/api/v1/analysis').set('Authorization', `Bearer ${token}`).set('Content-Type', 'image/jpeg').send(Buffer.from([0xff, 0xd8, 0xff]));
  assert.equal(response.status, 502);
  assert.equal(response.body.error.message, 'The image analysis provider returned an unreadable result.');
  assert.equal(await AnalysisRecord.countDocuments(), 0);
});

test('Gemini failure categories are returned safely with a correlation ID', async () => {
  const token = await register('Scan User', 'provider-error@example.com');
  providerBehavior = async () => { const error = new Error('private provider response'); error.name = 'GeminiProviderError'; error.status = 503; error.category = 'quota'; throw error; };
  const response = await request(app).post('/api/v1/analysis').set('Authorization', `Bearer ${token}`).set('Content-Type', 'image/jpeg').send(Buffer.from([0xff, 0xd8, 0xff]));
  assert.equal(response.status, 503);
  assert.equal(response.body.error.code, 'GEMINI_QUOTA');
  assert.equal(response.body.error.message.includes('private'), false);
  assert.equal(response.headers['x-request-id'], response.body.requestId);
});

test('customer cannot select partner role and passwords are hashed', async () => {
  const response = await request(app).post('/api/v1/auth/register').send({ name: 'Riya', email: 'RIYA@example.com', password: 'secure-pass-123', role: 'partner' });
  assert.equal(response.status, 400);
  const token = await register('Riya', 'RIYA@example.com');
  const login = await request(app).post('/api/v1/auth/login').send({ email: 'riya@example.com', password: 'secure-pass-123' });
  assert.equal(Object.hasOwn(login.body.data.user, 'passwordHash'), false);
  assert.equal((await request(app).get('/api/v1/partner/requests/eligible').set('Authorization', `Bearer ${token}`)).status, 403);
  assert.equal((await request(app).get('/api/v1/auth/me').set('Authorization', 'Bearer invalid-token')).status, 401);
  const expired = jwt.sign({ sub: '000000000000000000000000' }, config.jwtSecret, { expiresIn: -1 });
  assert.equal((await request(app).get('/api/v1/auth/me').set('Authorization', `Bearer ${expired}`)).status, 401);
  const user = await User.findOne({ email: 'riya@example.com' }).select('+passwordHash');
  assert.notEqual(user.passwordHash, 'secure-pass-123');
  assert.equal((await request(app).get('/api/v1/auth/me').set('Authorization', `Bearer ${token}`)).body.data.role, 'customer');
});

test('customer submission is shared with partner, single claim wins, and transitions are validated', async () => {
  const customer = await register('Riya', 'riya@example.com');
  const partner = await register('Partner One', 'partner@example.com', 'partner');
  const otherPartner = await register('Partner Two', 'partner2@example.com', 'partner');
  assert.equal((await request(app).get('/api/v1/requests/not-an-id').set('Authorization', `Bearer ${customer}`)).status, 400);
  const submitted = await request(app).post('/api/v1/requests').set('Authorization', `Bearer ${customer}`).send({
    item: { category: 'E-Waste', name: 'Old laptop', condition: 'Not working', quantity: 1 },
    pickup: { address: '12 Green Street', contactName: 'Riya', contactPhone: '+911234567890' },
  });
  assert.equal(submitted.status, 201);
  const id = submitted.body.data._id;
  assert.equal(Object.hasOwn(submitted.body.data, 'passwordHash'), false);
  assert.equal((await request(app).get('/api/v1/requests/mine').set('Authorization', `Bearer ${partner}`)).status, 403);
  const availableResponse = await request(app).get('/api/v1/partner/requests/eligible').set('Authorization', `Bearer ${partner}`);
  assert.equal(availableResponse.body.data.length, 1);
  assert.equal(Object.hasOwn(availableResponse.body.data[0].pickup, 'address'), false);
  assert.equal(Object.hasOwn(availableResponse.body.data[0].pickup, 'contactPhone'), false);
  const claims = await Promise.all([
    request(app).post(`/api/v1/partner/requests/${id}/accept`).set('Authorization', `Bearer ${partner}`),
    request(app).post(`/api/v1/partner/requests/${id}/accept`).set('Authorization', `Bearer ${otherPartner}`),
  ]);
  assert.deepEqual(claims.map((claim) => claim.status).sort(), [200, 409]);
  const winner = claims.find((claim) => claim.status === 200);
  assert.ok(winner.body.data.pickup.address);
  const wonToken = winner.body.data.partner.toString() === (await User.findOne({ email: 'partner@example.com' })).id ? partner : otherPartner;
  const invalid = await request(app).patch(`/api/v1/partner/requests/${id}/status`).set('Authorization', `Bearer ${wonToken}`).send({ status: 'Completed' });
  assert.equal(invalid.status, 409);
  const collected = await request(app).patch(`/api/v1/partner/requests/${id}/status`).set('Authorization', `Bearer ${wonToken}`).send({ status: 'Collected', note: 'Collected safely' });
  assert.equal(collected.status, 200);
  const wrongPartnerUpdate = await request(app).patch(`/api/v1/partner/requests/${id}/status`).set('Authorization', `Bearer ${otherPartner === wonToken ? partner : otherPartner}`).send({ status: 'ReceivedForProcessing' });
  assert.equal(wrongPartnerUpdate.status, 404);
  const customerView = await request(app).get(`/api/v1/requests/${id}`).set('Authorization', `Bearer ${customer}`);
  assert.equal(customerView.body.data.status, 'Collected');
  assert.equal(customerView.body.data.history.at(-1).note, 'Collected safely');
  const otherCustomer = await register('Asha', 'asha@example.com');
  const forbiddenCustomerRead = await request(app).get(`/api/v1/requests/${id}`).set('Authorization', `Bearer ${otherCustomer}`);
  assert.equal(forbiddenCustomerRead.status, 403);
  const forbidden = await request(app).get(`/api/v1/requests/${id}`).set('Authorization', `Bearer ${otherPartner === wonToken ? partner : otherPartner}`);
  assert.equal(forbidden.status, 403);
  const delivered = await request(app).patch(`/api/v1/partner/requests/${id}/status`).set('Authorization', `Bearer ${wonToken}`).send({ status: 'ReceivedForProcessing' });
  assert.equal(delivered.status, 200);
  const processingComplete = await request(app).patch(`/api/v1/partner/requests/${id}/status`).set('Authorization', `Bearer ${wonToken}`).send({ status: 'Completed' });
  assert.equal(processingComplete.status, 200);
  assert.deepEqual(processingComplete.body.data.history.map((event) => event.to), ['Submitted', 'Accepted', 'Collected', 'ReceivedForProcessing', 'Completed']);
  assert.equal(processingComplete.body.data.history.at(-1).actor.toString(), processingComplete.body.data.partner.toString());
});
