# DESIGN.md — SweetCraft Mobile UI/UX System

**Versi:** 2.0 · **Tanggal:** 20 November 2026
**Perubahan utama:** diselaraskan dengan kontrak backend yang berjalan (`backend/src`,
`backend/schema.sql`, `docs/backend.md`); menghapus rujukan yang tidak ada; menambah
kontrak data, inventaris layar, copy deck, dan governance.

Dokumen ini adalah pedoman tunggal untuk desain antarmuka dan implementasi front-end
**Flutter** pada aplikasi **SweetCraft**. Dokumen ini mengatur sistem visual, komponen
modular, interaksi, aksesibilitas, dan standar kode UI.

**Sumber kebenaran (urutan prioritas):**

1. Perilaku & data: `backend/src` dan `backend/schema.sql` (implementasi yang berjalan).
2. Ringkasan API & aturan backend: `docs/backend.md`.
3. Kebutuhan bisnis: `docs/laporan_proyek_sweetcraft.md`.
4. Visual, komponen, dan pola interaksi: dokumen ini.

Jika dokumen ini berbeda dengan kode, **kode yang menang**; perbarui dokumen ini.

**Ruang lingkup:** aplikasi mobile Flutter, target utama Android. **Di luar lingkup:**
dark mode, mode offline, notifikasi push, pembatalan pesanan, persetujuan harga oleh
pembeli, unggah foto referensi custom cake, keranjang/kuantitas, pencarian, dan pagination
(API belum menyediakan).

---

## 1. Design Philosophy

- **Identitas Visual:** Hangat, jujur, dan *handmade* layaknya toko kue rumahan yang rapi.
  Antarmuka berperan sebagai kanvas tenang yang menonjolkan foto produk, bukan marketplace padat.
- **Prinsip Modular (LEGO System):** UI dibangun dari token dan komponen standar yang dapat
  dirakit ulang di berbagai layar agar konsisten, tanpa membatasi fleksibilitas layar khusus.
- **Pemisahan Tanggung Jawab:** Dokumen ini mengatur *bagaimana* antarmuka tampil dan
  berinteraksi. Alur bisnis, status transaksi, dan validasi mengikuti kontrak backend
  tanpa mengasumsikan fitur yang belum tersedia di API.

---

## 2. Global Design Tokens

Seluruh nilai visual **wajib** terpusat di `lib/core/theme/app_tokens.dart` dan
`app_theme.dart` (dibuat saat Slice 1). Dilarang menulis warna hex, nama font, atau angka
*spacing/radius/elevation* secara *hardcoded* di file layar.

### 2.1 Color Tokens

**Brand & Neutral Surfaces**
- `canvasBackground`: `#FDFBF7` (*Warm Cream* — latar halaman)
- `surfaceCard`: `#FFFFFF` (*Pure White* — kartu dan modal)
- `surfaceSubtle`: `#F5EFE6` (*Soft Flour* — placeholder gambar, chip non-aktif, skeleton dasar)
- `primaryBrand`: `#8C4A27` (*Roasted Caramel* — tombol utama, aksen aktif)
- `primaryBrandDark`: `#5C341E` (*Dark Cocoa* — pressed state, focus ring, app bar aksen)
- `onPrimary`: `#FFFFFF` (teks/ikon di atas `primaryBrand`; kontras ≈6.7:1)
- `textPrimary`: `#2B2118` (*Dark Espresso* — judul dan teks utama)
- `textSecondary`: `#6E5D4F` (*Warm Taupe* — subjudul, metadata)
- `borderSubtle`: `#E6DDD0` (*Soft Sand* — **hanya** pembatas dekoratif, kontras ≈1.3:1)
- `borderControl`: `#9C8370` (batas input/dropdown; kontras ≈3.4:1 — memenuhi 3:1)
- `disabledBg`: `#EFE9E1` | `disabledText`: `#A79A8C` (state non-aktif; tidak untuk teks penting)
- `scrim`: `#2B2118` pada opasitas 40% (latar dialog/bottom sheet)
- `skeletonHighlight`: `#F8F3EC`

**Semantic Status Colors (terpisah dari warna brand)**
- `successBg`: `#DCFCE7` | `successText`: `#166534` (selesai, stok aman)
- `warningBg`: `#FEF3C7` | `warningText`: `#92400E` (menunggu konfirmasi/penawaran, stok menipis)
- `infoBg`: `#DBEAFE` | `infoText`: `#1E40AF` (dikonfirmasi, harga diajukan, diproses)
- `readyBg`: `#CCFBF1` | `readyText`: `#115E59` (siap diambil)
- `errorBg`: `#FEE2E2` | `errorText`: `#991B1B` (ditolak, validasi gagal, error jaringan)

**Kontras (WCAG AA):** minimal **4.5:1** untuk teks normal; **3:1** untuk teks besar
(≥18pt regular / ≥14pt bold) dan batas komponen interaktif. Pasangan status di atas
terukur ≈6–7:1. **Jangan** memakai `borderSubtle` sebagai satu-satunya batas input.

### 2.2 Typography (`google_fonts`)

- **Display & Headings:** `Fraunces` (SemiBold/Bold).
- **Body & UI:** `Plus Jakarta Sans` (Regular/Medium/SemiBold/Bold).
- **Harga:** `Plus Jakarta Sans` Bold + `FontFeature.tabularFigures()`.

| Token | Font | Size/Line (sp) | Weight | Pemakaian |
|---|---|---|---|---|
| `displayLg` | Fraunces | 30/38 | 600 | Judul banner |
| `headlineLg` | Fraunces | 24/32 | 600 | Judul layar |
| `titleLg` | Fraunces | 20/28 | 600 | Nama kue (detail) |
| `titleMd` | Plus Jakarta Sans | 16/24 | 600 | Nama kue (kartu), section |
| `bodyLg` | Plus Jakarta Sans | 16/24 | 400 | Teks utama/deskripsi |
| `bodyMd` | Plus Jakarta Sans | 14/22 | 400 | Metadata, helper |
| `labelMd` | Plus Jakarta Sans | 12/16 | 600 | Badge, label tombol kecil |
| `priceLg` | Plus Jakarta Sans | 18/24 | 700 | Harga (tabular) |

Ukuran minimum teks 12sp. Layout wajib bertahan pada `textScaler` 1.3 dan 2.0.

**Pemuatan font:** `google_fonts` mengambil font saat runtime. Jika first launch
tanpa internet, font fallback sistem dipakai. Keputusan: diterima untuk tahap ini;
bila aplikasi perlu tampil konsisten offline, font harus di-bundle sebagai aset.

### 2.3 Spacing, Radius, Elevation & Sizing

- **Spacing:** `xs=4`, `sm=8`, `md=12`, `lg=16` (padding layar standar), `xl=24`, `xxl=32` (dp).
- **Radius:** `radiusCard=16dp`, `radiusControl=12dp`, `radiusPill=999dp`.
- **Elevation:** `elevationNone=0` (border `borderSubtle` untuk elemen dekoratif);
  `elevationCard` (blur 8, offset (0,2), hitam 5%); `elevationModal` (blur 16,
  offset (0,6), hitam 12%). Maksimal satu lapis shadow per elemen.
- **Touch target:** minimal **48dp** (disarankan 48–52dp).
- **Ikon:** `iconSm=16`, `iconMd=20`, `iconLg=24`.
- **Border:** 1dp untuk kontrol normal, 2dp untuk `focusRing` (`primaryBrandDark`).

---

## 3. Reusable Component Library

### 3.1 Aturan Penggunaan
- Gunakan komponen bersama bila fungsi & perilakunya sama di berbagai layar.
- Komponen khusus (mis. form Custom Cake) wajib tetap memakai token dan standar global.
- Dilarang menduplikasi komponen yang sudah tersedia hanya karena beda halaman.
- **Setiap komponen wajib punya:** anatomi (ukuran/jarak), state, dan label `Semantics`.

### 3.2 Komponen Standar

1. **`AppButton`** — tinggi 48dp, radius 12dp, padding horizontal 16dp, ikon 18dp dengan
   jarak 8dp. Varian `primary` (bg `primaryBrand`, teks `onPrimary`), `secondary` (outline
   `primaryBrand`), `destructive` (bg `errorText`, teks putih), `ghost`.
   State: `normal`, `pressed` (bg `primaryBrandDark`), `disabled` (`disabledBg`/`disabledText`),
   `isLoading` (spinner 18dp, interaksi dinonaktifkan).
2. **`AppTextField` & `AppDropdown`** — tinggi 48dp, radius 12dp, latar `surfaceCard`,
   border `borderControl`; saat fokus border 2dp `primaryBrandDark`. Label di atas,
   pesan error (`errorText`) di bawah, `Semantics` terhubung ke label.
3. **`StatusBadge` & `StockBadge`** — kapsul, ikon 14dp + teks eksplisit. Pemetaan status
   ada di §4.2; ambang stok ada di §4.4. `Semantics`: "Status pesanan: Siap diambil".
4. **`ProductCard`** — radius 16dp, foto 4:3 via `AppImage`, `StockBadge` di sudut kiri
   atas foto, nama maksimal 2 baris (ellipsis), harga `priceLg` (paling menonjol setelah
   foto), kategori `bodyMd`. Stok 0: kartu diredupkan 40% dan aksi pesan dinonaktifkan.
5. **`OrderCard`** — radius 16dp; urutan: `StatusBadge` → tipe pesanan ("Kue siap saji" /
   "Kue custom") → ringkasan item/deskripsi → jadwal ambil lokal → harga → slot aksi
   kontekstual sesuai §4.2.
6. **`AppDialog` & `AppBottomSheet`** — `scrim` 40%, radius 16–24dp, drag handle untuk
   bottom sheet, tombol memenuhi 48dp.
7. **`AppSnackbar`** — varian `success`, `error`, `info`; durasi ±3 detik; tidak dipakai
   untuk error validasi field (gunakan pesan inline).
8. **`AppBottomNavBar`** — tab per role (lihat §8), label teks eksplisit, ikon 24dp,
   badge angka untuk pesanan `pending` (penjual).
9. **`AppImage`** — placeholder skeleton (`surfaceSubtle`) saat memuat, ikon netral saat
   gagal (`errorBuilder`), menerima rasio dan `cacheWidth` agar hemat memori.
10. **`AppEmptyState`, `AppErrorState`, `AppSkeleton`** — state standar: ilustrasi/ikon,
    judul, deskripsi, dan aksi opsional ("Coba lagi").
11. **`AppFilterChip`** — kapsul; state `selected` (bg `primaryBrand`, teks `onPrimary`)
    dan non-aktif (`surfaceSubtle`, teks `textSecondary`).
12. **`AppSectionHeader`** — `titleMd` + aksi teks opsional.

---

## 4. Layout & Business Context

### 4.1 Kepadatan & Breakpoint

| Lebar layar | Katalog | Daftar pesanan |
|---|---|---|
| `< 360dp` | 1 kolom | 1 kolom |
| `360–599dp` | 2 kolom | 1 kolom |
| `≥ 600dp` | 3–4 kolom, konten dibatasi maks. 720dp | 1 kolom, maks. 720dp |

- Mode Pembeli: eksploratif; foto produk dominan.
- Mode Penjual: operasional, satu tangan; baris pesanan mudah dipindai dengan aksi
  satu ketukan.
- Navigasi per role berbeda (lihat §8), tidak dipaksakan seragam.

### 4.2 Status Pesanan (kontrak backend)

Enum kanonik: `pending`, `approved`, `processing`, `ready`, `completed`, `cancelled`,
`rejected`. `cancelled` **tidak pernah** dihasilkan API.

| Status | Ready-stock | Custom | Ikon | Token | Aksi penjual yang valid |
|---|---|---|---|---|---|
| `pending` | Menunggu konfirmasi | Menunggu peninjauan | `schedule` | warning | `approved` / `processing` / `rejected` |
| `approved` | Dikonfirmasi | Harga diajukan | `verified_outlined` | info | `processing` |
| `processing` | Diproses | Diproses | `autorenew` | info | `ready` |
| `ready` | Siap diambil | Siap diambil | `storefront_outlined` | ready | `completed` |
| `completed` | Selesai | Selesai | `task_alt` | success | — |
| `rejected` | Ditolak | Ditolak | `block` | error | — |

Transisi di atas **wajib** dipatuhi UI: jangan menampilkan tombol yang akan ditolak API.
Tidak ada tombol "Batalkan", dan tidak ada aksi "Setujui harga" untuk pembeli.

### 4.3 Batasan Bisnis yang Tampak di UI

- **Satu pesanan = satu kue.** Tidak ada kuantitas, keranjang, atau checkout gabungan.
- `ready_stock` wajib memilih kue; harga disalin dari `cakes.price`; stok berkurang saat
  pesanan dibuat; stok habis → API membalas 400.
- `custom` wajib `custom_description` (5–2000 karakter); `cake_id` dan `agreed_price`
  bernilai null sampai penjual mengisi harga final. Harga hanya untuk pesanan custom, > 0.
- `custom_image_url` hanya URL teks; **tidak ada** unggah referensi dari aplikasi.
- Daftar kue & pesanan **tanpa pagination/pencarian**; filter kategori dilakukan client-side.
- Register hanya membuat akun pembeli; akun penjual disediakan (seed).

### 4.4 Semantik Null & Kosong

| Nilai | Tampilan |
|---|---|
| `stock = null` | "Tersedia" (tanpa batas) |
| `stock = 0` | "Habis" (aksi pesan nonaktif) |
| `stock = 1–5` | "Sisa N" (warning) |
| `stock > 5` | "Tersedia" |
| `agreed_price = null` | "Menunggu harga" — bukan `Rp0` |
| `pickup_date = null` | "Belum dijadwalkan" |
| `image_url = null` | Placeholder `AppImage` |
| `description = null` | Sembunyikan blok deskripsi |

### 4.5 Peta Error API → UI

Bentuk respons: `{ success, message, data }`; validasi 400: `data: [{ field, message }]`.

| Kode | Penyebab | Tindakan UI |
|---|---|---|
| 400 | Validasi / stok habis / transisi status tidak valid | Pesan per-field; error umum via snackbar |
| 401 | Token tidak ada/kedaluwarsa | Hapus sesi → login + "Sesi berakhir" |
| 403 | Role salah / pesanan milik orang lain | Sembunyikan aksi; pesan "Tidak punya akses" |
| 404 | Kue/pesanan tidak ditemukan | Empty state + kembali |
| 409 | Hapus kue yang dipakai pesanan; email terdaftar | Dialog penjelasan |
| 413 | Foto > 2 MB | Pesan ukuran + panduan kompresi |
| 502 | Cloudinary gagal | Snackbar "Gagal mengunggah. Coba lagi." |
| 500 | Kesalahan server | snackbar + "Coba lagi" |

### 4.6 Uang & Waktu

- `price`/`agreed_price` diterima sebagai number (IDR). Format: `Rp75.000`.
  Proyek **belum** memakai paket `intl`; gunakan formatter lokal + unit test, atau
  tambahkan `intl` dengan alasan yang jelas.
- Timestamp dikirim UTC (ISO). Tampilkan waktu lokal perangkat dengan satu format:
  `dd MMM yyyy, HH:mm`.
- Tanggal ambil bersifat opsional; UI menolak tanggal lampau (aturan UI, bukan API).

---

## 5. Interaction & Accessibility

### 5.1 State & Pencegahan Double Submission
- **Skeleton** untuk pemuatan awal; **progress indicator** untuk proses singkat;
  **button loading** untuk submit/ubah status.
- Saat request berjalan, tombol pemicu `isLoading` dan tidak dapat ditekan ulang.
- **Empty state:** ilustrasi + pesan ramah (Indonesia) + aksi opsional.
- **Error jaringan:** pesan jelas + "Coba lagi"; bedakan dengan error validasi.
- **Transisi:** halus dan konsisten; detail durasi di §5.5.

### 5.2 Sesi & Autentikasi
- **Splash:** baca token → `GET /api/auth/me`; sukses → beranda sesuai role; 401 → login.
- **Browse-first:** katalog publik; login diminta saat menekan aksi pesan/ajukan custom.
- **Token kedaluwarsa (401 di mana pun):** hapus sesi, kembali ke login dengan pesan.
- **Logout:** dialog konfirmasi, lalu hapus token dan kembali ke login.
- **Register:** tanpa pemilihan role; teks menjelaskan akun penjual disediakan admin.

### 5.3 Validasi & Input
- Validasi saat **submit** (dan saat blur untuk field panjang); error di bawah field.
- Error 400 dari API dipetakan ke field berdasarkan `field`.
- Aturan mengikuti backend: `name` 2–150; `price` ≥ 0; `stock` bilangan bulat ≥ 0 atau
  kosong (= tanpa batas); `description` ≤ 5000; `custom_description` 5–2000;
  `decoration_note` ≤ 500; password ≥ 6; email format valid.
- Input harga: keyboard angka; tampilkan pemisah ribuan saat tidak fokus.
- Tanggal ambil: date picker, minimum hari ini.

### 5.4 Aksi Destruktif
- Hapus menu wajib dialog konfirmasi ("Hapus [nama]? Tindakan ini tidak bisa dibatalkan.").
- Jika API membalas 409 (kue dipakai pesanan), jelaskan bahwa kue tidak dapat dihapus
  sampai tidak lagi dipakai; jangan menawarkan "hapus paksa".

### 5.5 Motion
- `durationFast=150ms`, `durationBase=250ms`, `curve=easeOutCubic`.
- Hormati `MediaQuery.disableAnimations`; transisi boleh dinonaktifkan.

### 5.6 Accessibility & Responsiveness
- Jangan mengandalkan warna saja; badge selalu ikon + teks.
- `Semantics` untuk tombol ikon dan badge ("Status pesanan: ...").
- Layout bertahan pada `textScaler` 1.3 dan 2.0 tanpa memotong teks penting.
- Gunakan `Expanded`, `Flexible`, `Wrap`, `LayoutBuilder`; jangan mengunci ukuran layar.
- Pull-to-refresh untuk katalog dan daftar pesanan (status bersifat *pull*, tanpa push).

---

## 6. Asset Management

**Inventaris aset dekoratif** (belum tersedia secara fisik):

| File | Rasio | Pemakaian |
|---|---|---|
| `assets/images/banner_custom_cake.png` | 16:9 | Banner ajakan kue custom di katalog |
| `assets/images/empty_catalog.png` | 1:1 | Katalog kosong |
| `assets/images/empty_orders.png` | 1:1 | Riwayat/inbox pesanan kosong |
| `assets/images/product_placeholder.png` | 4:3 | Placeholder produk tanpa foto |

- Gunakan **Material Icons** untuk ikon UI; aset lokal hanya untuk ilustrasi.
- **Build-safe:** jangan mereferensikan path yang belum ada; gunakan placeholder
  bawaan `AppImage` sampai file ditambahkan.
- `AppImage` menangani `loadingBuilder`, `errorBuilder`, rasio, dan `cacheWidth`.
- **Protokol pelaporan:** setiap selesai membuat layar yang membutuhkan aset yang belum
  ada, akhiri laporan dengan:
  > *"Halaman [Nama Halaman] sudah selesai tanpa kendala, hanya saja memerlukan beberapa
  > asset: `assets/images/[nama_file].png` (rasio [X:Y], [deskripsi])."*

---

## 7. AI Implementation Rules

1. **Periksa sebelum membuat:** pakai/perluas komponen yang ada; pisahkan hanya bila
   perilakunya memang berbeda.
2. **Jangan membuat abstraksi prematur:** dilarang wrapper seperti `CustomTitleText`;
   gunakan `Theme.of(context).textTheme` dan token.
3. **Jangan mengubah desain global untuk masalah lokal:** variasi diterapkan sebagai
   konfigurasi lokal layar.
4. **Dilarang mengarang kemampuan API:** fitur/tombol/field harus ada di `backend/src`.
   Jika belum ada, hentikan dan laporkan.
5. **Verifikasi pasca-implementasi:** jalankan `flutter analyze`; pastikan tidak ada
   *layout overflow* pada `textScaler` 1.3 dan 2.0. Bila tidak bisa dijalankan, sebutkan
   alasannya.

**Definition of Done UI:**
- [ ] Semua state layar ada: loading, empty, error, sukses.
- [ ] Tidak ada overflow pada layar kecil dan `textScaler` 2.0.
- [ ] Semua label memakai istilah baku (§9).
- [ ] Semua aksi yang tampil didukung API (§4).
- [ ] Kontras teks & batas kontrol memenuhi §2.1.
- [ ] `flutter analyze` bersih (0 issue).

---

## 8. Daftar Layar & Navigasi

### 8.1 Layar

| Layar | Role | Aksi utama | Endpoint |
|---|---|---|---|
| Login | semua | Masuk | `POST /api/auth/login` |
| Register | publik | Daftar (pembeli) | `POST /api/auth/register` |
| Katalog | publik | Lihat & pilih kue | `GET /api/cakes`, `GET /api/categories` |
| Detail Kue | publik | Mulai pesan | `GET /api/cakes/:id` |
| Form Pesan Ready-Stock | pembeli | Kirim pesanan | `POST /api/orders` (`ready_stock`) |
| Form Custom Cake | pembeli | Kirim permintaan | `POST /api/orders` (`custom`) |
| Riwayat Pesanan | pembeli | Lihat status | `GET /api/orders` |
| Detail Pesanan | pembeli | Pantau status | `GET /api/orders/:id` |
| Menu (Penjual) | penjual | Kelola kue | `GET /api/cakes` |
| Form Menu | penjual | Simpan kue + foto | `POST/PUT /api/cakes`, `POST /api/cakes/:id/image` |
| Inbox Pesanan | penjual | Proses pesanan | `GET /api/orders` |
| Detail Pesanan (Penjual) | penjual | Ubah status / isi harga | `PUT /api/orders/:id/status`, `PUT /api/orders/:id/price` |
| Profil | semua | Lihat akun & logout | `GET /api/auth/me` |

### 8.2 Navigasi per Role
- **Pembeli:** tab Katalog / Pesanan / Profil. Detail & form sebagai halaman stack.
- **Penjual:** tab Menu / Pesanan / Profil. Inbox memakai badge jumlah `pending`.
- Login/Register/Splash tanpa bottom navigation.

---

## 9. Copy & Terminologi

**Istilah baku:** Katalog (bukan Etalase), Menu (khusus penjual), Pesanan (bukan Order),
Kue Custom (bukan Custom Cake di teks UI), Harga Final.

**Label status:** lihat §4.2 (gunakan persis label pada kolom jenis pesanan).

**Tombol:** "Masuk", "Daftar", "Pesan sekarang", "Kirim permintaan custom",
"Simpan menu", "Unggah foto", "Tandai diproses", "Tandai siap", "Selesaikan",
"Tolak pesanan", "Coba lagi".

**Empty state:**
- Katalog kosong: "Belum ada menu. Coba lagi nanti."
- Riwayat kosong: "Belum ada pesanan. Yuk pilih kue di katalog."
- Inbox kosong: "Belum ada pesanan masuk."

**Error:** sebutkan apa yang gagal dan langkah berikutnya; jangan menyalahkan pengguna.
Contoh: "Koneksi terputus. Periksa internet lalu coba lagi."

---

## 10. Governance

- **Versi & perubahan:** catat tanggal dan ringkasan pada header setiap revisi.
- **Prioritas sumber:** lihat bagian atas dokumen.
- **Proses perubahan:** perubahan kontrak API wajib disertai pembaruan `DESIGN.md`
  pada bagian yang terdampak (§4, §8, atau §9).
- **Kepemilikan:** dokumen ini disimpan di `docs/DESIGN.md` dan di-review bersama
  perubahan frontend.
- **Eksklusi** (lihat ruang lingkup) tidak boleh diimplementasikan tanpa perubahan API
  dan pembaruan dokumen ini.
