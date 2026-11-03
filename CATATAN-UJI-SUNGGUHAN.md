# Catatan: hasil uji sungguhan

## Yang diuji di Chromium sungguhan (Playwright)

Server uji memakai `src/index.js` yang sebenarnya dan database SQLite dari
`schema.sql` yang baru (akun default admin/admin). Yang dicek: 42 skenario, lulus semua.

- Login default -> layar wajib ganti; aplikasi (#app) tidak tampil dan menu kosong.
- Bypass dari browser: save_all, get_app_data, dan ambil_nomor_dokumen ditolak server.
- Validasi di browser (HTML5 dan JS) dan validasi server (pesan "akun lain" dari server).
- Penggantian sah -> aplikasi terbuka dan menu Bendahara muncul.
- Sesi kedua milik akun yang sama dicabut setelah penggantian.
- Kredensial lama (admin/admin) ditolak; kredensial baru langsung masuk.
- Keluar dari layar wajib ganti -> sesi lokal dihapus.
- Kepala Sekolah: layar wajib ganti, menu terbatas, tidak bisa menyimpan.
- Cetakan laporan: logo default termuat; kop tiga baris rata kiri-kanan
  (jarak antarkata melebar, kata pertama dan terakhir menempel tepi).
- Halaman publik: crest memakai logo; og:image absolut mengikuti host; gambar
  og:image bisa diunduh (200, PNG, 1200x630); favicon bisa diunduh;
  User-Agent WhatsApp menerima og:image yang sama.
- Tidak ada JS error di halaman yang diuji.

## Perbaikan dari uji sungguhan

- Layar wajib ganti di mobile tampak kelabu: body mobile berlatar navy.
  Wrapper layar diberi latar terang yang sama dengan desktop.
- Ikon shield di layar wajib ganti diganti logo SIKasapa agar tidak bergantung pada lucide.

## Belum bisa diuji di lingkungan ini

- `wrangler deploy` ke Cloudflare (tidak ada akses jaringan).
- Perilaku asli Cloudflare: `run_worker_first` untuk "/" dan "/index.html",
  redirect /index.html -> / oleh ASSETS (html_handling), dan D1 sungguhan
  (diuji dengan SQLite).
- PDF jsPDF (pustaka tidak tersedia di disk).
- Chart.js dan lucide (dimuat dari CDN; di sini memakai stub).
- Pratinjau WhatsApp sungguhan (hanya diuji header dan User-Agent).

## Risiko CPU (sudah diatasi)

PBKDF2 100.000 iterasi memakan ~19 ms CPU di mesin uji, di atas batas 10 ms
per request Workers Free. Sudah diganti dengan HMAC-SHA256 + pepper: login
median 0,57 ms. Lihat `CATATAN-HASH-PEPPER.md`.
