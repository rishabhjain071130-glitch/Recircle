const express = require('express');
const mongoose = require('mongoose');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const { auth } = require('./middleware/auth');
const { analysisSchema, GeminiProviderError } = require('./services/gemini_analyzer');

const registerSchema = z.object({ name: z.string().trim().min(2).max(100), email: z.string().trim().email().max(254), password: z.string().min(8).max(72) }).strict();
const loginSchema = z.object({ email: z.string().trim().email(), password: z.string().min(1).max(72) }).strict();
const createSchema = z.object({
  item: z.object({ category: z.string().trim().min(2).max(60), name: z.string().trim().min(2).max(120), condition: z.string().trim().min(2).max(60), brandModel: z.string().max(120).optional(), quantity: z.number().int().min(1).max(999).default(1), imageReference: z.string().max(500).optional() }).strict(),
  pickup: z.object({ address: z.string().trim().min(5).max(500), contactName: z.string().trim().min(2).max(100), contactPhone: z.string().trim().min(5).max(30), preferredDate: z.string().max(40).optional(), preferredTime: z.string().max(60).optional(), notes: z.string().max(500).optional() }).strict(),
}).strict();
const statusSchema = z.object({ status: z.enum(['Collected', 'ReceivedForProcessing', 'Completed']), note: z.string().trim().max(500).optional() }).strict();
const imageMimeTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
const categoryNames = ['plastic', 'paper', 'cardboard', 'glass', 'metal', 'electronics', 'textiles', 'mixedMaterials', 'unknown'];

function imageFormat(image) {
  if (image.length >= 3 && image[0] === 0xff && image[1] === 0xd8 && image[2] === 0xff) return 'image/jpeg';
  if (image.length >= 8 && image.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) return 'image/png';
  if (image.length >= 12 && image.toString('ascii', 0, 4) === 'RIFF' && image.toString('ascii', 8, 12) === 'WEBP') return 'image/webp';
  return null;
}

function validate(schema, value) {
  const parsed = schema.safeParse(value);
  if (!parsed.success) {
    const error = new Error('Invalid request data');
    error.status = 400;
    error.details = parsed.error.issues.map((issue) => ({ field: issue.path.join('.'), message: issue.message }));
    throw error;
  }
  return parsed.data;
}

function tokenFor(user, config) {
  return jwt.sign({ sub: user.id, role: user.role }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
}

function validRequestId(req, res) {
  if (mongoose.isValidObjectId(req.params.id)) return true;
  res.status(400).json({ success: false, error: { message: 'Invalid request ID' } });
  return false;
}

module.exports = (models = {}, config = {}, { analyzeImage } = {}) => {
  const router = express.Router();
  router.use((req, _res, next) => { req.models = models; next(); });

  router.post('/analysis', auth(config, 'customer'), rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 10,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    keyGenerator: (req) => req.user.id,
  }), express.raw({ type: 'image/*', limit: '8mb' }), async (req, res, next) => {
    try {
      if (!Buffer.isBuffer(req.body) || req.body.length === 0) {
        return res.status(400).json({ success: false, error: { message: 'Choose a JPG, PNG, or WebP image to analyze.' } });
      }
      const declaredMime = (req.get('content-type') || '').split(';')[0].trim().toLowerCase();
      if (!imageMimeTypes.has(declaredMime) || imageFormat(req.body) !== declaredMime) {
        return res.status(400).json({ success: false, error: { message: 'The image content does not match a supported JPG, PNG, or WebP format.' } });
      }
      const manualCategory = req.get('x-recircle-category') || undefined;
      if (manualCategory && !categoryNames.includes(manualCategory)) {
        return res.status(400).json({ success: false, error: { message: 'Choose a valid item category.' } });
      }
      if (typeof analyzeImage !== 'function') {
        return res.status(503).json({ success: false, error: { message: 'Image analysis is not configured on the server.' } });
      }
      const providerResult = await analyzeImage({ image: req.body, mimeType: declaredMime, manualCategory });
      const parsedResult = analysisSchema.safeParse(providerResult);
      if (!parsedResult.success) throw new GeminiProviderError('The image analysis provider returned an unreadable result.', 502);
      const result = {
        ...parsedResult.data,
        ...(manualCategory ? { category: manualCategory } : {}),
      };
      const record = await models.AnalysisRecord.create({ user: req.user.id, result });
      res.status(201).json({ success: true, data: { ...result, analysisId: record.id, analyzedAt: record.createdAt } });
    } catch (error) { next(error); }
  });

  router.get('/analysis/history', auth(config, 'customer'), async (req, res, next) => {
    try {
      const records = await models.AnalysisRecord.find({ user: req.user.id }).sort({ createdAt: -1 }).limit(50).lean();
      res.json({ success: true, data: records.map((record) => ({ id: record._id, ...record.result, analyzedAt: record.createdAt })) });
    } catch (error) { next(error); }
  });

  router.post('/auth/register', async (req, res, next) => {
    try {
      const body = validate(registerSchema, req.body);
      const user = await models.User.create({ ...body, email: body.email.toLowerCase(), passwordHash: await bcrypt.hash(body.password, 12), role: 'customer' });
      res.status(201).json({ success: true, data: { token: tokenFor(user, config), user: { id: user.id, name: user.name, email: user.email, role: user.role } } });
    } catch (error) { if (error.code === 11000) return res.status(409).json({ success: false, error: { message: 'An account with this email already exists' } }); next(error); }
  });

  router.post('/auth/login', async (req, res, next) => {
    try {
      const body = validate(loginSchema, req.body);
      const user = await models.User.findOne({ email: body.email.toLowerCase() }).select('+passwordHash');
      if (!user || !user.active || !(await bcrypt.compare(body.password, user.passwordHash))) return res.status(401).json({ success: false, error: { message: 'Email or password is incorrect' } });
      res.json({ success: true, data: { token: tokenFor(user, config), user: { id: user.id, name: user.name, email: user.email, role: user.role } } });
    } catch (error) { next(error); }
  });

  router.post('/auth/partner-setup', async (req, res, next) => {
    try {
      if (!config.partnerSetupKey || req.get('x-partner-setup-key') !== config.partnerSetupKey) return res.status(403).json({ success: false, error: { message: 'Forbidden' } });
      const body = validate(registerSchema, req.body);
      const user = await models.User.create({ ...body, email: body.email.toLowerCase(), passwordHash: await bcrypt.hash(body.password, 12), role: 'partner' });
      res.status(201).json({ success: true, data: { id: user.id, name: user.name, email: user.email, role: user.role } });
    } catch (error) { if (error.code === 11000) return res.status(409).json({ success: false, error: { message: 'An account with this email already exists' } }); next(error); }
  });

  router.get('/auth/me', auth(config), (req, res) => res.json({ success: true, data: { id: req.user.id, name: req.user.name, email: req.user.email, role: req.user.role } }));

  router.post('/requests', auth(config, 'customer'), async (req, res, next) => {
    try {
      const body = validate(createSchema, req.body);
      const request = await models.PickupRequest.create({ ...body, customer: req.user.id, status: 'Submitted', history: [{ from: null, to: 'Submitted', actor: req.user.id, at: new Date() }] });
      res.status(201).json({ success: true, data: request });
    } catch (error) { next(error); }
  });

  router.get('/requests/mine', auth(config, 'customer'), async (req, res, next) => {
    try { const data = await models.PickupRequest.find({ customer: req.user.id }).sort({ createdAt: -1 }).limit(100).populate('partner', 'name email'); res.json({ success: true, data }); } catch (error) { next(error); }
  });

  router.get('/partner/requests/eligible', auth(config, 'partner'), async (req, res, next) => {
    try {
      const requests = await models.PickupRequest.find({ status: 'Submitted', partner: null }).sort({ createdAt: 1 }).limit(100).lean();
      const data = requests.map((request) => ({
        ...request,
        item: { category: request.item.category, name: request.item.name, condition: request.item.condition, quantity: request.item.quantity },
        pickup: { preferredDate: request.pickup.preferredDate, preferredTime: request.pickup.preferredTime },
      }));
      res.json({ success: true, data });
    } catch (error) { next(error); }
  });

  router.get('/partner/requests/mine', auth(config, 'partner'), async (req, res, next) => {
    try { const data = await models.PickupRequest.find({ partner: req.user.id }).sort({ updatedAt: -1 }).limit(100); res.json({ success: true, data }); } catch (error) { next(error); }
  });

  router.post('/partner/requests/:id/accept', auth(config, 'partner'), async (req, res, next) => {
    try {
      if (!validRequestId(req, res)) return;
      const result = await models.PickupRequest.updateOne({ _id: req.params.id, status: 'Submitted', partner: null }, { $set: { partner: req.user.id, status: 'Accepted' }, $push: { history: { from: 'Submitted', to: 'Accepted', actor: req.user.id, at: new Date() } } });
      if (result.modifiedCount !== 1) return res.status(409).json({ success: false, error: { message: 'Request is no longer available' } });
      res.json({ success: true, data: await models.PickupRequest.findById(req.params.id) });
    } catch (error) { next(error); }
  });

  router.get('/requests/:id', auth(config), async (req, res, next) => {
    try {
      if (!validRequestId(req, res)) return;
      const request = await models.PickupRequest.findById(req.params.id).populate('partner', 'name email');
      if (!request) return res.status(404).json({ success: false, error: { message: 'Request not found' } });
      const owns = request.customer.toString() === req.user.id;
      const assigned = request.partner && request.partner.id === req.user.id;
      if (!owns && !assigned) return res.status(403).json({ success: false, error: { message: 'Forbidden' } });
      res.json({ success: true, data: request });
    } catch (error) { next(error); }
  });

  router.patch('/partner/requests/:id/status', auth(config, 'partner'), async (req, res, next) => {
    try {
      if (!validRequestId(req, res)) return;
      const body = validate(statusSchema, req.body);
      const request = await models.PickupRequest.findOne({ _id: req.params.id, partner: req.user.id });
      if (!request) return res.status(404).json({ success: false, error: { message: 'Assigned request not found' } });
      const allowed = { Accepted: 'Collected', Collected: 'ReceivedForProcessing', ReceivedForProcessing: 'Completed' };
      if (allowed[request.status] !== body.status) return res.status(409).json({ success: false, error: { message: 'Status transition is not permitted' } });
      const result = await models.PickupRequest.updateOne({ _id: request.id, partner: req.user.id, status: request.status }, { $set: { status: body.status }, $push: { history: { from: request.status, to: body.status, actor: req.user.id, at: new Date(), note: body.note || '' } } });
      if (result.modifiedCount !== 1) return res.status(409).json({ success: false, error: { message: 'Request changed; refresh and try again' } });
      res.json({ success: true, data: await models.PickupRequest.findById(request.id) });
    } catch (error) { next(error); }
  });

  return router;
};
