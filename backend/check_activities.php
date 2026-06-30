<?php
require_once 'config.php';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$result = $conn->query('SELECT COUNT(*) as cnt FROM activity_log');
$row = $result->fetch_assoc();
echo "Total aktivitas: " . $row['cnt'] . "\n";

$result = $conn->query('SELECT id, judul, created_by, role, created_at FROM activity_log ORDER BY created_at DESC LIMIT 5');
echo "5 aktivitas terbaru:\n";
while($row = $result->fetch_assoc()) {
  echo "- " . $row['id'] . ": " . $row['judul'] . " (by: " . $row['created_by'] . ", role: " . $row['role'] . ") at " . $row['created_at'] . "\n";
}

$conn->close();
?>
