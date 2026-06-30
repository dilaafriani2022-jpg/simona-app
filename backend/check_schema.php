<?php
header("Content-Type: application/json");
require_once 'config.php';

// Check columns in users table
$result = $conn->query("DESCRIBE users");
$columns = [];
while($row = $result->fetch_assoc()) {
    $columns[] = $row['Field'];
}

echo json_encode([
    "status" => "success",
    "users_columns" => $columns,
    "anak_count" => $conn->query("SELECT COUNT(*) as count FROM anak")->fetch_assoc()['count'],
    "ortu_count" => $conn->query("SELECT COUNT(*) as count FROM users WHERE role = 'orang_tua'")->fetch_assoc()['count']
]);

$conn->close();
?>
