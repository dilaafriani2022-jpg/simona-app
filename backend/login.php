<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if (!$conn) {
    echo json_encode(["status" => "error", "message" => "Database connection failed"]);
    exit();
}

$data = json_decode(file_get_contents("php://input"));

if (!$data || !isset($data->username) || !isset($data->password)) {
    echo json_encode(["status" => "error", "message" => "Username and password required"]);
    exit();
}

$identifier = $conn->real_escape_string($data->username);
$password   = $data->password;

// Cari user berdasarkan role masing-masing:
// - operator  → username
// - guru      → nip
// - kepsek    → email
// - orang_tua → nisn (login pakai NISN anak sebagai username & password)
$sql = "SELECT * FROM users 
        WHERE username = '$identifier' 
           OR nip      = '$identifier' 
           OR email    = '$identifier' 
           OR nisn     = '$identifier'
        LIMIT 1";

$result = $conn->query($sql);

if (!$result) {
    echo json_encode(["status" => "error", "message" => "Query failed: " . $conn->error]);
    exit();
}

if ($result->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "User not found"]);
    exit();
}

$user = $result->fetch_assoc();

// Verifikasi password (bcrypt hash)
if (!password_verify($password, $user['password'])) {
    echo json_encode(["status" => "error", "message" => "Incorrect password"]);
    exit();
}

// Ambil semua kolom profil lengkap berdasarkan role
$userId  = (int)$user['id'];
$extra = [];

if ($user['role'] === 'guru') {
    // Map no_telp alias
    $user['no_hp'] = $user['no_telp'] ?? null;
    $user['telp'] = $user['no_telp'] ?? null;
    
    if (!empty($user['id_kelas'])) {
        $idKelas  = (int)$user['id_kelas'];
        $resKelas = $conn->query("SELECT nama_kelas FROM kelas WHERE id = $idKelas");
        if ($resKelas && $resKelas->num_rows > 0) {
            $rowKelas = $resKelas->fetch_assoc();
            $extra['nama_kelas'] = $rowKelas['nama_kelas'];
        }
    }
} elseif ($user['role'] === 'orang_tua') {
    $ortuId = $userId;
    // Map no_hp alias
    $user['no_telp'] = $user['no_hp'] ?? null;
    $user['telp'] = $user['no_hp'] ?? null;
    
    $sqlAnak = "SELECT a.*, a.nama_anak AS nama_anak, k.nama_kelas 
                 FROM anak a 
                 LEFT JOIN kelas k ON a.id_kelas = k.id 
                 WHERE a.id_ortu = $ortuId";
    $resAnak = $conn->query($sqlAnak);
    $extra['anak'] = [];
    if ($resAnak && $resAnak->num_rows > 0) {
        while ($row = $resAnak->fetch_assoc()) {
            $extra['anak'][] = $row;
        }
    }
}


// Jangan kirim password ke client
unset($user['password']);

echo json_encode([
    "status"  => "success",
    "message" => "Login successful",
    "user"    => array_merge($user, $extra)
]);

$conn->close();
?>