const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, maxlength: 100 },
  email: { type: String, required: true, lowercase: true, trim: true, unique: true, maxlength: 254 },
  passwordHash: { type: String, required: true, select: false },
  role: { type: String, enum: ['customer', 'partner', 'admin'], default: 'customer', required: true },
  active: { type: Boolean, default: true },
  phone: { type: String, trim: true, maxlength: 30, default: '' },
  address: { type: String, trim: true, maxlength: 500, default: '' },
  city: { type: String, trim: true, maxlength: 100, default: '' },
  pinCode: { type: String, trim: true, maxlength: 12, default: '' },
  serviceArea: { type: String, trim: true, maxlength: 200, default: '' },
  partnerStatus: { type: String, enum: ['pending', 'approved', 'rejected', 'suspended'], default: 'approved' },
  partnerStatusReason: { type: String, trim: true, maxlength: 500, default: '' },
  partnerAvailable: { type: Boolean, default: true },
}, { timestamps: true });
userSchema.index({ role: 1 }, { unique: true, partialFilterExpression: { role: 'admin' } });

const historySchema = new mongoose.Schema({
  from: { type: String, default: null },
  to: { type: String, required: true },
  actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  at: { type: Date, default: Date.now },
  note: { type: String, maxlength: 500, default: '' },
}, { _id: false });

const pickupSchema = new mongoose.Schema({
  customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  item: {
    category: { type: String, required: true, trim: true, maxlength: 60 },
    name: { type: String, required: true, trim: true, maxlength: 120 },
    condition: { type: String, required: true, trim: true, maxlength: 60 },
    brandModel: { type: String, trim: true, maxlength: 120, default: '' },
    quantity: { type: Number, min: 1, max: 999, default: 1 },
    imageReference: { type: String, maxlength: 500, default: '' },
  },
  pickup: {
    address: { type: String, required: true, trim: true, maxlength: 500 },
    contactName: { type: String, required: true, trim: true, maxlength: 100 },
    contactPhone: { type: String, required: true, trim: true, maxlength: 30 },
    preferredDate: { type: String, trim: true, maxlength: 40, default: '' },
    preferredTime: { type: String, trim: true, maxlength: 60, default: '' },
    notes: { type: String, trim: true, maxlength: 500, default: '' },
  },
  partner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null, index: true },
  status: { type: String, enum: ['Submitted', 'Accepted', 'Collected', 'ReceivedForProcessing', 'Completed', 'Cancelled'], default: 'Submitted', index: true },
  history: { type: [historySchema], default: [] },
  rejectedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
}, { timestamps: true });

const analysisRecordSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  result: { type: mongoose.Schema.Types.Mixed, required: true },
}, { timestamps: true });
const marketRateSchema = new mongoose.Schema({
  effectiveDate: { type: String, required: true },
  scope: { type: String, default: 'IN', required: true, trim: true },
  currency: { type: String, default: 'INR', required: true },
  unit: { type: String, default: 'kg', required: true },
  status: { type: String, enum: ['draft', 'scheduled', 'published', 'unpublished'], default: 'draft', required: true },
  materials: [{ materialId: { type: String, required: true }, name: { type: String, required: true }, minimum: { type: Number, min: 0 }, maximum: { type: Number, min: 0 }, indicative: { type: Number, min: 0 }, grade: { type: String, default: '' } }],
  isDemo: { type: Boolean, default: false, required: true },
  notes: { type: String, maxlength: 1000, default: '' },
  source: { type: String, maxlength: 500, default: '' },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  updatedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  publishedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  publishedAt: { type: Date, default: null },
  version: { type: Number, default: 1, required: true },
}, { timestamps: true, optimisticConcurrency: true });
marketRateSchema.index({ effectiveDate: 1, scope: 1 }, { unique: true });
marketRateSchema.index({ status: 1, effectiveDate: -1 });
marketRateSchema.index({ 'materials.materialId': 1, status: 1, effectiveDate: -1 });
const marketRateAuditSchema = new mongoose.Schema({
  marketRate: { type: mongoose.Schema.Types.ObjectId, ref: 'MarketRate', required: true },
  actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  action: { type: String, required: true }, reason: { type: String, default: '' },
  version: { type: Number, required: true }, snapshot: { type: mongoose.Schema.Types.Mixed, required: true },
}, { timestamps: true });
marketRateAuditSchema.index({ marketRate:  1, createdAt: -1 });
const marketRateHistorySchema = new mongoose.Schema({
  marketRate: { type: mongoose.Schema.Types.ObjectId, ref: 'MarketRate', required: true },
  effectiveDate: { type: String, required: true }, version: { type: Number, required: true },
  actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  action: { type: String, enum: ['published', 'corrected', 'unpublished'], required: true },
  snapshot: { type: mongoose.Schema.Types.Mixed, required: true },
}, { timestamps: true });
marketRateHistorySchema.index({ effectiveDate: -1, 'snapshot.materials.materialId': 1 });
marketRateHistorySchema.index({ marketRate: 1, version: -1 }, { unique: true });
const partnerApprovalAuditSchema = new mongoose.Schema({
  partner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  from: { type: String, required: true }, to: { type: String, required: true },
  reason: { type: String, maxlength: 500, default: '' },
}, { timestamps: true });
partnerApprovalAuditSchema.index({ partner: 1, createdAt: -1 });
analysisRecordSchema.index({ user: 1, createdAt: -1 });
pickupSchema.index({ customer: 1, createdAt: -1 });
pickupSchema.index({ partner: 1, status: 1, updatedAt: -1 });
pickupSchema.index({ status: 1, partner: 1, createdAt: -1 });

const User = mongoose.models.User || mongoose.model('User', userSchema);
const PickupRequest = mongoose.models.PickupRequest || mongoose.model('PickupRequest', pickupSchema);
const AnalysisRecord = mongoose.models.AnalysisRecord || mongoose.model('AnalysisRecord', analysisRecordSchema);
const MarketRate = mongoose.models.MarketRate || mongoose.model('MarketRate', marketRateSchema);
const MarketRateAudit = mongoose.models.MarketRateAudit || mongoose.model('MarketRateAudit', marketRateAuditSchema);
const MarketRateHistory = mongoose.models.MarketRateHistory || mongoose.model('MarketRateHistory', marketRateHistorySchema);
const PartnerApprovalAudit = mongoose.models.PartnerApprovalAudit || mongoose.model('PartnerApprovalAudit', partnerApprovalAuditSchema);
module.exports = { User, PickupRequest, AnalysisRecord, MarketRate, MarketRateAudit, MarketRateHistory, PartnerApprovalAudit };
