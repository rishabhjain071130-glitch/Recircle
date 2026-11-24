const { before, after, beforeEach, test } = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const request = require('supertest');
const { User, PickupRequest, AnalysisRecord, MarketRate, MarketRateAudit, MarketRateHistory, PartnerApprovalAudit } = require('../src/models');
const { PartnerLocation } = require('../src/partner_locations');
const { createApp } = require('../src/app');

process.env.MONGOMS_DOWNLOAD_DIR = require('node:path').join(__dirname, '..', '.mongo-cache');

let mongo;
let app;
const config = {
  jwtSecret: 'test-only-secret-that-is-longer-than-thirty-two-chars',
  jwtExpiresIn: '1h',
  corsOrigins: [],
  partnerSetupKey: 'test-setup-key',
};

before(async () => {
  mongo = await MongoMemoryServer.create();
  await mongoose.connect(mongo.getUri());
  app = createApp({
    config,
    models: { User, PickupRequest, AnalysisRecord, MarketRate, MarketRateAudit, MarketRateHistory, PartnerApprovalAudit },
    analyzeImage: async () => ({}),
  });
});

after(async () => {
  await mongoose.disconnect();
  if (mongo) await mongo.stop();
});

beforeEach(async () => {
  await Promise.all([
    User.deleteMany({}),
    PickupRequest.deleteMany({}),
    AnalysisRecord.deleteMany({}),
    MarketRate.deleteMany({}),
    MarketRateAudit.deleteMany({}),
    MarketRateHistory.deleteMany({}),
    PartnerApprovalAudit.deleteMany({}),
    PartnerLocation.deleteMany({}),
  ]);
});

async function customerToken() {
  const response = await request(app).post('/api/v1/auth/register').send({
    name: 'Map Customer',
    email: 'map-customer@example.com',
    password: 'secure-pass-123',
  });
  assert.equal(response.status, 201);
  return response.body.data.token;
}

async function partnerToken(email = 'map-partner@example.com') {
  const response = await request(app)
    .post('/api/v1/auth/partner-setup')
    .set('x-partner-setup-key', config.partnerSetupKey)
    .send({
      name: 'Green ReCircle Partner',
      email,
      password: 'secure-pass-123',
    });
  assert.equal(response.status, 201);

  const login = await request(app)
    .post('/api/v1/auth/login')
    .send({ email, password: 'secure-pass-123' });
  assert.equal(login.status, 200);
  return login.body.data.token;
}

test('approved partners can publish a location and customers can discover them by distance', async () => {
  const partner = await partnerToken();
  const customer = await customerToken();

  const publish = await request(app)
    .patch('/api/v1/partners/me/location')
    .set('Authorization', 'Bearer ' + partner)
    .send({ latitude: 27.4924, longitude: 77.6737 });

  assert.equal(publish.status, 200);
  assert.equal(publish.body.data.latitude, 27.4924);
  assert.equal(publish.body.data.longitude, 77.6737);

  const nearby = await request(app)
    .get('/api/v1/partners/nearby?latitude=27.4925&longitude=77.6738&radiusKm=5')
    .set('Authorization', 'Bearer ' + customer);

  assert.equal(nearby.status, 200);
  assert.equal(nearby.body.data.length, 1);
  assert.equal(nearby.body.data[0].name, 'Green ReCircle Partner');
  assert.equal(nearby.body.data[0].distanceKm < 1, true);
});

test('unavailable partners are not returned to customers', async () => {
  const partner = await partnerToken();
  const customer = await customerToken();

  await request(app)
    .patch('/api/v1/partners/me/location')
    .set('Authorization', 'Bearer ' + partner)
    .send({ latitude: 27.4924, longitude: 77.6737 });

  await User.updateOne(
    { email: 'map-partner@example.com' },
    { $set: { partnerAvailable: false } },
  );

  const nearby = await request(app)
    .get('/api/v1/partners/nearby?latitude=27.4924&longitude=77.6737&radiusKm=5')
    .set('Authorization', 'Bearer ' + customer);

  assert.equal(nearby.status, 200);
  assert.equal(nearby.body.data.length, 0);
});
