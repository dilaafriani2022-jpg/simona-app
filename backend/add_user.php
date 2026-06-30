<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
require_once 'config.php';
require_once 'cors.php';
require_once 'log_activity.php';
require_once 'auth_helper.php';

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->name) || !isset($data->role) || !isset($data->password)) {
    echo json_encode(["status" => "error", "message" => "Incomplete data"]);
    exit();
}

// ── Ambil user yang melakukan aktivitas (dari request) ──
$currentUser = extractUserFromData($data);
$currentUserId = $currentUser['id'] ?? null;
$currentUserRole = $currentUser['role'] ?? null;

$name = $conn->real_escape_string($data->name);
$role = $conn->real_escape_string($data->role);
$password = password_hash($data->password, PASSWORD_BCRYPT);

$username = isset($data->username) ? "'".$conn->real_escape_string($data->username)."'" : "NULL";
$nip = isset($data->nip) ? "'".$conn->real_escape_string($data->nip)."'" : "NULL";
$nisn = isset($data->nisn) ? "'".$conn->real_escape_string($data->nisn)."'" : "NULL";
$email = isset($data->email) ? "'".$conn->real_escape_string($data->email)."'" : "NULL";
$no_telp = isset($data->no_hp) ? "'".$conn->real_escape_string($data->no_hp)."'" : "NULL";
$pekerjaan = isset($data->pekerjaan) ? "'".$conn->real_escape_string($data->pekerjaan)."'" : "NULL";
$alamat = isset($data->alamat) ? "'".$conn->real_escape_string($data->alamat)."'" : "NULL";
$tempat_lahir = isset($data->tempat_lahir) ? "'".$conn->real_escape_string($data->tempat_lahir)."'" : "NULL";
$tanggal_lahir = isset($data->tanggal_lahir) ? "'".$conn->real_escape_string($data->tanggal_lahir)."'" : "NULL";
$agama = isset($data->agama) ? "'".$conn->real_escape_string($data->agama)."'" : "NULL";
$jenis_kelamin = isset($data->jenis_kelamin) ? "'".$conn->real_escape_string($data->jenis_kelamin)."'" : "NULL";
$status_nikah = isset($data->status_nikah) ? "'".$conn->real_escape_string($data->status_nikah)."'" : "NULL";
$pendidikan = isset($data->pendidikan) ? "'".$conn->real_escape_string($data->pendidikan)."'" : "NULL";
$jurusan = isset($data->jurusan) ? "'".$conn->real_escape_string($data->jurusan)."'" : "NULL";
$rt_rw = isset($data->rt_rw) ? "'".$conn->real_escape_string($data->rt_rw)."'" : "NULL";
$kelurahan = isset($data->kelurahan) ? "'".$conn->real_escape_string($data->kelurahan)."'" : "NULL";
$kecamatan = isset($data->kecamatan) ? "'".$conn->real_escape_string($data->kecamatan)."'" : "NULL";
$kota = isset($data->kota) ? "'".$conn->real_escape_string($data->kota)."'" : "NULL";
$provinsi = isset($data->provinsi) ? "'".$conn->real_escape_string($data->provinsi)."'" : "NULL";
$kode_pos = isset($data->kode_pos) ? "'".$conn->real_escape_string($data->kode_pos)."'" : "NULL";

$sql = "INSERT INTO users (name, role, username, nip, nisn, email, password, no_telp, pekerjaan, alamat, tempat_lahir, tanggal_lahir, agama, jenis_kelamin, status_nikah, pendidikan, jurusan, rt_rw, kelurahan, kecamatan, kota, provinsi, kode_pos) 
        VALUES ('$name', '$role', $username, $nip, $nisn, $email, '$password', $no_telp, $pekerjaan, $alamat, $tempat_lahir, $tanggal_lahir, $agama, $jenis_kelamin, $status_nikah, $pendidikan, $jurusan, $rt_rw, $kelurahan, $kecamatan, $kota, $provinsi, $kode_pos)";

try {
    if ($conn->query($sql) === TRUE) {
        logActivity(
            getPdo(),
            "User ditambahkan",
            "Pengguna '{$name}' dengan role '{$role}' berhasil dibuat",
            "user",
            "tambah",
            $currentUserId,
            $currentUserRole
        );
        echo json_encode(["status" => "success", "message" => "User added successfully"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Error: " . $conn->error]);
    }
} catch (mysqli_sql_exception $e) {
    $errMsg = $e->getMessage();
    if (str_contains($errMsg, 'Duplicate entry')) {
        if (str_contains($errMsg, 'key \'username\'')) {
            $friendly = "Username sudah digunakan oleh pengguna lain.";
        } else if (str_contains($errMsg, 'key \'email\'')) {
            $friendly = "Email sudah digunakan oleh pengguna lain.";
        } else if (str_contains($errMsg, 'key \'nip\'')) {
            $friendly = "NIP sudah digunakan oleh pengguna lain.";
        } else if (str_contains($errMsg, 'key \'nisn\'')) {
            $friendly = "NISN sudah digunakan oleh pengguna lain.";
        } else {
            $friendly = "Data yang dimasukkan (Username, Email, NIP, atau NISN) sudah terdaftar pada pengguna lain.";
        }
        echo json_encode(["status" => "error", "message" => $friendly]);
    } else {
        echo json_encode(["status" => "error", "message" => "Database error: " . $errMsg]);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => "System error: " . $e->getMessage()]);
}

$conn->close();
?>
