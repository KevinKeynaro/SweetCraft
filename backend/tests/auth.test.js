const test = require('node:test');
const assert = require('node:assert/strict');
const { api, db } = require('./helper');

const EMAIL = 'test.auth@example.com';

test('login akun seed → token & role benar', async () => {
  const penjual = await api('POST', '/api/auth/login', {
    body: { email: 'penjual@example.com', password: 'penjual123' },
  });
  assert.equal(penjual.status, 200);
  assert.equal(penjual.json.data.user.role, 'penjual');
  assert.ok(penjual.json.data.token);

  const pembeli = await api('POST', '/api/auth/login', {
    body: { email: 'pembeli@example.com', password: 'pembeli123' },
  });
  assert.equal(pembeli.status, 200);
  assert.equal(pembeli.json.data.user.role, 'pembeli');
});

test('login ditolak: password salah, email tak terdaftar, body kosong', async () => {
  assert.equal(
    (await api('POST', '/api/auth/login', {
      body: { email: 'penjual@example.com', password: 'salahbanget' },
    })).status,
    401
  );
  assert.equal(
    (await api('POST', '/api/auth/login', {
      body: { email: 'tidakada@example.com', password: 'salahbanget' },
    })).status,
    401
  );
  assert.equal((await api('POST', '/api/auth/login', { body: {} })).status, 400);
});

test('register: sukses, duplikat, validasi', async (t) => {
  const pool = db();
  await pool.query('DELETE FROM users WHERE email = ?', [EMAIL]); // sisa run sebelumnya
  t.after(async () => {
    await pool.query('DELETE FROM users WHERE email = ?', [EMAIL]);
    await pool.end();
  });

  const ok = await api('POST', '/api/auth/register', {
    body: { name: 'Test Auth', email: EMAIL, password: 'rahasia123' },
  });
  assert.equal(ok.status, 201);
  assert.equal(ok.json.data.user.email, EMAIL);

  const dup = await api('POST', '/api/auth/register', {
    body: { name: 'Test Auth', email: EMAIL, password: 'rahasia123' },
  });
  assert.equal(dup.status, 409);

  const invalid = await api('POST', '/api/auth/register', {
    body: { name: 'A', email: 'bukan-email', password: '1' },
  });
  assert.equal(invalid.status, 400);
  assert.ok(invalid.json.data.some((e) => e.field === 'email'));
});

test('me: butuh token valid', async () => {
  const login = await api('POST', '/api/auth/login', {
    body: { email: 'penjual@example.com', password: 'penjual123' },
  });
  const token = login.json.data.token;

  assert.equal((await api('GET', '/api/auth/me')).status, 401);
  assert.equal((await api('GET', '/api/auth/me', { token: 'garbage.token.here' })).status, 401);

  const me = await api('GET', '/api/auth/me', { token });
  assert.equal(me.status, 200);
  assert.equal(me.json.data.user.email, 'penjual@example.com');
});
