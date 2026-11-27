const { before, after, test } = require('node:test');
const assert = require('node:assert/strict');
const cloudinary = require('cloudinary').v2;
const { api, login, db } = require('./helper');

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const PNG_1PX = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  'base64'
);

const canUpload =
  Boolean(process.env.CLOUDINARY_CLOUD_NAME) &&
  !process.env.CLOUDINARY_CLOUD_NAME.startsWith('mock');

let tp;
let tb;
let pool;
let cakeId;
let imageUrl;
let extraImageUrl;

const imageForm = (buffer, type, filename) => {
  const fd = new FormData();
  fd.append('image', new Blob([buffer], { type }), filename);
  return fd;
};

before(async () => {
  tp = await login('penjual@example.com', 'penjual123');
  tb = await login('pembeli@example.com', 'pembeli123');
  pool = db();

  const res = await api('POST', '/api/cakes', {
    token: tp, body: { category_id: 1, name: 'Kue Uji Upload', price: 10000 },
  });
  assert.equal(res.status, 201);
  cakeId = res.json.data.cake.id;
});

after(async () => {
  for (const url of [imageUrl, extraImageUrl]) {
    if (!url) continue;
    const m = url.match(/\/upload\/(?:v\d+\/)?(.+)\.[a-z0-9]+$/i);
    if (m) await cloudinary.uploader.destroy(m[1], { invalidate: true });
  }
  if (cakeId) await pool.query('DELETE FROM cakes WHERE id = ?', [cakeId]);
  await pool.end();
});

test('guard & validasi file', async () => {
  const url = `/api/cakes/${cakeId}/image`;

  assert.equal(
    (await api('POST', url, { form: imageForm(PNG_1PX, 'image/png', 'a.png') })).status,
    401
  );
  assert.equal(
    (await api('POST', url, { token: tb, form: imageForm(PNG_1PX, 'image/png', 'a.png') })).status,
    403
  );
  assert.equal((await api('POST', url, { token: tp, form: new FormData() })).status, 400);
  assert.equal(
    (await api('POST', url, {
      token: tp, form: imageForm(Buffer.from('x'), 'text/plain', 'a.txt'),
    })).status,
    400
  );
  // Tipe gambar di luar JPG/PNG/WEBP tidak boleh ditolak oleh fileFilter.
  // 502 diterima saat kredensial Cloudinary belum tersedia.
  const gifRes = await api('POST', url, {
    token: tp, form: imageForm(PNG_1PX, 'image/gif', 'a.gif'),
  });
  assert.ok(
    [200, 502].includes(gifRes.status),
    `image/gif ditolak fileFilter (status ${gifRes.status})`
  );
  if (gifRes.status === 200) {
    extraImageUrl = gifRes.json?.data?.cake?.image_url;
  }
  assert.equal(
    (await api('POST', url, {
      token: tp, form: imageForm(Buffer.alloc(3 * 1024 * 1024, 1), 'image/png', 'b.png'),
    })).status,
    413
  );
  assert.equal(
    (await api('POST', '/api/cakes/abc/image', {
      token: tp, form: imageForm(PNG_1PX, 'image/png', 'a.png'),
    })).status,
    400
  );
  assert.equal(
    (await api('POST', '/api/cakes/9999/image', {
      token: tp, form: imageForm(PNG_1PX, 'image/png', 'a.png'),
    })).status,
    404
  );
});

test(
  'upload ke Cloudinary & URL bisa diakses',
  { skip: !canUpload && 'kredensial Cloudinary belum diisi' },
  async () => {
    const res = await api('POST', `/api/cakes/${cakeId}/image`, {
      token: tp, form: imageForm(PNG_1PX, 'image/png', 'kue.png'),
    });
    assert.equal(res.status, 200);

    imageUrl = res.json.data.cake.image_url;
    assert.ok(imageUrl.startsWith('https://res.cloudinary.com/'));

    const head = await fetch(imageUrl, { method: 'HEAD' });
    assert.equal(head.status, 200);

    const detail = await api('GET', `/api/cakes/${cakeId}`);
    assert.equal(detail.json.data.cake.image_url, imageUrl);
  }
);

test('upload foto referensi custom order: guard & upload ke Cloudinary', async () => {
  const url = '/api/orders/image';

  assert.equal(
    (await api('POST', url, { form: imageForm(PNG_1PX, 'image/png', 'ref.png') })).status,
    401
  );
  assert.equal(
    (await api('POST', url, {
      token: tp, form: imageForm(PNG_1PX, 'image/png', 'ref.png'),
    })).status,
    403
  );
  assert.equal((await api('POST', url, { token: tb, form: new FormData() })).status, 400);
  assert.equal(
    (await api('POST', url, {
      token: tb, form: imageForm(Buffer.from('x'), 'text/plain', 'ref.txt'),
    })).status,
    400
  );

  let uploadedOrderUrl;
  try {
    const res = await api('POST', url, {
      token: tb, form: imageForm(PNG_1PX, 'image/png', 'ref.png'),
    });
    if (!canUpload) {
      assert.equal(res.status, 502);
      return;
    }
    assert.equal(res.status, 200);
    uploadedOrderUrl = res.json?.data?.image_url;
    assert.ok(uploadedOrderUrl && uploadedOrderUrl.startsWith('https://res.cloudinary.com/'));

    const head = await fetch(uploadedOrderUrl, { method: 'HEAD' });
    assert.equal(head.status, 200);
  } finally {
    if (uploadedOrderUrl) {
      const m = uploadedOrderUrl.match(/\/upload\/(?:v\d+\/)?(.+)\.[a-z0-9]+$/i);
      if (m) await cloudinary.uploader.destroy(m[1], { invalidate: true });
    }
  }
});
