const jwt = require('jsonwebtoken');

// Verifikasi header "Authorization: Bearer <token>" → req.user = { id, role }
function verifyToken(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res
      .status(401)
      .json({ success: false, message: 'Token tidak ada. Login dulu.', data: null });
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    return next();
  } catch {
    return res
      .status(401)
      .json({ success: false, message: 'Token tidak valid atau kedaluwarsa', data: null });
  }
}

module.exports = { verifyToken };
