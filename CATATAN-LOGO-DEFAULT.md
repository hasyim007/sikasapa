# Catatan: logo default SIKasapa

Logo `SIKASAPA_Education_Finance_Logo.png` menjadi logo bawaan di seluruh aplikasi.
Bila Bendahara belum mengunggah logo sendiri, aplikasi memakai logo ini.

## Aset

- `public/assets/logo-full.png` — logo lengkap (800 px, 256 warna). Dipakai di hero login (mobile).
- `public/assets/logo-icon.png` — ikon persegi (192 px) dari topi toga, grafik, dan koin.
  Dipakai di sidebar admin, kartu login, dan crest halaman publik.
- `public/assets/logo-default.js` — ikon yang sama sebagai data URL (`LOGO_DEFAULT_DATAURL`).
  Disematkan supaya tersedia seketika untuk cetakan (jendela print dicetak setelah 300 ms,
  tidak sempat menunggu gambar dimuat) dan untuk PDF.
- `public/favicon.ico` (16/32/48 px), `public/favicon-32.png`, `public/apple-touch-icon.png` (180 px).

## Berkas yang diubah

- `public/script_core.js`
  - `logoLaporanAktif(pg)` / `logoWebAktif(pg)`: pakai logo unggahan, atau logo default bila kosong.
  - Lima cetakan HTML dan tiga pemanggilan PDF memakai helper di atas.
  - Crest header publik dan pratinjau Halaman Publik memakai logo default.
  - Panel Logo Laporan & Logo Web menampilkan logo default bila belum ada unggahan.
  - Pesan hapus logo menyebut bahwa logo bawaan dipakai.
- `public/index.html`, `public/login.html`, `public/admin.html`: favicon, pemuatan `logo-default.js`,
  dan penggantian ikon dompet bawaan dengan logo.
- `PANDUAN.md`: catatan logo bawaan.

## Tidak perlu migrasi

Kolom `logo` dan `publikLogo` tetap `NULL` secara default. Tampilan logo bawaan terjadi di sisi
aplikasi, jadi database tidak berubah.

## Pengujian

- Dijalankan di Chromium dengan server lokal yang memakai Worker sebenarnya dan SQLite:
  logo termuat di crest halaman publik, hero login mobile, kartu login, sidebar admin,
  pratinjau Halaman Publik, panel Logo Laporan, dan cetakan laporan.
- Data URL logo default terbukti menjadi gambar valid.
- Belum diuji: PDF jsPDF (pustaka tidak tersedia offline). Jalur kodenya sama dengan
  cetakan HTML.
