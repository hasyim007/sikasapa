# Catatan: kop surat rata kiri-kanan (justify) otomatis

Semua baris kop di cetakan sekarang dibentangkan ke lebar baris kop
terpanjang, jadi blok kop tampil rata kiri dan kanan tanpa pengaturan manual.

Berlaku untuk:
- HTML: kwitansi, lembar presensi (cetak & gabungan), laporan & laporan gabungan.
- PDF: lembar presensi (unduh) dan header laporan/gabungan (pita biru).

## Berkas yang diubah

- `public/script_core.js`
  - `kopHtml()`: wrapper dengan `text-align-last: justify`.
  - `gambarKopPdf()` (baru): menggambar kop di jsPDF dengan jarak antarkata
    yang dihitung dari lebar blok. Baris satu kata tetap biasa.
  - `unduhPresensiAbsensiPdf()` dan `gambarHeaderLaporanPdf()` memakai helper ini.
    Pada pita laporan, lebar kop dikurangi lebar teks "Tahun Ajaran" dan periode
    di sisi kanan (diukur, bukan ditebak).

## Catatan perilaku

Baris pendek yang hanya beberapa kata (mis. "SDN 01 Papahan") ikut
direntangkan sampai selebar baris terpanjang, sehingga jarak antarkatanya
menjadi lebar. Kalau tidak diinginkan, kop bisa dibatasi hanya pada baris
yang panjangnya mendekati baris terpanjang.
