# Setup dan Troubleshooting Monak App

## Persyaratan
- XAMPP atau Laragon sudah terinstall
- MySQL/MariaDB sudah aktif (port 3306)
- PHP versi 7.4 atau lebih baru

## Langkah Setup

### 1. Pastikan MySQL Sudah Berjalan
- Buka XAMPP Control Panel
- Pastikan **MySQL** dalam status "Running"
- Jika belum, klik tombol "Start" di samping MySQL

### 2. Inisialisasi Database
Buka browser dan akses:
```
http://localhost/monak/backend/db_setup.php
```

Anda akan melihah pesan berupa:
```
Database 'monak_db' siap!
Tabel 'users' berhasil disiapkan!
Tabel 'tahun_ajaran' berhasil disiapkan!
...
Migrasi & Seeding Database Selesai!
```

**Catatan**: Jika mendapat error, pastikan MySQL sudah aktif di XAMPP

### 3. Test Koneksi Login
Akses endpoint ini di browser:
```
http://localhost/monak/backend/login.php
```

Jika sudah setup, silakan test login dengan data default:

**Akun Operator:**
- Username: `admin`
- Password: `password123`

**Akun Guru:**
- NIP: `123456789`
- Password: `guru123`

**Akun Kepala Sekolah:**
- Email: `kepsek@school.id`
- Password: `kepsek123`

**Akun Orang Tua:**
- NISN: `9988776655`
- Password: `ortu123`

### 4. Jalankan Flutter App
```bash
flutter pub get
flutter run
```

Atau untuk web:
```bash
flutter run -d chrome
```

## Troubleshooting

### Error: "Database connection failed"
- Pastikan MySQL sudah aktif di XAMPP
- Cek konfigurasi di `backend/config.php`
- Pastikan database `monak_db` sudah dibuat dengan menjalankan `db_setup.php`

### Error: "User not found"
- Pastikan Anda sudah menjalankan `db_setup.php` terlebih dahulu
- Gunakan username/NIP/NISN/email yang benar sesuai data seed

### Error: "Incorrect password"
- Cek kembali password yang Anda masukkan
- Password default sudah tersedia di bagian "Akun Default" di atas

### Error: "Connection Error" di Flutter App
- Pastikan API URL di `lib/services/api_service.dart` sudah benar
- Untuk localhost: `http://127.0.0.1/monak/backend`
- Untuk Android Emulator: `http://10.0.2.2/monak/backend`
- XAMPP harus running di port 80 (default)

### Error CORS di Browser Developer Console
- Ini normal dan sudah ditangani di `backend/cors.php`
- Pastikan semua file backend sudah diupdate dengan CORS headers

## Struktur File Backend
```
backend/
├── config.php              # Konfigurasi database
├── cors.php                # CORS headers
├── db_setup.php            # Setup database & seed data
├── login.php               # Endpoint login
├── auth_helper.php         # Helper authentication
├── add_user.php            # Tambah user
├── update_user.php         # Update user (baru)
├── delete_user.php         # Hapus user
├── get_users.php           # List users
├── get_dashboard_stats.php # Dashboard stats
└── manage_*.php            # Endpoint manajemen data lainnya
```

## Reset Database
Jika ingin reset ulang semua data:
1. Login ke PhpMyAdmin di `http://localhost/phpmyadmin`
2. Drop database `monak_db`
3. Jalankan `db_setup.php` lagi
