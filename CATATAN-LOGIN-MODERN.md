# Catatan: halaman login modern + tombol lihat password

## Halaman login (login.html)
- Desain baru: kartu putih di atas latar navy bertekstur halus, sama untuk HP dan desktop.
- Logo ikon, judul "Selamat datang", dan satu baris "SIKasapa · SDN 01 Papahan".
- Deskripsi akun Bendahara/Kepala Sekolah/Guru dihapus. Pengguna tidak perlu
  membaca paragraf petunjuk untuk bisa login.
- Field username dan password memakai ikon, dengan tinggi dan radius yang konsisten.
- Tombol "Masuk" dan link kembali ke halaman wali murid dirapikan.
- ID dan perilaku yang dipakai script_core.js tidak berubah (formLogin, loginUsername,
  loginPassword, loginError, loginScreen).

## Tombol lihat/sembunyikan password (semua field password)
- Helper di script_core.js: `pwWrap()`, `pwEyeBtnHtml()`, dan satu event
  listener delegasi, jadi berlaku juga untuk form yang dirender ulang.
- Dipasang di: login, layar ganti password wajib, Pengaturan (password Bendahara
  dan Kepala Sekolah), serta form akun Guru Ekstrakurikuler.
- Tombol berupa `type="button"` sehingga tidak men-submit form, dan memiliki
  `aria-label` yang berubah sesuai keadaan.

## Pengujian
- Login: pesan error untuk password salah, login benar masuk ke dashboard, tombol mata
  bolak-balik di 360, 390, 412, dan 1280 px.
- Tombol mata di layar ganti password wajib, Pengaturan, dan form Guru.
- E2E 42/42 lulus dari database bersih.

## Pembaruan teks sambutan
- Judul "Selamat datang", lalu "Admin Keuangan Ekstrakurikuler" dan "SDN 01 PAPAHAN"
  (huruf kapital, ukuran lebih besar). Keterangan "Silakan masuk..." dihapus.
- Hanya login.html yang berubah (teks + style `.lg-welcome`, `.lg-school`).

## Data Siswa: Ekspor, Impor, Template (Excel)
- Menu Data Siswa punya tombol Ekspor (.xlsx), Impor, dan Template. Impor & Template hanya untuk Bendahara.
- Kolom: Nama, Kelas, Ekstrakurikuler (pisah dengan `;`), Nama Wali, No. HP Wali, Tanggal Gabung, Status.
- Impor menerima .xlsx/.xls/.csv, menampilkan pratinjau (baru / diperbarui / dilewati + catatan) sebelum disimpan.
- Siswa dengan Nama & Kelas sama diperbarui (ekskul ditambah, tidak ada yang dihapus); ekskul yang tidak dikenal diabaikan.
- Memakai SheetJS (xlsx 0.18.5) dari cdnjs, dimuat di admin.html. Jika gagal dimuat, Ekspor kembali ke CSV.

## Halaman wali murid (index.html) di HP
- Blok biru di atas kini menyerap sisa tinggi layar (isi di tengah), lembar putih form menempel di bawah:
  tidak ada lagi area putih kosong di bawah tombol "Lihat Informasi Pembayaran".
- Tiga keunggulan (Data Aman, Real-time, Tanpa Aplikasi) jadi tiga kartu sama lebar; deskripsi dirapikan (14px, rata-rata 4 baris).
- Layar pendek: deskripsi disembunyikan di tinggi <= 860px, kartu keunggulan di <= 700px, supaya tombol utama selalu
  terlihat di atas navigasi bawah. Hanya CSS HP (< 640px) di index.html yang berubah; tampilan desktop/tablet tetap.
