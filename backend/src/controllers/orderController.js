const pool = require('../config/db');
const { ok, fail } = require('../utils/response');

const SELECT_ORDER = `SELECT o.id, o.user_id, u.name AS buyer_name, o.cake_id, c.name AS cake_name,
  o.order_type, o.custom_image_url, o.custom_description, o.decoration_note,
  o.agreed_price, o.pickup_date, o.status, o.created_at, o.updated_at
  FROM orders o
  JOIN users u ON u.id = o.user_id
  LEFT JOIN cakes c ON c.id = o.cake_id`;

// Transisi status yang diizinkan — mengikuti laporan §5:
// ready-stock: pending -> processing -> ready -> completed
// custom:      pending -> approved (harga final) -> processing -> ready -> completed
const TRANSITIONS = {
  pending: ['approved', 'processing', 'rejected'],
  approved: ['processing'],
  processing: ['ready'],
  ready: ['completed'],
  completed: [],
  cancelled: [],
  rejected: [],
};

async function findOrder(id) {
  const [rows] = await pool.query(`${SELECT_ORDER} WHERE o.id = ?`, [id]);
  return rows[0];
}

async function createOrder(req, res) {
  const {
    order_type, cake_id, custom_image_url, custom_description, decoration_note, pickup_date,
  } = req.body;

  if (order_type === 'ready_stock') {
    // Transaksi: cek stok + kurangi + insert harus atomik.
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      const [cakes] = await conn.query(
        'SELECT id, price, stock FROM cakes WHERE id = ? FOR UPDATE',
        [cake_id]
      );
      if (cakes.length === 0) {
        await conn.rollback();
        return fail(res, 400, 'Kue tidak ditemukan');
      }
      const cake = cakes[0];
      if (cake.stock !== null && cake.stock < 1) {
        await conn.rollback();
        return fail(res, 400, 'Stok kue habis');
      }
      if (cake.stock !== null) {
        await conn.query('UPDATE cakes SET stock = stock - 1 WHERE id = ?', [cake_id]);
      }
      const [result] = await conn.query(
        `INSERT INTO orders (user_id, cake_id, order_type, decoration_note, agreed_price, pickup_date)
         VALUES (?, ?, 'ready_stock', ?, ?, ?)`,
        [req.user.id, cake_id, decoration_note ?? null, cake.price, pickup_date ?? null]
      );
      await conn.commit();
      return ok(res, 201, 'Pesanan berhasil dibuat', { order: await findOrder(result.insertId) });
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  }

  const [result] = await pool.query(
    `INSERT INTO orders (user_id, order_type, custom_image_url, custom_description, decoration_note, pickup_date)
     VALUES (?, 'custom', ?, ?, ?, ?)`,
    [req.user.id, custom_image_url ?? null, custom_description, decoration_note ?? null, pickup_date ?? null]
  );
  return ok(res, 201, 'Pesanan custom berhasil dibuat', { order: await findOrder(result.insertId) });
}

async function listOrders(req, res) {
  const { status } = req.query;
  const conditions = [];
  const params = [];

  // Pembeli hanya melihat pesanannya sendiri; penjual melihat semua.
  if (req.user.role !== 'penjual') {
    conditions.push('o.user_id = ?');
    params.push(req.user.id);
  }
  if (status) {
    conditions.push('o.status = ?');
    params.push(status);
  }

  const where = conditions.length ? ` WHERE ${conditions.join(' AND ')}` : '';
  const [rows] = await pool.query(`${SELECT_ORDER}${where} ORDER BY o.id DESC`, params);
  return ok(res, 200, 'Daftar pesanan', { orders: rows });
}

async function getOrder(req, res) {
  const order = await findOrder(Number(req.params.id));
  if (!order) return fail(res, 404, 'Pesanan tidak ditemukan');
  if (req.user.role !== 'penjual' && order.user_id !== req.user.id) {
    return fail(res, 403, 'Tidak boleh melihat pesanan milik orang lain');
  }
  return ok(res, 200, 'Detail pesanan', { order });
}

async function updateStatus(req, res) {
  const order = await findOrder(Number(req.params.id));
  if (!order) return fail(res, 404, 'Pesanan tidak ditemukan');

  const { status } = req.body;
  if (!TRANSITIONS[order.status].includes(status)) {
    return fail(res, 400, `Tidak bisa mengubah status dari '${order.status}' ke '${status}'`);
  }

  await pool.query('UPDATE orders SET status = ? WHERE id = ?', [status, order.id]);
  return ok(res, 200, 'Status pesanan diperbarui', { order: await findOrder(order.id) });
}

async function updatePrice(req, res) {
  const order = await findOrder(Number(req.params.id));
  if (!order) return fail(res, 404, 'Pesanan tidak ditemukan');
  if (order.order_type !== 'custom') {
    return fail(res, 400, 'Harga final hanya untuk pesanan custom');
  }

  await pool.query('UPDATE orders SET agreed_price = ? WHERE id = ?', [
    req.body.agreed_price,
    order.id,
  ]);
  return ok(res, 200, 'Harga final disimpan', { order: await findOrder(order.id) });
}

module.exports = { createOrder, listOrders, getOrder, updateStatus, updatePrice };
