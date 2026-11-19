const multer = require('multer');

const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp'];

// memoryStorage: file masuk sebagai req.file.buffer → langsung di-stream ke Cloudinary,
// tidak menyentuh disk server.
// Source: https://github.com/expressjs/multer#memorystorage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 }, // maksimal 2 MB
  fileFilter: (req, file, cb) => {
    if (!ALLOWED_MIME.includes(file.mimetype)) {
      const err = new Error('Tipe file tidak didukung. Gunakan JPG, PNG, atau WEBP.');
      err.status = 400;
      return cb(err);
    }
    return cb(null, true);
  },
});

module.exports = upload;
