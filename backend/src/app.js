const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { getConfig } = require('./config');

function createApp({ config = getConfig(), models, analyzeImage } = {}) {
  const app = express();
  app.disable('x-powered-by');
  app.use(helmet());
  app.use(cors({ origin: (origin, callback) => {
    if (!origin || config.corsOrigins.includes(origin)) return callback(null, true);
    return callback(new Error('Origin not allowed'));
  } }));
  app.use(express.json({ limit: '1mb' }));
  app.get('/api/v1/health', (_req, res) => {
    const databaseConnected = require('mongoose').connection.readyState === 1;
    res.status(databaseConnected ? 200 : 503).json({
      success: databaseConnected,
      data: { status: databaseConnected ? 'ok' : 'unavailable', database: databaseConnected ? 'connected' : 'disconnected' },
    });
  });
  app.use('/api/v1/auth', rateLimit({ windowMs: 15 * 60 * 1000, limit: 30, standardHeaders: 'draft-7', legacyHeaders: false }));
  app.use('/api/v1', require('./routes')(models, config, { analyzeImage }));
  app.use((_req, res) => res.status(404).json({ success: false, error: { message: 'Route not found' } }));
  app.use((err, _req, res, _next) => {
    if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
      return res.status(400).json({ success: false, error: { message: 'Malformed JSON request body' } });
    }
    const status = err.status || 500;
    if (status >= 500) console.error('Unhandled API error:', err.name || 'Error');
    const message = status === 413
      ? 'The image is too large. Choose an image under 8 MB.'
      : status >= 500
        ? (err.name === 'GeminiProviderError' ? err.message : 'Internal server error')
        : err.message;
    res.status(status).json({ success: false, error: { message, ...(err.details ? { details: err.details } : {}) } });
  });
  return app;
}

module.exports = { createApp };
