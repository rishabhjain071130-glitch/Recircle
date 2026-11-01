const jwt = require('jsonwebtoken');

function auth(config, role, { allowUnapprovedPartner = false } = {}) {
  return async (req, res, next) => {
    const unauthorized = (message) => {
      if (req.path === '/analysis') console.error(JSON.stringify({ event: 'analysis_failure', requestId: req.requestId || 'unknown', stage: 'authentication', httpStatus: 401, errorCategory: 'authentication' }));
      return res.status(401).json({ success: false, error: { message }, requestId: req.requestId });
    };
    const match = (req.headers.authorization || '').match(/^Bearer\s+(.+)$/i);
    if (!match) return unauthorized('Authentication required');
    let payload;
    try {
      payload = jwt.verify(match[1], config.jwtSecret);
    } catch (_error) {
      return unauthorized('Session is invalid or expired');
    }
    try {
      const user = await req.models.User.findById(payload.sub).select('name email role active phone address city pinCode serviceArea partnerStatus partnerStatusReason partnerAvailable');
      if (!user || !user.active) return unauthorized('Session is invalid or expired');
      if (role && user.role !== role) return res.status(403).json({ success: false, error: { message: 'Forbidden' } });
      if (role === 'partner' && !allowUnapprovedPartner && user.partnerStatus !== 'approved') {
        const messages = { pending: 'Partner account is awaiting admin approval', rejected: 'Partner account was rejected', suspended: 'Partner account is suspended' };
        return res.status(403).json({ success: false, error: { code: `PARTNER_${String(user.partnerStatus || 'pending').toUpperCase()}`, message: messages[user.partnerStatus] || 'Partner account is not approved' } });
      }
      req.user = user;
      return next();
    } catch (error) {
      return next(error);
    }
  };
}
module.exports = { auth };
