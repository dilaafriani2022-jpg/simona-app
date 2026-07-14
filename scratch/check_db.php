<?php
require 'backend/config.php';
$res1 = $conn->query("SELECT COUNT(*) as c FROM penilaian WHERE tipe = 'karya'");
echo "Penilaian tipe=karya: " . ($res1 ? $res1->fetch_assoc()['c'] : "query failed: " . $conn->error) . "\n";

$res2 = $conn->query("SHOW TABLES LIKE 'karya_anak'");
echo "Table karya_anak exists: " . ($res2 && $res2->num_rows > 0 ? "yes" : "no") . "\n";

if ($res2 && $res2->num_rows > 0) {
    $res3 = $conn->query("SELECT COUNT(*) as c FROM karya_anak");
    echo "karya_anak count: " . ($res3 ? $res3->fetch_assoc()['c'] : "query failed") . "\n";
}

$res4 = $conn->query("SELECT id, name, role FROM users");
echo "Users:\n";
while ($row = $res4->fetch_assoc()) {
    echo "  - ID {$row['id']}: {$row['name']} ({$row['role']})\n";
}

$res5 = $conn->query("SELECT id, nama_anak, id_kelas FROM anak");
echo "Anak:\n";
while ($row = $res5->fetch_assoc()) {
    echo "  - ID {$row['id']}: {$row['nama_anak']} (Kelas ID: {$row['id_kelas']})\n";
}

$res6 = $conn->query("SELECT id, tipe, id_anak, id_guru FROM penilaian LIMIT 5");
echo "Penilaian sample:\n";
while ($row = $res6->fetch_assoc()) {
    echo "  - ID {$row['id']}: Tipe {$row['tipe']}, Anak {$row['id_anak']}, Guru {$row['id_guru']}\n";
}
