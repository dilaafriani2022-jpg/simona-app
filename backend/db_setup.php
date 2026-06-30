<?php
$host = "localhost";
$user = "root";
$pass = "";

// 1. Connect without db to create it if not exists
$conn = new mysqli($host, $user, $pass);
if ($conn->connect_error) {
    die("Koneksi gagal: " . $conn->connect_error . "\nPastikan MySQL (XAMPP/Laragon) Anda sudah aktif.");
}

$conn->query("CREATE DATABASE IF NOT EXISTS monak_db");
$conn->select_db("monak_db");

echo "Database 'monak_db' siap!\n";

// 2. Create tables
$tables = [
    "users" => "CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        role ENUM('operator', 'kepsek', 'guru', 'orang_tua') NOT NULL,
        username VARCHAR(50) UNIQUE,
        nip VARCHAR(20) UNIQUE,
        nisn VARCHAR(20) UNIQUE,
        email VARCHAR(100) UNIQUE,
        password VARCHAR(255) NOT NULL,
        no_telp VARCHAR(20),
        pekerjaan VARCHAR(100),
        alamat TEXT,
        
        -- Parent-specific columns
        ayah_nama VARCHAR(100) DEFAULT NULL,
        ayah_nik VARCHAR(20) DEFAULT NULL,
        ayah_ttl VARCHAR(100) DEFAULT NULL,
        ayah_agama VARCHAR(30) DEFAULT NULL,
        ayah_pendidikan VARCHAR(50) DEFAULT NULL,
        ayah_pekerjaan VARCHAR(100) DEFAULT NULL,
        ayah_penghasilan VARCHAR(50) DEFAULT NULL,
        ayah_hp VARCHAR(20) DEFAULT NULL,
        ibu_nama VARCHAR(100) DEFAULT NULL,
        ibu_nik VARCHAR(20) DEFAULT NULL,
        ibu_ttl VARCHAR(100) DEFAULT NULL,
        ibu_agama VARCHAR(30) DEFAULT NULL,
        ibu_pendidikan VARCHAR(50) DEFAULT NULL,
        ibu_pekerjaan VARCHAR(100) DEFAULT NULL,
        ibu_penghasilan VARCHAR(50) DEFAULT NULL,
        ibu_hp VARCHAR(20) DEFAULT NULL,
        wali_nama VARCHAR(100) DEFAULT NULL,
        wali_hubungan VARCHAR(50) DEFAULT NULL,
        wali_pekerjaan VARCHAR(100) DEFAULT NULL,
        wali_hp VARCHAR(20) DEFAULT NULL,
        rt_rw VARCHAR(20) DEFAULT NULL,
        kelurahan VARCHAR(100) DEFAULT NULL,
        kecamatan VARCHAR(100) DEFAULT NULL,
        kota VARCHAR(100) DEFAULT NULL,
        provinsi VARCHAR(100) DEFAULT NULL,
        kode_pos VARCHAR(10) DEFAULT NULL,
        
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )",
    "tahun_ajaran" => "CREATE TABLE IF NOT EXISTS tahun_ajaran (
        id INT AUTO_INCREMENT PRIMARY KEY,
        tahun VARCHAR(20) NOT NULL,
        status ENUM('aktif', 'nonaktif') DEFAULT 'aktif'
    )",
    "kelas" => "CREATE TABLE IF NOT EXISTS kelas (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nama_kelas VARCHAR(50) NOT NULL,
        id_tahun_ajaran INT,
        FOREIGN KEY (id_tahun_ajaran) REFERENCES tahun_ajaran(id) ON DELETE SET NULL
    )",
    "anak" => "CREATE TABLE IF NOT EXISTS anak (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nama_anak VARCHAR(100) NOT NULL,
        nisn VARCHAR(20) UNIQUE,
        jenis_kelamin ENUM('L', 'P'),
        tanggal_lahir DATE,
        alamat TEXT,
        id_kelas INT,
        id_ortu INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_kelas) REFERENCES kelas(id) ON DELETE SET NULL,
        FOREIGN KEY (id_ortu) REFERENCES users(id) ON DELETE SET NULL
    )",
    "aspek_penilaian" => "CREATE TABLE IF NOT EXISTS aspek_penilaian (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nama_aspek VARCHAR(100) NOT NULL,
        deskripsi TEXT DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )",
    "sekolah" => "CREATE TABLE IF NOT EXISTS sekolah (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nama_sekolah VARCHAR(150) NOT NULL,
        npsn VARCHAR(20) UNIQUE,
        jenjang VARCHAR(50),
        `status` VARCHAR(50),
        alamat TEXT,
        kelurahan VARCHAR(100),
        kecamatan VARCHAR(100),
        kabupaten VARCHAR(100),
        kota_kabupaten VARCHAR(100),
        provinsi VARCHAR(100),
        kode_pos VARCHAR(10),
        no_telp VARCHAR(20),
        telepon VARCHAR(20),
        email VARCHAR(100),
        website VARCHAR(100),
        kepala_sekolah VARCHAR(100),
        operator_nama VARCHAR(100),
        nip_kepala_sekolah VARCHAR(20),
        visi TEXT,
        misi TEXT,
        logo_url VARCHAR(255),
        tahun_berdiri YEAR,
        akreditasi VARCHAR(10),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )"
];

foreach ($tables as $name => $sql) {
    if ($conn->query($sql)) {
        echo "Tabel '$name' berhasil disiapkan!\n";
    } else {
        echo "Gagal membuat tabel '$name': " . $conn->error . "\n";
    }
}

// 3. Seed users if empty
$checkUsers = $conn->query("SELECT id FROM users LIMIT 1");
if ($checkUsers->num_rows == 0) {
    $pass_admin = password_hash('password123', PASSWORD_BCRYPT);
    $pass_guru = password_hash('guru123', PASSWORD_BCRYPT);
    $pass_kepsek = password_hash('kepsek123', PASSWORD_BCRYPT);
    $pass_ortu = password_hash('ortu123', PASSWORD_BCRYPT);

    $conn->query("INSERT INTO users (name, role, username, password) VALUES ('Admin Operator', 'operator', 'admin', '$pass_admin')");
    $conn->query("INSERT INTO users (name, role, nip, password) VALUES ('Budi Santoso', 'guru', '123456789', '$pass_guru')");
    $conn->query("INSERT INTO users (name, role, email, password) VALUES ('H. Ahmad', 'kepsek', 'kepsek@school.id', '$pass_kepsek')");
    $conn->query("INSERT INTO users (name, role, nisn, password) VALUES ('Wali Murid Ani', 'orang_tua', '9988776655', '$pass_ortu')");
    echo "Seed data user berhasil dimasukkan!\n";
}

// 4. Seed tahun_ajaran if empty
$checkTA = $conn->query("SELECT id FROM tahun_ajaran LIMIT 1");
if ($checkTA->num_rows == 0) {
    $conn->query("INSERT INTO tahun_ajaran (tahun, status) VALUES ('2023/2024', 'aktif')");
    $conn->query("INSERT INTO tahun_ajaran (tahun, status) VALUES ('2024/2025', 'nonaktif')");
    echo "Seed data tahun ajaran berhasil dimasukkan!\n";
}

// 5. Seed kelas if empty
$checkKelas = $conn->query("SELECT id FROM kelas LIMIT 1");
if ($checkKelas->num_rows == 0) {
    $conn->query("INSERT INTO kelas (nama_kelas, id_tahun_ajaran) VALUES ('Kelompok A', 1), ('Kelompok B', 1)");
    echo "Seed data kelas berhasil dimasukkan!\n";
}

// 6. Seed aspek if empty
$checkAspek = $conn->query("SELECT id FROM aspek_penilaian LIMIT 1");
if ($checkAspek->num_rows == 0) {
    $conn->query("INSERT INTO aspek_penilaian (nama_aspek, deskripsi) VALUES 
        ('Agama & Moral', 'Perkembangan nilai agama dan moral anak usia dini'),
        ('Fisik Motorik', 'Kemampuan gerak kasar dan gerak halus anak'),
        ('Kognitif', 'Kemampuan memecahkan masalah, berpikir logis, dan mengenal konsep lambang bilangan')");
    echo "Seed data aspek penilaian berhasil dimasukkan!\n";
}

// 7. Seed anak if empty
$checkAnak = $conn->query("SELECT id FROM anak LIMIT 1");
if ($checkAnak->num_rows == 0) {
    $conn->query("INSERT INTO anak (nama_anak, nisn, jenis_kelamin, tanggal_lahir, alamat, id_kelas, id_ortu) VALUES 
        ('Ani Wijaya', '12345678', 'P', '2019-08-12', 'Jl. Sudirman No. 45', 1, 4),
        ('Budi Pratama', '87654321', 'L', '2019-03-24', 'Jl. Merdeka No. 12', 1, 4)");
    echo "Seed data anak berhasil dimasukkan!\n";
}

$conn->close();
echo "Migrasi & Seeding Database Selesai!\n";
?>
