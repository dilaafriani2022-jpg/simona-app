<?php
require_once 'config.php';

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$conn->query('TRUNCATE TABLE activity_log');
echo "✓ Activity log cleared\n";

$conn->close();
?>
