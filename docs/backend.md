# Laporan Pengerjaan Backend — SweetCraft

Dokumen ini mencatat seluruh pekerjaan backend (REST API Express.js + MySQL) dari awal
hingga akhir: apa yang dibuat, keputusan yang diambil, bug yang ditemukan, dan bukti
verifikasi. Tanggal pengerjaan: 18–19 November 2026.

Acuan proyek: `docs/laporan_proyek_sweetcraft.md`, `docs/techstack.md`,
`docs/soal_asas_koke.md`, `backend/schema.sql`, `docs/AGENTS.md`.

---

## 1. Ringkasan

Backend SweetCraft sudah **selesai dan teruji live** untuk:

- [x] Skema database MySQL (5 tabel, relasi, seed)
- [x] Seed akun uji dengan password di-hash bcrypt di layer aplikasi
- [x] Autentikasi & otorisasi (register, login, JWT, role penjual/pembeli)
- [x] CRUD menu kue + daftar kategori
- [x] Upload foto menu ke Cloudinary
- [x] Pesanan ready-stock & custom pre-order, termasuk update status dan harga final

Yang belum dikerjakan: **klien Flutter** (lihat §9).

---

## 2. Lingkungan & Stack

| Komponen | Versi/Sumber |
|---|---|
| Node.js | v24.20.0 |
| Express | 5.3 |
| MySQL | 8.4.3 (Laragon, port 3306, database `sweetcraft_db`) |
| mysql2 | 3.24.6 |
| bcrypt | 6.x (salt rounds 10) |
| jsonwebtoken | 9.0.3 (expiresIn `1d`) |
| zod | 4.6 |
| multer | 2.5.0 (memoryStorage) |
| cloudinary | 2.11.0 |

Akun uji (dari `npm run seed`):

| Email | Password | Role |
|---|---|---|
| `penjual@example.com` | `penjual123` | penjual |
| `pembeli@example.com` | `pembeli123` | pembeli |

---

## 3. Kronologi Pengerjaan

### Fase 0 — Pembersihan awal

- [x] Menghapus sisa proyek lama ("Novelist") dari README, `docs/techstack.md`, `backend/.env`, `.env.example`
- [x] Menyeragamkan role menjadi 2 saja: **Penjual** dan **Pembeli** (tanpa Admin) di dokumen & komentar
- [x] Menyeragamkan email akun uji menjadi `@example.com` (dokumen, `.env`, seed)

### Fase 1 — Database

- [x] Menulis `backend/schema.sql`:
  - [x] `roles` (seed: `penjual`, `pembeli`)
  - [x] `users` (FK `role_id`, email UNIQUE, password VARCHAR(255) untuk hash bcrypt)
  - [x] `categories` (seed: Tart, Cupcake, Pastry, Artisan Bread)
  - [x] `cakes` (FK `category_id`, `price` DECIMAL, `image_url`)
  - [x] `orders` (FK `user_id`, FK `cake_id` nullable, ENUM status)
  - [x] Semua tabel `ENGINE=InnoDB`
- [x] Devisi tambahan di luar ERD (sudah dikonfirmasi): `cakes.description`, `cakes.stock`,
      status order `rejected`
- [x] Aturan FK: users→roles RESTRICT, cakes→categories RESTRICT, orders→users CASCADE,
      orders→cakes RESTRICT
- [x] Membuat `backend/database/seed.js` (idempoten, bcrypt runtime) + script `npm run seed`
- [x] Verifikasi live: 5 tabel InnoDB, 4 kategori, 2 user, password TIDAK plaintext,
      `bcrypt.compare` benar → `true`, password salah → `false`, seed aman dijalankan ulang

### Fase 2 — Fondasi server

- [x] `src/index.js`: cors, `express.json()`, endpoint `/health`, error middleware global,
      fail-fast jika DB tidak bisa dihubungi
- [x] `src/config/db.js`: pool mysql2 (limit 10, `decimalNumbers: true` agar `price` berupa number)
- [x] `backend/.env` + `.env.example` (DB, JWT, Cloudinary)

### Fase 3 — Autentikasi

- [x] `POST /api/auth/register` — validasi zod, password di-hash bcrypt, **role selalu `pembeli`**
- [x] `POST /api/auth/login` — verifikasi bcrypt, terbitkan JWT `{ id, role }` (1 hari),
      pesan error disamakan untuk email salah/password salah
- [x] `GET /api/auth/me` — profil dari token (protected)
- [x] Middleware `verifyToken` (Bearer token → `req.user`)
- [x] Bukti awal: **14/14 cek PASS**
- [x] Bug ditemukan & diperbaiki: `require('mysql2/promise')` tidak punya `.promise()` lagi
      (API promise sudah langsung) — server gagal start, diperbaiki sebelum test

### Fase 4 — Refactor validasi (permintaan pengguna)

- [x] Membuat middleware `validate(schema)` — mem-parse `{ body, query, params }`
- [x] Penyesuaian Express 5 (diverifikasi ke dokumentasi resmi):
  - [x] `req.body` bisa `undefined` jika request tanpa body → `?? {}`
  - [x] `req.query` bersifat getter-only → **hanya `req.body` yang ditulis balik**
- [x] Schema auth dibungkus key `body`; error field dibersihkan dari prefix `body.`
- [x] Bukti: **14/14 cek PASS** ulang, format respons & status code tidak berubah
- [x] Bug ditemukan & diperbaiki: route PUT dengan dua `validate` (params lalu body) membuat
      validator params menimpa `req.body` dengan `undefined` → ditambah guard
      `if (result.data.body !== undefined)`

### Fase 5 — Menu kue & kategori

- [x] `GET /api/cakes` (publik), `GET /api/cakes/:id` (publik) — join nama kategori
- [x] `POST /api/cakes` (penjual), `PUT /api/cakes/:id` (penjual, update parsial),
      `DELETE /api/cakes/:id` (penjual) — middleware `requireRole('penjual')`
- [x] `GET /api/categories` — untuk dropdown form Flutter
- [x] Mapping error FK: kategori tidak ada → 400; kue dipakai order → 409
- [x] Bukti: **30/30 cek PASS**; regresi auth **8/8 PASS**

### Fase 6 — Upload foto menu (Cloudinary)

- [x] `src/config/cloudinary.js` — kredensial dari `.env` (hanya di server)
- [x] `src/middlewares/uploadMiddleware.js` — multer memoryStorage, JPG/PNG/WEBP, maks 2 MB
- [x] `POST /api/cakes/:id/image` (penjual) — `upload_stream` → simpan `secure_url` ke DB
- [x] Mapping error: tanpa file/tipe salah → 400, ukuran > 2 MB → 413,
      Cloudinary gagal → 502
- [x] Bukti validasi awal: 11 cek PASS, upload live terblokir **403 dari Cloudinary**
- [x] Setelah akses akun Cloudinary diperbaiki (role master admin), upload live:
      **18/18 cek PASS** — termasuk URL gambar di-HEAD → 200, asset uji dihapus lagi

### Fase 7 — Pesanan (orders)

- [x] `POST /api/orders` (pembeli) — `ready_stock` / `custom`
  - [x] ready-stock: `cake_id` wajib, `agreed_price` disalin dari `cakes.price`
  - [x] stok dikurangi dalam **transaksi** (`SELECT ... FOR UPDATE`), stok habis → 400
  - [x] custom: wajib `custom_description`, `cake_id` & `agreed_price` NULL
- [x] `GET /api/orders?status=` — pembeli melihat miliknya, penjual melihat semua
- [x] `GET /api/orders/:id` — pemilik atau penjual; pembeli lain → 403
- [x] `PUT /api/orders/:id/status` (penjual) — transisi dibatasi:
      `pending → approved|processing|rejected`, `approved → processing`,
      `processing → ready`, `ready → completed`
- [x] `PUT /api/orders/:id/price` (penjual) — `agreed_price`, hanya pesanan `custom`
- [x] Bukti: **42/42 cek PASS**, termasuk stok 2→1→0 dan semua transisi valid/tidak valid

### Fase 8 — Kepatuhan `docs/AGENTS.md`

- [x] Evaluasi diri terhadap 5 aturan AGENTS.md dan pelaporannya ke pengguna
- [x] Mengembalikan helper `ok`/`fail` lokal ke tiap controller (surgical, tanpa abstraksi)
- [x] Atas keputusan pengguna (Opsi B), helper diekstrak kembali ke `src/utils/response.js`
      saat pemakai ketiga (orders) benar-benar ada
- [x] Bukti: regresi **38/38** (setelah restore lokal) dan **17/17** (setelah ekstrak ulang)

---

## 4. Struktur Folder Backend

```
backend/
├── .env                     # kredensial (tidak di-commit)
├── .env.example
├── package.json             # dev / start / seed
├── schema.sql               # referensi skema + seed roles & categories
├── database/
│   └── seed.js              # seed akun uji (bcrypt runtime, idempoten)
└── src/
    ├── index.js             # entry point Express, error middleware
    ├── config/
    │   ├── db.js            # pool MySQL
    │   └── cloudinary.js    # konfigurasi SDK Cloudinary
    ├── controllers/
    │   ├── authController.js
    │   ├── cakeController.js
    │   └── orderController.js
    ├── middlewares/
    │   ├── authMiddleware.js    # verifyToken, requireRole
    │   ├── validateMiddleware.js# validate(schema)
    │   └── uploadMiddleware.js  # multer memoryStorage
    ├── routes/
    │   ├── authRoutes.js
    │   ├── cakeRoutes.js
    │   ├── categoryRoutes.js
    │   └── orderRoutes.js
    ├── utils/
    │   └── response.js      # ok() / fail()
    └── validations/
        ├── authValidation.js
        ├── cakeValidation.js
        └── orderValidation.js
```

---

## 5. Daftar Endpoint

### Auth

- [x] `POST /api/auth/register` — body `{name, email, password, phone?}` → 201
- [x] `POST /api/auth/login` — body `{email, password}` → 200 + `token`
- [x] `GET /api/auth/me` — Bearer token → 200

### Katalog & kategori

- [x] `GET /api/cakes` — publik → 200 daftar kue
- [x] `GET /api/cakes/:id` — publik → 200 / 404 / 400
- [x] `POST /api/cakes` — penjual → 201
- [x] `PUT /api/cakes/:id` — penjual, update parsial → 200
- [x] `DELETE /api/cakes/:id` — penjual → 200 / 409 jika dipakai order
- [x] `POST /api/cakes/:id/image` — penjual, multipart field `image` → 200
- [x] `GET /api/categories` — publik → 200

### Pesanan

- [x] `POST /api/orders` — pembeli → 201
- [x] `GET /api/orders?status=` — login (difilter per role) → 200
- [x] `GET /api/orders/:id` — pemilik/penjual → 200 / 403 / 404
- [x] `PUT /api/orders/:id/status` — penjual → 200 / 400
- [x] `PUT /api/orders/:id/price` — penjual (custom saja) → 200 / 400

Semua respons memakai format konsisten: `{ success, message, data }`.

---

## 6. Keputusan Desain & Alasan

- [x] **Role register = `pembeli` selalu** — mencegah siapa pun menjadi penjual lewat API;
      akun penjual hanya lewat seed
- [x] **Password plaintext hanya di form login** — DB menyimpan hash bcrypt (syarat soal)
- [x] **Seed users di Node script, bukan `schema.sql`** — hash tidak pernah ditulis manual
- [x] **Katalog `GET` publik** — Flutter bisa menampilkan menu sebelum login
- [x] **`req.body` saja yang ditulis balik** di middleware validasi — `req.query` getter-only
      di Express 5
- [x] **`decimalNumbers: true`** — `price` sampai ke Flutter sebagai number, bukan string
- [x] **Stok ready-stock dikurangi dalam transaksi** — mencegah stok minus saat pesanan bersamaan
- [x] **Transisi status dibatasi** sesuai alur laporan §5 — mencegah status mundur
- [x] **Tidak ada endpoint pembatalan** (keputusan pengguna) — status `cancelled` tersedia di
      ENUM tetapi tidak dipakai
- [x] **Penjual tidak bisa membuat pesanan** (403, keputusan pengguna) — logikanya penjual
      membeli barangnya sendiri
- [x] **Helper respons dibagi** (`utils/response.js`) hanya setelah ada 3 pemakai

---

## 7. Bug yang Ditemukan & Diperbaiki

| # | Gejala | Penyebab | Perbaikan | Verifikasi |
|---|---|---|---|---|
| 1 | Server gagal start: `.promise is not a function` | `mysql2/promise` sudah promise-based, tidak punya `.promise()` | Hapus chaining `.promise()` | Server start + 14/14 test |
| 2 | PUT kue 400 padahal body valid | `validate(params)` menimpa `req.body` dengan `undefined` | Guard `if (result.data.body !== undefined)` | 30/30 test |
| 3 | Log koneksi DB kosong saat MySQL mati | `AggregateError` punya `.message` kosong | Log `err.message \|\| err.code` | Terlihat `ECONNREFUSED` |
| 4 | Upload selalu 502 | Upload dibatasi di level akun Cloudinary (403 untuk semua upload) | Perbaikan akses akun oleh pengguna | 18/18 test |

Catatan lingkungan: MySQL Laragon beberapa kali restart saat pengujian
(`ECONNREFUSED` sementara) — bukan bug aplikasi; diulang setelah port hidup.

---

## 8. Bukti Verifikasi

Semua pengujian dijalankan **live** terhadap server Express + MySQL + Cloudinary
sungguhan. Suite permanen tersedia di `backend/tests/` dan dijalankan dengan `npm test`
(lihat §10).

| Suite | Cakupan | Hasil |
|---|---|---|
| Schema & seed | 5 tabel InnoDB, seed roles/kategori, hash bcrypt valid, idempoten | PASS |
| Auth awal | register/login/me, 400/401/403/409 | 14/14 PASS |
| Auth setelah refactor `validate` | skenario yang sama | 14/14 PASS |
| Cakes CRUD | katalog, create/update/delete, role guard, FK 400/409 | 30/30 PASS |
| Auth regresi | login/register/me setelah perubahan middleware | 8/8 PASS |
| Upload (validasi) | guard, tipe file, ukuran, id | 11 cek PASS |
| Upload (live) | upload Cloudinary, URL diakses, simpan DB, cleanup | 18/18 PASS |
| Orders | stok transaksional, custom, filter, akses, transisi status, harga | 42/42 PASS |
| Regresi gabungan | auth + cakes + upload + FK setelah helper lokal | 38/38 PASS |
| Regresi final | auth + cakes + upload setelah helper dibagi | 17/17 PASS |
| Suite permanen (`npm test`) | auth, cakes, orders, upload — 4 file, 20 tes | 20/20 PASS (dijalankan berulang, exit 0) |

Status akhir database setelah semua pengujian: `cakes=0`, `orders=0`, `users=2`
(hanya akun seed), dan tidak ada asset uji tersisa di Cloudinary.

---

## 9. Catatan & Keterbatasan

- [x] Tidak ada endpoint pembatalan pesanan (keputusan)
- [x] Penjual tidak bisa membuat pesanan (keputusan)
- [ ] `cakes` tidak punya `seller_id` sesuai ERD — semua penjual berbagi satu katalog.
      Isolasi per-penjual butuh perubahan skema (belum diminta)
- [ ] Upload foto referensi custom cake belum punya endpoint khusus —
      `orders.custom_image_url` masih menerima URL teks
- [ ] `pickup_date` disimpan sebagai DATETIME lokal; respons JSON tampil ISO UTC
      (input `10:00` → `03:00Z`). Flutter perlu konversi ke zona waktu perangkat
- [x] Suite pengujian permanen tersedia di `backend/tests/` dan dijalankan dengan `npm test`
- [ ] Suite belum terhubung ke CI (perlu langkah CI terpisah bila diinginkan)
- [ ] Klien Flutter belum dibuat

---

## 10. Cara Menjalankan

```bash
# 1. Database: eksekusi backend/schema.sql di MySQL Workbench (sekali saja)
# 2. Backend
cd backend
npm install
npm run seed     # mengisi 2 akun uji (bcrypt runtime)
npm run dev      # server di http://localhost:5000

# 3. Pengujian (di terminal terpisah, server harus tetap berjalan)
npm test
```

Prasyarat pengujian:

- MySQL aktif dan `npm run seed` sudah dijalankan (tes memakai akun seed).
- Server API berjalan di `http://localhost:5000` (atau set `API_URL`).
- Tes `upload` memakai kredensial Cloudinary dari `.env`; jika cloud name masih
  `mock`, tes upload otomatis di-skip.
- Tes hanya membuat/menghapus data miliknya sendiri (kue, pesanan, akun `test.*@example.com`)
  dan menghapus asset Cloudinary uji setelah selesai.

### Aturan pengujian manual

- [ ] Jalankan `npm test` setelah setiap perubahan pada **authentication, cakes, orders, atau upload**
- [ ] Jalankan seluruh suite sebelum commit perubahan backend
- [ ] Jalankan seluruh suite sebelum rilis
- [ ] Jika ada tes gagal: investigasi penyebabnya sebelum melanjutkan. Jangan mengubah
      implementasi hanya agar tes lolos.

Tidak memakai CI, cron, atau workflow — suite dijalankan manual di komputer lokal.

Cek server: `GET http://localhost:5000/health` → `{ "success": true, ... }`

Login uji (PowerShell):

```powershell
curl.exe -s -X POST http://localhost:5000/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"penjual@example.com","password":"penjual123"}'
```
