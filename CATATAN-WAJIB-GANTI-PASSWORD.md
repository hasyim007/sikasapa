# Catatan: wajib ganti username & password default

Akun default sekarang:
- Bendahara: `admin` / `admin`
- Kepala Sekolah: `kepsek` / `admin` (username harus beda dari Bendahara)

Saat login pertama dengan akun default, aplikasi hanya menampilkan layar
"Ganti Username & Password". Menu dan data tidak dikirim sama sekali sampai
penggantian berhasil. Password lama `sikasapa123` / `kepsek123` sudah tidak
berlaku.

## Berkas yang diubah

- `schema.sql`: kolom baru `wajib_ganti_bendahara` & `wajib_ganti_kepsek`;
  seed akun default diganti ke `admin`/`admin` dengan flag wajib = 1.
- `schema.sql`: kedua kolom sudah termasuk di definisi tabel (instalasi baru dari nol).
- `src/index.js`:
  - `login()` mengembalikan `wajibGantiPassword`.
  - `dispatchRpc()` menolak semua RPC untuk akun yang masih wajib ganti,
    kecuali daftar `RPC_BEBAS_GERBANG` (login, logout, RPC publik, dan
    `ganti_password_wajib`). Daftarnya default-tolak: rute baru ikut
    terkunci otomatis.
  - RPC baru `ganti_password_wajib`. Saat berhasil, semua sesi lain milik
    peran yang sama dicabut, supaya sesi yang dibuat dengan password default
    tidak ikut hidup.
- `public/script_core.js`:
  - Password default dihapus dari `seedDB()` (sebelumnya tertulis sebagai
    teks biasa di JS publik).
  - `fetchDBFromServer()` mengenali `WAJIB_GANTI_PASSWORD` (bukan dianggap
    sesi tidak valid, jadi tidak logout paksa).
  - `initAdminPage()` menampilkan layar penggantian bila diminta server.
- `public/admin.html`: markup layar penggantian (di luar `#app`, jadi sidebar
  dan menu tetap tersembunyi).
- `public/login.html`: satu kalimat petunjuk.
- `PANDUAN.md`: kredensial default baru.

## Aturan penggantian

- Username baru: minimal 4 karakter, tidak boleh `admin` atau `kepsek`
  (sesuai akun), tidak boleh sama dengan akun lain, dan tidak boleh bentrok
  dengan username Guru Ekstra.
- Password baru: minimal 6 karakter, tidak boleh `admin`, dan tidak boleh
  sama dengan username.
- Aturan ini dicek di server. Pengecekan di browser hanya umpan balik cepat.

## Cara memulai

Instalasi baru: jalankan `schema.sql`, set `PASSWORD_PEPPER`, lalu deploy.
Tidak ada file migrasi.

## Catatan keamanan

- Default `admin` / `admin` tertulis di repo, jadi siapa pun bisa mencobanya.
  Sampai pemilik mengganti kredensial, siapa yang login duluan akan
  mendapat layar penggantian. Lakukan penggantian segera setelah deploy.
- Password tidak pernah masuk ke log aktivitas.

## Pengujian

Sudah diuji otomatis terhadap SQLite dan handler Worker yang sebenarnya:
install baru, gerbang server di semua RPC yang dilindungi, validasi
username/password, pencabutan sesi, akun guru (tidak terpengaruh), dan
instalasi baru dari schema.sql.
Layar penggantian di browser belum diuji secara langsung; perlu dicoba
sekali setelah deploy.
