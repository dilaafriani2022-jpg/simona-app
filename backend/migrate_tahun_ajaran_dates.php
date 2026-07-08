<?php
// ─── Migrasi: Tambah kolom tanggal akhir semester ke tabel tahun_ajaran ───
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require_once 'config.php';

$results = [];

// Tambah kolom tanggal_mulai jika belum ada
$cols = [
    "tanggal_mulai_semester_1"  => "DATE DEFAULT NULL COMMENT 'Tanggal mulai semester ganjil'",
    "tanggal_akhir_semester_1"  => "DATE DEFAULT NULL COMMENT 'Tanggal akhir semester ganjil'",
    "tanggal_mulai_semester_2"  => "DATE DEFAULT NULL COMMENT 'Tanggal mulai semester genap'",
    "tanggal_akhir_semester_2"  => "DATE DEFAULT NULL COMMENT 'Tanggal akhir semester genap'",
];

foreach ($cols as $col => $def) {
    // Cek apakah kolom sudah ada
    $check = $conn->query("SHOW COLUMNS FROM tahun_ajaran LIKE '$col'");
    if ($check && $check->num_rows === 0) {
        $sql = "ALTER TABLE tahun_ajaran ADD COLUMN $col $def";
        if ($conn->query($sql)) {
            $results[] = "✅ Kolom '$col' berhasil ditambahkan.";
        } else {
            $results[] = "❌ Gagal tambah '$col': " . $conn->error;
        }
    } else {
        $results[] = "⏭️  Kolom '$col' sudah ada, dilewati.";
    }
}

// Set nilai default untuk tahun ajaran aktif (2025/2026):
// Semester 1 (Ganjil): Juli - Desember 2025
// Semester 2 (Genap) : Januari - Juni 2026
$update = $conn->query("
    UPDATE tahun_ajaran
    SET
        tanggal_mulai_semester_1 = '2025-07-14',
        tanggal_akhir_semester_1 = '2025-12-19',
        tanggal_mulai_semester_2 = '2026-01-05',
        tanggal_akhir_semester_2 = '2026-06-19'
    WHERE status = 'aktif'
");
if ($update) {
    $results[] = "✅ Tanggal default semester berhasil di-set untuk tahun ajaran aktif.";
} else {
    $results[] = "❌ Gagal set tanggal default: " . $conn->error;
}

$conn->close();
echo json_encode(["status" => "success", "messages" => $results]);
?>
