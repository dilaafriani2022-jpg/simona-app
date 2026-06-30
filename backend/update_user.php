<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
require_once 'config.php';
require_once 'cors.php';
require_once 'log_activity.php';

$data = json_decode(file_get_contents("php://input"));

if (!isset($data->id)) {
    echo json_encode(["status" => "error", "message" => "User ID required"]);
    exit();
}

$id      = intval($data->id);
$updates = [];

if (isset($data->name)) {
    $updates[] = "name = '" . $conn->real_escape_string($data->name) . "'";
}
if (isset($data->email)) {
    $updates[] = "email = '" . $conn->real_escape_string($data->email) . "'";
}
if (isset($data->username)) {
    $updates[] = "username = '" . $conn->real_escape_string($data->username) . "'";
}
if (isset($data->nip)) {
    $updates[] = "nip = '" . $conn->real_escape_string($data->nip) . "'";
}
if (isset($data->nisn)) {
    $updates[] = "nisn = '" . $conn->real_escape_string($data->nisn) . "'";
}
if (isset($data->no_hp)) {
    $escapedNoHp = $conn->real_escape_string($data->no_hp);
    $updates[] = "no_telp = '$escapedNoHp'";
    $updates[] = "no_hp = '$escapedNoHp'";
}
if (isset($data->pekerjaan)) {
    $updates[] = "pekerjaan = '" . $conn->real_escape_string($data->pekerjaan) . "'";
}
if (isset($data->alamat)) {
    $updates[] = "alamat = '" . $conn->real_escape_string($data->alamat) . "'";
}
if (isset($data->tempat_lahir)) {
    $updates[] = "tempat_lahir = '" . $conn->real_escape_string($data->tempat_lahir) . "'";
}
if (isset($data->tanggal_lahir)) {
    $updates[] = "tanggal_lahir = '" . $conn->real_escape_string($data->tanggal_lahir) . "'";
}
if (isset($data->agama)) {
    $updates[] = "agama = '" . $conn->real_escape_string($data->agama) . "'";
}
if (isset($data->jenis_kelamin)) {
    $updates[] = "jenis_kelamin = '" . $conn->real_escape_string($data->jenis_kelamin) . "'";
}
if (isset($data->status_nikah)) {
    $updates[] = "status_nikah = '" . $conn->real_escape_string($data->status_nikah) . "'";
}
if (isset($data->pendidikan)) {
    $updates[] = "pendidikan = '" . $conn->real_escape_string($data->pendidikan) . "'";
}
if (isset($data->jurusan)) {
    $updates[] = "jurusan = '" . $conn->real_escape_string($data->jurusan) . "'";
}
if (isset($data->rt_rw)) {
    $updates[] = "rt_rw = '" . $conn->real_escape_string($data->rt_rw) . "'";
}
if (isset($data->kelurahan)) {
    $updates[] = "kelurahan = '" . $conn->real_escape_string($data->kelurahan) . "'";
}
if (isset($data->kecamatan)) {
    $updates[] = "kecamatan = '" . $conn->real_escape_string($data->kecamatan) . "'";
}
if (isset($data->kota)) {
    $updates[] = "kota = '" . $conn->real_escape_string($data->kota) . "'";
}
if (isset($data->provinsi)) {
    $updates[] = "provinsi = '" . $conn->real_escape_string($data->provinsi) . "'";
}
if (isset($data->kode_pos)) {
    $updates[] = "kode_pos = '" . $conn->real_escape_string($data->kode_pos) . "'";
}
if (isset($data->role)) {
    $updates[] = "role = '" . $conn->real_escape_string($data->role) . "'";
}

// ✅ FIX: Password di-hash sebelum disimpan
if (isset($data->password) && !empty($data->password)) {
    $hashedPassword = password_hash($data->password, PASSWORD_BCRYPT);
    $updates[]      = "password = '" . $hashedPassword . "'";
}

if (empty($updates)) {
    echo json_encode(["status" => "error", "message" => "No fields to update"]);
    exit();
}

$sql = "UPDATE users SET " . implode(", ", $updates) . " WHERE id = $id";

try {
    if ($conn->query($sql) === TRUE) {
        $get_user = $conn->query("SELECT name, nip, role FROM users WHERE id = $id LIMIT 1");
        $name = "ID $id";
        $nip  = '';
        $role = "unknown";
        if ($get_user && $row = $get_user->fetch_assoc()) {
            $name = $row['name'];
            $nip  = $row['nip'] ?? '';
            $role = $row['role'];
        }

        // ✅ Jika user adalah kepsek, sinkronkan ke tabel sekolah agar raport otomatis update
        if ($role === 'kepsek') {
            $escaped_name = $conn->real_escape_string($name);
            $escaped_nip  = $conn->real_escape_string($nip);
            $conn->query("UPDATE sekolah SET kepala_sekolah = '$escaped_name', nip_kepala_sekolah = '$escaped_nip' LIMIT 1");
        }

        logActivity(getPdo(), "User diperbarui", "Pengguna '{$name}' ({$role}) berhasil diperbarui", "user", "edit");
        echo json_encode(["status" => "success", "message" => "User updated successfully"]);
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