<?php
require_once 'config.php';

header('Content-Type: text/plain');

echo "Database Name: " . $db . "\n\n";

$res1 = $conn->query("SHOW TABLES");
echo "Tables:\n";
while ($row = $res1->fetch_row()) {
    echo "  - " . $row[0] . "\n";
}
echo "\n";

// Check Penilaian count
$res2 = $conn->query("SELECT tipe, COUNT(*) as c FROM penilaian GROUP BY tipe");
echo "Penilaian counts:\n";
if ($res2) {
    while ($row = $res2->fetch_assoc()) {
        echo "  - Tipe {$row['tipe']}: {$row['c']}\n";
    }
} else {
    echo "  - Error: " . $conn->error . "\n";
}
echo "\n";

// Check karya_anak count if exists
$res3 = $conn->query("SHOW TABLES LIKE 'karya_anak'");
if ($res3 && $res3->num_rows > 0) {
    $res4 = $conn->query("SELECT COUNT(*) as c FROM karya_anak");
    echo "karya_anak table count: " . ($res4 ? $res4->fetch_assoc()['c'] : "query error") . "\n\n";
} else {
    echo "karya_anak table does not exist.\n\n";
}

// Sample Karya records in penilaian
$res5 = $conn->query("SELECT id, id_anak, id_guru, judul, deskripsi, tanggal FROM penilaian WHERE tipe = 'karya' LIMIT 5");
echo "Sample Karya in penilaian:\n";
if ($res5) {
    while ($row = $res5->fetch_assoc()) {
        echo "  - ID {$row['id']}: {$row['judul']} (Anak ID: {$row['id_anak']}, Guru ID: {$row['id_guru']}, Tgl: {$row['tanggal']})\n";
    }
} else {
    echo "  - Error: " . $conn->error . "\n";
}
echo "\n";

// Check children (anak)
$res6 = $conn->query("SELECT id, nama_anak, id_kelas FROM anak LIMIT 5");
echo "Sample Anak:\n";
if ($res6) {
    while ($row = $res6->fetch_assoc()) {
        echo "  - ID {$row['id']}: {$row['nama_anak']} (Kelas ID: {$row['id_kelas']})\n";
    }
}
echo "\n";

// Check users
$res7 = $conn->query("SELECT id, name, role FROM users LIMIT 5");
echo "Sample Users:\n";
if ($res7) {
    while ($row = $res7->fetch_assoc()) {
        echo "  - ID {$row['id']}: {$row['name']} ({$row['role']})\n";
    }
}
?>
