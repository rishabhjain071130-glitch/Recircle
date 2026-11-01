const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const request = require('supertest');
const jwt = require('jsonwebtoken');
const { User, PickupRequest, AnalysisRecord, MarketRate, MarketRateAudit, MarketRateHistory, PartnerApprovalAudit } = require('../src/models');
const { createApp } = require('../src/app');
const { getConfig, validateConfig } = require('../src/config');
const { utcTodayInIndia } = require('../src/market_rates');
const { seedDemoRatesForModels, assertDemoMode } = require('../scripts/seed_demo_rates');

process.env.MONGOMS_DOWNLOAD_DIR = require('node:path').join(__dirname, '..', '.mongo-cache');

let mongo;
let testDbPath;
let app;
let providerBehavior;
let authTestIp = 1;
const analysisFixture = {
  itemName: 'Old laptop', category: 'electronics', likelyMaterials: ['metal', 'plastic'],
  visibleCondition: 'worn', reusePotential: 'uncertain', confidence: 0.72,
  uncertaintyNotes: ['Internal function cannot be determined from a photo.'],
  reuseSuggestions: [], recyclingRecommendation: 'Check local e-waste guidance.',
  safetyNotes: ['Do not use a visibly damaged battery.'], explanation: 'A laptop is visible.',
};
const config = { jwtSecret: 'test-only-secret-that-is-longer-than-thirty-two-chars', jwtExpiresIn: '1h', corsOrigins: [], partnerSetupKey: 'test-setup-key', demoMode: true };

before(async () => {
  testDbPath = await require('node:fs/promises').mkdtemp(require('node:path').join(__dirname, '..', '.mongo-cache', 'api-test-'));
  mongo = await MongoMemoryServer.create({ instance: { dbPath: testDbPath } });
  await mongoose.connect(mongo.getUri());
  providerBehavior = async () => analysisFixture;
  app = createApp({ config, models: { User, PickupRequest, AnalysisRecord, MarketRate, MarketRateAudit, MarketRateHistory, PartnerApprovalAudit }, analyzeImage: (...args) => providerBehavior(...args) });
});
after(async () => {
  await mongoose.disconnect();
  if (mongo) await mongo.stop();
  if (testDbPath) await require('node:fs/promises').rm(testDbPath, { recursive: true, force: true });
});
beforeEach(async () => { providerBehavior = async () => analysisFixture; await User.deleteMany({}); await PickupRequest.deleteMany({}); await AnalysisRecord.deleteMany({}); await MarketRate.deleteMany({}); await MarketRateAudit.deleteMany({}); await MarketRateHistory.deleteMany({}); await PartnerApprovalAudit.deleteMany({}); });

async function register(name, email, role = 'customer') {
  const ip = `198.51.100.${(authTestIp++ % 200) + 1}`;
  if (role === 'partner') {
    const result = await request(app).post('/api/v1/auth/partner-setup').set('x-forwarded-for', ip).set('x-partner-setup-key', config.partnerSetupKey).send({ name, email, password: 'secure-pass-123' });
    assert.equal(result.status, 201);
  } else {
    const result = await request(app).post('/api/v1/auth/register').set('x-forwarded-for', ip).send({ name, email, password: 'secure-pass-123' });
    assert.equal(result.status, 201);
  }
  const login = await request(app).post('/api/v1/auth/login').set('x-forwarded-for', ip).send({ email, password: 'secure-pass-123' });
  assert.equal(login.status, 200);
  return login.body.data.token;
}

test('health endpoint reports database connectivity', async () => {
  assert.equal(app.get('trust proxy'), 1);
  const response = await request(app).get('/api/v1/health');
  assert.equal(response.status, 200);
  assert.deepEqual(response.body.data, { status: 'ok', database: 'connected' });
});

test('market rates require backend admin role and expose only published demo sheets', async () => {
  const customerToken = await register('Customer', 'rates-customer@example.com');
  const partnerToken = await register('Partner', 'rates-partner@example.com', 'partner');
  assert.equal((await request(app).post('/api/v1/admin/market-rates').send({})).status, 401);
  assert.equal((await request(app).get('/api/v1/admin/market-rates').set('Authorization', `Bearer ${customerToken}`)).status, 403);
  assert.equal((await request(app).post('/api/v1/admin/market-rates').set('Authorization', `Bearer ${partnerToken}`).send({})).status, 403);
  const admin = await User.create({ name: 'Admin', email: 'rates-admin@example.com', passwordHash: 'hashed', role: 'admin' });
  const adminToken = jwt.sign({ sub: admin.id, role: 'customer' }, config.jwtSecret, { expiresIn: '1h' });
  const body = { effectiveDate: utcTodayInIndia(), scope: 'IN', materials: [{ materialId: 'copper', name: 'Copper', minimum: 100, maximum: 120, indicative: 110 }] };
  const draft = await request(app).post('/api/v1/admin/market-rates').set('Authorization', `Bearer ${adminToken}`).send(body);
  assert.equal(draft.status, 201);
  assert.equal(draft.body.data.isDemo, true);
  assert.equal((await request(app).get('/api/v1/market-rates')).body.data, null);
  const published = await request(app).post(`/api/v1/admin/market-rates/${draft.body.data._id}/publish`).set('Authorization', `Bearer ${adminToken}`).send({});
  assert.equal(published.status, 200);
  assert.equal((await request(app).get('/api/v1/market-rates')).body.data.materials[0].indicative, 110);
  const correction = await request(app).patch(`/api/v1/admin/market-rates/${draft.body.data._id}`).set('Authorization', `Bearer ${adminToken}`).send({ ...body, materials: [{ ...body.materials[0], maximum: 125, indicative: 112 }] });
  assert.equal(correction.status, 200);
  assert.equal(await MarketRateAudit.countDocuments({ action: 'corrected' }), 1);
  assert.equal(await MarketRateHistory.countDocuments({ action: 'corrected' }), 1);
  assert.equal((await MarketRateAudit.findOne({ action: 'corrected' })).snapshot.materials[0].maximum, 120);
  assert.equal((await request(app).get('/api/v1/market-rates')).body.data.materials[0].maximum, 125);
});

test('market rate validation, duplicate dates, and unpublish audit are enforced', async () => {
  const admin = await User.create({ name: 'Admin', email: 'admin-validation@example.com', passwordHash: 'hashed', role: 'admin' });
  const token = jwt.sign({ sub: admin.id }, config.jwtSecret, { expiresIn: '1h' });
  const base = { effectiveDate: utcTodayInIndia(), materials: [{ materialId: 'copper', name: 'Copper', minimum: 100, maximum: 90, indicative: 95 }] };
  const invalid = await request(app).post('/api/v1/admin/market-rates').set('Authorization', `Bearer ${token}`).send(base);
  assert.equal(invalid.status, 400);
  const valid = { ...base, materials: [{ ...base.materials[0], maximum: 120, indicative: 110 }] };
  const created = await request(app).post('/api/v1/admin/market-rates').set('Authorization', `Bearer ${token}`).send(valid);
  assert.equal(created.status, 201);
  assert.equal((await request(app).post('/api/v1/admin/market-rates').set('Authorization', `Bearer ${token}`).send(valid)).status, 409);
  const id = created.body.data._id;
  await request(app).post(`/api/v1/admin/market-rates/${id}/publish`).set('Authorization', `Bearer ${token}`).send({});
  const unpublished = await request(app).post(`/api/v1/admin/market-rates/${id}/unpublish`).set('Authorization', `Bearer ${token}`).send({ reason: 'Demo correction review' });
  assert.equal(unpublished.status, 200);
  assert.equal((await request(app).get('/api/v1/market-rates')).body.data, null);
  assert.equal(await MarketRateAudit.countDocuments({ action: 'unpublished', reason: 'Demo correction review' }), 1);
  assert.equal(await MarketRateHistory.countDocuments({ action: 'unpublished' }), 1);
});

test('demo seed is gated and idempotent without replacing edited sheets', async () => {
  assert.throws(() => assertDemoMode({ DEMO_MODE: 'false' }), /disabled/);
  const admin = await User.create({ name: 'Seed Admin', email: 'seed-admin@example.com', passwordHash: 'hashed', role: 'admin' });
  const models = { User, MarketRate, MarketRateHistory, MarketRateAudit };
  const today = utcTodayInIndia();
  assert.equal(await seedDemoRatesForModels(models, today), 5);
  assert.equal(await MarketRate.countDocuments({ isDemo: true }), 5);
  const edited = await MarketRate.findOne({ effectiveDate: today });
  edited.materials[0].indicative = 702;
  await edited.save();
  assert.equal(await seedDemoRatesForModels(models, today), 0);
  assert.equal((await MarketRate.findById(edited.id)).materials[0].indicative, 702);
  assert.ok(await MarketRate.exists({ status: 'scheduled', effectiveDate: { $gt: today } }));
  assert.ok(await MarketRateHistory.exists({ action: 'published' }));
  assert.equal(admin.role, 'admin');
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

test('partner registration is pending until an authenticated admin approves it', async () => {
  const registration = await request(app).post('/api/v1/auth/partner-register').send({
    name: 'New Partner', email: 'new-partner@example.com', phone: '+911234567890', password: 'secure-pass-123',
    address: '14 Green Street', city: 'Delhi', pinCode: '110001', serviceArea: 'Central Delhi',
  });
  assert.equal(registration.status, 201);
  assert.equal(registration.body.data.user.role, 'partner');
  assert.equal(registration.body.data.user.partnerStatus, 'pending');
  const token = registration.body.data.token;
  const partner = await User.findOne({ email: 'new-partner@example.com' }).select('+passwordHash');
  assert.notEqual(partner.passwordHash, 'secure-pass-123');
  assert.equal((await request(app).get('/api/v1/partner/requests/eligible').set('Authorization', `Bearer ${token}`)).status, 403);
  assert.equal((await request(app).get('/api/v1/partner/profile').set('Authorization', `Bearer ${token}`)).status, 200);
  assert.equal((await request(app).patch('/api/v1/partner/profile').set('Authorization', `Bearer ${token}`).send({
    name: partner.name, phone: partner.phone, address: partner.address, city: partner.city, pinCode: partner.pinCode, serviceArea: partner.serviceArea, partnerAvailable: true, partnerStatus: 'approved',
  })).status, 400);
  const admin = await User.create({ name: 'Admin', email: 'partner-admin@example.com', passwordHash: 'hashed', role: 'admin' });
  const adminToken = jwt.sign({ sub: admin.id }, config.jwtSecret, { expiresIn: '1h' });
  assert.equal((await request(app).patch(`/api/v1/admin/partners/${partner.id}/status`).send({ status: 'approved' })).status, 401);
  assert.equal((await request(app).patch(`/api/v1/admin/partners/${partner.id}/status`).set('Authorization', `Bearer ${token}`).send({ status: 'approved' })).status, 403);
  const approved = await request(app).patch(`/api/v1/admin/partners/${partner.id}/status`).set('Authorization', `Bearer ${adminToken}`).send({ status: 'approved' });
  assert.equal(approved.status, 200);
  assert.equal(approved.body.data.partnerStatus, 'approved');
  assert.equal((await request(app).get('/api/v1/partner/requests/eligible').set('Authorization', `Bearer ${token}`)).status, 200);
  assert.equal(await PartnerApprovalAudit.countDocuments({ partner: partner.id, to: 'approved' }), 1);
});

test('rejected and suspended partners are blocked and admin approval writes are protected', async () => {
  const admin = await User.create({ name: 'Admin', email: 'partner-admin-two@example.com', passwordHash: 'hashed', role: 'admin' });
  const adminToken = jwt.sign({ sub: admin.id }, config.jwtSecret, { expiresIn: '1h' });
  for (const status of ['rejected', 'suspended']) {
    const partner = await User.create({ name: status, email: `${status}@example.com`, passwordHash: 'hashed', role: 'partner', partnerStatus: status });
    const token = jwt.sign({ sub: partner.id }, config.jwtSecret, { expiresIn: '1h' });
    assert.equal((await request(app).get('/api/v1/partner/requests/mine').set('Authorization', `Bearer ${token}`)).status, 403);
    assert.equal((await request(app).get(`/api/v1/admin/partners?status=${status}`).set('Authorization', `Bearer ${adminToken}`)).body.data.length, 1);
  }
  const customer = await User.create({ name: 'Customer', email: 'nonadmin@example.com', passwordHash: 'hashed', role: 'customer' });
  const customerToken = jwt.sign({ sub: customer.id }, config.jwtSecret, { expiresIn: '1h' });
  assert.equal((await request(app).get('/api/v1/admin/partners').set('Authorization', `Bearer ${customerToken}`)).status, 403);
});

test('partner declines are private to that partner and availability controls eligibility', async () => {
  const customer = await register('Request Owner', 'owner@example.com');
  const partnerA = await User.create({ name: 'Partner A', email: 'a@example.com', passwordHash: 'hashed', role: 'partner', partnerStatus: 'approved', phone: '+911111111111', address: '1 Main Street', city: 'Delhi', pinCode: '110001', serviceArea: 'North Delhi' });
  const partnerB = await User.create({ name: 'Partner B', email: 'b@example.com', passwordHash: 'hashed', role: 'partner', partnerStatus: 'approved', phone: '+922222222222' });
  const tokenA = jwt.sign({ sub: partnerA.id }, config.jwtSecret, { expiresIn: '1h' });
  const tokenB = jwt.sign({ sub: partnerB.id }, config.jwtSecret, { expiresIn: '1h' });
  const created = await request(app).post('/api/v1/requests').set('Authorization', `Bearer ${customer}`).send({ item: { category: 'E-Waste', name: 'Laptop', condition: 'Used' }, pickup: { address: '12 Green Street', contactName: 'Owner', contactPhone: '+919999999999' } });
  const id = created.body.data._id;
  const profileBody = { name: partnerA.name, phone: partnerA.phone, address: partnerA.address, city: partnerA.city, pinCode: partnerA.pinCode, serviceArea: partnerA.serviceArea, partnerAvailable: false };
  assert.equal((await request(app).patch('/api/v1/partner/profile').set('Authorization', `Bearer ${tokenA}`).send(profileBody)).body.data.partnerAvailable, false);
  assert.deepEqual((await request(app).get('/api/v1/partner/requests/eligible').set('Authorization', `Bearer ${tokenA}`)).body.data, []);
  assert.equal((await request(app).patch('/api/v1/partner/profile').set('Authorization', `Bearer ${tokenA}`).send({ ...profileBody, partnerAvailable: true })).status, 200);
  assert.equal((await request(app).post(`/api/v1/partner/requests/${id}/reject`).set('Authorization', `Bearer ${tokenA}`).send({ reason: 'Outside my service area' })).status, 200);
  assert.deepEqual((await request(app).get('/api/v1/partner/requests/eligible').set('Authorization', `Bearer ${tokenA}`)).body.data, []);
  assert.equal((await request(app).get('/api/v1/partner/requests/eligible').set('Authorization', `Bearer ${tokenB}`)).body.data.length, 1);
  assert.equal((await request(app).post(`/api/v1/partner/requests/${id}/accept`).set('Authorization', `Bearer ${tokenB}`)).status, 200);
  const ownerRequests = await request(app).get('/api/v1/requests/mine').set('Authorization', `Bearer ${customer}`);
  assert.equal(ownerRequests.body.data[0].partner.phone, partnerB.phone);
  const other = await register('Other owner', 'other-owner@example.com');
  assert.equal((await request(app).get(`/api/v1/requests/${id}`).set('Authorization', `Bearer ${other}`)).status, 403);
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
