<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php';
require_once 'cors.php';

$data = json_decode(file_get_contents("php://input"), true);

$role     = $data['role'] ?? '';
$sourceId = $data['source_id'] ?? 0;
$password = $data['password'] ?? '';

if (!$role || !$sourceId || !$password) {
    echo json_encode(["status" => "error", "message" => "Data tidak lengkap"]);
    exit;
}

$name     = '';
$nip      = '';
$nisn     = '';
$email    = '';
$no_telp  = '';
$pekerjaan = '';
$alamat   = '';

if ($role == 'guru') {
    $sql    = "SELECT name, nip, email FROM users WHERE id = $sourceId AND role = 'guru'";
    $result = $conn->query($sql);
    $guru   = $result->fetch_assoc();

    if (!$guru) {
        echo json_encode(["status" => "error", "message" => "Guru tidak ditemukan"]);
        exit;
    }

    $name  = $guru['name'];
    $nip   = $guru['nip'];
    $email = $guru['email'];

} elseif ($role == 'orang_tua') {
    $sql    = "SELECT s.nama_anak AS nama_anak, s.nisn, s.id_ortu, o.no_hp, o.pekerjaan, o.alamat 
               FROM anak s
               LEFT JOIN orang_tua o ON s.id_ortu = o.id
               WHERE s.id = $sourceId";
    $result = $conn->query($sql);
    $anak  = $result->fetch_assoc();

    if (!$anak) {
        echo json_encode(["status" => "error", "message" => "Anak tidak ditemukan"]);
        exit;
    }

    $name      = $anak['name'] ?? 'Orang Tua ' . $anak['nama_anak'];
    $nisn      = $anak['nisn'];
    $no_telp   = $anak['no_hp'] ?? '';
    $pekerjaan = $anak['pekerjaan'] ?? '';
    $alamat    = $anak['alamat'] ?? '';

} elseif ($role == 'kepsek') {
    $sql    = "SELECT name, nip, email FROM users WHERE id = $sourceId AND role = 'kepsek'";
    $result = $conn->query($sql);
    $kepsek = $result->fetch_assoc();

    if (!$kepsek) {
        echo json_encode(["status" => "error", "message" => "Kepala Sekolah tidak ditemukan"]);
        exit;
    }

    $name  = $kepsek['name'];
    $nip   = $kepsek['nip'] ?? '';
    $email = $kepsek['email'];
}

// ✅ Hash password
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

// ✅ UPDATE user yang sudah ada (set password saja, identifier sudah ada)
$sql = "UPDATE users SET password = '$hashedPassword' WHERE id = $sourceId AND role = '$role'";

if ($conn->query($sql)) {
    echo json_encode([
        "status"  => "success",
        "message" => "User berhasil dibuat",
        "data"    => [
            "id"   => $sourceId,
            "name" => $name,
            "role" => $role
        ]
    ]);
} else {
    echo json_encode(["status" => "error", "message" => $conn->error]);
}

$conn->close();
?>