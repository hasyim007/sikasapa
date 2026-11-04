-- =========================================================
-- SIKasapa — Skema database Cloudflare D1 (SQLite)
-- Jalankan sekali (setelah `npx wrangler d1 create sikasapa-db` &
-- database_id sudah diisi di wrangler.toml) lewat:
--   npx wrangler d1 execute sikasapa-db --remote --file=./schema.sql
-- (atau: npm run db:schema:remote)
--
-- ARSITEKTUR — SATU proyek Cloudflare Worker untuk semuanya:
-- Frontend statis (folder public/) & backend (src/index.js) di-deploy
-- bersamaan lewat satu `npx wrangler deploy`. Semua akses data dari
-- browser HANYA lewat rute /rpc/<nama> di src/index.js (9 fungsi:
-- login, logout, get_app_data, get_public_data, get_public_riwayat,
-- save_all, restore_backup, ambil_nomor_dokumen, catat_log_cetak).
-- D1 sendiri tidak pernah diakses langsung dari browser — hanya
-- Worker yang punya binding ke database ini.
--
-- FILE (logo, bukti pengeluaran): TIDAK PAKAI R2/object storage sama
-- sekali. Gambar disimpan LANGSUNG sebagai data URL base64 di kolom
-- TEXT (pengaturan.logo, pengaturan.publik_logo, pengeluaran.bukti),
-- dikirim & diterima sebagai bagian dari save_all()/restore_backup()
-- biasa. Browser mengecilkan gambar (resize + kompres JPEG) dulu
-- sebelum disimpan, supaya tetap di bawah batas ukuran 1 baris D1
-- (2.000.000 byte) — lihat kompresGambar() di public/script_core.js.
--
-- Mau reset bersih dari nol? Jalankan
-- drop-schema.sql dulu, baru file ini lagi (atau: npm run db:reset:remote).
-- =========================================================

CREATE TABLE IF NOT EXISTS ekskul (
  id TEXT PRIMARY KEY,
  nama TEXT NOT NULL,
  pembina TEXT DEFAULT '',
  jenis_pembayaran TEXT DEFAULT 'pertemuan',
  tarif REAL DEFAULT 0,
  hari_jadwal TEXT DEFAULT '[]',
  warna TEXT DEFAULT '#1769D1',
  -- Tautan OPSIONAL ke ekstra_absensi.id — dipakai supaya satu jenis
  -- ekstrakurikuler tidak perlu diinput dobel di "Data Ekstrakurikuler"
  -- (iuran) DAN "Kelola Absensi" (kehadiran) secara terpisah tanpa
  -- relasi. Kalau diisi:
  --  1) Peserta ekstra_absensi terkait OTOMATIS mengikuti peserta
  --     ekskul ini (siswa.ekstra_absensi_ids disinkronkan tiap kali
  --     siswa.ekskul_ids berubah — lihat syncPesertaAbsensiDariEkskul()
  --     di public/script_core.js), jadi tidak ada lagi 2 daftar peserta
  --     yang bisa nyasar diam-diam.
  --  2) Untuk ekskul jenis_pembayaran='pertemuan', estimasi Tunggakan
  --     memakai data kehadiran SEBENARNYA dari tabel absensi (status
  --     'hadir' saja yang dianggap wajib bayar; izin/sakit/alpa tidak
  --     ditagih) — lihat hitungEstimasiTunggakanPertemuan().
  -- NULL = ekskul ini berdiri sendiri, tidak ada absensi digital
  -- (perilaku lama, estimasi tetap murni dari jadwal hari).
  -- Sengaja TIDAK diberi FOREIGN KEY di level kolom (supaya ALTER TABLE
  -- tidak perlu rebuild tabel saat skema berubah) — validitasnya dijaga di
  -- application code (submitEkskul() & deleteEkstraAbsensi() di
  -- public/script_core.js) dan dibersihkan manual saat ekstra_absensi
  -- terkait dihapus.
  ekstra_absensi_id TEXT DEFAULT NULL,
  -- Aktivasi bulan (menu "Aktivasi Bulan & Libur") — JSON object, HANYA
  -- berisi entri untuk bulan yang DINONAKTIFKAN, mis.
  -- {"7":{"aktif":false,"alasan":"Libur Semester"}}. Bulan yang tidak
  -- ada di sini dianggap AKTIF (perilaku default). Dipakai supaya
  -- Informasi Pembayaran publik bisa menampilkan alasan (mis. "Libur
  -- Semester") alih-alih stempel "Belum Dibayar" untuk bulan yang
  -- memang sengaja tidak ditagih — lihat renderKalenderEkstra() &
  -- cariInfoPembayaranPublik() di public/script_core.js.
  bulan_aktif TEXT DEFAULT '{}',
  -- Hari libur ekstra KHUSUS ekstrakurikuler ini (menu "Aktivasi Bulan &
  -- Libur") — JSON array objek {"tanggal":"YYYY-MM-DD","keterangan":"..."}.
  -- Dulu satu pengaturan global (lihat pengaturan.hari_libur di bawah,
  -- sekarang legacy/tidak dipakai UI lagi) — dipindah jadi per jenis
  -- ekstrakurikuler supaya tiap ekstra bisa punya kalender liburnya
  -- sendiri. Dipakai tanggalPertemuanBulan() untuk mengecualikan
  -- pertemuan dari Estimasi Tunggakan Per Pertemuan & Cetak Presensi.
  hari_libur TEXT DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS siswa (
  id TEXT PRIMARY KEY,
  nama TEXT NOT NULL,
  kelas TEXT DEFAULT '',
  ekskul_ids TEXT DEFAULT '[]',
  aktif INTEGER DEFAULT 1,
  wali_nama TEXT DEFAULT '',
  wali_hp TEXT DEFAULT '',
  -- Daftar id ekstra_absensi yang diikuti siswa ini — TERPISAH dari
  -- ekskul_ids (ekskul yang ada pembayarannya). Satu siswa bisa ikut
  -- ekskul berbayar & ekstra absensi-saja sekaligus, atau salah satunya.
  ekstra_absensi_ids TEXT DEFAULT '[]',
  -- Tanggal siswa ini mulai wajib bayar iuran (semua ekskul yang
  -- diikutinya, tidak per-ekskul — lihat catatan di
  -- tanggalMulaiTerdeteksiBulanan()/tanggalMulaiTerdeteksi() di
  -- script_core.js). NULL = belum diisi manual; kalau siswa juga belum
  -- pernah punya riwayat pembayaran/absensi, sistem cuma menganggap dia
  -- nunggak bulan berjalan saja (supaya tidak salah tagih siswa yang
  -- memang baru gabung). Diisi otomatis = tanggal hari ini saat siswa
  -- BARU ditambahkan; untuk siswa yang sudah ada sebelum kolom ini ada
  -- tetap NULL sampai diisi manual satu-satu atau lewat
  -- "Isi Tanggal Gabung Massal" di menu Data Siswa.
  tanggal_gabung TEXT DEFAULT NULL
);

-- =========================================================
-- MODUL ABSENSI EKSTRAKURIKULER (guru ekstra) — SENGAJA terpisah dari
-- tabel `ekskul` (yang ada iuran/pembayarannya). Sekolah bisa punya
-- ekstrakurikuler yang cuma butuh absensi tanpa iuran kas, jadi
-- daftar jenisnya dikelola sendiri di sini oleh Bendahara lewat menu
-- "Kelola Absensi". Guru ekstra hanya login untuk mengisi absensi,
-- TIDAK bisa melihat data keuangan sama sekali (lihat getGuruData()
-- di src/index.js — responsnya sengaja dibatasi).
-- =========================================================
CREATE TABLE IF NOT EXISTS ekstra_absensi (
  id TEXT PRIMARY KEY,
  nama TEXT NOT NULL,
  keterangan TEXT DEFAULT '',
  warna TEXT DEFAULT '#1769D1',
  -- Jadwal hari latihan (format sama seperti ekskul.hari_jadwal, mis.
  -- '["Jumat","Sabtu"]') — dipakai untuk menghitung tanggal pertemuan
  -- bulanan supaya menu "Kelola Absensi" bisa mencetak Presensi Absensi
  -- yang sinkron dengan absensi yang sudah diisi guru (lihat
  -- tanggalPertemuanBulan() & cetakPresensiAbsensiJalankan() di
  -- public/script_core.js).
  hari_jadwal TEXT DEFAULT '[]'
);

-- Akun login guru ekstra — dibuat oleh Bendahara lewat menu Pengaturan.
-- Satu guru bisa diberi akses ke lebih dari satu jenis ekstra_absensi.
CREATE TABLE IF NOT EXISTS guru_ekstra (
  id TEXT PRIMARY KEY,
  nama TEXT NOT NULL,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  ekstra_ids TEXT DEFAULT '[]',
  aktif INTEGER DEFAULT 1
);

-- Kehadiran GURU EKSTRA itu sendiri (guru pembina hadir/tidak pada satu
-- ekstra, satu tanggal) — SENGAJA tabel terpisah dari `absensi` (siswa) di
-- bawah supaya alurnya jelas: guru WAJIB mengisi baris ini dulu (lewat RPC
-- simpan_absensi_guru_sendiri()) sebelum server mengizinkan dia menyimpan
-- absensi siswa untuk ekstra & tanggal yang sama — dicek di
-- simpanAbsensiGuru() (src/index.js). id dibuat DETERMINISTIK
-- (`abg_<ekstraId>_<tanggal>`) supaya mengisi ulang tanggal yang sama
-- otomatis menimpa (upsert), bukan dobel — sama seperti pola id di
-- `absensi`. guru_nama disimpan sebagai SALINAN (snapshot) di kolom
-- terpisah supaya kehadiran guru tetap bisa dicetak di lembar presensi
-- walau akun guru_ekstra yang mengisi sudah dihapus (guru_id ON DELETE
-- SET NULL, sama alasannya seperti siswa_id di tabel `absensi`).
CREATE TABLE IF NOT EXISTS absensi_guru (
  id TEXT PRIMARY KEY,
  ekstra_id TEXT REFERENCES ekstra_absensi(id) ON DELETE CASCADE,
  guru_id TEXT REFERENCES guru_ekstra(id) ON DELETE SET NULL,
  guru_nama TEXT DEFAULT '',
  tanggal TEXT NOT NULL,
  status TEXT DEFAULT 'hadir',
  catatan TEXT DEFAULT ''
);

-- Satu baris = kehadiran satu siswa pada satu ekstra, satu tanggal.
-- id dibuat DETERMINISTIK (lihat simpanAbsensiGuru() di src/index.js:
-- `ab_<ekstraId>_<tanggal>_<siswaId>`) supaya mengisi ulang absensi hari
-- yang sama otomatis menimpa (upsert), bukan dobel.
CREATE TABLE IF NOT EXISTS absensi (
  id TEXT PRIMARY KEY,
  ekstra_id TEXT REFERENCES ekstra_absensi(id) ON DELETE CASCADE,
  siswa_id TEXT REFERENCES siswa(id) ON DELETE SET NULL,
  tanggal TEXT NOT NULL,
  status TEXT DEFAULT 'hadir',
  catatan TEXT DEFAULT '',
  dicatat_oleh TEXT DEFAULT ''
);

-- siswa_id sengaja ON DELETE SET NULL (bukan CASCADE) — riwayat
-- pembayaran harus TETAP ADA (untuk Total Saldo & laporan) walau
-- siswanya sudah dihapus dari data induk, cuma namanya jadi "-".
-- Lihat deleteSiswa()/tandaiHapus() di script_core.js dan bug
-- terkait yang dijelaskan panjang lebar di CATATAN-PERBAIKAN.md
-- (bug itu sudah diperbaiki di skema Supabase yang jadi dasar file
-- ini, jadi versi D1 ini langsung memakai desain yang sudah benar).
CREATE TABLE IF NOT EXISTS pemasukan (
  id TEXT PRIMARY KEY,
  siswa_id TEXT REFERENCES siswa(id) ON DELETE SET NULL,
  ekskul_id TEXT REFERENCES ekskul(id) ON DELETE CASCADE,
  jenis TEXT DEFAULT 'pertemuan',
  periode TEXT DEFAULT '',
  nominal REAL DEFAULT 0,
  tanggal_bayar TEXT DEFAULT '',
  keterangan TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS pengeluaran (
  id TEXT PRIMARY KEY,
  ekskul_id TEXT REFERENCES ekskul(id) ON DELETE CASCADE,
  kategori TEXT DEFAULT '',
  nominal REAL DEFAULT 0,
  tanggal TEXT DEFAULT '',
  keterangan TEXT DEFAULT '',
  bukti TEXT
);

CREATE TABLE IF NOT EXISTS kategori_pengeluaran (
  kategori TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS aktivitas (
  id TEXT PRIMARY KEY,
  waktu TEXT NOT NULL,
  user TEXT DEFAULT '',
  role TEXT DEFAULT '',
  aksi TEXT DEFAULT '',
  detail TEXT DEFAULT ''
);

-- Satu baris saja (id selalu 1) — setara tabel pengaturan Supabase.
CREATE TABLE IF NOT EXISTS pengaturan (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  tahun_ajaran TEXT DEFAULT '2026/2027',
  logo TEXT,
  kepala_sekolah TEXT DEFAULT '',
  nip_kepsek TEXT DEFAULT '',
  bendahara TEXT DEFAULT '',
  nip_bendahara TEXT DEFAULT '',
  username TEXT DEFAULT 'bendahara',
  password_hash TEXT,
  nama_kepsek_akun TEXT DEFAULT '',
  username_kepsek TEXT DEFAULT 'kepsek',
  password_kepsek_hash TEXT,
  -- 1 = akun ini masih memakai username/password DEFAULT dan WAJIB diganti
  -- saat login pertama. Selama 1, server (dispatchRpc() di src/index.js)
  -- menolak semua aksi kecuali logout & ganti_password_wajib. Diset ke 0
  -- oleh gantiPasswordWajib() setelah penggantian berhasil.
  wajib_ganti_bendahara INTEGER NOT NULL DEFAULT 0,
  wajib_ganti_kepsek INTEGER NOT NULL DEFAULT 0,
  publik_nama_web TEXT DEFAULT 'SIKASAPA',
  publik_logo TEXT,
  publik_tagline TEXT DEFAULT 'Sistem Informasi Keuangan Ekstrakurikuler',
  -- Konten hero halaman publik (menu admin "Halaman Publik") — dulu semua
  -- ini hardcode di public/index.html, sekarang bisa diubah Bendahara.
  -- publik_deskripsi KOSONG = pakai kalimat bawaan (lihat
  -- renderPublicScreenContent() di script_core.js) yang otomatis
  -- menyisipkan nama sekolah dari kop_lines baris pertama.
  publik_eyebrow TEXT DEFAULT 'Layanan Wali Murid',
  publik_headline1 TEXT DEFAULT 'Pembayaran',
  publik_headline2 TEXT DEFAULT 'Ekstrakurikuler',
  publik_deskripsi TEXT DEFAULT '',
  publik_chip1 TEXT DEFAULT 'Data Aman & Resmi Sekolah',
  publik_chip2 TEXT DEFAULT 'Hasil Real-time',
  publik_chip3 TEXT DEFAULT 'Tanpa Perlu Aplikasi',
  kop_lines TEXT DEFAULT '[{"text":"SDN 01 Papahan","size":14,"bold":true}]',
  -- Nomor urut dokumen resmi (Laporan & Kwitansi), per tahun,
  -- format JSON mis. {"2026": 7} — lihat ambilNomorDokumen() di
  -- src/index.js.
  nomor_laporan_counter TEXT DEFAULT '{}',
  nomor_kwitansi_counter TEXT DEFAULT '{}',
  -- LEGACY — tidak lagi diatur lewat UI mana pun (dipindah jadi per
  -- ekstrakurikuler, lihat ekskul.hari_libur di atas). Kolom ini
  -- dibiarkan ada supaya kode lama tidak error, tapi
  -- isinya sudah tidak dibaca oleh tampilan manapun.
  hari_libur TEXT DEFAULT '[]',
  -- Template pesan WhatsApp untuk menu "Pengingat Pembayaran" — diatur
  -- bebas oleh Bendahara di menu itu sendiri. Placeholder yang dikenali
  -- (diganti di script_core.js/susunPesanPengingat()): {namaSiswa},
  -- {waliNama}, {kelas}, {ekskul}, {daftarBulan}, {totalTunggakan},
  -- {jumlahPertemuanKurang}, {namaSekolah}.
  template_wa_bulanan TEXT DEFAULT 'Assalamu''alaikum Bapak/Ibu wali dari ananda {namaSiswa} ({kelas}), mohon izin mengingatkan bahwa iuran ekstrakurikuler {ekskul} untuk bulan {daftarBulan} sebesar {totalTunggakan} belum kami terima. Kami mohon kesediaan Bapak/Ibu untuk berkenan melakukan pembayaran secepatnya. Atas perhatian dan kerja samanya, kami ucapkan terima kasih. Wassalamu''alaikum warahmatullahi wabarakatuh.',
  template_wa_pertemuan TEXT DEFAULT 'Assalamu''alaikum Bapak/Ibu wali dari ananda {namaSiswa} ({kelas}), mohon izin mengingatkan bahwa iuran ekstrakurikuler {ekskul} per pertemuan masih kurang {jumlahPertemuanKurang}x pertemuan (estimasi {totalTunggakan}) pada bulan {daftarBulan}. Kami mohon kesediaan Bapak/Ibu untuk berkenan melakukan pembayaran secepatnya. Atas perhatian dan kerja samanya, kami ucapkan terima kasih. Wassalamu''alaikum warahmatullahi wabarakatuh.'
);

CREATE TABLE IF NOT EXISTS sessions (
  token TEXT PRIMARY KEY,
  role TEXT NOT NULL,
  -- Diisi HANYA untuk sesi guru ekstra (id baris guru_ekstra yang
  -- login) — dipakai server memvalidasi guru itu cuma boleh menyimpan
  -- absensi untuk ekstra yang memang ditugaskan ke dia. NULL untuk
  -- sesi Bendahara/Kepala Sekolah. Lihat cekSesi()/login() di src/index.js.
  ref_id TEXT,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);

-- Rate-limit login di server: kunci akun 12 menit setelah 5x gagal
-- berturut-turut (sama seperti versi Supabase yang sudah diperbaiki).
CREATE TABLE IF NOT EXISTS login_fails (
  username TEXT PRIMARY KEY,
  fails INTEGER NOT NULL DEFAULT 0,
  locked_until INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------
-- ISI AWAL (akun default) — hanya kalau tabel memang masih kosong.
--
-- Akun default:
--   - Bendahara        : username 'admin'  / password 'admin'
--   - Kepala Sekolah   : username 'kepsek' / password 'admin'
--   (username harus berbeda antar akun, jadi hanya Bendahara yang bernama 'admin'.)
--
-- Password default TIDAK disimpan sebagai hash: password_hash dibiarkan NULL.
-- Login menerima password default hanya selama wajib_ganti_* = 1 (lihat
-- cekPasswordAkun() di src/index.js). Setelah penggantian, hash HMAC tersimpan
-- dan flag mati. Dengan begitu tidak ada hash yang bergantung pada pepper saat
-- database dibuat.
-- ---------------------------------------------------------
INSERT INTO pengaturan (id, username, password_hash, username_kepsek, password_kepsek_hash, bendahara, nama_kepsek_akun, wajib_ganti_bendahara, wajib_ganti_kepsek)
SELECT 1,
  'admin', NULL,
  'kepsek', NULL,
  'Bendahara', 'Kepala Sekolah', 1, 1
WHERE NOT EXISTS (SELECT 1 FROM pengaturan WHERE id = 1);

INSERT INTO kategori_pengeluaran (kategori)
SELECT column1 FROM (
  VALUES ('Peralatan'), ('Transport Lomba'), ('Konsumsi'),
         ('Seragam'), ('Piala/Penghargaan'), ('Lainnya')
)
WHERE NOT EXISTS (SELECT 1 FROM kategori_pengeluaran LIMIT 1);

-- Riwayat pengingat / konfirmasi WhatsApp per siswa. Tabel ini juga dibuat
-- otomatis oleh Worker saat pertama dipakai, jadi blok ini opsional.
CREATE TABLE IF NOT EXISTS pengingat_log (
  id TEXT PRIMARY KEY,
  waktu TEXT NOT NULL,
  siswa_id TEXT NOT NULL,
  ekskul_id TEXT,
  jenis TEXT NOT NULL,   -- 'pengingat' | 'konfirmasi'
  cara TEXT NOT NULL,    -- 'manual' | 'otomatis'
  ref_id TEXT,           -- id pemasukan (untuk konfirmasi pembayaran)
  user TEXT
);
CREATE INDEX IF NOT EXISTS idx_pengingat_log_siswa ON pengingat_log(siswa_id, waktu);
