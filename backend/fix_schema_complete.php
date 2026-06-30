<?php
/**
 * fix_schema_complete.php
 * Menambahkan semua kolom yang hilang agar manage_anak.php dan manage_ortu.php
 * bisa berjalan dengan benar.
 *
 * Jalankan sekali via browser: http://127.0.0.1/monak/backend/fix_schema_complete.php
 */

header("Content-Type: text/html; charset=UTF-8");
require_once 'config.php';

$results = [];

// ─── Helper ─────────────────────────────────────────────────────────────────
function addColIfMissing(mysqli $conn, string $table, string $col, string $def): void {
    global $results;
    $check = $conn->query("SHOW COLUMNS FROM `$table` LIKE '$col'");
    if ($check && $check->num_rows === 0) {
        $sql = "ALTER TABLE `$table` ADD COLUMN `$col` $def";
        if ($conn->query($sql)) {
            $results[] = "✅ Ditambahkan: `$table`.`$col`";
        } else {
            $results[] = "❌ Gagal `$table`.`$col`: " . $conn->error;
        }
    } else {
        $results[] = "⏭️ Sudah ada: `$table`.`$col`";
    }
}

// ════════════════════════════════════════════════════════════════════════════
// 1. Tabel ANAK — kolom tambahan yang dipakai manage_anak.php
// ════════════════════════════════════════════════════════════════════════════
$anakCols = [
    'nik'            => "VARCHAR(20) DEFAULT NULL",
    'tempat_lahir'   => "VARCHAR(100) DEFAULT NULL",
    'agama'          => "VARCHAR(30) DEFAULT NULL",
    'status_anak'    => "VARCHAR(20) DEFAULT NULL",
    'anak_ke'        => "TINYINT UNSIGNED DEFAULT NULL",
    'berat_badan'    => "DECIMAL(5,2) DEFAULT NULL",
    'tinggi_badan'   => "DECIMAL(5,2) DEFAULT NULL",
    'created_at'     => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
    'updated_at'     => "TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP",
];
foreach ($anakCols as $col => $def) {
    addColIfMissing($conn, 'anak', $col, $def);
}

// ════════════════════════════════════════════════════════════════════════════
// 2. Tabel USERS — kolom orang tua yang dipakai manage_ortu.php
// ════════════════════════════════════════════════════════════════════════════
$usersCols = [
    // Kontak & profil orang tua
    'no_hp'           => "VARCHAR(20) DEFAULT NULL",
    'no_telp'         => "VARCHAR(20) DEFAULT NULL",   // alias no_hp di beberapa query
    // Data Ayah
    'ayah_nama'       => "VARCHAR(100) DEFAULT NULL",
    'ayah_nik'        => "VARCHAR(20) DEFAULT NULL",
    'ayah_ttl'        => "VARCHAR(100) DEFAULT NULL",
    'ayah_agama'      => "VARCHAR(30) DEFAULT NULL",
    'ayah_pendidikan' => "VARCHAR(50) DEFAULT NULL",
    'ayah_pekerjaan'  => "VARCHAR(100) DEFAULT NULL",
    'ayah_penghasilan'=> "VARCHAR(50) DEFAULT NULL",
    'ayah_hp'         => "VARCHAR(20) DEFAULT NULL",
    'ayah_status'     => "VARCHAR(20) DEFAULT 'Hidup'",
    // Data Ibu
    'ibu_nama'        => "VARCHAR(100) DEFAULT NULL",
    'ibu_nik'         => "VARCHAR(20) DEFAULT NULL",
    'ibu_ttl'         => "VARCHAR(100) DEFAULT NULL",
    'ibu_agama'       => "VARCHAR(30) DEFAULT NULL",
    'ibu_pendidikan'  => "VARCHAR(50) DEFAULT NULL",
    'ibu_pekerjaan'   => "VARCHAR(100) DEFAULT NULL",
    'ibu_penghasilan' => "VARCHAR(50) DEFAULT NULL",
    'ibu_hp'          => "VARCHAR(20) DEFAULT NULL",
    'ibu_status'      => "VARCHAR(20) DEFAULT 'Hidup'",
    // Data Wali
    'wali_nama'       => "VARCHAR(100) DEFAULT NULL",
    'wali_hubungan'   => "VARCHAR(50) DEFAULT NULL",
    'wali_pekerjaan'  => "VARCHAR(100) DEFAULT NULL",
    'wali_hp'         => "VARCHAR(20) DEFAULT NULL",
    // Alamat detail
    'rt_rw'           => "VARCHAR(20) DEFAULT NULL",
    'kelurahan'       => "VARCHAR(100) DEFAULT NULL",
    'kecamatan'       => "VARCHAR(100) DEFAULT NULL",
    'kota'            => "VARCHAR(100) DEFAULT NULL",
    'provinsi'        => "VARCHAR(100) DEFAULT NULL",
    'kode_pos'        => "VARCHAR(10) DEFAULT NULL",
    // Guru tambahan
    'jenis_kelamin'   => "ENUM('L','P') DEFAULT NULL",
    'id_kelas'        => "INT DEFAULT NULL",
];
foreach ($usersCols as $col => $def) {
    addColIfMissing($conn, 'users', $col, $def);
}

// ════════════════════════════════════════════════════════════════════════════
// 3. Tabel ASPEK_PENILAIAN — kolom created_at
// ════════════════════════════════════════════════════════════════════════════
addColIfMissing($conn, 'aspek_penilaian', 'created_at', "TIMESTAMP DEFAULT CURRENT_TIMESTAMP");

// ════════════════════════════════════════════════════════════════════════════
// 4. Tabel TAHUN_AJARAN — pastikan ada
// ════════════════════════════════════════════════════════════════════════════
$conn->query("
    CREATE TABLE IF NOT EXISTS tahun_ajaran (
        id     INT AUTO_INCREMENT PRIMARY KEY,
        tahun  VARCHAR(20) NOT NULL,
        status ENUM('aktif','nonaktif') DEFAULT 'aktif'
    )
");
$results[] = "✅ Tabel tahun_ajaran dipastikan ada";

// Seed tahun ajaran jika kosong
$r = $conn->query("SELECT COUNT(*) AS c FROM tahun_ajaran");
if ($r && $r->fetch_assoc()['c'] == 0) {
    $conn->query("INSERT INTO tahun_ajaran (tahun, status) VALUES ('2025/2026', 'aktif')");
    $results[] = "✅ Seed tahun_ajaran: 2025/2026";
}

// ════════════════════════════════════════════════════════════════════════════
// 5. Tabel KELAS — pastikan ada
// ════════════════════════════════════════════════════════════════════════════
$conn->query("
    CREATE TABLE IF NOT EXISTS kelas (
        id              INT AUTO_INCREMENT PRIMARY KEY,
        nama_kelas      VARCHAR(50) NOT NULL,
        id_tahun_ajaran INT,
        FOREIGN KEY (id_tahun_ajaran) REFERENCES tahun_ajaran(id)
    )
");
$results[] = "✅ Tabel kelas dipastikan ada";

// Seed kelas jika kosong
$r = $conn->query("SELECT COUNT(*) AS c FROM kelas");
if ($r && $r->fetch_assoc()['c'] == 0) {
    $ta = $conn->query("SELECT id FROM tahun_ajaran LIMIT 1")->fetch_assoc()['id'] ?? 0;
    if ($ta) {
        $conn->query("INSERT INTO kelas (nama_kelas, id_tahun_ajaran) VALUES ('Kelompok A', $ta), ('Kelompok B', $ta)");
        $results[] = "✅ Seed kelas: Kelompok A & B";
    }
}

// ════════════════════════════════════════════════════════════════════════════
// 6. Pastikan tabel activity_log ada dengan kolom created_by & role
// ════════════════════════════════════════════════════════════════════════════
$conn->query("
    CREATE TABLE IF NOT EXISTS activity_log (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        judul       VARCHAR(255) NOT NULL,
        deskripsi   TEXT,
        jenis       VARCHAR(50) DEFAULT 'info',
        aksi        VARCHAR(50) DEFAULT 'info',
        created_by  INT,
        role        VARCHAR(50),
        created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
    )
");
$results[] = "✅ Tabel activity_log dipastikan ada dengan kolom created_by & role";

// Tambah kolom created_by jika belum ada
if (!columnExists($conn, 'activity_log', 'created_by')) {
    $conn->query("ALTER TABLE activity_log ADD COLUMN created_by INT");
    $conn->query("ALTER TABLE activity_log ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL");
    $results[] = "✅ Kolom created_by ditambahkan ke activity_log";
} else {
    $results[] = "⊙ Kolom created_by sudah ada di activity_log";
}

// Tambah kolom role jika belum ada
if (!columnExists($conn, 'activity_log', 'role')) {
    $conn->query("ALTER TABLE activity_log ADD COLUMN role VARCHAR(50)");
    $results[] = "✅ Kolom role ditambahkan ke activity_log";
} else {
    $results[] = "⊙ Kolom role sudah ada di activity_log";
}

$conn->close();
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Fix Schema — monak</title>
    <style>
        body { font-family: monospace; background:#1a1a2e; color:#e0e0e0; padding:30px; }
        h2   { color:#f0a500; }
        li   { margin:4px 0; font-size:14px; }
        .ok  { color:#4ade80; }
        .err { color:#f87171; }
        .skip{ color:#94a3b8; }
        .btn { display:inline-block; margin-top:20px; padding:12px 24px; background:#f0a500;
               color:#1a1a2e; border-radius:8px; text-decoration:none; font-weight:bold; }
    </style>
</head>
<body>
<h2>🔧 Fix Schema — monak Backend</h2>
<ul>
<?php foreach ($results as $r): ?>
    <li class="<?= str_starts_with($r, '✅') ? 'ok' : (str_starts_with($r, '❌') ? 'err' : 'skip') ?>">
        <?= htmlspecialchars($r) ?>
    </li>
<?php endforeach; ?>
</ul>
<p><strong>Selesai!</strong> Semua kolom yang diperlukan sudah ditambahkan.</p>
<a class="btn" href="/monak/backend/get_dashboard_stats.php" target="_blank">Test Dashboard Stats</a>
<a class="btn" href="/monak/backend/manage_anak.php" target="_blank">Test Manage Anak</a>
<a class="btn" href="/monak/backend/manage_ortu.php" target="_blank">Test Manage Ortu</a>
</body>
</html>
