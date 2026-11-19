// Helper respons konsisten: { success, message, data }
// Dipakai auth, cakes, dan orders.
const ok = (res, status, message, data = null) =>
  res.status(status).json({ success: true, message, data });

const fail = (res, status, message, data = null) =>
  res.status(status).json({ success: false, message, data });

module.exports = { ok, fail };
