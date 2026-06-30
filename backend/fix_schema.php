<?php
header("Content-Type: application/json");
require_once 'config.php';

// Add missing columns
$columns_to_add = [
    "name" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(100) DEFAULT 'Unknown' AFTER id",
    "email" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(100) UNIQUE AFTER username",
    "nip" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS nip VARCHAR(20) UNIQUE AFTER username",
    "nisn" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS nisn VARCHAR(20) UNIQUE AFTER nip",
    "pekerjaan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS pekerjaan VARCHAR(100) AFTER alamat",
    "anak_created_at" => "ALTER TABLE anak ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
    "aspek_created_at" => "ALTER TABLE aspek_penilaian ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
    "ayah_nama" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ayah_nama VARCHAR(100) DEFAULT NULL",
    "ayah_nik" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ayah_nik VARCHAR(20) DEFAULT NULL",
    "ayah_ttl" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ayah_ttl VARCHAR(100) DEFAULT NULL",
    "ayah_agama" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ayah_agama VARCHAR(30) DEFAULT NULL",
    "ayah_pendidikan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ayah_pendidikan VARCHAR(50) DEFAULT NULL",
    "ayah_pekerjaan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ayah_pekerjaan VARCHAR(100) DEFAULT NULL",
    "ayah_penghasilan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ayah_penghasilan VARCHAR(50) DEFAULT NULL",
    "ayah_hp" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ayah_hp VARCHAR(20) DEFAULT NULL",
    "ibu_nama" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ibu_nama VARCHAR(100) DEFAULT NULL",
    "ibu_nik" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ibu_nik VARCHAR(20) DEFAULT NULL",
    "ibu_ttl" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ibu_ttl VARCHAR(100) DEFAULT NULL",
    "ibu_agama" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ibu_agama VARCHAR(30) DEFAULT NULL",
    "ibu_pendidikan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ibu_pendidikan VARCHAR(50) DEFAULT NULL",
    "ibu_pekerjaan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ibu_pekerjaan VARCHAR(100) DEFAULT NULL",
    "ibu_penghasilan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ibu_penghasilan VARCHAR(50) DEFAULT NULL",
    "ibu_hp" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS ibu_hp VARCHAR(20) DEFAULT NULL",
    "wali_nama" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS wali_nama VARCHAR(100) DEFAULT NULL",
    "wali_hubungan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS wali_hubungan VARCHAR(50) DEFAULT NULL",
    "wali_pekerjaan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS wali_pekerjaan VARCHAR(100) DEFAULT NULL",
    "wali_hp" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS wali_hp VARCHAR(20) DEFAULT NULL",
    "rt_rw" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS rt_rw VARCHAR(20) DEFAULT NULL",
    "kelurahan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS kelurahan VARCHAR(100) DEFAULT NULL",
    "kecamatan" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS kecamatan VARCHAR(100) DEFAULT NULL",
    "kota" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS kota VARCHAR(100) DEFAULT NULL",
    "provinsi" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS provinsi VARCHAR(100) DEFAULT NULL",
    "kode_pos" => "ALTER TABLE users ADD COLUMN IF NOT EXISTS kode_pos VARCHAR(10) DEFAULT NULL",
];

foreach ($columns_to_add as $col_name => $sql) {
    if ($conn->query($sql)) {
        echo "✓ Kolom '$col_name' berhasil ditambahkan atau sudah ada\n";
    } else {
        echo "✗ Error pada kolom '$col_name': " . $conn->error . "\n";
    }
}

// Update username to be name for existing users
$conn->query("UPDATE users SET name = username WHERE name = 'Unknown' AND username IS NOT NULL");

// Add sample orang_tua data if not exists
$check = $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'orang_tua'")->fetch_assoc();
if ($check['count'] == 0) {
    $pass_ortu = password_hash('pass123', PASSWORD_BCRYPT);
    $conn->query("INSERT INTO users (name, username, role, password, email, no_telp, pekerjaan, alamat) VALUES 
        ('Ibu Siti (Wali Ani)', 'wali_ani', 'orang_tua', '$pass_ortu', 'ibu.siti@email.com', '081234567890', 'Guru', 'Jl. Sudirman No. 45, Bengkalis'),
        ('Pak Ahmad (Wali Budi)', 'wali_budi', 'orang_tua', '$pass_ortu', 'pak.ahmad@email.com', '081987654321', 'Karyawan Swasta', 'Jl. Merdeka No. 12, Bengkalis')");
    echo "✓ Sample orang_tua data berhasil ditambahkan\n";
}

echo "\n✓ Schema update selesai!";
$conn->close();
?>
