require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const pool = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const cakeRoutes = require('./routes/cakeRoutes');
const categoryRoutes = require('./routes/categoryRoutes');

const app = express();
app.use(cors());
app.use(express.json());

// Health check — cek server hidup, tanpa auth
app.get('/health', (req, res) =>
  res.json({ success: true, message: 'SweetCraft API hidup', data: null })
);

app.use('/api/auth', authRoutes);
app.use('/api/cakes', cakeRoutes);
app.use('/api/categories', categoryRoutes);

// Express 5: rejection dari handler async otomatis diteruskan ke middleware ini.
// Source: https://expressjs.com/en/guide/error-handling.html
app.use((err, req, res, next) => {
  // Error dari multer (upload): ukuran berlebih → 413, lainnya (mis. field salah) → 400
  // Source: https://github.com/expressjs/multer#error-handling
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res
        .status(413)
        .json({ success: false, message: 'Ukuran file maksimal 2 MB', data: null });
    }
    return res.status(400).json({ success: false, message: err.message, data: null });
  }
  // Error dengan status eksplisit (mis. fileFilter menolak tipe file)
  if (err.status) {
    return res.status(err.status).json({ success: false, message: err.message, data: null });
  }
  if (err.code === 'ER_DUP_ENTRY') {
    return res
      .status(409)
      .json({ success: false, message: 'Email sudah terdaftar', data: null });
  }
  // FK: kategori yang dirujuk tidak ada (mis. category_id 9999)
  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    return res
      .status(400)
      .json({ success: false, message: 'Referensi tidak valid (kategori tidak ditemukan)', data: null });
  }
  // FK RESTRICT: data masih dipakai baris lain (mis. kue sudah ada di orders)
  if (err.code === 'ER_ROW_IS_REFERENCED_2') {
    return res
      .status(409)
      .json({ success: false, message: 'Data masih dipakai data lain, tidak bisa dihapus', data: null });
  }
  console.error(err);
  return res
    .status(500)
    .json({ success: false, message: 'Terjadi kesalahan server', data: null });
});

const PORT = process.env.PORT || 5000;

// Fail fast: server tidak jalan kalau DB tidak bisa dihubungi
pool
  .query('SELECT 1')
  .then(() => {
    app.listen(PORT, () =>
      console.log(`SweetCraft API berjalan di http://localhost:${PORT}`)
    );
  })
  .catch((err) => {
    // AggregateError dari koneksi punya message kosong; tampilkan code sebagai cadangan.
    console.error('Gagal koneksi database:', err.message || err.code || err);
    process.exit(1);
  });
