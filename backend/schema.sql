-- ============================================================================
-- SweetCraft — Bakery & Custom Cake Pre-Order System
-- Skema Basis Data (MySQL 8.x)
--
-- STATUS: File statis / referensi. Belum dieksekusi ke server MySQL manapun.
-- Tujuan: acuan struktur database untuk AI CLI & developer.
--
-- Sumber desain: docs/laporan_proyek_sweetcraft.md (ERD §4, Role §2, Alur §5)
--
-- Cara pakai (jika ingin dieksekusi nanti):
--   mysql -u root -p < backend/schema.sql
-- Nama database mengikuti DB_NAME di backend/.env (sweetcraft_db).
-- ============================================================================

CREATE DATABASE IF NOT EXISTS sweetcraft_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE sweetcraft_db;

-- ----------------------------------------------------------------------------
-- Tabel: roles
-- Sumber: ERD §4 — "roles ↔ users (1 : N)"
-- Isi seed: 2 role sesuai dokumen (Penjual, Pembeli). TIDAK ada role Admin.
-- ----------------------------------------------------------------------------
CREATE TABLE roles (
  id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Tabel: users
-- Sumber: ERD §4 — id, role_id (FK), name, email (UQ), password, phone
-- Kolom password menampung hash bcrypt (60 karakter), BUKAN teks biasa
--   (syarat soal ujian: password disimpan dalam bentuk hash).
-- ----------------------------------------------------------------------------
CREATE TABLE users (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id    INT UNSIGNED NOT NULL,
  name       VARCHAR(100) NOT NULL,
  email      VARCHAR(150) NOT NULL UNIQUE,
  password   VARCHAR(255) NOT NULL,
  phone      VARCHAR(20)  NULL,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                       ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role
    FOREIGN KEY (role_id) REFERENCES roles (id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Tabel: categories
-- Sumber: ERD §4 — "categories ↔ cakes (1 : N)"
-- Contoh kategori dari laporan: Tart, Cupcake, Pastry, Artisan Bread.
-- ----------------------------------------------------------------------------
CREATE TABLE categories (
  id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Tabel: cakes
-- Sumber: ERD §4 — id, category_id (FK), name, price, is_custom, image_url
--
-- DEVISI TAMBAHAN (di luar ERD §4, disebut di laporan §2.1):
--   description : penjual "mengubah informasi harga/stok/deskripsi"
--   stock       : §1.1 "produk siap saji dengan jumlah terbatas".
--                 NULL = tidak dibatasi (mis. produk custom).
--   Jika ingin kembali 100% ke ERD §4, hapus kedua kolom ini.
-- ----------------------------------------------------------------------------
CREATE TABLE cakes (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id INT UNSIGNED NOT NULL,
  name        VARCHAR(150) NOT NULL,
  price       DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  is_custom   BOOLEAN       NOT NULL DEFAULT FALSE,
  stock       INT UNSIGNED  NULL,
  description TEXT          NULL,
  image_url   VARCHAR(500)  NULL,          -- URL hasil upload ke Cloudinary
  created_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_cakes_category
    FOREIGN KEY (category_id) REFERENCES categories (id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Tabel: orders
-- Sumber: ERD §4 — id, user_id (FK), cake_id (FK, nullable), order_type,
--   custom_image_url, custom_description, decoration_note, agreed_price,
--   pickup_date, status, created_at, updated_at
--
-- DEVISI TAMBAHAN:
--   status 'rejected' ditambahkan agar laporan §2.1 ("Ditolak") bisa
--   diimplementasikan. ERD §4 asli hanya mendefinisikan 6 nilai.
--
-- Konvensi data (dijaga di layer aplikasi, bukan constraint SQL):
--   order_type = 'ready_stock' -> cake_id WAJIB terisi,
--                                agreed_price mengikuti cakes.price
--   order_type = 'custom'      -> cake_id boleh NULL (pre-order murni),
--                                custom_image_url / custom_description terisi,
--                                agreed_price diisi penjual setelah review
-- ----------------------------------------------------------------------------
CREATE TABLE orders (
  id                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id            INT UNSIGNED NOT NULL,
  cake_id            INT UNSIGNED NULL,
  order_type         ENUM('ready_stock', 'custom') NOT NULL,
  custom_image_url   VARCHAR(500) NULL,
  custom_description TEXT         NULL,
  decoration_note    VARCHAR(500) NULL,
  agreed_price       DECIMAL(10,2) NULL,
  pickup_date        DATETIME     NULL,
  status             ENUM(
                       'pending',
                       'approved',
                       'processing',
                       'ready',
                       'completed',
                       'cancelled',
                       'rejected'
                     ) NOT NULL DEFAULT 'pending',
  created_at         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
                                  ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_orders_cake
    FOREIGN KEY (cake_id) REFERENCES cakes (id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_orders_status (status)
) ENGINE=InnoDB;

-- ============================================================================
-- SEED DATA MINIMAL
--   roles & categories      -> langsung di sini (data statis).
--   users (akun pengujian, soal ujian no. 12) -> TIDAK di-seed di sini.
--     Alasan (Opsi B): password harus di-hash bcrypt di layer APLIKASI —
--     MySQL tidak memiliki fungsi bcrypt. Akun uji dibuat oleh script Node:
--       npm run seed        (backend/database/seed.js)
--     Password akun uji (plaintext, dev only):
--       penjual@example.com -> penjual123
--       pembeli@example.com -> pembeli123
--     Alur login nanti: bcrypt.compare(plaintext, hash dari DB) di backend.
-- ============================================================================

INSERT INTO roles (name) VALUES
  ('penjual'),
  ('pembeli');

INSERT INTO categories (name) VALUES
  ('Tart'),
  ('Cupcake'),
  ('Pastry'),
  ('Artisan Bread');
