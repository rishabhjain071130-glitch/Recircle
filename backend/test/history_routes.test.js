const { test } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const request = require('supertest');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const createRoutes = require('../src/routes');

const config = { jwtSecret: 'history-unit-test-secret-that-is-longer-than-thirty-two-characters', jwtExpiresIn: '1h' };
const userId = 'aaaaaaaaaaaaaaaaaaaaaaaa';
const otherUserId = 'bbbbbbbbbbbbbbbbbbbbbbbb';
const fixture = {
  itemName: 'Desk lamp', category: 'metal', likelyMaterials: ['metal'], visibleCondition: 'good',
  reusePotential: 'promising', confidence: 0.8, uncertaintyNotes: [], reuseSuggestions: [],
  recyclingRecommendation: 'Check local guidance.', safetyNotes: [], explanation: 'A lamp is visible.',
};

function createHarness() {
  const records = [];
  const User = {
    findById(id) {
      const selected = { id: id.toString(), role: 'customer', name: 'History User', email: 'private@example.com', active: true };
      return { select: async () => selected };
    },
  };
  const AnalysisRecord = {
    async create({ user, result }) {
      const record = { _id: new mongoose.Types.ObjectId(), user, result, createdAt: new Date() };
      record.id = record._id.toString();
      records.push(record);
      return record;
    },
    find(filter) {
      let rows = records.filter((record) => record.user === filter.user);
      const query = {
        sort() { rows = [...rows].sort((a, b) => b.createdAt - a.createdAt || b._id.toString().localeCompare(a._id.toString())); return query; },
        skip(count) { rows = rows.slice(count); return query; },
        limit(count) { rows = rows.slice(0, count); return query; },
        lean: async () => rows.map((row) => ({ ...row, _id: row._id })),
      };
      return query;
    },
    countDocuments: async (filter) => records.filter((record) => record.user === filter.user).length,
    findOne: (filter) => ({ lean: async () => records.find((record) => record._id.toString() === filter._id && record.user === filter.user) || null }),
  };
  const app = express();
  app.use(express.raw({ type: 'image/*', limit: '8mb' }));
  app.use('/api/v1', createRoutes({ User, AnalysisRecord }, config, { analyzeImage: async () => fixture }));
  app.use((_req, res) => res.status(404).json({ success: false, error: { message: 'Route not found' } }));
  app.use((error, _req, res, _next) => res.status(error.status || 500).json({ success: false, error: { message: error.message } }));
  const token = (sub) => jwt.sign({ sub, role: 'customer' }, config.jwtSecret, { expiresIn: '1h' });
  return { app, records, token };
}

test('successful authenticated analysis is persisted and appears in paginated history and detail', async () => {
  const { app, records, token } = createHarness();
  const auth = `Bearer ${token(userId)}`;
  const saved = await request(app).post('/api/v1/analysis').set('Authorization', auth).set('Content-Type', 'image/jpeg').send(Buffer.from([0xff, 0xd8, 0xff, 1]));
  assert.equal(saved.status, 201);
  assert.equal(records.length, 1);
  assert.equal(records[0].user, userId);
  assert.equal(Object.hasOwn(records[0], 'image'), false);

  const history = await request(app).get('/api/v1/analysis/history?page=1&limit=2').set('Authorization', auth);
  assert.equal(history.status, 200);
  assert.equal(history.body.data.items.length, 1);
  assert.equal(history.body.data.items[0].itemName, 'Desk lamp');
  assert.deepEqual(history.body.data.pagination, { page: 1, limit: 2, total: 1, totalPages: 1 });

  const detail = await request(app).get(`/api/v1/analysis/history/${saved.body.data.analysisId}`).set('Authorization', auth);
  assert.equal(detail.status, 200);
  assert.equal(detail.body.data.itemName, 'Desk lamp');
});

test('history and detail require authentication and never return another user’s record', async () => {
  const { app, token } = createHarness();
  const saved = await request(app).post('/api/v1/analysis').set('Authorization', `Bearer ${token(userId)}`).set('Content-Type', 'image/jpeg').send(Buffer.from([0xff, 0xd8, 0xff, 1]));
  const url = `/api/v1/analysis/history/${saved.body.data.analysisId}`;
  assert.equal((await request(app).get('/api/v1/analysis/history')).status, 401);
  assert.equal((await request(app).get(url)).status, 401);
  assert.equal((await request(app).get(url).set('Authorization', `Bearer ${token(otherUserId)}`)).status, 404);
  assert.equal((await request(app).get('/api/v1/analysis/history/nope').set('Authorization', `Bearer ${token(userId)}`)).status, 400);
});

test('history pagination rejects out of range and unknown parameters', async () => {
  const { app, token } = createHarness();
  const auth = `Bearer ${token(userId)}`;
  for (const query of ['?page=0', '?limit=51', '?page=abc', '?unexpected=1']) {
    assert.equal((await request(app).get(`/api/v1/analysis/history${query}`).set('Authorization', auth)).status, 400);
  }
});
