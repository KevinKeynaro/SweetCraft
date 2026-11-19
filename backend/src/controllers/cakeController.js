const pool = require('../config/db');
const cloudinary = require('../config/cloudinary');
const { ok, fail } = require('../utils/response');

// Kolom yang boleh diubah lewat PUT (whitelist — mencegah injeksi nama kolom)
const UPDATABLE = ['category_id', 'name', 'price', 'is_custom', 'stock', 'description', 'image_url'];

const SELECT_CAKE = `SELECT c.id, c.category_id, cat.name AS category, c.name, c.price,
  c.is_custom, c.stock, c.description, c.image_url, c.created_at, c.updated_at
  FROM cakes c JOIN categories cat ON cat.id = c.category_id`;

async function listCakes(req, res) {
  const [rows] = await pool.query(`${SELECT_CAKE} ORDER BY c.id DESC`);
  return ok(res, 200, 'Daftar menu kue', { cakes: rows });
}

async function getCake(req, res) {
  const [rows] = await pool.query(`${SELECT_CAKE} WHERE c.id = ?`, [Number(req.params.id)]);
  if (rows.length === 0) return fail(res, 404, 'Kue tidak ditemukan');
  return ok(res, 200, 'Detail kue', { cake: rows[0] });
}

async function createCake(req, res) {
  // req.body sudah tervalidasi oleh middleware validate()
  const {
    category_id,
    name,
    price,
    is_custom = false,
    stock = null,
    description = null,
    image_url = null,
  } = req.body;

  const [result] = await pool.query(
    `INSERT INTO cakes (category_id, name, price, is_custom, stock, description, image_url)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [category_id, name, price, is_custom, stock, description, image_url]
  );

  const [rows] = await pool.query(`${SELECT_CAKE} WHERE c.id = ?`, [result.insertId]);
  return ok(res, 201, 'Kue berhasil ditambahkan', { cake: rows[0] });
}

async function updateCake(req, res) {
  const id = Number(req.params.id);

  const [exists] = await pool.query('SELECT id FROM cakes WHERE id = ?', [id]);
  if (exists.length === 0) return fail(res, 404, 'Kue tidak ditemukan');

  // Hanya kolom yang dikirim (whitelist di atas) yang di-update
  const fields = UPDATABLE.filter((f) => req.body[f] !== undefined);
  const setClause = fields.map((f) => `${f} = ?`).join(', ');
  await pool.query(`UPDATE cakes SET ${setClause} WHERE id = ?`, [
    ...fields.map((f) => req.body[f]),
    id,
  ]);

  const [rows] = await pool.query(`${SELECT_CAKE} WHERE c.id = ?`, [id]);
  return ok(res, 200, 'Kue berhasil diubah', { cake: rows[0] });
}

async function deleteCake(req, res) {
  const id = Number(req.params.id);
  // Jika kue sudah dipakai di orders, FK RESTRICT membuat MySQL menolak →
  // ditangani error middleware sebagai 409.
  const [result] = await pool.query('DELETE FROM cakes WHERE id = ?', [id]);
  if (result.affectedRows === 0) return fail(res, 404, 'Kue tidak ditemukan');
  return ok(res, 200, 'Kue berhasil dihapus');
}

// Upload buffer ke Cloudinary via upload_stream (dokumentasi resmi: method ini
// mengembalikan stream, dibungkus Promise agar bisa di-await + .end(buffer)).
// Source: https://cloudinary.com/documentation/node_image_and_video_upload#the_code_upload_stream_code_method
function uploadBuffer(buffer, options) {
  return new Promise((resolve, reject) => {
    cloudinary.uploader
      .upload_stream(options, (error, result) => (error ? reject(error) : resolve(result)))
      .end(buffer);
  });
}

async function uploadCakeImage(req, res) {
  const id = Number(req.params.id);

  if (!req.file) {
    return fail(res, 400, 'File gambar wajib dikirim pada field "image"');
  }

  const [exists] = await pool.query('SELECT id FROM cakes WHERE id = ?', [id]);
  if (exists.length === 0) return fail(res, 404, 'Kue tidak ditemukan');

  let result;
  try {
    result = await uploadBuffer(req.file.buffer, {
      folder: 'sweetcraft/cakes',
      resource_type: 'image',
    });
  } catch (err) {
    console.error('Cloudinary upload gagal:', err.message || err);
    return fail(res, 502, 'Gagal mengunggah gambar ke Cloudinary');
  }

  // Yang disimpan ke DB hanya URL HTTPS (secure_url)
  await pool.query('UPDATE cakes SET image_url = ? WHERE id = ?', [result.secure_url, id]);

  const [rows] = await pool.query(`${SELECT_CAKE} WHERE c.id = ?`, [id]);
  return ok(res, 200, 'Foto menu berhasil diunggah', { cake: rows[0] });
}

// Dipakai form Flutter untuk dropdown kategori saat menambah/mengubah menu
async function listCategories(req, res) {
  const [rows] = await pool.query('SELECT id, name FROM categories ORDER BY name');
  return ok(res, 200, 'Daftar kategori', { categories: rows });
}

module.exports = {
  listCakes, getCake, createCake, updateCake, deleteCake, uploadCakeImage, listCategories,
};
