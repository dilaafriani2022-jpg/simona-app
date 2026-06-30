<?php
header("Content-Type: application/json");
require_once 'config.php';

echo "=== Creating Guru Feature Tables ===\n\n";

// 1. Tabel Penilaian Checklist
$sql_penilaian = "CREATE TABLE IF NOT EXISTS penilaian_checklist (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_anak INT NOT NULL,
    id_guru INT NOT NULL,
    id_aspek INT NOT NULL,
    tanggal DATE NOT NULL,
    status ENUM('Belum Berkembang', 'Mulai Berkembang', 'Berkembang', 'Berkembang Sangat Baik') DEFAULT 'Belum Berkembang',
    catatan TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
    FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (id_aspek) REFERENCES aspek_penilaian(id) ON DELETE CASCADE
)";

// 2. Tabel Anekdot (Observations)
$sql_anekdot = "CREATE TABLE IF NOT EXISTS anekdot (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_anak INT NOT NULL,
    id_guru INT NOT NULL,
    tanggal DATE NOT NULL,
    waktu TIME NOT NULL,
    peristiwa TEXT NOT NULL,
    interpretasi TEXT,
    tindak_lanjut TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
    FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE
)";

// 3. Tabel Karya (Work/Portfolio)
$sql_karya = "CREATE TABLE IF NOT EXISTS karya_anak (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_anak INT NOT NULL,
    id_guru INT NOT NULL,
    judul VARCHAR(255) NOT NULL,
    deskripsi TEXT,
    tanggal DATE NOT NULL,
    kategori ENUM('Seni', 'Kerajinan', 'Tulis', 'Konstruksi', 'Musik', 'Lainnya') DEFAULT 'Lainnya',
    url_foto VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
    FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE
)";

// 4. Tabel Absensi
$sql_absensi = "CREATE TABLE IF NOT EXISTS absensi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_anak INT NOT NULL,
    id_guru INT NOT NULL,
    tanggal DATE NOT NULL,
    status ENUM('Hadir', 'Sakit', 'Izin', 'Alpa') DEFAULT 'Hadir',
    keterangan TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_attendance (id_anak, tanggal),
    FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
    FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE
)";

// 5. Tabel Jadwal Anak (Student Schedule)
$sql_jadwal = "CREATE TABLE IF NOT EXISTS jadwal_kelas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_kelas INT NOT NULL,
    id_guru INT NOT NULL,
    hari ENUM('Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat') NOT NULL,
    jam_mulai TIME NOT NULL,
    jam_selesai TIME NOT NULL,
    kegiatan VARCHAR(255) NOT NULL,
    ruangan VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_kelas) REFERENCES kelas(id) ON DELETE CASCADE,
    FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE
)";

$tables = [
    'penilaian_checklist' => $sql_penilaian,
    'anekdot' => $sql_anekdot,
    'karya_anak' => $sql_karya,
    'absensi' => $sql_absensi,
    'jadwal_kelas' => $sql_jadwal
];

foreach ($tables as $name => $sql) {
    if ($conn->query($sql)) {
        echo "✓ Tabel '$name' berhasil disiapkan\n";
    } else {
        echo "✗ Error tabel '$name': " . $conn->error . "\n";
    }
}

// Seed sample data if tables are empty
echo "\n=== Seeding Sample Data ===\n\n";

// Seed jadwal if empty
$check = $conn->query("SELECT COUNT(*) as count FROM jadwal_kelas")->fetch_assoc();
if ($check['count'] == 0) {
    $jadwal_queries = [
        "INSERT INTO jadwal_kelas (id_kelas, id_guru, hari, jam_mulai, jam_selesai, kegiatan, ruangan) VALUES 
         (1, 2, 'Senin', '08:00', '09:00', 'Seni Rupa', 'Ruang Seni'),
         (1, 2, 'Selasa', '08:00', '09:00', 'Musik', 'Ruang Musik'),
         (1, 2, 'Rabu', '08:00', '10:00', 'Olahraga', 'Lapangan'),
         (1, 2, 'Kamis', '09:00', '10:00', 'Bahasa Inggris', 'Ruang Kelas A'),
         (1, 2, 'Jumat', '08:00', '09:00', 'Ekskul Tari', 'Aula')"
    ];
    foreach ($jadwal_queries as $q) {
        $conn->query($q);
    }
    echo "✓ Sample jadwal data berhasil ditambahkan\n";
}

// Seed penilaian if empty
$check = $conn->query("SELECT COUNT(*) as count FROM penilaian_checklist")->fetch_assoc();
if ($check['count'] == 0) {
    $conn->query("INSERT INTO penilaian_checklist (id_anak, id_guru, id_aspek, tanggal, status, catatan) VALUES 
    (1, 2, 1, DATE(NOW()), 'Berkembang Sangat Baik', 'Sangat baik dalam pemahaman moral'),
    (1, 2, 2, DATE(NOW()), 'Berkembang', 'Kemampuan motorik halus berkembang'),
    (3, 2, 1, DATE(NOW()), 'Mulai Berkembang', 'Perlu bimbingan lebih')");
    echo "✓ Sample penilaian data berhasil ditambahkan\n";
}

// Seed anekdot if empty
$check = $conn->query("SELECT COUNT(*) as count FROM anekdot")->fetch_assoc();
if ($check['count'] == 0) {
    $conn->query("INSERT INTO anekdot (id_anak, id_guru, tanggal, waktu, peristiwa, interpretasi, tindak_lanjut) VALUES 
    (1, 2, DATE(NOW()), '10:30', 'Ani membantu teman yang terjatuh', 'Menunjukkan kepedulian dan empati', 'Terus kembangkan sifat empati ini'),
    (3, 2, DATE(NOW()), '11:00', 'Anindya berhasil menyelesaikan puzzle sendiri', 'Menunjukkan ketekunan dan kemampuan problem solving', 'Berikan tantangan puzzle yang lebih sulit')");
    echo "✓ Sample anekdot data berhasil ditambahkan\n";
}

// Seed karya if empty
$check = $conn->query("SELECT COUNT(*) as count FROM karya_anak")->fetch_assoc();
if ($check['count'] == 0) {
    $conn->query("INSERT INTO karya_anak (id_anak, id_guru, judul, deskripsi, tanggal, kategori) VALUES 
    (1, 2, 'Melukis Bunga', 'Hasil melukis dengan cat air', DATE(NOW()), 'Seni'),
    (3, 2, 'Membuat Boneka Kain', 'Boneka tangan dari kain flanel', DATE(NOW()), 'Kerajinan'),
    (4, 2, 'Menulis Cerita Pendek', 'Cerita tentang petualangan hewan', DATE(NOW()), 'Tulis')");
    echo "✓ Sample karya data berhasil ditambahkan\n";
}

// Seed absensi if empty
$check = $conn->query("SELECT COUNT(*) as count FROM absensi")->fetch_assoc();
if ($check['count'] == 0) {
    $conn->query("INSERT INTO absensi (id_anak, id_guru, tanggal, status, keterangan) VALUES 
    (1, 2, DATE(NOW()), 'Hadir', NULL),
    (3, 2, DATE(NOW()), 'Hadir', NULL),
    (4, 2, DATE(NOW()), 'Sakit', 'Demam tinggi'),
    (5, 2, DATE(NOW()), 'Izin', 'Keperluan keluarga'),
    (6, 2, DATE(NOW()), 'Hadir', NULL)");
    echo "✓ Sample absensi data berhasil ditambahkan\n";
}



echo "\n✓ Database setup untuk guru features selesai!\n";
$conn->close();
?>
