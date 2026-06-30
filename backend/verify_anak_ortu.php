<?php
header("Content-Type: application/json");
require_once 'config.php';

// Get all anak with parent info
$sql = "SELECT s.id, s.nama_anak AS nama_anak, u.name as nama_ortu, u.email FROM anak s 
        LEFT JOIN users u ON s.id_ortu = u.id 
        ORDER BY s.id ASC";

$result = $conn->query($sql);
$data = [];
while($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode([
    "status" => "success",
    "total_anak" => count($data),
    "anak_terhubung" => count(array_filter($data, fn($s) => !empty($s['nama_ortu']))),
    "data" => $data
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

$conn->close();
?>
