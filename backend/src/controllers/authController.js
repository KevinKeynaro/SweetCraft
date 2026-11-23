const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { ok, fail } = require('../utils/response');

const SALT_ROUNDS = 10;

// Register: role SELALU 'pembeli' — akun penjual hanya lewat seed.
// (Keamanan: kalau register bebas pilih role, siapa pun bisa jadi penjual via API.)
async function register(req, res) {
  // req.body sudah tervalidasi & dibersihkan oleh middleware validate()
  const { name, email, password, phone } = req.body;
  const hash = await bcrypt.hash(password, SALT_ROUNDS);

  // Subquery ambil id role 'pembeli' — tidak hardcode id agar tahan terhadap DB baru.
  const [result] = await pool.query(
    `INSERT INTO users (role_id, name, email, password, phone)
     VALUES ((SELECT id FROM roles WHERE name = 'pembeli'), ?, ?, ?, ?)`,
    [name, email, hash, phone ?? null]
  );

  const [rows] = await pool.query(
    'SELECT id, name, email, phone FROM users WHERE id = ?',
    [result.insertId]
  );
  return ok(res, 201, 'Registrasi berhasil', { user: rows[0] });
}

async function login(req, res) {
  // req.body sudah tervalidasi & dibersihkan oleh middleware validate()
  const { email, password } = req.body;
  const [rows] = await pool.query(
    `SELECT u.id, u.name, u.email, u.phone, u.password, r.name AS role
     FROM users u JOIN roles r ON r.id = u.role_id
     WHERE u.email = ?`,
    [email]
  );

  // Pesan sama untuk email tak terdaftar & password salah — jangan bocorkan mana yang keliru.
  if (rows.length === 0 || !(await bcrypt.compare(password, rows[0].password))) {
    return fail(res, 401, 'Email atau password salah');
  }

  const { id, name, phone, role } = rows[0];
  // Source: https://www.npmjs.com/package/jsonwebtoken — sign(payload, secretOrPrivateKey, options)
  const token = jwt.sign({ id, role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });

  return ok(res, 200, 'Login berhasil', {
    token,
    user: { id, name, email: rows[0].email, phone, role },
  });
}

async function me(req, res) {
  const [rows] = await pool.query(
    `SELECT u.id, u.name, u.email, u.phone, r.name AS role
     FROM users u JOIN roles r ON r.id = u.role_id
     WHERE u.id = ?`,
    [req.user.id]
  );
  if (rows.length === 0) {
    return fail(res, 404, 'User tidak ditemukan');
  }
  return ok(res, 200, 'Profil user', { user: rows[0] });
}

module.exports = { register, login, me };
