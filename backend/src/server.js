const mongoose = require('mongoose');
const { getConfig, validateConfig } = require('./config');
const { createApp } = require('./app');
const { User, PickupRequest, AnalysisRecord } = require('./models');
const { createGeminiAnalyzer } = require('./services/gemini_analyzer');

async function start() {
  const config = validateConfig(getConfig());
  try {
    await mongoose.connect(config.mongoUri, {
      serverSelectionTimeoutMS: 8000,
      connectTimeoutMS: 8000,
    });
  } catch (error) {
    // Avoid printing a MongoDB URI, which may contain credentials.
    console.error(`MongoDB connection failed (${error.name || 'Error'}); server not started.`);
    throw new Error('MongoDB connection failed; check that the configured database is running and reachable.');
  }
  const app = createApp({
    config,
    models: { User, PickupRequest, AnalysisRecord },
    analyzeImage: createGeminiAnalyzer(config),
  });
  return app.listen(config.port, '0.0.0.0', () => console.log(`ReCircle API listening on port ${config.port}`));
}

if (require.main === module) start().catch((error) => { console.error(error.message); process.exit(1); });
module.exports = { start };
