// Helper bersama suite pengujian.
// Prasyarat: MySQL aktif dan server API berjalan (npm run dev).
require('dotenv').config();
const mysql = require('mysql2/promise');

const BASE = process.env.API_URL || 'http://localhost:5000';

async function api(method, path, { body, token, form } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: form || (body ? JSON.stringify(body) : undefined),
  });
  return { status: res.status, json: await res.json().catch(() => null) };
}

async function login(email, password) {
  const res = await api('POST', '/api/auth/login', { body: { email, password } });
  if (res.status !== 200) throw new Error(`Login gagal untuk ${email}: ${res.status}`);
  return res.json.data.token;
}

function db() {
  return mysql.createPool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
  });
}

module.exports = { api, login, db, BASE };
