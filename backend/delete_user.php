<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
require_once 'config.php';
require_once 'cors.php';
require_once 'log_activity.php';

$data = json_decode(file_get_contents("php://input"));

// ── Ambil user yang melakukan aktivitas (graceful fallback) ──
$currentUser = $data->user ?? null;
$currentUserId = $currentUser->id ?? null;
$currentUserRole = $currentUser->role ?? null;

if (!isset($data->id)) {
    echo json_encode(["status" => "error", "message" => "ID missing"]);
    exit();
}

$id = intval($data->id);

$get_user = $conn->query("SELECT name, role FROM users WHERE id = $id LIMIT 1");
$name = "ID $id";
$role = "unknown";
if ($get_user && $row = $get_user->fetch_assoc()) {
    $name = $row['name'];
    $role = $row['role'];
}

$sql = "DELETE FROM users WHERE id = $id AND role != 'operator'"; // Prevent deleting operator themselves easily

if ($conn->query($sql) === TRUE) {
    if ($conn->affected_rows > 0) {
        logActivity(getPdo(), "User dihapus", "Pengguna '{$name}' ({$role}) berhasil dihapus", "user", "hapus", $currentUserId, $currentUserRole);
        echo json_encode(["status" => "success", "message" => "User deleted successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "User not found or cannot delete operator"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . $conn->error]);
}

$conn->close();
?>
