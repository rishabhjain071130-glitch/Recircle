require('dotenv').config();
const mongoose = require('mongoose');
const { User, MarketRate, MarketRateHistory, MarketRateAudit } = require('../src/models');
const { utcTodayInIndia } = require('../src/market_rates');

const illustrativeMaterials = [
  { materialId: 'copper', name: 'Copper', minimum: 680, maximum: 720, indicative: 700 },
  { materialId: 'aluminium', name: 'Aluminium', minimum: 110, maximum: 140, indicative: 125 },
  { materialId: 'iron-steel', name: 'Iron / Steel', minimum: 25, maximum: 35, indicative: 30 },
  { materialId: 'brass', name: 'Brass', minimum: 400, maximum: 450, indicative: 425 },
  { materialId: 'circuit-boards', name: 'Circuit Boards (PCB)', minimum: 180, maximum: 280, indicative: 230 },
  { materialId: 'mixed-e-waste', name: 'Mixed E-Waste', minimum: 30, maximum: 55, indicative: 42.5 },
];
function assertDemoMode(env = process.env) {
  if (env.DEMO_MODE !== 'true') throw new Error('Demo seeding is disabled. Set DEMO_MODE=true explicitly for the selected database.');
}
async function seedDemoRatesForModels({ User, MarketRate, MarketRateHistory, MarketRateAudit }, todayValue = utcTodayInIndia()) {
  const today = new Date(`${todayValue}T12:00:00+05:30`);
  const dates = [-30, -7, -1, 0, 7].map((offset) => {
    const d = new Date(today); d.setUTCDate(d.getUTCDate() + offset);
    return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata', year: 'numeric', month: '2-digit', day: '2-digit' }).format(d);
  });
  const admin = await User.findOne({ role: 'admin', active: true });
  if (!admin) throw new Error('Bootstrap an admin account before seeding demo rates.');
  let inserted = 0;
  for (const effectiveDate of dates) {
    if (await MarketRate.exists({ effectiveDate, scope: 'IN' })) continue;
    const doc = await MarketRate.create({ effectiveDate, scope: 'IN', currency: 'INR', unit: 'kg', status: effectiveDate > todayValue ? 'scheduled' : 'published', materials: illustrativeMaterials, isDemo: true, notes: 'DEMO DATA: illustrative values for application demonstration only. Not real market quotations or guaranteed offers.', source: 'Illustrative demo dataset supplied for demonstration; not sourced from live markets.', createdBy: admin.id, updatedBy: admin.id, publishedBy: effectiveDate <= todayValue ? admin.id : null, publishedAt: effectiveDate <= todayValue ? new Date() : null });
    if (doc.status === 'published') {
      const snapshot = doc.toObject();
      await MarketRateHistory.create({ marketRate: doc.id, effectiveDate, version: doc.version, actor: admin.id, action: 'published', snapshot });
      await MarketRateAudit.create({ marketRate: doc.id, actor: admin.id, action: 'demo_seed_published', version: doc.version, snapshot });
    }
    inserted += 1;
  }
  return inserted;
}
async function seedDemoRates() {
  assertDemoMode();
  if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI is required.');
  await mongoose.connect(process.env.MONGODB_URI);
  try {
    const inserted = await seedDemoRatesForModels({ User, MarketRate, MarketRateHistory, MarketRateAudit });
    console.log(`Demo seed complete: inserted ${inserted} rate sheets; existing dates were left unchanged.`);
  } finally { await mongoose.disconnect(); }
}
if (require.main === module) seedDemoRates().catch((error) => { console.error(error.message); process.exitCode = 1; });
module.exports = { seedDemoRates, seedDemoRatesForModels, assertDemoMode, illustrativeMaterials };
