// ============================================================================
// Seed akun pengujian SweetCraft (Opsi B)
// Password di-hash bcrypt SAAT RUNTIME — meniru alur register asli:
//   bcrypt.hash(plaintext) -> simpan hash ke DB
//   (login nanti: bcrypt.compare(plaintext, hash dari DB))
//
// Jalankan dari folder backend/:  npm run seed
// Prasyarat: schema.sql sudah dieksekusi (tabel users & roles ada).
//
// Sumber pola API: https://www.npmjs.com/package/bcrypt#usage
// ("We recommend using async API if you use bcrypt on a server" — hash
//  CPU-intensive; versi async memakai thread pool, tidak memblokir event loop)
// ============================================================================

require('dotenv').config();
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');

const SALT_ROUNDS = 10;

// Akun pengujian wajib per soal ujian no. 12 (dev only — bukan kredensial produksi)
const TEST_ACCOUNTS = [
  { role: 'penjual', name: 'Penjual SweetCraft', email: 'penjual@example.com', password: 'penjual123', phone: '081200000001' },
  { role: 'pembeli', name: 'Pembeli SweetCraft', email: 'pembeli@example.com', password: 'pembeli123', phone: '081200000002' },
];

async function seed() {
  const pool = mysql.createPool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  try {
    for (const acc of TEST_ACCOUNTS) {
      // 1. Hash password di aplikasi (bukan di database)
      const passwordHash = await bcrypt.hash(acc.password, SALT_ROUNDS);

      // 2. Cari role_id dari tabel roles (seeded oleh schema.sql)
      const [roles] = await pool.query(
        'SELECT id FROM roles WHERE name = ?',
        [acc.role]
      );
      if (roles.length === 0) {
        throw new Error(`Role '${acc.role}' tidak ditemukan — jalankan schema.sql dulu.`);
      }

      // 3. Insert idempotent: script aman dijalankan berulang
      await pool.query(
        `INSERT INTO users (role_id, name, email, password, phone)
         VALUES (?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
           name = VALUES(name), password = VALUES(password), phone = VALUES(phone)`,
        [roles[0].id, acc.name, acc.email, passwordHash, acc.phone]
      );

      console.log(`✔ ${acc.email} (role: ${acc.role}, password: ${acc.password})`);
    }
    console.log('Seed selesai.');
  } finally {
    await pool.end();
  }
}

seed().catch((err) => {
  console.error('Seed gagal:', err.message);
  process.exit(1);
});
