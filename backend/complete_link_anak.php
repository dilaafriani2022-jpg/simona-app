<?php
header("Content-Type: application/json");
require_once 'config.php';

// Find students without parent
$result = $conn->query("SELECT id, nama_anak FROM anak WHERE id_ortu IS NULL OR id_ortu NOT IN (SELECT id FROM users WHERE role = 'orang_tua')");

$unlinked = [];
while($row = $result->fetch_assoc()) {
    $unlinked[] = $row;
}

// Link them to first available orang_tua
if (count($unlinked) > 0) {
    // Get first available orang_tua
    $ortuRes = $conn->query("SELECT id FROM users WHERE role = 'orang_tua' LIMIT 1");
    $firstOrtuId = ($ortuRes && $ortuRes->num_rows > 0) ? (int)$ortuRes->fetch_assoc()['id'] : 1;

    foreach ($unlinked as $anak) {
        $conn->query("UPDATE anak SET id_ortu = $firstOrtuId WHERE id = " . $anak['id']);
        echo "✓ Anak '{$anak['nama_anak']}' dihubungkan dengan Orang Tua ID $firstOrtuId\n";
    }
}

echo "\n✓ Semua anak sudah terhubung dengan orang tua!";
$conn->close();
?>
