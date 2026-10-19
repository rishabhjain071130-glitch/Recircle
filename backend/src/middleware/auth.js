const jwt = require('jsonwebtoken');

function auth(config, role) {
  return async (req, res, next) => {
    const match = (req.headers.authorization || '').match(/^Bearer\s+(.+)$/i);
    if (!match) return res.status(401).json({ success: false, error: { message: 'Authentication required' } });
    let payload;
    try {
      payload = jwt.verify(match[1], config.jwtSecret);
    } catch (_error) {
      return res.status(401).json({ success: false, error: { message: 'Session is invalid or expired' } });
    }
    try {
      const user = await req.models.User.findById(payload.sub).select('name email role active');
      if (!user || !user.active) return res.status(401).json({ success: false, error: { message: 'Session is invalid or expired' } });
      if (role && user.role !== role) return res.status(403).json({ success: false, error: { message: 'Forbidden' } });
      req.user = user;
      return next();
    } catch (error) {
      return next(error);
    }
  };
}
module.exports = { auth };
