require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const { User } = require('../src/models');

async function bootstrap() {
  const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD;
  const name = process.env.ADMIN_NAME?.trim();
  if (!process.env.MONGODB_URI || !email || !password || !name) throw new Error('Set MONGODB_URI, ADMIN_EMAIL, ADMIN_PASSWORD, and ADMIN_NAME in the server environment.');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || name.length < 2) throw new Error('ADMIN_EMAIL or ADMIN_NAME is invalid.');
  if (password.length < 12) throw new Error('ADMIN_PASSWORD must contain at least 12 characters.');
  await mongoose.connect(process.env.MONGODB_URI);
  try {
    await User.init();
    if (await User.exists({ role: 'admin' })) throw new Error('An admin already exists; bootstrap is one-time and will not create another.');
    await User.create({ name, email, passwordHash: await bcrypt.hash(password, 12), role: 'admin' });
    console.log('Initial admin account created. Sign in through the existing ReCircle login.');
  } finally { await mongoose.disconnect(); }
}
if (require.main === module) bootstrap().catch((error) => { console.error(error.message); process.exitCode = 1; });
module.exports = { bootstrap };
