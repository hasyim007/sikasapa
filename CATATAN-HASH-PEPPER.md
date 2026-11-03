# Catatan: hashing password dengan pepper (paket gratis)

## Masalah

Hash PBKDF2-SHA256 dengan 100.000 iterasi memakan sekitar 19 ms CPU per verifikasi
di mesin uji. Batas CPU Workers Free per request menurut dokumentasi Cloudflare
(yang saya ingat, belum dicek ulang online) adalah 10 ms. Akibatnya login bisa
gagal dengan error CPU limit.

## Solusi

- **Hash baru**: `hmac1$<salt>$<mac>`, dengan `mac = HMAC-SHA256(PASSWORD_PEPPER, salt || password)`.
  Pepper adalah secret Worker (`npx wrangler secret put PASSWORD_PEPPER`) dan
  tidak tersimpan di database.
- **Akun default** (`admin`/`admin`, `kepsek`/`admin`) disimpan dengan `password_hash = NULL`.
  Login menerima password default hanya selama flag wajib-ganti masih aktif
  (`cekPasswordAkun()`). Setelah diganti, hash HMAC tersimpan dan flag mati.
- **Hash PBKDF2 tidak lagi diverifikasi.** Instalasi baru dari `schema.sql` tidak
  pernah punya hash PBKDF2, jadi tidak ada yang perlu dimigrasikan.

## Hasil ukur (mesin uji, bukan Cloudflare)

| | Sebelum | Sesudah |
|---|---|---|
| Verifikasi password | PBKDF2 100k: ~19 ms | HMAC: ~0,12 ms |
| Login RPC (median, termasuk query D1 tiruan + JSON) | ~19 ms+ | 0,57 ms (p95 1,75 ms) |

Angka di Cloudflare belum diukur, karena tidak ada akses jaringan. Pengukuran
pertama setelah deploy tetap perlu dilakukan.

## Kenapa ini aman untuk kasus ini (dan batasnya)

- **Database bocor saja**: hash tidak bisa ditebak tanpa pepper, karena pepper
  tidak ada di database.
- **Tebakan online**: dibatasi `login_fails` (5 percobaan gagal lalu terkunci
  12 menit per username).
- **Batasnya**: kalau database DAN pepper sama-sama bocor, tebakan offline cepat
  karena HMAC tidak dirancang lambat. Password minimal 6 karakter membuat risiko
  itu lebih besar. Kalau Anda ingin memperkecil risiko ini, naikkan minimum
  password menjadi 8 karakter (client dan server).
- **Pepper hilang**: semua hash tidak bisa diverifikasi. Solusinya reset semua
  akun. Pada instalasi baru: `npm run db:reset:remote`, yang menghapus SEMUA data,
  jadi pastikan belum ada data penting.

## Yang harus dilakukan sebelum deploy

1. `npx wrangler secret put PASSWORD_PEPPER` (string acak panjang). Tanpa ini,
   penggantian password gagal dengan pesan "PASSWORD_PEPPER belum diset".
2. Instalasi baru: `npm run db:schema:remote`, lalu `npm run deploy`.

## Pengujian

- `test_pepper.mjs`: 8 tes. Akun default bisa masuk tanpa pepper; password lain
  ditolak; akun default tidak berlaku lagi setelah flag mati; penggantian tanpa
  pepper gagal dengan pesan jelas; pepper salah ditolak; isi database tidak memuat
  password atau pepper; guru tanpa hash tidak bisa login.
- Tes sebelumnya diperbarui ke format baru: 45 tes unit, 42 skenario E2E di
  Chromium, semua lulus.
- Belum diuji: pepper dan CPU di Workers sungguhan.
