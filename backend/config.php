<?php
// Sembunyikan output error PHP agar tidak merusak format JSON di Flutter
error_reporting(0);
ini_set('display_errors', 0);

// Nonaktifkan mode strict exception agar error MySQL tidak jadi HTML output
mysqli_report(MYSQLI_REPORT_OFF);

$host = "127.0.0.1";   // Gunakan IP bukan 'localhost' agar koneksi lewat TCP/IP
$port = 3306;
$user = "root";
$pass = "";
$db   = "monak_db";

$conn = new mysqli($host, $user, $pass, $db, $port);

if ($conn->connect_error) {
    error_log("Database Connection failed: " . $conn->connect_error);
    header("Content-Type: application/json");
    echo json_encode([
        "status"  => "error",
        "message" => "Database connection failed: " . $conn->connect_error
    ]);
    exit();
}

$conn->set_charset("utf8mb4");
?>