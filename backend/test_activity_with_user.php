<?php
require_once 'config.php';

// Simulate POST request with user data (like Flutter app will send)
$userData = [
    "action" => "add",
    "nama_kelas" => "Test Class from API",
    "id_tahun_ajaran" => 1,
    "user" => [
        "id" => "1",
        "name" => "Admin Operator",
        "role" => "operator"
    ]
];

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => "http://127.0.0.1/monak/backend/manage_kelas.php",
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($userData)
]);

$response = curl_exec($ch);
curl_close($ch);

echo "Response: $response\n";

// Check if activity was logged with user info
$conn = new mysqli($host, $user, $pass, $db);
echo "\nLatest activities:\n";
$result = $conn->query('SELECT id, judul, created_by, role, created_at FROM activity_log ORDER BY id DESC LIMIT 3');
while($row = $result->fetch_assoc()) {
  echo "- " . $row['id'] . ": " . $row['judul'] . " (created_by: " . $row['created_by'] . ", role: " . $row['role'] . ")\n";
}
$conn->close();
?>
