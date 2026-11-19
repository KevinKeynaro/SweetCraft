const { before, after, test } = require('node:test');
const assert = require('node:assert/strict');
const { api, login, db } = require('./helper');

const TEMP_EMAIL = 'test.order@example.com';
let tp;
let tb;
let pool;
let cakeId;
const orderIds = [];

before(async () => {
  tp = await login('penjual@example.com', 'penjual123');
  tb = await login('pembeli@example.com', 'pembeli123');
  pool = db();

  const res = await api('POST', '/api/cakes', {
    token: tp,
    body: { category_id: 1, name: 'Tart Uji Order', price: 75000, stock: 2 },
  });
  assert.equal(res.status, 201);
  cakeId = res.json.data.cake.id;
});

after(async () => {
  for (const id of orderIds) await pool.query('DELETE FROM orders WHERE id = ?', [id]);
  if (cakeId) await pool.query('DELETE FROM cakes WHERE id = ?', [cakeId]);
  await pool.query('DELETE FROM users WHERE email = ?', [TEMP_EMAIL]);
  await pool.end();
});

test('guard: tanpa token 401, penjual tidak bisa memesan 403', async () => {
  assert.equal(
    (await api('POST', '/api/orders', {
      body: { order_type: 'custom', custom_description: 'xxxxx' },
    })).status,
    401
  );
  assert.equal(
    (await api('POST', '/api/orders', {
      token: tp, body: { order_type: 'custom', custom_description: 'xxxxx' },
    })).status,
    403
  );
});

test('ready-stock: harga dari kue, stok berkurang, stok habis 400', async () => {
  const o1 = await api('POST', '/api/orders', {
    token: tb,
    body: { order_type: 'ready_stock', cake_id: cakeId, decoration_note: 'Selamat ulang tahun' },
  });
  assert.equal(o1.status, 201);
  orderIds.push(o1.json.data.order.id);
  assert.equal(o1.json.data.order.agreed_price, 75000);
  assert.equal(o1.json.data.order.status, 'pending');
  assert.equal(o1.json.data.order.cake_name, 'Tart Uji Order');

  assert.equal((await api('GET', `/api/cakes/${cakeId}`)).json.data.cake.stock, 1);

  const o2 = await api('POST', '/api/orders', {
    token: tb, body: { order_type: 'ready_stock', cake_id: cakeId },
  });
  assert.equal(o2.status, 201);
  orderIds.push(o2.json.data.order.id);
  assert.equal((await api('GET', `/api/cakes/${cakeId}`)).json.data.cake.stock, 0);

  const habis = await api('POST', '/api/orders', {
    token: tb, body: { order_type: 'ready_stock', cake_id: cakeId },
  });
  assert.equal(habis.status, 400);
});

test('validasi ready-stock: cake_id wajib & harus ada', async () => {
  assert.equal(
    (await api('POST', '/api/orders', { token: tb, body: { order_type: 'ready_stock' } })).status,
    400
  );
  assert.equal(
    (await api('POST', '/api/orders', {
      token: tb, body: { order_type: 'ready_stock', cake_id: 9999 },
    })).status,
    400
  );
});

test('custom: tanpa cake & harga, wajib deskripsi', async () => {
  const res = await api('POST', '/api/orders', {
    token: tb,
    body: {
      order_type: 'custom',
      custom_description: 'Kue ulang tahun tema bunga, rasa coklat',
      decoration_note: 'Tulisan: Happy Birthday',
      pickup_date: '2026-12-01T10:00',
    },
  });
  assert.equal(res.status, 201);
  orderIds.push(res.json.data.order.id);
  assert.equal(res.json.data.order.cake_id, null);
  assert.equal(res.json.data.order.agreed_price, null);
  assert.ok(res.json.data.order.pickup_date.startsWith('2026-12-01'));

  assert.equal(
    (await api('POST', '/api/orders', { token: tb, body: { order_type: 'custom' } })).status,
    400
  );
});

test('daftar: filter role & status', async () => {
  const pembeli = await api('GET', '/api/orders', { token: tb });
  assert.equal(pembeli.status, 200);
  assert.ok(pembeli.json.data.orders.every((o) => o.user_id === 2));
  assert.ok(orderIds.every((id) => pembeli.json.data.orders.some((o) => o.id === id)));

  const penjual = await api('GET', '/api/orders', { token: tp });
  assert.ok(orderIds.every((id) => penjual.json.data.orders.some((o) => o.id === id)));

  const pending = await api('GET', '/api/orders?status=pending', { token: tb });
  assert.ok(orderIds.every((id) => pending.json.data.orders.some((o) => o.id === id)));

  const completed = await api('GET', '/api/orders?status=completed', { token: tb });
  assert.equal(completed.status, 200);
  assert.ok(orderIds.every((id) => !completed.json.data.orders.some((o) => o.id === id)));

  assert.equal((await api('GET', '/api/orders?status=ngawur', { token: tb })).status, 400);
});

test('detail & akses: pemilik, penjual, pembeli lain 403', async () => {
  const id = orderIds[0];
  assert.equal((await api('GET', `/api/orders/${id}`, { token: tb })).status, 200);
  assert.equal((await api('GET', `/api/orders/${id}`, { token: tp })).status, 200);
  assert.equal((await api('GET', '/api/orders/abc', { token: tb })).status, 400);
  assert.equal((await api('GET', '/api/orders/9999', { token: tb })).status, 404);

  const reg = await api('POST', '/api/auth/register', {
    body: { name: 'Test Order', email: TEMP_EMAIL, password: 'rahasia123' },
  });
  assert.equal(reg.status, 201);

  const other = await api('POST', '/api/auth/login', {
    body: { email: TEMP_EMAIL, password: 'rahasia123' },
  });
  const tb2 = other.json.data.token;
  assert.equal((await api('GET', `/api/orders/${id}`, { token: tb2 })).status, 403);
  assert.equal((await api('GET', '/api/orders', { token: tb2 })).json.data.orders.length, 0);
});

test('transisi status dibatasi', async () => {
  const id = orderIds[0];
  assert.equal(
    (await api('PUT', `/api/orders/${id}/status`, {
      token: tb, body: { status: 'processing' },
    })).status,
    403
  );

  assert.equal(
    (await api('PUT', `/api/orders/${id}/status`, {
      token: tp, body: { status: 'processing' },
    })).status,
    200
  );
  assert.equal(
    (await api('PUT', `/api/orders/${id}/status`, {
      token: tp, body: { status: 'completed' },
    })).status,
    400
  );
  assert.equal(
    (await api('PUT', `/api/orders/${id}/status`, {
      token: tp, body: { status: 'ready' },
    })).status,
    200
  );

  const done = await api('PUT', `/api/orders/${id}/status`, {
    token: tp, body: { status: 'completed' },
  });
  assert.equal(done.status, 200);
  assert.equal(done.json.data.order.status, 'completed');

  assert.equal(
    (await api('PUT', `/api/orders/${id}/status`, {
      token: tp, body: { status: 'approved' },
    })).status,
    400
  );
  assert.equal(
    (await api('PUT', `/api/orders/${id}/status`, {
      token: tp, body: { status: 'ngawur' },
    })).status,
    400
  );
});

test('harga final hanya untuk pesanan custom', async () => {
  const custom = orderIds[2];
  const ready = orderIds[1];

  assert.equal(
    (await api('PUT', `/api/orders/${custom}/price`, {
      token: tb, body: { agreed_price: 100000 },
    })).status,
    403
  );

  const ok = await api('PUT', `/api/orders/${custom}/price`, {
    token: tp, body: { agreed_price: 150000 },
  });
  assert.equal(ok.status, 200);
  assert.equal(ok.json.data.order.agreed_price, 150000);

  assert.equal(
    (await api('PUT', `/api/orders/${ready}/price`, {
      token: tp, body: { agreed_price: 1 },
    })).status,
    400
  );
  assert.equal(
    (await api('PUT', `/api/orders/${custom}/price`, {
      token: tp, body: { agreed_price: -5 },
    })).status,
    400
  );
});
