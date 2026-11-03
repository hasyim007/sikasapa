# Catatan: pratinjau link (Open Graph) otomatis mengikuti domain

Saat link halaman publik dibagikan di WhatsApp/Facebook, pratinjau menampilkan
logo SIKasapa, judul, dan deskripsi. Alamat gambarnya mengikuti domain yang sedang
dipakai (`*.workers.dev` maupun domain sekolah), tanpa pengaturan apa pun.

## Cara kerja

- Crawler WhatsApp tidak menjalankan JavaScript, jadi tag `og:image` harus ada di
  HTML dari server. `public/index.html` menulis alamatnya dengan placeholder
  `__BASE_URL__`.
- `src/index.js` (`halamanPublik()`) mengganti placeholder itu dengan origin request
  yang sedang dilayani. Origin ini diambil dari request, bukan dari konfigurasi.
- `wrangler.toml`: `run_worker_first` ditambah `/` dan `/index.html` agar halaman publik
  diproses Worker. Asset lain tetap dilayani langsung dari `public/`.

## Berkas yang diubah

- `src/index.js`: fungsi `halamanPublik()` dan rute `/` & `/index.html`. Rute `/health`
  tetap JSON, dan `/` tidak lagi dianggap health check (dulu tidak pernah tercapai).
- `wrangler.toml`: `run_worker_first` dan komentarnya.
- `public/index.html`: meta `description`, `og:*`, dan `twitter:*`.
- `public/assets/og-image.png` (baru): gambar pratinjau 1200×630, logo di tengah
  kanvas putih (rasio yang dipakai WhatsApp & Facebook).
- Aset logo dibangun ulang dari sumber dengan latar putih murni (sebelumnya sekitar
  254, sehingga tampak seperti bingkai tipis). Ukuran file ikut turun.

## Pengujian

- 12 tes unit: origin mengikuti beberapa domain (termasuk port & IP), redirect
  `/index.html` diteruskan, header cache, HEAD, User-Agent WhatsApp, `/health`, dan `/rpc`.
- Harness lokal dengan Worker sebenarnya: `og:image` berubah sesuai header Host.
- Belum diuji: `wrangler deploy` (CLI tidak tersedia offline). Validasi TOML sudah
  dilakukan. Setelah deploy, cek `https://<domain>/` dengan Facebook Sharing Debugger
  atau kirim link ke diri sendiri di WhatsApp.
