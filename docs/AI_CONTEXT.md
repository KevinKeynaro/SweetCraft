# AI Context — SweetCraft Frontend

Dokumen ini adalah prompt konteks untuk AI CLI lain. Tempel isinya di awal sesi
sebelum memberi tugas pada proyek ini.

---

KONTEKS PROYEK SWEETCRAFT — BACA SEBELUM MENGUBAH KODE

Kamu bekerja pada proyek SweetCraft:
- Frontend Flutter di `frontend/` (Flutter 3.47.6, Dart SDK ^3.13.5).
- Backend Node/Express di `backend/`, berjalan di `http://localhost:5000`.
- Database MySQL `sweetcraft_db` (Laragon, MySQL 8.4).
- Target utama: Android. Verifikasi runtime saat ini memakai Chrome karena
  Visual Studio toolchain untuk Windows desktop belum tersedia.

KEPUTUSAN PENTING DARI PEMILIK PROYEK

Pemilik proyek secara sadar MENOLAK struktur berlapis dan meminta frontend
dibuat sesederhana mungkin. Ini bukan kesalahan, bukan utang teknis yang harus
dibersihkan, dan bukan sesuatu yang boleh di-refactor tanpa izin.

Divergensi berikut DISENGAJA:

1. Warna dan font DITULIS HARDCODED langsung di widget/page.
   - Tidak ada `lib/core/theme/`, `app_tokens.dart`, `app_theme.dart`, atau
     sistem token warna/typography.
   - Tidak ada `ThemeData` global.
   - DESIGN.md §2 masih menyatakan warna/font dilarang hardcoded. Dokumen itu
     SENGAJA tidak diubah. Untuk styling, kode saat ini dan prompt ini menang
     atas DESIGN.md.

2. Tidak ada state management.
   - Tidak ada Provider, ChangeNotifier, AuthProvider, AuthGate, repository,
     atau model `AppUser`.
   - Halaman memanggil `ApiService` langsung.
   - Gunakan `StatefulWidget` untuk state lokal form.

3. Tidak ada folder `features/`, `core/`, `shared/`, atau `theme/`.
   - Struktur final saat ini hanya: `services/`, `pages/`, `widgets/`.

4. Validasi form ditulis INLINE di masing-masing page.
   - Duplikasi validator email/nama antara login dan register DISENGAJA.
   - Jangan memindahkannya ke file validator bersama tanpa izin.

5. Auto-login dilakukan di `main.dart` sebelum `runApp`.
   - Baca token dari SharedPreferences.
   - Jika ada, panggil `GET /api/auth/me`.
   - Sukses: langsung `HomePage`.
   - 401: hapus token, tampilkan `LoginPage`.
   - Tidak ada halaman splash terpisah dan tidak ada AuthGate.

6. Register tidak auto-login.
   - `POST /api/auth/register` tidak mengembalikan token.
   - Setelah register sukses, kembali ke Login dengan email terisi.

7. `HomePage` hanya placeholder setelah login.
   - Katalog, Pesanan, Profil, dan tab per role BELUM dibuat.
   - Jangan mengarang fitur atau endpoint yang belum ada di backend.

STRUKTUR FILE SAAT INI

frontend/lib/
  main.dart                  # startup, cek token, MaterialApp, tanpa ThemeData
  services/api.dart          # HTTP, token, timeout, ApiException
  widgets/app_button.dart    # tombol primary/outlined, hardcoded
  widgets/app_text_field.dart # input teks, label, error, toggle password
  widgets/auth_scaffold.dart # layout bersama login/register
  pages/login_page.dart      # form login, validasi inline, panggil API
  pages/register_page.dart   # form register, validasi inline, panggil API
  pages/home_page.dart       # placeholder, nama/role, logout

frontend/test/
  auth_pages_test.dart       # tes widget login/register/home

File lama berikut SUDAH DIHAPUS dan tidak boleh dibuat lagi tanpa izin:
- lib/core/theme/*
- lib/features/auth/*
- lib/features/home/*
- lib/shared/widgets/*
- lib/service/api.dart
- test/auth_validators_test.dart
- test/auth_screens_test.dart

API AUTENTIKASI YANG BERLAKU

Base URL `ApiService`:
- Android emulator: http://10.0.2.2:5000/api
- Platform lain: http://localhost:5000/api
- Override: flutter run --dart-define=API_BASE_URL=http://IP:5000/api

POST /api/auth/login
Body: { "email": "...", "password": "..." }
Sukses 200:
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "token": "JWT",
    "user": { "id": 2, "name": "...", "email": "...", "phone": "...", "role": "pembeli" }
  }
}
Gagal 401: { "success": false, "message": "Email atau password salah", "data": null }

POST /api/auth/register
Body: { "name": "...", "email": "...", "password": "...", "phone": "opsional" }
Sukses 201: { "success": true, "message": "Registrasi berhasil", "data": { "user": {...} } }
Tanpa token. Role selalu `pembeli`.
409: { "success": false, "message": "Email sudah terdaftar", "data": null }

GET /api/auth/me
Header: Authorization: Bearer <token>
Sukses 200: { "success": true, "message": "Profil user", "data": { "user": {...} } }
401 jika token tidak ada/kedaluwarsa.

Validasi backend:
- name: 2–100 karakter
- email: format valid, maksimal 150
- password register: minimal 6, maksimal 255
- phone: opsional, 8–20 karakter
Error validasi 400:
{ "success": false, "message": "Data tidak valid", "data": [{ "field": "email", "message": "..." }] }

Akun uji dev:
- pembeli@example.com / pembeli123 (role pembeli)
- penjual@example.com / penjual123 (role penjual)

GAYA VISUAL YANG HARUS DIPAKAI (HARDCODED)

Gunakan nilai literal ini, jangan membuat token/konstanta bersama:

- Latar halaman: Color(0xFFFDFBF7)
- Permukaan kartu/input: Color(0xFFFFFFFF)
- Brand/caramel: Color(0xFF8C4A27)
- Brand gelap: Color(0xFF5C341E)
- Teks utama: Color(0xFF2B2118)
- Teks sekunder: Color(0xFF6E5D4F)
- Border kontrol: Color(0xFF9C8370)
- Border dekoratif: Color(0xFFE6DDD0)
- Error: Color(0xFF991B1B)
- Sukses: Color(0xFF166534)
- Disabled background: Color(0xFFEFE9E1)
- Disabled text: Color(0xFFA79A8C)

Tipografi:
- Judul/display: GoogleFonts.fraunces(...)
- Body/UI: GoogleFonts.plusJakartaSans(...)

Ukuran:
- Touch target minimal 48dp
- Radius kontrol 12dp
- Radius kartu 16dp
- Padding layar umum 16dp/24dp

ATURAN KERJA UNTUK AI

MUST:
- Baca file yang relevan sebelum mengubah apa pun.
- Ikuti pola yang sudah ada: page di `lib/pages`, widget reusable di
  `lib/widgets`, panggilan API langsung lewat `ApiService`.
- Pertahankan auto-login di `main.dart` dan alur navigator saat ini.
- Jalankan `flutter analyze` dan `flutter test` setelah perubahan.
- Laporkan bukti output, bukan klaim "seharusnya berhasil".
- Jika menambah halaman baru, gunakan styling hardcoded dengan nilai di atas.
- Jika butuh data user di halaman lain, oper `name`/`role` lewat constructor
  atau ambil ulang lewat `ApiService`; jangan membuat model/provider baru
  tanpa izin.

MUST NOT:
- Jangan membuat `ThemeData`, token warna, `app_theme.dart`, atau folder tema.
- Jangan membuat Provider/ChangeNotifier/AuthGate/repository/model auth.
- Jangan memindahkan halaman ke folder `features/`.
- Jangan memperbarui `docs/DESIGN.md` tanpa izin eksplisit.
- Jangan "memperbaiki" kode agar sesuai DESIGN.md §2.
- Jangan menambah dependency baru.
- Jangan mengubah register menjadi auto-login.
- Jangan menghapus `provider` dari `pubspec.yaml` tanpa izin (saat ini tidak
  dipakai, tetapi itu dependency yang ditambahkan pemilik proyek).
- Jangan melakukan refactor besar atau rename file yang tidak diminta.
- Jangan mengarang endpoint/fitur yang belum ada di `backend/src`.

VERIFIKASI YANG DIHARAPKAN

Dari folder `frontend/`:
  flutter analyze
  flutter test

Target:
- `flutter analyze` → 0 issue
- `flutter test` → semua tes lulus

Untuk uji runtime:
  cd backend && npm run dev
  cd frontend && flutter run -d chrome

Pastikan MySQL Laragon menyala dan database `sweetcraft_db` tersedia.

CATATAN KONDISI SAAT INI

- Perubahan frontend belum di-commit. Jangan revert pekerjaan yang ada.
- `lib/main.dart` sudah memuat logika auto-login.
- `lib/services/api.dart` sudah menangani token, timeout, dan error per-field.
- Tes saat ini ada di `test/auth_pages_test.dart` (4 tes lulus).
- `flutter run -d windows` belum bisa dipakai karena Visual Studio toolchain
  belum terpasang.

TUGAS BERIKUTNYA (KEMUNGKINAN)

Jika diminta melanjutkan, arah yang wajar adalah halaman Katalog
(`GET /api/cakes`, `GET /api/categories`) dengan pola yang sama:
- `lib/pages/catalog_page.dart`
- styling hardcoded
- panggil `ApiService.get(...)` langsung
- tidak menambah state management

Jika kamu ragu antara mengikuti prompt ini atau DESIGN.md, BERHENTI dan
tanyakan kepada pemilik proyek. Jangan memilih sendiri.

---

## Cara pakai

1. Tempel isi prompt di atas pada pesan pertama sesi AI CLI lain, sebelum memberi tugas.
2. Jika CLI tersebut otomatis membaca `docs/DESIGN.md` atau skill, prompt ini tetap berlaku karena menyatakan bahwa keputusan pemilik proyek mengalahkan `DESIGN.md`.
3. Minta AI membaca file aktual di `frontend/lib/` sebelum mengubah apa pun.
4. Jangan minta AI "merapikan arsitektur" kecuali Anda memang ingin mengembalikan token/tema/Provider.
