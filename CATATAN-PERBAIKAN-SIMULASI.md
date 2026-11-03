# Catatan perbaikan hasil simulasi (input siswa -> cetak)

Berkas diubah: `public/script_core.js`, `src/index.js` (hanya get_public_data: tambah tanggalGabung). Tanpa migrasi SQL.

1. Laporan cetak: kolom Rincian Pemasukan & Rekap Status kini mencakup bulan PERIODE yang dibayar
   (`rentangBulanMatriks()`), jadi tabel selalu cocok dengan Total Pemasukan.
2. Paste massal siswa: mendukung pemisah TAB (copy dari Excel/Sheets); ada peringatan bila kelas kosong.
3. Tunggakan: Tanggal Gabung tidak lagi diabaikan setelah ada pembayaran pertama (dipakai yang lebih awal).
4. Popup cetak diblokir (HP/in-app browser): tampil pesan jelas, dan tidak ada nomor dokumen terbuang
   (pengecekan dilakukan sebelum nomor diambil dari server). 5 fungsi cetak.
5. Halaman wali murid: bulan sebelum siswa bergabung = "Belum Aktif", bulan belum tiba = "Belum Jatuh Tempo";
   keduanya tidak dihitung "Belum Dibayar".
6. Validasi: nominal maks Rp 100.000.000 (pemasukan & pengeluaran); tanggal bayar tidak boleh masa depan.
7. Siswa dari paste massal kini diberi Tanggal Gabung hari ini (sama dengan form); Rekap Per Pertemuan hanya
   menghitung pertemuan yang sudah lewat.
Tambahan: nilai kop/pengguna/kelas di dokumen cetak kini di-escape HTML (22 titik).

Efek samping yang perlu diketahui: angka Tunggakan siswa lama bisa bertambah (bulan sebelum pembayaran pertama
sekarang ikut ditagih bila Tanggal Gabung diisi lebih awal).
