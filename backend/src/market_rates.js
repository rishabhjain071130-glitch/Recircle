const express = require('express');
const mongoose = require('mongoose');
const { z } = require('zod');
const { auth } = require('./middleware/auth');

const materialSchema = z.object({
  materialId: z.string().regex(/^[a-z0-9-]+$/), name: z.string().trim().min(1).max(80),
  minimum: z.number().min(0), maximum: z.number().min(0), indicative: z.number().min(0), grade: z.string().max(100).optional(),
}).strict().refine((m) => m.minimum <= m.maximum && m.indicative >= m.minimum && m.indicative <= m.maximum, { message: 'Prices must be ordered minimum ≤ indicative ≤ maximum' });
const sheetSchema = z.object({
  effectiveDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/), scope: z.string().trim().min(1).max(80).default('IN'),
  currency: z.literal('INR').default('INR'), unit: z.literal('kg').default('kg'), materials: z.array(materialSchema).max(100),
  status: z.enum(['draft', 'scheduled']).default('draft'), notes: z.string().max(1000).optional(), source: z.string().max(500).optional(),
}).strict().refine((s) => { const date = new Date(`${s.effectiveDate}T00:00:00.000Z`); return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === s.effectiveDate; }, { message: 'Effective date is invalid', path: ['effectiveDate'] }).refine((s) => new Set(s.materials.map((m) => m.materialId)).size === s.materials.length, { message: 'Duplicate materials are not allowed', path: ['materials'] });
const pageSchema = z.object({ page: z.coerce.number().int().min(1).default(1), limit: z.coerce.number().int().min(1).max(50).default(20), date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(), demo: z.enum(['true', 'false']).optional() }).strict();
const fail = (res, status, message) => res.status(status).json({ success: false, error: { message } });
const utcTodayInIndia = () => new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
function makeMarketRateRouter(models, config) {
  const router = express.Router();
  const customerFilter = (extra = {}) => ({ status: { $in: ['published', 'scheduled'] }, isDemo: config.demoMode, ...extra });
  router.get('/market-rates/available-dates', async (_req, res, next) => {
    try { const data = await models.MarketRate.find(customerFilter()).select('effectiveDate').sort({ effectiveDate: -1 }).lean(); res.json({ success: true, data: [...new Set(data.map((x) => x.effectiveDate))] }); } catch (e) { next(e); }
  });
  router.get('/market-rates/history/:material', async (req, res, next) => {
    try {
      const q = pageSchema.parse(req.query); const filter = customerFilter({ 'materials.materialId': req.params.material, effectiveDate: { $lt: utcTodayInIndia() } });
      if (models.MarketRateHistory) {
        const historyFilter = { effectiveDate: { $lt: utcTodayInIndia() }, action: { $in: ['published', 'corrected'] } };
        const rows = await models.MarketRateHistory.find(historyFilter).sort({ effectiveDate: -1, version: -1 }).lean();
        const history = rows.filter((row) => row.snapshot?.isDemo === config.demoMode && row.snapshot?.materials?.some((material) => material.materialId === req.params.material));
        const pageItems = history.slice((q.page - 1) * q.limit, q.page * q.limit).map((row) => ({ ...row.snapshot, historicalAction: row.action, materials: row.snapshot.materials.filter((m) => m.materialId === req.params.material) }));
        return res.json({ success: true, data: { items: pageItems, pagination: { page: q.page, limit: q.limit, total: history.length, totalPages: Math.ceil(history.length / q.limit) } } });
      }
      const [items, total] = await Promise.all([models.MarketRate.find(filter).sort({ effectiveDate: -1 }).skip((q.page - 1) * q.limit).limit(q.limit).lean(), models.MarketRate.countDocuments(filter)]);
      res.json({ success: true, data: { items: items.map((x) => ({ ...x, materials: x.materials.filter((m) => m.materialId === req.params.material) })), pagination: { page: q.page, limit: q.limit, total, totalPages: Math.ceil(total / q.limit) } } });
    } catch (e) { next(e); }
  });
  router.get('/market-rates/:material', async (req, res, next) => {
    try { const item = await models.MarketRate.findOne(customerFilter({ 'materials.materialId': req.params.material, effectiveDate: { $lte: utcTodayInIndia() } })).sort({ effectiveDate: -1 }).lean(); res.json({ success: true, data: item ? { ...item, materials: item.materials.filter((m) => m.materialId === req.params.material) } : null }); } catch (e) { next(e); }
  });
  router.get('/market-rates', async (req, res, next) => {
    try {
      const date = req.query.date || utcTodayInIndia();
      if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return fail(res, 400, 'Date must use YYYY-MM-DD');
      const item = await models.MarketRate.findOne(customerFilter({ effectiveDate: date, status: date > utcTodayInIndia() ? 'scheduled' : { $in: ['published', 'scheduled'] } })).lean();
      res.json({ success: true, data: item || null });
    } catch (e) { next(e); }
  });
  router.get('/admin/market-rates', auth(config, 'admin'), async (req, res, next) => {
    try { const q = pageSchema.parse(req.query); const filter = q.demo ? { isDemo: q.demo === 'true' } : {}; const [items, total] = await Promise.all([models.MarketRate.find(filter).sort({ effectiveDate: -1 }).skip((q.page - 1) * q.limit).limit(q.limit).lean(), models.MarketRate.countDocuments(filter)]); res.json({ success: true, data: { items, demoMode: config.demoMode, pagination: { page: q.page, limit: q.limit, total, totalPages: Math.ceil(total / q.limit) } } }); } catch (e) { next(e); }
  });
  router.get('/admin/market-rates/:id/history', auth(config, 'admin'), async (req, res, next) => {
    try {
      if (!mongoose.isValidObjectId(req.params.id)) return fail(res, 400, 'Invalid market rate ID');
      if (!models.MarketRateHistory) return res.json({ success: true, data: [] });
      const entries = await models.MarketRateHistory.find({ marketRate: req.params.id }).sort({ version: -1 }).limit(50).lean();
      res.json({ success: true, data: entries });
    } catch (e) { next(e); }
  });
  router.post('/admin/market-rates', auth(config, 'admin'), async (req, res, next) => {
    try { const body = sheetSchema.parse(req.body); const doc = await models.MarketRate.create({ ...body, notes: config.demoMode ? (body.notes || 'DEMO DATA: illustrative values for demonstration only; not real market quotations or guaranteed offers.') : body.notes, isDemo: config.demoMode, createdBy: req.user.id, updatedBy: req.user.id }); await models.MarketRateAudit.create({ marketRate: doc.id, actor: req.user.id, action: 'created', version: doc.version, snapshot: doc.toObject() }); res.status(201).json({ success: true, data: doc }); } catch (e) { if (e.code === 11000) return fail(res, 409, 'A rate sheet already exists for this date and scope'); next(e); }
  });
  router.patch('/admin/market-rates/:id', auth(config, 'admin'), async (req, res, next) => {
    try {
      if (!mongoose.isValidObjectId(req.params.id)) return fail(res, 400, 'Invalid market rate ID');
      const body = sheetSchema.parse(req.body); const doc = await models.MarketRate.findById(req.params.id); if (!doc) return fail(res, 404, 'Rate sheet not found');
      const action = doc.status === 'published' ? 'corrected' : 'updated';
      if (doc.status === 'published') {
        const prior = doc.toObject();
        await models.MarketRateAudit.create({ marketRate: doc.id, actor: req.user.id, action, version: doc.version, snapshot: prior });
        if (models.MarketRateHistory) await models.MarketRateHistory.create({ marketRate: doc.id, effectiveDate: doc.effectiveDate, actor: req.user.id, action: 'corrected', version: doc.version + 1, snapshot: prior });
      }
      Object.assign(doc, body, { status: doc.status === 'published' ? 'published' : body.status, updatedBy: req.user.id, version: doc.version + 1 }); await doc.save();
      await models.MarketRateAudit.create({ marketRate: doc.id, actor: req.user.id, action: `${action}_saved`, version: doc.version, snapshot: doc.toObject() }); res.json({ success: true, data: doc });
    } catch (e) { if (e.name === 'VersionError') return fail(res, 409, 'Rate sheet changed; refresh and retry'); if (e.code === 11000) return fail(res, 409, 'A rate sheet already exists for this date and scope'); next(e); }
  });
  router.post('/admin/market-rates/:id/publish', auth(config, 'admin'), async (req, res, next) => {
    try {
      const reason = z.object({ reason: z.string().max(500).optional() }).strict().parse(req.body || {});
      const id = req.params.id; if (!mongoose.isValidObjectId(id)) return fail(res, 400, 'Invalid market rate ID');
      const current = await models.MarketRate.findOne({ _id: id, status: { $in: ['draft', 'scheduled', 'unpublished'] } });
      if (!current || current.materials.length === 0) return fail(res, 409, 'Rate sheet cannot be published; it may be empty, missing, or already published');
      const nextStatus = current.effectiveDate > utcTodayInIndia() ? 'scheduled' : 'published';
      const doc = await models.MarketRate.findOneAndUpdate({ _id: id, status: current.status, version: current.version }, { $set: { status: nextStatus, publishedBy: req.user.id, publishedAt: new Date(), updatedBy: req.user.id }, $inc: { version: 1 } }, { new: true, runValidators: true });
      if (!doc) return fail(res, 409, 'Rate sheet changed; refresh and retry');
      await models.MarketRateAudit.create({ marketRate: doc.id, actor: req.user.id, action: 'published', reason: reason.reason || '', version: doc.version, snapshot: doc.toObject() });
      if (models.MarketRateHistory) await models.MarketRateHistory.create({ marketRate: doc.id, effectiveDate: doc.effectiveDate, actor: req.user.id, action: 'published', version: doc.version, snapshot: doc.toObject() });
      res.json({ success: true, data: doc });
    } catch (e) { next(e); }
  });
  router.post('/admin/market-rates/:id/unpublish', auth(config, 'admin'), async (req, res, next) => {
    try {
      const body = z.object({ reason: z.string().trim().min(3).max(500) }).strict().parse(req.body || {}); const id = req.params.id; if (!mongoose.isValidObjectId(id)) return fail(res, 400, 'Invalid market rate ID');
      const doc = await models.MarketRate.findOneAndUpdate({ _id: id, status: 'published' }, { $set: { status: 'unpublished', updatedBy: req.user.id }, $inc: { version: 1 } }, { new: true }); if (!doc) return fail(res, 409, 'Only a published rate sheet can be unpublished');
      await models.MarketRateAudit.create({ marketRate: doc.id, actor: req.user.id, action: 'unpublished', reason: body.reason, version: doc.version, snapshot: doc.toObject() });
      if (models.MarketRateHistory) await models.MarketRateHistory.create({ marketRate: doc.id, effectiveDate: doc.effectiveDate, actor: req.user.id, action: 'unpublished', version: doc.version, snapshot: doc.toObject() });
      res.json({ success: true, data: doc });
    } catch (e) { next(e); }
  });
  return router;
}
module.exports = { makeMarketRateRouter, utcTodayInIndia };
