# SweetCraft Tech Stack

## Backend

- **Runtime & Language**: Node.js, JavaScript (CommonJS)
- **Framework**: Express.js (v5)
- **Database**: MySQL via `mysql2/promise` (Connection pool, raw SQL)
- **Authentication & Security**:
  - `jsonwebtoken` (JWT 2 roles: Penjual, Pembeli)
  - `bcrypt` (Password hashing)
  - `cors` (Cross-origin resource sharing)
- **Validation**: `zod` (Request body & param validation)
- **File Upload & Storage**:
  - `multer` (Memory storage)
  - `cloudinary` (Cloud image hosting untuk foto produk kue & referensi custom cake)
- **Configuration**: `dotenv` (Environment variables)
- **Dev Tool**: `nodemon` (Hot reload)

### Out of Scope (Backend)
- Payment gateway
- Realtime chat

---

## Frontend

- **Framework**: Flutter (Dart)
- **Libraries**:
  - `http` (HTTP client untuk konsumsi REST API — request JSON & `multipart/form-data`)
  - `provider` (State management antarmuka)
  - `shared_preferences` (Penyimpanan lokal token JWT & identitas role pengguna)
  - `image_picker` (Pilih foto produk kue & referensi desain custom cake dari galeri/kamera)
  - `google_fonts` (Font kustom antarmuka)
