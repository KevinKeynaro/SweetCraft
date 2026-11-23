# FLUTTER_AUDIT_REPORT

Audit kompatibilitas klien Flutter terhadap kontrak backend SweetCraft.

- **Backend referensi:** commit `39a3fb5c5aa7c4f356782fb8fc797078d903dbc1`
  (`fix: harden order concurrency and API validation`)
- **Metode:** read-only — membaca source Flutter, manifest Android, Gradle, serta
  mencocokkan dengan implementasi backend (`backend/src`), bukan hanya dokumentasi.
- **Tanggal:** 20 November 2026
- **Status:** tidak ada perubahan pada file Flutter, konfigurasi, atau dependensi.

---

## 1. Kondisi repository Flutter (fakta)

| Item | Bukti |
|---|---|
| File Dart sumber | Hanya `frontend/lib/main.dart` (122 baris) |
| File tes | `frontend/test/widget_test.dart` (30 baris, tes counter template) |
| Lapisan API/Repository/Provider | **Tidak ada** (tidak ada folder `models/`, `services/`, `providers/`, `repositories/`) |
| Pemakaian HTTP | **0 hasil** untuk `http`, `/api/`, `jsonDecode`, `Bearer`, `baseUrl` di source Dart; satu-satunya kecocokan berasal dari file generated `frontend/.dart_tool/dartpad/web_plugin_registrant.dart` |
| `lib/main.dart` | Aplikasi counter bawaan Flutter (`MyApp` → `MyHomePage`), tidak ada jaringan — bukti: baris 1–122 |
| Dependensi siap pakai | `http ^1.6.0`, `provider ^6.1.5+1`, `shared_preferences ^2.5.6`, `image_picker ^1.2.4`, `google_fonts ^9.0.0` (`pubspec.yaml:37–41`) — semuanya **belum dipakai** |

**Kesimpulan:** tidak ada komunikasi Flutter → backend untuk diaudit. Permintaan
nomor 3–9 (endpoint, payload, model, error handling) berstatus **NOT IMPLEMENTED**,
bukan "kompatibel".

---

## 2. Trace lapisan yang diminta

```
UI (main.dart counter)
  → Provider/Controller   : tidak ada
  → Repository            : tidak ada
  → API Client            : tidak ada
  → Express Backend       : tidak pernah dipanggil
```

Tidak ada satu pun request HTTP yang dibuat aplikasi (`lib/main.dart` hanya
`setState` counter; `test/widget_test.dart` hanya menguji counter).

---

## 3. Temuan

### FL-01 — HIGH — Izin INTERNET tidak ada di manifest utama (release build tidak bisa call API)

- **File/baris:** `frontend/android/app/src/main/AndroidManifest.xml:1–45`
- **Bukti:** tidak ada `<uses-permission android:name="android.permission.INTERNET"/>`;
  manifest hanya berisi `<application>` dan `<queries>`.
- **Pembanding:** izin hanya ada di
  `frontend/android/app/src/debug/AndroidManifest.xml:4` (khusus debug/profile).
- **Dampak:** build **release** tidak memiliki izin jaringan → seluruh pemanggilan
  backend gagal.
- **Backend terkait:** semua endpoint `/api/*`.
- **Status:** Confirmed (static). Belum diuji build release.
- **Saran (nanti):** tambahkan izin INTERNET ke manifest utama.

### FL-02 — MEDIUM — HTTP lokal (cleartext) diblokir pada target SDK modern

- **File/baris:** `frontend/android/app/build.gradle.kts:22–23`
  (`targetSdk = flutter.targetSdkVersion`); `AndroidManifest.xml:2–5` tidak memiliki
  `android:usesCleartextTraffic` maupun `android:networkSecurityConfig`.
- **Sumber resmi:** Android — *"The default value for apps that target API level 27 or
  lower is `true`. Apps that target API level 28 or higher default to `false`."*
  (https://developer.android.com/guide/topics/manifest/application-element#usesCleartextTraffic)
- **Dampak:** rencana base URL lokal `http://10.0.2.2:5000` akan gagal di
  emulator/perangkat (cleartext ditolak).
- **Status:** Confirmed (static, berdasarkan konfigurasi + dokumentasi). Belum diuji runtime.
- **Saran (nanti):** network security config khusus debug yang mengizinkan `10.0.2.2`,
  atau `usesCleartextTraffic` hanya pada build debug.

### FL-03 — HIGH (project blocker) — Tidak ada API client sama sekali

- **File/baris:** `frontend/lib/main.dart:1–122`; `frontend/test/widget_test.dart:1–30`;
  `pubspec.yaml:37–41`.
- **Bukti:** tidak ada import `package:http/http.dart`, tidak ada model, tidak ada
  panggilan endpoint, tidak ada penyimpanan token meski `shared_preferences` terpasang.
- **Dampak:** tidak ada integrasi untuk diaudit; seluruh kontrak backend belum pernah
  dipakai klien.
- **Status:** Confirmed.
- **Saran:** implementasi Slice 1 (ApiClient + session + auth + katalog) sebelum audit
  integrasi berikutnya.

### FL-04 — NOT APPLICABLE (belum ada kode) — `price/decision` wajib `agreed_price`

- **Backend:** `backend/src/routes/orderRoutes.js:20`;
  `backend/src/validations/orderValidation.js:78–89` (wajib `agreed_price`, maks 2 desimal).
- **Flutter:** tidak ada request `price/decision` (grep 0 hasil).
- **Kewajiban saat implementasi:** kirim `{ decision, agreed_price }` dengan harga yang
  sedang tampil; jika **409** → refresh detail sebelum memutuskan.
- **Status:** Not implemented (bukan mismatch).

### FL-05 — NOT APPLICABLE — `is_custom` harus `bool`

- **Backend:** `backend/src/controllers/cakeController.js:13`
  (`Boolean(row.is_custom)`) — semua respons kue (list/detail/create/update/upload).
- **Flutter:** tidak ada model kue.
- **Kewajiban saat implementasi:** field Dart `bool isCustom`
  (`json['is_custom'] as bool`), bukan `int`.
- **Status:** Not implemented.

### FL-06 — NOT APPLICABLE — 409 sebagai konflik data

- **Backend:** `orderController.js:113,128,140,150,179,224` (409 untuk
  transisi/harga/pembatalan yang bersamaan).
- **Flutter:** tidak ada penanganan status code apa pun.
- **Kewajiban saat implementasi:** 409 → tampilkan pesan "Data berubah, muat ulang",
  refresh detail; jangan retry otomatis.
- **Status:** Not implemented.

### FL-07 — NOT APPLICABLE — 404 JSON & 413

- **Backend:** `index.js:27–30` (404 JSON) dan `index.js:48–56`
  (400 parser / 413 body besar).
- **Flutter:** tidak ada HTTP client/decoder.
- **Kewajiban saat implementasi:** parse JSON untuk semua respons; tangani 404
  (empty/not found) dan 413 (body terlalu besar) tanpa crash `jsonDecode`.
- **Status:** Not implemented.

### FL-08 — INFO — Dependensi sudah memadai

- **File:** `pubspec.yaml:37–41`; tidak ada dependency baru yang dibutuhkan untuk
  lapisan HTTP/penyimpanan sesi.
- **Catatan:** `image_picker` siap untuk unggah referensi custom.

### FL-09 — INFO — Tes Flutter masih template

- **File:** `frontend/test/widget_test.dart:13–29` — hanya menguji counter.
- **Dampak:** tidak ada tes kontrak/model; regresi integrasi tidak terlindungi.

### FL-10 — INFO — Konfigurasi base URL & sesi belum ada

- **Bukti:** tidak ada konstanta `baseUrl`/`API_URL` di source; `shared_preferences`
  belum diimpor.
- **Catatan untuk implementasi:** Android emulator → `http://10.0.2.2:5000`;
  perangkat fisik → IP host; sebaiknya lewat `--dart-define`.

### FL-11 — LOW — Identitas aplikasi masih default

- **File:** `build.gradle.kts:19` (`applicationId = "com.example.frontend"`),
  `AndroidManifest.xml:3` (`android:label="frontend"`).
- **Dampak:** bukan blocker kontrak API, tapi belum siap rilis.

---

## 4. Matriks kompatibilitas endpoint (status: belum dipanggil)

| Endpoint backend | Metode | Kebutuhan klien | Status di Flutter |
|---|---|---|---|
| `/api/auth/register` | POST | `{name,email,password,phone?}`; role selalu pembeli | Tidak ada |
| `/api/auth/login` | POST | `{email,password}` → `token` | Tidak ada |
| `/api/auth/me` | GET | Bearer token | Tidak ada |
| `/api/cakes` | GET | katalog publik; `is_custom` boolean | Tidak ada |
| `/api/cakes/:id` | GET | detail | Tidak ada |
| `/api/cakes` | POST/PUT/DELETE | penjual; 409 saat dihapus & dipakai order | Tidak ada |
| `/api/cakes/:id/image` | POST | multipart `image` ≤2 MB | Tidak ada |
| `/api/categories` | GET | dropdown kategori | Tidak ada |
| `/api/uploads` | POST | multipart `image` → `{url}` | Tidak ada |
| `/api/orders` | POST | `ready_stock` (cake_id) / `custom` (description; `custom_image_url` dari upload) | Tidak ada |
| `/api/orders` | GET | filter `?status=` | Tidak ada |
| `/api/orders/:id` | GET | owner/penjual | Tidak ada |
| `/api/orders/:id/status` | PUT | penjual; 409 konflik | Tidak ada |
| `/api/orders/:id/price` | PUT | penjual; `agreed_price` ≤2 desimal; 409 | Tidak ada |
| `/api/orders/:id/price/decision` | PUT | pembeli; `{decision, agreed_price}`; 409 | Tidak ada |
| `/api/orders/:id/cancel` | PUT | pembeli; `pending`/`approved`; 409 | Tidak ada |

---

## 5. Checklist implementasi klien (untuk fase berikutnya)

- [ ] Tambah izin INTERNET di manifest utama (FL-01).
- [ ] Konfigurasi cleartext khusus debug untuk `10.0.2.2` (FL-02).
- [ ] `ApiClient` dengan base URL `--dart-define`, header Bearer, parsing
      `{success,message,data}`.
- [ ] Model `Cake.isCustom` sebagai `bool`.
- [ ] Decision harga mengirim `agreed_price` yang tampil (maks 2 desimal).
- [ ] Tangani 401 (logout), 403, 404 (empty), 409 (refresh), 413, 502.
- [ ] Alur upload referensi: `POST /api/uploads` → simpan `url` → sertakan saat buat
      order custom.
- [ ] Tes unit untuk parsing model & pemetaan error.

---

## 6. Verifikasi yang dilakukan / tidak

| Dilakukan | Bukti |
|---|---|
| Baca seluruh file Dart (`lib`, `test`) | `main.dart` 1–122; `widget_test.dart` 1–30 |
| Grep pemakaian HTTP/API | 0 hasil di source (hanya generated `.dart_tool`) |
| Cek manifest & Gradle Android | `AndroidManifest.xml` 1–45; debug manifest 1–6; `build.gradle.kts` 22–23 |
| Cocokkan kontrak backend | `orderRoutes.js:15–21`, `orderValidation.js:78–89`, `orderController.js:107–228`, `index.js:27–56`, `cakeController.js:13` |
| Git status | Bersih pada commit `39a3fb5` |

| Tidak dilakukan | Alasan |
|---|---|
| `flutter analyze` / `flutter test` | Audit read-only; dapat menulis artefak `.dart_tool` |
| Uji emulator/runtime | Tidak ada kode API; tidak perlu |
| Uji 409/404/413 dari klien | Klien belum ada |

**Tidak ada klaim bahwa Flutter "kompatibel"** — buktinya justru belum ada integrasi.
