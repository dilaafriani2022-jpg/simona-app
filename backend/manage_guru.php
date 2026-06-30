<?php
error_reporting(0); // Suppress warnings — output only clean JSON
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';
require_once 'cors.php';
require_once 'log_activity.php';
require_once 'auth_helper.php';

$method = $_SERVER['REQUEST_METHOD'];

// ── Helper escape ──────────────────────────────────────────────────────────
$s = fn($v) => isset($v) && $v !== '' && $v !== null
    ? "'" . $conn->real_escape_string((string)$v) . "'"
    : "NULL";

// ════════════════════════════════════════════════════════════════════════════
// GET — daftar semua guru
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $search = isset($_GET['search']) ? $conn->real_escape_string($_GET['search']) : '';

    $sql = "SELECT
                u.id, u.name, u.nip, u.nik,
                u.jenis_kelamin,
                u.tempat_lahir, u.tanggal_lahir,
                u.agama, u.status_nikah,
                u.status_kepeg, u.jabatan,
                u.pendidikan, u.jurusan, u.tahun_mulai,
                u.no_telp, u.email_guru, u.alamat,
                u.id_kelas, k.nama_kelas
            FROM users u
            LEFT JOIN kelas k ON u.id_kelas = k.id
            WHERE u.role = 'guru'";

    if (!empty($search)) {
        $sql .= " AND (u.name LIKE '%$search%'
                    OR u.nip  LIKE '%$search%'
                    OR u.no_telp LIKE '%$search%'
                    OR u.jabatan LIKE '%$search%')";
    }

    $sql .= " ORDER BY u.name ASC";

    $result = $conn->query($sql);
    $data   = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }

    echo json_encode(["status" => "success", "data" => $data]);

// ════════════════════════════════════════════════════════════════════════════
// POST — tambah / update / delete
// ════════════════════════════════════════════════════════════════════════════
} elseif ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true);
    $action = $input['action'] ?? '';
    
    // ── Ambil user yang melakukan aktivitas (graceful fallback) ──
    $currentUser = $input['user'] ?? null;
    $currentUserId = $currentUser['id'] ?? null;
    $currentUserRole = $currentUser['role'] ?? null;

    // ── ADD ────────────────────────────────────────────────────────────────
    if ($action === 'add') {
        $name     = $conn->real_escape_string($input['name']  ?? '');
        $nip      = $conn->real_escape_string($input['nip']   ?? '');
        $id_kelas = !empty($input['id_kelas']) ? intval($input['id_kelas']) : 'NULL';

        if (empty($name)) {
            echo json_encode(["status" => "error", "message" => "Nama wajib diisi"]);
            exit;
        }

        // Cek NIP duplikat (hanya jika NIP diisi)
        if (!empty($nip)) {
            $cek = $conn->query("SELECT id FROM users WHERE nip = '$nip'");
            if ($cek->num_rows > 0) {
                echo json_encode(["status" => "error", "message" => "NIP sudah terdaftar"]);
                exit;
            }
        }

        // Password default = NIP (jika ada) atau 'guru123'
        $pass_raw = !empty($nip) ? $nip : 'guru123';
        $hashed   = password_hash($pass_raw, PASSWORD_DEFAULT);

        // Insert directly into users
        $sqlUser = "INSERT INTO users (
                    name, role, password, nip, nik,
                    jenis_kelamin, tempat_lahir, tanggal_lahir,
                    agama, status_nikah,
                    status_kepeg, jabatan,
                    pendidikan, jurusan, tahun_mulai,
                    no_telp, email_guru, alamat,
                    id_kelas
                ) VALUES (
                    '$name', 'guru', '$hashed',
                    {$s($input['nip'])},           {$s($input['nik'])},
                    {$s($input['jenis_kelamin'])}, {$s($input['tempat_lahir'])},
                    {$s($input['tanggal_lahir'])},
                    {$s($input['agama'])},         {$s($input['status_nikah'])},
                    {$s($input['status_kepeg'])},  {$s($input['jabatan'])},
                    {$s($input['pendidikan'])},    {$s($input['jurusan'])},
                    {$s($input['tahun_mulai'])},
                    {$s($input['no_telp'])},       {$s($input['email_guru'])},
                    {$s($input['alamat'])},
                    $id_kelas
                )";
        
        if ($conn->query($sqlUser)) {
            $userId = $conn->insert_id;
            logActivity(
                getPdo(),
                "Data guru ditambahkan",
                "Guru '{$name}' berhasil dibuat",
                "guru",
                "tambah",
                $currentUserId,
                $currentUserRole
            );
            echo json_encode([
                "status"  => "success",
                "message" => "Guru berhasil ditambahkan",
                "id"      => $userId,
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => "Gagal menambahkan guru: " . $conn->error]);
        }

    // ── UPDATE ─────────────────────────────────────────────────────────────
    } elseif ($action === 'update') {
        $id       = intval($input['id'] ?? 0);
        $name     = $conn->real_escape_string($input['name'] ?? '');
        $nip      = $conn->real_escape_string($input['nip']  ?? '');
        $id_kelas = !empty($input['id_kelas']) ? intval($input['id_kelas']) : 'NULL';

        if ($id <= 0) {
            echo json_encode(["status" => "error", "message" => "ID tidak valid"]);
            exit;
        }

        // Cek NIP duplikat dengan guru lain
        if (!empty($nip)) {
            $cek = $conn->query("SELECT id FROM users WHERE nip = '$nip' AND id != $id");
            if ($cek->num_rows > 0) {
                echo json_encode(["status" => "error", "message" => "NIP sudah digunakan guru lain"]);
                exit;
            }
        }

        // Update users table directly
        $sqlUser = "UPDATE users SET
                    name            = '$name',
                    nip             = {$s($input['nip'] ?? null)},
                    nik             = {$s($input['nik'] ?? null)},
                    jenis_kelamin   = {$s($input['jenis_kelamin'] ?? null)},
                    tempat_lahir    = {$s($input['tempat_lahir'] ?? null)},
                    tanggal_lahir   = {$s($input['tanggal_lahir'] ?? null)},
                    agama           = {$s($input['agama'] ?? null)},
                    status_nikah    = {$s($input['status_nikah'] ?? null)},
                    status_kepeg    = {$s($input['status_kepeg'] ?? null)},
                    jabatan         = {$s($input['jabatan'] ?? null)},
                    pendidikan      = {$s($input['pendidikan'] ?? null)},
                    jurusan         = {$s($input['jurusan'] ?? null)},
                    tahun_mulai     = {$s($input['tahun_mulai'] ?? null)},
                    no_telp         = {$s($input['no_telp'] ?? null)},
                    email_guru      = {$s($input['email_guru'] ?? null)},
                    alamat          = {$s($input['alamat'] ?? null)},
                    id_kelas        = $id_kelas
                WHERE id = $id AND role = 'guru'";
        
        if ($conn->query($sqlUser)) {
            logActivity(
                getPdo(),
                "Data guru diperbarui",
                "Guru '{$name}' berhasil diperbarui",
                "guru",
                "edit",
                $currentUserId,
                $currentUserRole
            );
            echo json_encode(["status" => "success", "message" => "Data guru berhasil diperbarui"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Gagal memperbarui guru: " . $conn->error]);
        }

    // ── DELETE ─────────────────────────────────────────────────────────────
    } elseif ($action === 'delete') {
        $id = intval($input['id'] ?? 0);

        if ($id <= 0) {
            echo json_encode(["status" => "error", "message" => "ID tidak valid"]);
            exit;
        }

        $get_name = $conn->query("SELECT name FROM users WHERE id = $id AND role = 'guru' LIMIT 1");
        $name = "ID $id";
        if ($get_name && $row = $get_name->fetch_assoc()) {
            $name = $row['name'];
        }

        // Lepas relasi kelas terlebih dahulu sebelum hapus
        $conn->query("UPDATE users SET id_kelas = NULL WHERE id = $id");

        if ($conn->query("DELETE FROM users WHERE id = $id AND role = 'guru'")) {
            logActivity(
                getPdo(),
                "Data guru dihapus",
                "Guru '{$name}' berhasil dihapus",
                "guru",
                "hapus",
                $currentUserId,
                $currentUserRole
            );
            echo json_encode(["status" => "success", "message" => "Guru berhasil dihapus"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Action tidak dikenali"]);
    }
}

$conn->close();
?>