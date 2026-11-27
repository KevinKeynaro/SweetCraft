const multer = require('multer');

// memoryStorage: file masuk sebagai req.file.buffer → langsung di-stream ke Cloudinary,
// tidak menyentuh disk server.
// Source: https://github.com/expressjs/multer#memorystorage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 }, // maksimal 2 MB
  fileFilter: (req, file, cb) => {
    // Terima semua tipe gambar (JPG, PNG, WEBP, GIF, HEIC, dll).
    // Sumber: https://github.com/expressjs/multer#filefilter
    const isImage =
      typeof file.mimetype === 'string' && file.mimetype.startsWith('image/');
    if (!isImage) {
      const err = new Error('File harus berupa gambar.');
      err.status = 400;
      return cb(err);
    }
    return cb(null, true);
  },
});

module.exports = upload;
