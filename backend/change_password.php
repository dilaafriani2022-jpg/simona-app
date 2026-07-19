<?php
require_once 'cors.php';
header("Content-Type: application/json");
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Method tidak diizinkan"]);
    exit;
}

$input = json_decode(file_get_contents("php://input"), true);
$id        = intval($input['id'] ?? 0);
$old_pass  = $input['old_password'] ?? '';
$new_pass  = $input['new_password'] ?? '';

if (!$id || !$old_pass || !$new_pass) {
    echo json_encode(["status" => "error", "message" => "Data tidak lengkap"]);
    exit;
}

// Ambil password lama & role
$stmt = $conn->prepare("SELECT password, role FROM users WHERE id = ? LIMIT 1");
$stmt->bind_param("i", $id);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();

if (!$row) {
    echo json_encode(["status" => "error", "message" => "User tidak ditemukan"]);
    exit;
}

// Verifikasi password lama (support plain-text lama & bcrypt baru)
$valid = password_verify($old_pass, $row['password'])
      || $old_pass === $row['password'];

if (!$valid && $row['role'] === 'orang_tua') {
    // Fallback: Cek apakah cocok dengan NISN anak yang terhubung (default login credentials)
    $escaped_pass = $conn->real_escape_string($old_pass);
    $check_res = $conn->query("SELECT id FROM anak WHERE id_ortu = $id AND nisn = '$escaped_pass' LIMIT 1");
    if ($check_res && $check_res->num_rows > 0) {
        $valid = true;
    }
}

if (!$valid) {
    echo json_encode(["status" => "error", "message" => "Password lama tidak sesuai"]);
    exit;
}

// Simpan password baru (di-hash)
$hashed = password_hash($new_pass, PASSWORD_BCRYPT);
$upd = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
$upd->bind_param("si", $hashed, $id);

if ($upd->execute()) {
    echo json_encode(["status" => "success", "message" => "Password berhasil diperbarui"]);
} else {
    echo json_encode(["status" => "error", "message" => $conn->error]);
}

$conn->close();
?>
