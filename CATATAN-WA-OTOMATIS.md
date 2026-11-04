# Kirim Otomatis Pengingat WhatsApp ke Semua Tunggakan

Menu **Pengingat Pembayaran** punya panel "Kirim ke Semua Tunggakan" (khusus Bendahara) dengan dua cara:

## A. Antrean Manual (gratis, tanpa gateway, selalu tersedia)
1. Tekan "Mulai Antrean Manual (N)".
2. Untuk tiap siswa: tekan "Buka WhatsApp" (nomor & pesan sudah terisi), tekan Kirim di WhatsApp,
   kembali ke aplikasi, lalu tekan "Sudah Terkirim" (atau "Lewati").
3. Yang ditandai terkirim tercatat untuk hari ini dan tidak muncul lagi di antrean; yang dilewati tetap antre.
4. "Berhenti" kapan saja; ringkasan masuk ke Log Aktivitas. Tidak perlu token apa pun.

## B. Kirim Otomatis (butuh gateway WhatsApp, lihat Pengaktifan di bawah)

## Cara kerja
1. Aplikasi menyusun pesan tiap siswa yang menunggak (template & nomor WA dari Data Siswa).
2. Bendahara menekan "Kirim ke Semua", mencentang persetujuan, lalu "Mulai Kirim".
3. Pesan dikirim SATU PER SATU dari browser dengan jeda acak 8-15 detik ke server (`/rpc/kirim_wa_satu`),
   lalu server meneruskan ke gateway WhatsApp memakai token rahasia.
4. Layar progres menampilkan terkirim/gagal. Siswa tanpa nomor dilewati. Yang sudah terkirim hari ini
   tidak dikirim lagi (dicatat di browser, per hari). Maksimal 100 pesan per proses.
5. Menutup jendela progres atau menekan Hentikan = pengiriman berhenti. Halaman harus tetap terbuka.
6. Ringkasan masuk ke Log Aktivitas.

## Pengaktifan Fonnte (satu kali)
Dicek terhadap dokumentasi resmi Fonnte (docs.fonnte.com) pada 3 November 2026. Tampilan menu di situs
Fonnte bisa berubah; kalau namanya berbeda, cari menu "Device".

### 1. Siapkan akun dan nomor pengirim
1. Daftar di fonnte.com dan masuk ke dashboard.
2. Siapkan SATU nomor WhatsApp khusus pengirim (bukan nomor pribadi/utama sekolah) yang aktif di sebuah HP.
3. Pilih paket sesuai kebutuhan; tiap device punya paket sendiri (cek harga & batas di situs Fonnte).

### 2. Tambah dan hubungkan device
1. Di menu **Device**, klik **Add Device**, isi nama (mis. "SIKasapa") dan nomor WhatsApp pengirim.
2. Klik **Connect**, tunggu kode QR muncul.
3. Di HP pengirim: WhatsApp > **Perangkat tertaut (Linked devices)** > **Tautkan perangkat** > pindai QR.
4. Pastikan status device menjadi **Connected**. HP harus tetap online agar pengiriman berjalan.

### 3. Ambil token device
1. Di daftar device (menu Device), klik token pada device tersebut; token otomatis tersalin.
2. Perlakukan token seperti password: siapa pun yang memegangnya bisa mengirim pesan dari nomor itu.
   Jangan ditempel di chat, kode halaman, atau repositori.

### 4. Simpan token sebagai secret di Cloudflare, lalu deploy
Di folder proyek (sekali `npx wrangler login` bila belum):
```
npx wrangler secret put WA_GATEWAY_TOKEN
npx wrangler deploy
```
Saat diminta, tempel token lalu Enter. Alternatif lewat dashboard Cloudflare: Workers & Pages > `sikasapa` >
Settings > Variables and Secrets > Add > tipe **Secret**, nama `WA_GATEWAY_TOKEN`.
Untuk uji lokal (`npx wrangler dev`): salin `.dev.vars.example` ke `.dev.vars` dan isi tokennya.

### 5. Uji
1. Buka Pengingat Pembayaran. Kotak "Otomatis" harus menampilkan tombol **Kirim Otomatis (N)** dan
   "Kirim pesan tes otomatis ke nomor sendiri".
2. Isi nomor Anda sendiri, tekan **Kirim Tes**. Pastikan pesan masuk ke WhatsApp.
3. Baru setelah itu coba **Kirim Otomatis** ke beberapa siswa dulu sebelum seluruh tunggakan.

### Detail teknis yang dipakai aplikasi (sesuai dokumentasi Fonnte)
- Alamat: `POST https://api.fonnte.com/send` (alamat lama md.fonnte.com sudah usang). Bisa diganti lewat variabel `WA_GATEWAY_URL`.
- Header `Authorization: <token>` TANPA kata "Bearer". Isian form: `target` (nomor, aplikasi mengubah 08... menjadi 62...) dan `message`.
- Balasan sukses berisi `status: true`. Kegagalan berisi `reason`, mis. `device disconnected` atau `target invalid`.

### Kalau gagal
| Pesan | Artinya | Tindakan |
|---|---|---|
| Token gateway WhatsApp belum diatur di server | Secret belum tersimpan / belum deploy | Ulangi langkah 4 |
| device disconnected | HP/WhatsApp terputus dari Fonnte | Connect ulang device (langkah 2) |
| target invalid | Nomor wali salah / tidak terdaftar WhatsApp | Perbaiki nomor di Data Siswa |
| Pengiriman berhenti setelah 5 gagal berturut-turut | Ada masalah umum (token, koneksi, paket) | Periksa dashboard Fonnte lalu coba lagi |

## Catatan penting
- Gateway tidak resmi: nomor pengirim bisa dibatasi/diblokir WhatsApp. Pakai nomor khusus, jangan kirim
  berulang dalam sehari.
- HP pengirim harus tetap online. Kalau device terputus, pengiriman berhenti otomatis.
- Pengiriman terjadwal otomatis (tanpa halaman terbuka) belum ada, karena hitungan tunggakan dilakukan di browser.
- Tombol Kirim per baris (membuka WhatsApp manual) tetap tersedia.

## Riwayat Pengingat per Siswa
- Setiap pengingat yang dikirim (tombol Kirim per baris, Antrean Manual, maupun Kirim Otomatis) dicatat di server
  (tabel `pengingat_log`, dibuat otomatis saat pertama dipakai; `schema.sql` juga sudah memuatnya).
- Tiap baris tunggakan menampilkan "Terakhir diingatkan ... (manual/otomatis) · Nx".
- Penanda "sudah diingatkan hari ini" kini tersimpan di server, jadi berlaku lintas perangkat/browser dan
  tidak terkirim dobel. (Tombol "Reset catatan terkirim" dihapus.)

## Konfirmasi Pembayaran ke WhatsApp Wali
- Di form "Catat Pembayaran Iuran" (hanya saat menambah baru, bukan edit) ada kotak
  "Kirim konfirmasi pembayaran ke WhatsApp wali". Aktif bila nomor WA wali valid; tercentang secara default.
  Isi pesan bisa dilihat lewat "Lihat isi pesan".
- Bila gateway aktif: terkirim otomatis setelah disimpan. Bila belum: WhatsApp terbuka untuk dikirim manual.
- Di daftar Pemasukan ada ikon WhatsApp per transaksi untuk mengirim/ulang kapan saja; ikon berubah hijau
  (centang) kalau konfirmasinya sudah pernah dikirim.
- Isi pesan memakai template bawaan `TEMPLATE_WA_KONFIRMASI` di `script_core.js`
  (placeholder: {namaSiswa} {kelas} {ekskul} {periode} {nominal} {tanggalBayar} {namaSekolah}).
