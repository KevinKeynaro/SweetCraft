// Middleware validasi reusable — dipasang di routes SEBELUM controller.
// Express 5 (sumber: https://expressjs.com/en/guide/migrating-5.html):
//  - req.body = undefined jika request tanpa body → di-?? {} agar tidak crash
//  - req.query = getter-only (tidak bisa ditulis balik) → yang ditulis balik HANYA req.body
const validate = (schema) => (req, res, next) => {
  const result = schema.safeParse({
    body: req.body ?? {},
    query: req.query,
    params: req.params,
  });

  if (!result.success) {
    return res.status(400).json({
      success: false,
      message: 'Data tidak valid',
      data: result.error.issues.map((i) => ({
        field: i.path.filter((p) => p !== 'body').join('.'), // "name", bukan "body.name"
        message: i.message,
      })),
    });
  }

  req.body = result.data.body; // body sudah bersih & tervalidasi untuk controller
  return next();
};

module.exports = { validate };
