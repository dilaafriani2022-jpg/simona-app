<?php
require_once 'config.php';
header('Content-Type: text/plain');

echo "--- Sekolah Active Info ---\n";
$res1 = $conn->query("SELECT * FROM sekolah LIMIT 1");
if ($res1) {
    print_r($res1->fetch_assoc());
} else {
    echo "Error: " . $conn->error . "\n";
}

echo "\n--- Tahun Ajaran List ---\n";
$res2 = $conn->query("SELECT * FROM tahun_ajaran");
if ($res2) {
    while ($row = $res2->fetch_assoc()) {
        print_r($row);
    }
} else {
    echo "Error: " . $conn->error . "\n";
}

echo "\n--- Prosem Info for Active TA ---\n";
$res3 = $conn->query("SELECT id, tahun_ajaran, semester, tgl_mulai, tgl_selesai FROM prosem");
if ($res3) {
    while ($row = $res3->fetch_assoc()) {
        print_r($row);
    }
} else {
    echo "Error: " . $conn->error . "\n";
}
?>
