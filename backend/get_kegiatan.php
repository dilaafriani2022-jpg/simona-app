<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

// ════════════════════════════════════════════════════════════════════════════
// GET - Ambil kegiatan pembelajaran by aspek
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $id_aspek = isset($_GET['id_aspek']) ? intval($_GET['id_aspek']) : null;

    if (!$id_aspek) {
        echo json_encode(["status" => "error", "message" => "ID aspek wajib diisi"]);
        exit;
    }

    $sql = "SELECT id, nama_kegiatan, deskripsi 
            FROM kegiatan_pembelajaran 
            WHERE id_aspek = $id_aspek
            ORDER BY id ASC";

    $result = $conn->query($sql);
    if (!$result) {
        echo json_encode(["status" => "error", "message" => $conn->error]);
        exit;
    }

    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }

    echo json_encode(["status" => "success", "data" => $data]);

}

$conn->close();
?>
