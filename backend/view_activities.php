<?php
require_once 'config.php';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

echo "=== RECENT ACTIVITIES ===\n";
$result = $conn->query("
  SELECT 
    al.id, al.judul, al.created_by, al.role, al.created_at,
    COALESCE(u.name, 'Unknown') as user_name
  FROM activity_log al
  LEFT JOIN users u ON al.created_by = u.id
  ORDER BY al.id DESC 
  LIMIT 10
");

while($row = $result->fetch_assoc()) {
  echo sprintf(
    "[%d] %s | by: %s (%s) | %s\n",
    $row['id'],
    $row['judul'],
    $row['user_name'],
    $row['role'] ?: 'NULL',
    $row['created_at']
  );
}

$conn->close();
?>
