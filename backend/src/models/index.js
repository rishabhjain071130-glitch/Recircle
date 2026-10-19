const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, maxlength: 100 },
  email: { type: String, required: true, lowercase: true, trim: true, unique: true, maxlength: 254 },
  passwordHash: { type: String, required: true, select: false },
  role: { type: String, enum: ['customer', 'partner'], default: 'customer', required: true },
  active: { type: Boolean, default: true },
}, { timestamps: true });

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
}, { timestamps: true });

const analysisRecordSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  result: { type: mongoose.Schema.Types.Mixed, required: true },
}, { timestamps: true });
analysisRecordSchema.index({ user: 1, createdAt: -1 });
pickupSchema.index({ customer: 1, createdAt: -1 });
pickupSchema.index({ partner: 1, status: 1, updatedAt: -1 });
pickupSchema.index({ status: 1, partner: 1, createdAt: -1 });

const User = mongoose.models.User || mongoose.model('User', userSchema);
const PickupRequest = mongoose.models.PickupRequest || mongoose.model('PickupRequest', pickupSchema);
const AnalysisRecord = mongoose.models.AnalysisRecord || mongoose.model('AnalysisRecord', analysisRecordSchema);
module.exports = { User, PickupRequest, AnalysisRecord };
