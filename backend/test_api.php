<?php
header("Content-Type: application/json");
require_once 'config.php';

// ────────────────────────────────────────────────────────────────────────
// TEST ENDPOINTS
// ────────────────────────────────────────────────────────────────────────

$tests = [];

// Test 1: Database Connection
try {
    $conn->ping();
    $tests[] = ["test" => "Database Connection", "status" => "success", "message" => "Connected to database"];
} catch (Exception $e) {
    $tests[] = ["test" => "Database Connection", "status" => "error", "message" => $e->getMessage()];
}

// Test 2: Check Tables Exist
$tables = ['users', 'tujuan_pembelajaran', 'kegiatan_pembelajaran', 'aspek_penilaian'];
foreach ($tables as $table) {
    $result = $conn->query("SHOW TABLES LIKE '$table'");
    if ($result && $result->num_rows > 0) {
        $tests[] = ["test" => "Table: $table", "status" => "success", "message" => "Table exists"];
    } else {
        $tests[] = ["test" => "Table: $table", "status" => "warning", "message" => "Table not found"];
    }
}

// Test 3: Check User 2 (default guru)
$stmt = $conn->prepare("SELECT id, nama FROM users WHERE id = 2");
$stmt->execute();
$result = $stmt->get_result();
if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $tests[] = ["test" => "Default User (ID: 2)", "status" => "success", "message" => "User found: " . $row['nama']];
} else {
    $tests[] = ["test" => "Default User (ID: 2)", "status" => "warning", "message" => "User not found"];
}

// Test 4: Check Aspek Penilaian
$stmt = $conn->prepare("SELECT COUNT(*) as cnt FROM aspek_penilaian");
$stmt->execute();
$result = $stmt->get_result();
$row = $result->fetch_assoc();
$tests[] = ["test" => "Aspek Penilaian Count", "status" => "info", "message" => "Total: " . $row['cnt']];

// Test 5: Check Tujuan Pembelajaran
$stmt = $conn->prepare("SELECT COUNT(*) as cnt FROM tujuan_pembelajaran WHERE id_guru = 2");
$stmt->execute();
$result = $stmt->get_result();
$row = $result->fetch_assoc();
$tests[] = ["test" => "Tujuan Pembelajaran (Guru 2)", "status" => "info", "message" => "Total: " . $row['cnt']];

// Test 6: Check Kegiatan Pembelajaran
$stmt = $conn->prepare("SELECT COUNT(*) as cnt FROM kegiatan_pembelajaran WHERE id_guru = 2");
$stmt->execute();
$result = $stmt->get_result();
$row = $result->fetch_assoc();
$tests[] = ["test" => "Kegiatan Pembelajaran (Guru 2)", "status" => "info", "message" => "Total: " . $row['cnt']];

$conn->close();

// Return results
echo json_encode([
    "status" => "success",
    "data" => $tests,
    "timestamp" => date("Y-m-d H:i:s"),
    "url_get_kegiatan" => "/monak/backend/manage_kegiatan_pembelajaran.php?id_guru=2",
    "url_get_tujuan" => "/monak/backend/manage_tujuan_pembelajaran.php?id_guru=2",
]);
?>
