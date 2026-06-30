<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php';
require_once 'cors.php';

$role = isset($_GET['role']) ? $_GET['role'] : '';

if (!$role) {
    echo json_encode(["status" => "error", "message" => "Role tidak ditentukan"]);
    exit;
}

if ($role == 'guru') {
    // Get guru yang belum punya user account
    $sql = "SELECT DISTINCT u.id, u.name, u.nip, u.email 
            FROM users u
            WHERE u.role = 'guru' AND u.id NOT IN (SELECT id FROM users WHERE role = 'guru' AND username IS NOT NULL)
            ORDER BY u.name ASC";
} elseif ($role == 'orang_tua') {
    // Get anak/orang tua
    $sql = "SELECT s.id, s.nama_anak AS nama_anak, s.nisn, u.id as ortu_id, u.name as ortu_name
            FROM anak s
            LEFT JOIN users u ON s.id_ortu = u.id
            ORDER BY s.nama_anak ASC";
} elseif ($role == 'kepsek') {
    // Get kepala sekolah yang belum punya user
    $sql = "SELECT DISTINCT u.id, u.name, u.email, u.nip
            FROM users u
            WHERE u.role = 'kepsek' AND u.id NOT IN (SELECT id FROM users WHERE role = 'kepsek' AND username IS NOT NULL)
            ORDER BY u.name ASC";
}

$result = $conn->query($sql);
$data = [];

while($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode(["status" => "success", "data" => $data]);

$conn->close();
?>
