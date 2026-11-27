const pool = require('../config/db');
const { ok, fail } = require('../utils/response');
const { uploadImageBuffer } = require('../utils/uploadImage');

const SELECT_ORDER = `SELECT o.id, o.user_id, u.name AS buyer_name, o.cake_id, c.name AS cake_name,
  o.order_type, o.custom_image_url, o.custom_description, o.decoration_note,
  o.agreed_price, o.pickup_date, o.status, o.created_at, o.updated_at
  FROM orders o
  JOIN users u ON u.id = o.user_id
  LEFT JOIN cakes c ON c.id = o.cake_id`;

// Transisi status yang boleh dilakukan PENJUAL.
// ready-stock: pending -> approved -> processing -> ready -> completed
// custom:      pending -> processing -> ready -> completed
// Pesanan custom tidak lagi disetujui penjual; pembeli yang memutuskan
// approved/rejected setelah penjual menetapkan harga final.
//
// Catatan: UI penjual hanya menampilkan "Terima & Proses" (pending -> processing)
// untuk ready-stock, jadi pending -> approved sengaja dipertahankan sebagai
// jalur API untuk konfirmasi eksplisit di masa depan (mis. pembayaran/DP).
const SELLER_TRANSITIONS = {
  pending: ['approved', 'processing', 'rejected'],
  approved: ['processing'],
  processing: ['ready'],
  ready: ['completed'],
  completed: [],
  cancelled: [],
  rejected: [],
};

// Pembeli hanya boleh membatalkan ready-stock dalam 60 menit sejak dibuat.
// Jendela waktu dievaluasi di SQL (INTERVAL 60 MINUTE) agar memakai jam DB.

async function findOrder(id) {
  const [rows] = await pool.query(`${SELECT_ORDER} WHERE o.id = ?`, [id]);
  return rows[0];
}

// Kembalikan stok ready-stock tepat satu kali saat pesanan dibatalkan/ditolak.
// Stok NULL berarti tanpa batas, jadi tidak perlu dikembalikan.
async function restoreStock(conn, order) {
  if (order.order_type !== 'ready_stock' || order.cake_id == null) return;
  await conn.query(
    'UPDATE cakes SET stock = stock + 1 WHERE id = ? AND stock IS NOT NULL',
    [order.cake_id]
  );
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

// Penjual memperbarui status produksi. Row order dikunci agar transisi dan
// pengembalian stok terjadi atomik. Sumber: MySQL 8.4 locking reads.
// https://dev.mysql.com/doc/refman/8.4/en/innodb-locking-reads.html
async function updateStatus(req, res) {
  const { status } = req.body;
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [rows] = await conn.query(
      'SELECT id, user_id, cake_id, order_type, status FROM orders WHERE id = ? FOR UPDATE',
      [Number(req.params.id)]
    );
    const order = rows[0];
    if (!order) {
      await conn.rollback();
      return fail(res, 404, 'Pesanan tidak ditemukan');
    }

    // Pesanan custom disetujui pembeli setelah harga final ditetapkan penjual.
    if (order.order_type === 'custom' && status === 'approved') {
      await conn.rollback();
      return fail(res, 400, 'Pesanan custom disetujui oleh pembeli, bukan penjual');
    }
    // Produksi custom baru boleh dimulai setelah pembeli menyetujui harga.
    if (order.order_type === 'custom' && order.status === 'pending' && status === 'processing') {
      await conn.rollback();
      return fail(res, 400, 'Menunggu keputusan harga dari pembeli');
    }

    if (!SELLER_TRANSITIONS[order.status].includes(status)) {
      await conn.rollback();
      return fail(res, 400, `Tidak bisa mengubah status dari '${order.status}' ke '${status}'`);
    }

    await conn.query('UPDATE orders SET status = ? WHERE id = ?', [status, order.id]);
    // Pesanan ready-stock yang ditolak penjual wajib mengembalikan stok.
    if (status === 'rejected') await restoreStock(conn, order);

    await conn.commit();
    return ok(res, 200, 'Status pesanan diperbarui', { order: await findOrder(order.id) });
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}

// Pembeli memutuskan hasil pre-order custom: menerima atau menolak harga final.
async function updateBuyerDecision(req, res) {
  const { status } = req.body; // 'approved' | 'rejected'
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [rows] = await conn.query(
      'SELECT id, user_id, cake_id, order_type, status, agreed_price FROM orders WHERE id = ? FOR UPDATE',
      [Number(req.params.id)]
    );
    const order = rows[0];
    if (!order) {
      await conn.rollback();
      return fail(res, 404, 'Pesanan tidak ditemukan');
    }
    if (order.user_id !== req.user.id) {
      await conn.rollback();
      return fail(res, 403, 'Tidak boleh mengubah pesanan milik orang lain');
    }
    if (order.order_type !== 'custom') {
      await conn.rollback();
      return fail(res, 400, 'Keputusan harga hanya untuk pesanan custom');
    }
    if (order.status !== 'pending') {
      await conn.rollback();
      return fail(res, 400, `Pesanan berstatus '${order.status}' tidak bisa diputuskan`);
    }
    if (status === 'approved' && order.agreed_price == null) {
      await conn.rollback();
      return fail(res, 400, 'Harga final belum ditetapkan penjual');
    }

    await conn.query('UPDATE orders SET status = ? WHERE id = ?', [status, order.id]);
    await conn.commit();
    return ok(res, 200, 'Keputusan pesanan disimpan', { order: await findOrder(order.id) });
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}

// Pembeli membatalkan pesanan sendiri. Ready-stock dibatasi 60 menit dan
// stoknya dikembalikan; custom hanya boleh dibatalkan selama masih pending.
async function cancelOrder(req, res) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [rows] = await conn.query(
      `SELECT id, user_id, cake_id, order_type, status, created_at,
              (created_at >= (NOW() - INTERVAL 60 MINUTE)) AS within_cancel_window
       FROM orders WHERE id = ? FOR UPDATE`,
      [Number(req.params.id)]
    );
    const order = rows[0];
    if (!order) {
      await conn.rollback();
      return fail(res, 404, 'Pesanan tidak ditemukan');
    }
    if (order.user_id !== req.user.id) {
      await conn.rollback();
      return fail(res, 403, 'Tidak boleh membatalkan pesanan milik orang lain');
    }

    if (order.order_type === 'custom') {
      if (order.status !== 'pending') {
        await conn.rollback();
        return fail(res, 400, 'Pre-order yang sudah disetujui tidak bisa dibatalkan');
      }
    } else {
      if (order.status !== 'pending' && order.status !== 'approved') {
        await conn.rollback();
        return fail(res, 400, `Pesanan berstatus '${order.status}' tidak bisa dibatalkan`);
      }
      if (!order.within_cancel_window) {
        await conn.rollback();
        return fail(res, 400, 'Batas waktu pembatalan 60 menit sudah lewat');
      }
    }

    await conn.query("UPDATE orders SET status = 'cancelled' WHERE id = ?", [order.id]);
    await restoreStock(conn, order);

    await conn.commit();
    return ok(res, 200, 'Pesanan dibatalkan', { order: await findOrder(order.id) });
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}

async function updatePrice(req, res) {
  const order = await findOrder(Number(req.params.id));
  if (!order) return fail(res, 404, 'Pesanan tidak ditemukan');
  if (order.order_type !== 'custom') {
    return fail(res, 400, 'Harga final hanya untuk pesanan custom');
  }
  if (order.status !== 'pending') {
    return fail(res, 400, 'Harga final hanya bisa diubah selama pesanan menunggu');
  }

  // Guard status di query: harga terkunci begitu pembeli memutuskan.
  const [result] = await pool.query(
    "UPDATE orders SET agreed_price = ? WHERE id = ? AND status = 'pending'",
    [req.body.agreed_price, order.id]
  );
  if (result.affectedRows === 0) {
    return fail(res, 400, 'Harga final hanya bisa diubah selama pesanan menunggu');
  }
  return ok(res, 200, 'Harga final disimpan', { order: await findOrder(order.id) });
}

async function uploadCustomOrderImage(req, res) {
  if (!req.file) {
    return fail(res, 400, 'File gambar wajib dikirim pada field "image"');
  }

  let result;
  try {
    result = await uploadImageBuffer(req.file.buffer, 'sweetcraft/orders');
  } catch (err) {
    console.error('Cloudinary upload gagal:', err.message || err);
    return fail(res, 502, 'Gagal mengunggah gambar ke Cloudinary');
  }

  return ok(res, 200, 'Foto referensi berhasil diunggah', {
    image_url: result.secure_url,
  });
}

module.exports = {
  createOrder,
  listOrders,
  getOrder,
  updateStatus,
  updateBuyerDecision,
  cancelOrder,
  updatePrice,
  uploadCustomOrderImage,
};
