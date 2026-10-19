require('dotenv').config();

function getConfig(env = process.env) {
  return {
    port: Number(env.PORT || 3000),
    mongoUri: env.MONGODB_URI || '',
    jwtSecret: env.JWT_SECRET || '',
    jwtExpiresIn: env.JWT_EXPIRES_IN || '1d',
    corsOrigins: (env.CORS_ORIGINS || 'http://localhost:3000')
      .split(',').map((origin) => origin.trim()).filter(Boolean),
    partnerSetupKey: env.PARTNER_SETUP_KEY || '',
    geminiApiKey: env.GEMINI_API_KEY || '',
    geminiModel: env.GEMINI_MODEL || 'gemini-3.8-flash',
  };
}

function validateConfig(config) {
  const missing = [];
  if (!config.mongoUri) missing.push('MONGODB_URI');
  if (!config.jwtSecret || config.jwtSecret.length < 32) {
    missing.push('JWT_SECRET (at least 32 characters)');
  }
  if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) {
    missing.push('PORT (must be between 1 and 65535)');
  }
  if (missing.length) {
    throw new Error(`Invalid server configuration: ${missing.join(', ')}`);
  }
  return config;
}

module.exports = { getConfig, validateConfig };
