======================================================================
PANDUAN MENARUH FILE AUDIO NOTIFIKASI SUARA "ANDA MEMASUKI ZONA RAWAN"
======================================================================

1. NAMA FILE & FORMAT:
   - Nama file: zona_rawan.mp3  (atau zona_rawan.wav)
   - Wajib huruf KECIL semua, tanpa spasi, hanya huruf, angka, dan underscore (_).
   - Format yang didukung: MP3, WAV, atau OGG.

2. LOKASI FOLDER:
   - Letakkan file audio Anda tepat di folder ini:
     android/app/src/main/res/raw/zona_rawan.mp3

3. CARA MEMBUAT SUARA "Anda memasuki zona rawan":
   - Opsi A: Rekam suara sendiri melalui HP/PC lalu simpan sebagai zona_rawan.mp3.
   - Opsi B: Gunakan website Text-to-Speech gratis (seperti SoundOfText.com, ttsmaker.com, atau Narakeet), pilih bahasa Indonesia, ketik teks "Anda memasuki zona rawan", lalu unduh dan beri nama zona_rawan.mp3.

4. PENGATURAN KODE FLUTTER:
   - Kode di 'lib/services/notification_service.dart' sudah dikonfigurasikan:
     sound: const RawResourceAndroidNotificationSound('zona_rawan')
   - Saat aplikasi dijalankan dan pengguna masuk ke zona merah/rawan, notifikasi akan langsung membunyikan audio "Anda memasuki zona rawan".
======================================================================
