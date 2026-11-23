# SweetCraft — Brief UI/UX

Dokumen ini menjelaskan SweetCraft dari sudut pandang UI/UX, untuk dibagikan kepada
desainer (manusia atau AI) yang akan merancang antarmuka aplikasi Flutter.

Acuan: `docs/laporan_proyek_sweetcraft.md`, `docs/techstack.md`, `backend/schema.sql`,
dan implementasi API yang sudah berjalan (`backend/src`).

---

## 1. Produk ini apa

Aplikasi mobile (Flutter) untuk toko kue UMKM yang menjual **dua jenis barang dengan
perilaku berbeda**:

1. **Kue siap saji (ready-stock)** — seperti etalase: stok terbatas, harga pasti,
   dipesan langsung.
2. **Custom cake pre-order** — seperti konsultasi: pembeli mengirim referensi desain
   dan preferensi, penjual meninjau, lalu menetapkan harga.

Masalah yang diselesaikan: pemesanan custom toko kue biasanya berantakan di WhatsApp —
foto referensi tercecer, kesepakatan harga tidak terdokumentasi, dan pembeli tidak tahu
status pengerjaan.

**Konsekuensi desain:** ini bukan e-commerce biasa. Ada dua mode transaksi dengan ritme
berbeda — satu *self-service instan*, satu *negosiasi terkurasi*.

---

## 2. Dua pengguna, dua mental model

| | **Pembeli** (customer) | **Penjual** (pemilik toko) |
|---|---|---|
| Konteks pakai | santai, ponsel, sering sambil browsing | sibuk, di dapur/toko, satu tangan, cepat |
| Tujuan utama | "Saya mau kue untuk acara X" | "Pesanan mana yang harus saya kerjakan?" |
| Emosi yang diinginkan | percaya, tergoda, tenang | terkendali, tidak ada yang terlewat |
| Frekuensi | sesekali, intens saat ada acara | harian, berulang |

Implikasi: aplikasi yang sama, tetapi **navigasi dan kepadatan informasi berbeda per
role**. Jangan memaksa satu layout untuk keduanya.

---

## 3. Peta fitur → layar (sesuai backend yang ada)

### Pembeli

- Login / Register → katalog (grid kue: foto, nama, harga, kategori, badge stok)
- Detail kue → form pesan ready-stock: **catatan ucapan/dekorasi**, tanggal ambil
  (satu pesanan = satu kue)
- Form **Custom Cake**: deskripsi preferensi (wajib, min. 5 karakter), catatan dekorasi,
  tanggal ambil, slot foto referensi
- **Riwayat pesanan**: kartu pesanan + status, filter status, detail (harga final,
  catatan)
- Profil / logout

### Penjual

- Login → **Menu**: daftar kue + tambah/ubah/hapus + upload foto
- **Pesanan masuk**: semua pesanan, filter status; untuk custom: baca referensi →
  **isi harga final**
- **Update status produksi** per pesanan
- Profil / logout

---

## 4. Tiga alur utama

### A. Ready-stock (cepat)

Katalog → pilih kue → tulis ucapan → tanggal ambil → pesan → status
"Menunggu konfirmasi" → penjual proses → siap → selesai.

Target UX: dari lihat ke checkout < 60 detik, tanpa mengulang data akun.

### B. Custom cake (perlu kepercayaan)

Katalog (CTA "Buat Kue Custom") → form spesifikasi + foto referensi → kirim →
penjual tinjau → penjual ajukan harga → pembeli lihat harga → produksi → siap → selesai.

Target UX: pembeli merasa "permintaan saya dipahami", bukan mengisi formulir birokrasi.

### C. Penjual mengelola (efisien)

Daftar pesanan (urut terbaru) → buka detail → ubah status satu ketukan → untuk custom
isi harga.

Target UX: satu tangan, target sentuh besar, minim salah tekan.

---

## 5. Batasan nyata dari backend

Penting agar desain tidak menjanjikan hal yang belum ada.

| Batasan | Dampak desain |
|---|---|
| Register **selalu** membuat akun pembeli; akun penjual disediakan (seed) | Di layar register **jangan** ada pilihan role. Login tidak menawarkan "daftar sebagai penjual" |
| Status order: `pending, approved, processing, ready, completed, rejected` (`cancelled` tidak dipakai) | 6 status perlu label manusiawi. **Tidak ada tombol batal** |
| Transisi status hanya dilakukan penjual | Pembeli hanya melihat, tidak mengubah status |
| `approved` dipakai di dua alur | Label bisa ambigu: ready-stock ≈ "dikonfirmasi", custom ≈ "harga diajukan". Desainer perlu memutuskan representasinya |
| **Belum ada endpoint "pembeli menyetujui harga"** | Alur laporan menyebut "pembeli setuju dengan penawaran", tetapi API belum punya aksinya. Jangan desain tombol "Setuju harga" dulu, atau tandai sebagai usulan fitur |
| `custom_image_url` masih berupa **URL teks**; endpoint upload referensi custom belum ada | Form custom: siapkan slot foto secara visual, tetapi fungsinya belum tersedia. Bisa ditandai "segera hadir" atau dialihkan ke tautan |
| Upload foto menu: jpg/png/webp, **maks 2 MB** | Beri panduan crop/kompresi; tampilkan error yang jelas |
| `stock` NULL = **tanpa batas**, 0 = habis | Badge: "Tersedia", "Sisa N", "Habis", "Pre-order" — bukan sekadar angka |
| Harga dikirim sebagai number (IDR) | Format `Rp75.000`; tampilkan jelas "harga final" hanya untuk custom |
| `pickup_date` dikirim sebagai ISO UTC | Tampilkan dalam waktu lokal perangkat; hindari kebingungan jam |
| Daftar kue & pesanan **tanpa pagination** | Rancang empty state & list yang nyaman; jangan berasumsi infinite scroll dari server |
| Tidak ada push notification; pembaruan status bersifat **pull** | Sediakan affordance refresh yang jelas (pull-to-refresh) dan ekspektasi realistis |
| Katalog `GET` bersifat publik | Putuskan: *browse first* atau *login wall* |
| Tidak ada `seller_id` pada kue | Satu toko saja; jangan desain multi-toko/vendor |

---

## 6. Arah visual & interaksi yang disarankan

- **Tone**: hangat, handmade, "toko kue rumahan yang rapi" — bukan startup SaaS, bukan
  mewah. Foto produk jadi bintang; UI menyingkir.
- **Tipografi**: `google_fonts` tersedia; pilih satu display font lembut + satu sans
  yang sangat terbaca untuk harga/status.
- **Warna status** (konsisten): menunggu = netral/kuning, dikonfirmasi/diproses = biru,
  siap = hijau/teal, selesai = hijau tua, ditolak = merah.
- **Hierarki kartu kue**: foto → nama → harga (paling menonjol setelah foto) →
  kategori → status stok.
- **Form custom**: pecah menjadi 2 langkah (Spesifikasi → Jadwal & Referensi) agar
  tidak terasa seperti formulir panjang.
- **Aksesibilitas**: target sentuh ≥ 48dp, kontras teks ≥ 4.5:1, teks bisa diperbesar
  tanpa rusak, jangan mengandalkan warna saja untuk status.
- **State wajib**: loading (skeleton), kosong ("Belum ada pesanan — yuk pilih kue"),
  error jaringan (pesan + tombol coba lagi), sukses (feedback jelas).
- **Bahasa**: Indonesia, sapaan netral-hangat; hindari istilah teknis di UI.

Akun demo untuk eksplorasi:

| Email | Password | Role |
|---|---|---|
| `penjual@example.com` | `penjual123` | penjual |
| `pembeli@example.com` | `pembeli123` | pembeli |

---

## 7. Pertanyaan terbuka untuk didiskusikan

1. Apakah katalog bisa dibuka sebelum login, atau langsung login wall?
2. Bagaimana menampilkan `approved` agar tidak membingungkan di dua jenis pesanan?
3. Untuk custom cake tanpa upload referensi: tampilkan slot "segera hadir", atau
   sembunyikan dulu?
4. Apakah penjual butuh layar ringkasan harian sebelum daftar pesanan, atau langsung
   daftar?
5. Berapa banyak status ditampilkan sekaligus, atau disederhanakan menjadi 3 tahap
   visual (Diterima → Diproses → Selesai)?
6. Apakah harga final custom perlu penanda "menunggu persetujuan pembeli" secara
   visual, mengingat aksinya belum ada di API?

---

## 8. Prompt siap tempel untuk AI desainer

> Kamu adalah Senior UI/UX Designer. Desain aplikasi mobile Flutter bernama SweetCraft
> untuk toko kue UMKM dengan dua role: Pembeli dan Penjual. Pembeli menjelajah katalog
> kue siap saji (foto, harga, stok terbatas; stok null = tak terbatas) dan mengajukan
> custom cake (deskripsi preferensi wajib, catatan dekorasi, tanggal ambil, slot foto
> referensi yang belum aktif di API). Penjual mengelola menu (CRUD + upload foto maks
> 2 MB), meninjau pesanan custom, mengisi harga final, dan mengubah status:
> pending → approved/processing/rejected → ready → completed. Pembeli hanya melihat
> status (pull-to-refresh, tanpa notifikasi) dan tidak punya aksi batal atau menyetujui
> harga. Register hanya untuk pembeli; akun penjual disediakan. Tantangan utama:
> memisahkan pengalaman "belanja cepat" dan "negosiasi custom" tanpa membingungkan,
> serta membuat status yang sama (`approved`) bermakna jelas di dua jenis pesanan.
> Berikan: arsitektur informasi, wireframe per layar, design token
> (warna/tipografi/spacing), komponen status, dan catatan aksesibilitas.
> Bahasa UI: Indonesia.
