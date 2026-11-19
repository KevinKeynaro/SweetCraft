const { before, after, test } = require('node:test');
const assert = require('node:assert/strict');
const { api, login, db } = require('./helper');

let tp;
let tb;
let pool;
let cakeId;

before(async () => {
  tp = await login('penjual@example.com', 'penjual123');
  tb = await login('pembeli@example.com', 'pembeli123');
  pool = db();

  const res = await api('POST', '/api/cakes', {
    token: tp,
    body: { category_id: 1, name: 'Kue Uji Suite', price: 75000, stock: 10 },
  });
  assert.equal(res.status, 201);
  cakeId = res.json.data.cake.id;
});

after(async () => {
  if (cakeId) await pool.query('DELETE FROM cakes WHERE id = ?', [cakeId]);
  await pool.end();
});

test('katalog publik & daftar kategori', async () => {
  assert.equal((await api('GET', '/api/cakes')).status, 200);

  const cats = await api('GET', '/api/categories');
  assert.equal(cats.status, 200);
  assert.equal(cats.json.data.categories.length, 4);
});

test('guard role: tanpa token 401, pembeli 403', async () => {
  assert.equal((await api('POST', '/api/cakes', { body: { name: 'x' } })).status, 401);
  assert.equal(
    (await api('POST', '/api/cakes', {
      token: tb, body: { category_id: 1, name: 'Kue', price: 1000 },
    })).status,
    403
  );
});

test('validasi create', async () => {
  const invalid = await api('POST', '/api/cakes', {
    token: tp, body: { name: 'X', price: -5 },
  });
  assert.equal(invalid.status, 400);
  const fields = invalid.json.data.map((e) => e.field);
  assert.ok(fields.includes('name'));
  assert.ok(fields.includes('price'));
  assert.ok(fields.includes('category_id'));

  assert.equal(
    (await api('POST', '/api/cakes', {
      token: tp, body: { category_id: 9999, name: 'Kue Hantu', price: 1000 },
    })).status,
    400
  );
});

test('detail: 200, harga number, 404, 400', async () => {
  const detail = await api('GET', `/api/cakes/${cakeId}`);
  assert.equal(detail.status, 200);
  assert.equal(typeof detail.json.data.cake.price, 'number');

  assert.equal((await api('GET', '/api/cakes/9999')).status, 404);
  assert.equal((await api('GET', '/api/cakes/abc')).status, 400);
});

test('update parsial', async () => {
  assert.equal(
    (await api('PUT', `/api/cakes/${cakeId}`, { token: tb, body: { price: 1 } })).status,
    403
  );

  const ok = await api('PUT', `/api/cakes/${cakeId}`, { token: tp, body: { price: 80000 } });
  assert.equal(ok.status, 200);
  assert.equal(ok.json.data.cake.price, 80000);
  assert.equal(ok.json.data.cake.name, 'Kue Uji Suite');

  assert.equal(
    (await api('PUT', `/api/cakes/${cakeId}`, { token: tp, body: {} })).status,
    400
  );
  assert.equal(
    (await api('PUT', '/api/cakes/9999', { token: tp, body: { price: 1 } })).status,
    404
  );
});

test('hapus: guard, FK restrict 409, lalu 200', async () => {
  assert.equal((await api('DELETE', `/api/cakes/${cakeId}`)).status, 401);
  assert.equal((await api('DELETE', `/api/cakes/${cakeId}`, { token: tb })).status, 403);
  assert.equal((await api('DELETE', '/api/cakes/9999', { token: tp })).status, 404);

  const [order] = await pool.query(
    "INSERT INTO orders (user_id, cake_id, order_type, agreed_price) VALUES (2, ?, 'ready_stock', 80000)",
    [cakeId]
  );
  assert.equal((await api('DELETE', `/api/cakes/${cakeId}`, { token: tp })).status, 409);
  await pool.query('DELETE FROM orders WHERE id = ?', [order.insertId]);

  const id = cakeId;
  assert.equal((await api('DELETE', `/api/cakes/${id}`, { token: tp })).status, 200);
  assert.equal((await api('GET', `/api/cakes/${id}`)).status, 404);
  cakeId = null;
});
