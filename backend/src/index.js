require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./config/db');
const authRoutes = require('./routes/authRoutes');

const app = express();
app.use(cors());
app.use(express.json());

// Health check — cek server hidup, tanpa auth
app.get('/health', (req, res) =>
  res.json({ success: true, message: 'SweetCraft API hidup', data: null })
);

app.use('/api/auth', authRoutes);

// Express 5: rejection dari handler async otomatis diteruskan ke middleware ini.
// Source: https://expressjs.com/en/guide/error-handling.html
app.use((err, req, res, next) => {
  if (err.code === 'ER_DUP_ENTRY') {
    return res
      .status(409)
      .json({ success: false, message: 'Email sudah terdaftar', data: null });
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
    console.error('Gagal koneksi database:', err.message);
    process.exit(1);
  });
