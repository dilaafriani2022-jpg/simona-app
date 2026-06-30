<?php
// ── Tangkap semua output sebelum kita kirim JSON ──────────────────────────
ob_start();

ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Access-Control-Max-Age: 86400");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    ob_end_clean();
    http_response_code(200);
    exit;
}

function sendJson(array $payload, int $code = 200): void {
    ob_end_clean();
    http_response_code($code);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    require_once 'config.php';
    require_once 'log_activity.php';
    require_once 'auth_helper.php';
} catch (Throwable $e) {
    sendJson(["status" => "error", "message" => "Config error: " . $e->getMessage()], 500);
}

$rawInput = file_get_contents('php://input');
$data = json_decode($rawInput);

$currentUser = extractUserFromData($data);
$currentUserId = $currentUser['id'] ?? null;
$currentUserRole = $currentUser['role'] ?? null;

if (!isset($conn) || $conn->connect_error) {
    $msg = isset($conn) ? $conn->connect_error : 'Koneksi database tidak tersedia';
    sendJson(["status" => "error", "message" => "DB connect error: $msg"], 500);
}

$s = fn($v) => (isset($v) && $v !== '') ? "'" . $conn->real_escape_string((string)$v) . "'" : "NULL";

$method = $_SERVER['REQUEST_METHOD'];

// ════════════════════════════════════════════════════════════════════════════
//  GET
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $action = $_GET['action'] ?? '';

    // ── GET ANAK (ANAK) ───────────────────────────────────────────────────
    if ($action === 'get_anak') {
        $sql    = "SELECT id, nama_anak AS nama_anak, nisn, id_kelas FROM anak ORDER BY nama_anak ASC";
        $result = $conn->query($sql);

        if (!$result) {
            sendJson(["status" => "error", "message" => "Query error: " . $conn->error], 500);
        }

        $data = [];
        while ($row = $result->fetch_assoc()) $data[] = $row;

        sendJson(["status" => "success", "data" => $data]);
    }

    // ── GET SEMUA ORTU ─────────────────────────────────────────────────────
    $sql_ortu = "SELECT 
                    u.id, u.name, u.email,
                    u.no_hp, u.pekerjaan, u.alamat,
                    u.ayah_nama, u.ayah_nik, u.ayah_ttl, u.ayah_agama,
                    u.ayah_pendidikan, u.ayah_pekerjaan, u.ayah_penghasilan, u.ayah_hp, u.ayah_status,
                    u.ibu_nama, u.ibu_nik, u.ibu_ttl, u.ibu_agama,
                    u.ibu_pendidikan, u.ibu_pekerjaan, u.ibu_penghasilan, u.ibu_hp, u.ibu_status,
                    u.wali_nama, u.wali_hubungan, u.wali_pekerjaan, u.wali_hp,
                    u.rt_rw, u.kelurahan, u.kecamatan, u.kota, u.provinsi, u.kode_pos
                 FROM users u
                 WHERE u.role = 'orang_tua'
                 ORDER BY u.name ASC";

    $result_ortu = $conn->query($sql_ortu);

    if (!$result_ortu) {
        sendJson(["status" => "error", "message" => "Query error: " . $conn->error], 500);
    }

    $data = [];
    while ($ortu = $result_ortu->fetch_assoc()) {
        $user_id = (int)$ortu['id'];

        // Ambil anak yang terhubung lewat tabel anak
        $sql_anak = "SELECT a.id, a.nama_anak AS nama_anak, a.nisn 
                     FROM anak a 
                     WHERE a.id_ortu = $user_id";
                     
        $res_anak = $conn->query($sql_anak);

        $anak = [];
        if ($res_anak) {
            while ($row = $res_anak->fetch_assoc()) $anak[] = $row;
        }

        $ortu['anak'] = $anak;
        $data[]       = $ortu;
    }

    sendJson(["status" => "success", "data" => $data]);
}

// ════════════════════════════════════════════════════════════════════════════
//  POST
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'POST') {
    $raw  = file_get_contents("php://input");
    $data = json_decode($raw);

    if (json_last_error() !== JSON_ERROR_NONE) {
        sendJson(["status" => "error", "message" => "Request body bukan JSON valid: " . json_last_error_msg()], 400);
    }

    $action = $data->action ?? '';

    // ── ADD PARENT ─────────────────────────────────────────────────────────
    if ($action === 'add_parent') {
        $name      = $conn->real_escape_string($data->name      ?? '');
        $no_hp     = $conn->real_escape_string($data->no_hp     ?? '');
        $pekerjaan = $conn->real_escape_string($data->pekerjaan ?? '');
        $alamat    = $conn->real_escape_string($data->alamat    ?? '');
        $email     = $conn->real_escape_string($data->email     ?? '');
        $nisn      = $conn->real_escape_string($data->nisn      ?? '');

        if (empty($name)) {
            sendJson(["status" => "error", "message" => "Nama orang tua wajib diisi"], 400);
        }

        $password  = password_hash('ortu123', PASSWORD_BCRYPT);
        $email_val = $email ? "'$email'" : 'NULL';
        $nisn_val  = $nisn  ? "'$nisn'"  : 'NULL';

        // Insert directly into users
        $sqlUser = "INSERT INTO users (
                    name, role, nisn, email, password,
                    no_hp, no_telp, pekerjaan, alamat,
                    ayah_nama, ayah_nik, ayah_ttl, ayah_agama,
                    ayah_pendidikan, ayah_pekerjaan, ayah_penghasilan, ayah_hp, ayah_status,
                    ibu_nama, ibu_nik, ibu_ttl, ibu_agama,
                    ibu_pendidikan, ibu_pekerjaan, ibu_penghasilan, ibu_hp, ibu_status,
                    wali_nama, wali_hubungan, wali_pekerjaan, wali_hp,
                    rt_rw, kelurahan, kecamatan, kota, provinsi, kode_pos
                ) VALUES (
                    '$name', 'orang_tua', $nisn_val, $email_val, '$password',
                    '$no_hp', '$no_hp', '$pekerjaan', '$alamat',
                    {$s($data->ayah_nama)},        {$s($data->ayah_nik)},
                    {$s($data->ayah_ttl)},         {$s($data->ayah_agama)},
                    {$s($data->ayah_pendidikan)},  {$s($data->ayah_pekerjaan)},
                    {$s($data->ayah_penghasilan)}, {$s($data->ayah_hp)}, {$s($data->ayah_status ?? 'Hidup')},
                    {$s($data->ibu_nama)},         {$s($data->ibu_nik)},
                    {$s($data->ibu_ttl)},          {$s($data->ibu_agama)},
                    {$s($data->ibu_pendidikan)},   {$s($data->ibu_pekerjaan)},
                    {$s($data->ibu_penghasilan)},  {$s($data->ibu_hp)}, {$s($data->ibu_status ?? 'Hidup')},
                    {$s($data->wali_nama)},        {$s($data->wali_hubungan)},
                    {$s($data->wali_pekerjaan)},   {$s($data->wali_hp)},
                    {$s($data->rt_rw)},            {$s($data->kelurahan)},
                    {$s($data->kecamatan)},        {$s($data->kota)},
                    {$s($data->provinsi)},         {$s($data->kode_pos)}
                )";
        
        if ($conn->query($sqlUser)) {
            $userId = $conn->insert_id;
            logActivity(
                getPdo(),
                "Data orang tua ditambahkan",
                "Orang tua '{$name}' berhasil dibuat",
                "ortu",
                "tambah",
                $currentUserId,
                $currentUserRole
            );
            sendJson([
                "status"  => "success",
                "message" => "Orang tua berhasil ditambahkan",
                "ortu_id" => $userId,
            ]);
        } else {
            sendJson(["status" => "error", "message" => "Gagal membuat user orang tua: " . $conn->error], 500);
        }
    }

    // ── UPDATE DETAIL ──────────────────────────────────────────────────────
    if ($action === 'update_detail') {
        $ortu_id = (int)($data->ortu_id ?? 0); // user ID
        if ($ortu_id <= 0) {
            sendJson(["status" => "error", "message" => "ID orang tua tidak valid"], 400);
        }

        $name      = $conn->real_escape_string($data->name      ?? '');
        $no_hp     = $conn->real_escape_string($data->no_hp     ?? '');
        $pekerjaan = $conn->real_escape_string($data->pekerjaan ?? '');
        $alamat    = $conn->real_escape_string($data->alamat    ?? '');
        $email     = $conn->real_escape_string($data->email     ?? '');

        // Update users table directly
        $sqlUser = "UPDATE users SET
                    name             = '$name',
                    email            = '$email',
                    no_hp            = '$no_hp',
                    no_telp          = '$no_hp',
                    pekerjaan        = '$pekerjaan',
                    alamat           = '$alamat',
                    ayah_nama        = {$s($data->ayah_nama)},
                    ayah_nik         = {$s($data->ayah_nik)},
                    ayah_ttl         = {$s($data->ayah_ttl)},
                    ayah_agama       = {$s($data->ayah_agama)},
                    ayah_pendidikan  = {$s($data->ayah_pendidikan)},
                    ayah_pekerjaan   = {$s($data->ayah_pekerjaan)},
                    ayah_penghasilan = {$s($data->ayah_penghasilan)},
                    ayah_hp          = {$s($data->ayah_hp)},
                    ayah_status      = {$s($data->ayah_status ?? 'Hidup')},
                    ibu_nama         = {$s($data->ibu_nama)},
                    ibu_nik          = {$s($data->ibu_nik)},
                    ibu_ttl          = {$s($data->ibu_ttl)},
                    ibu_agama        = {$s($data->ibu_agama)},
                    ibu_pendidikan   = {$s($data->ibu_pendidikan)},
                    ibu_pekerjaan    = {$s($data->ibu_pekerjaan)},
                    ibu_penghasilan  = {$s($data->ibu_penghasilan)},
                    ibu_hp           = {$s($data->ibu_hp)},
                    ibu_status       = {$s($data->ibu_status ?? 'Hidup')},
                    wali_nama        = {$s($data->wali_nama)},
                    wali_hubungan    = {$s($data->wali_hubungan)},
                    wali_pekerjaan   = {$s($data->wali_pekerjaan)},
                    wali_hp          = {$s($data->wali_hp)},
                    rt_rw            = {$s($data->rt_rw)},
                    kelurahan        = {$s($data->kelurahan)},
                    kecamatan        = {$s($data->kecamatan)},
                    kota             = {$s($data->kota)},
                    provinsi         = {$s($data->provinsi)},
                    kode_pos         = {$s($data->kode_pos)}
                WHERE id = $ortu_id AND role = 'orang_tua'";
        
        if ($conn->query($sqlUser)) {
            logActivity(
                getPdo(),
                "Data orang tua diperbarui",
                "Orang tua '{$name}' berhasil diperbarui",
                "ortu",
                "edit",
                $currentUserId,
                $currentUserRole
            );
            sendJson(["status" => "success", "message" => "Data orang tua berhasil diperbarui"]);
        } else {
            sendJson(["status" => "error", "message" => "Gagal mengupdate orang tua: " . $conn->error], 500);
        }
    }

    // ── UPDATE LINK ANAK (ANAK) ───────────────────────────────────────────
    if ($action === 'update_link') {
        $ortu_id   = (int)($data->ortu_id ?? 0); // user ID
        $anak_ids = $data->anak_ids ?? [];

        if ($ortu_id <= 0) {
            sendJson(["status" => "error", "message" => "ID orang tua tidak valid"], 400);
        }

        // Cari nama orang tua dari tabel users
        $resOrtu = $conn->query("SELECT name FROM users WHERE id = $ortu_id AND role = 'orang_tua' LIMIT 1");
        if (!$resOrtu || $resOrtu->num_rows === 0) {
            sendJson(["status" => "error", "message" => "Profil orang tua tidak ditemukan untuk User ID $ortu_id"], 404);
        }
        $rowOrtu = $resOrtu->fetch_assoc();
        $name = $rowOrtu['name'];

        $conn->begin_transaction();
        try {
            // Lepas semua anak lama
            if (!$conn->query("UPDATE anak SET id_ortu = NULL WHERE id_ortu = $ortu_id")) {
                throw new Exception($conn->error);
            }

            // Hubungkan anak baru
            if (!empty($anak_ids)) {
                $safe_ids = array_map('intval', (array)$anak_ids);
                $ids_str  = implode(',', $safe_ids);
                if (!$conn->query("UPDATE anak SET id_ortu = $ortu_id WHERE id IN ($ids_str)")) {
                    throw new Exception($conn->error);
                }
            }
            
            logActivity(
                getPdo(),
                "Link anak orang tua diperbarui",
                "Menghubungkan anak ke orang tua '{$name}'",
                "ortu",
                "edit",
                $currentUserId,
                $currentUserRole
            );
            $conn->commit();
            sendJson(["status" => "success", "message" => "Data anak berhasil dihubungkan"]);
        } catch (Exception $e) {
            $conn->rollback();
            sendJson(["status" => "error", "message" => "Gagal menghubungkan: " . $e->getMessage()], 500);
        }
    }

    // ── DELETE ORTU ────────────────────────────────────────────────────────
    if ($action === 'delete_ortu') {
        $ortu_id = (int)($data->ortu_id ?? 0); // user ID

        if ($ortu_id <= 0) {
            sendJson(["status" => "error", "message" => "ID orang tua tidak valid"], 400);
        }

        // Cari nama orang tua dari tabel users
        $resOrtu = $conn->query("SELECT name FROM users WHERE id = $ortu_id AND role = 'orang_tua' LIMIT 1");
        if (!$resOrtu || $resOrtu->num_rows === 0) {
            sendJson(["status" => "error", "message" => "Data orang tua tidak ditemukan"], 404);
        }
        $row_ortu = $resOrtu->fetch_assoc();
        $name = $row_ortu['name'];

        $conn->begin_transaction();
        try {
            // 1. Putuskan relasi anak (data anak tidak terhapus)
            if (!$conn->query("UPDATE anak SET id_ortu = NULL WHERE id_ortu = $ortu_id")) {
                throw new Exception($conn->error);
            }

            // 2. Hapus user
            if (!$conn->query("DELETE FROM users WHERE id = $ortu_id AND role = 'orang_tua'")) {
                throw new Exception($conn->error);
            }

            $conn->commit();
            
            logActivity(
                getPdo(),
                "Data orang tua dihapus",
                "Orang tua '{$name}' berhasil dihapus",
                "ortu",
                "hapus",
                $currentUserId,
                $currentUserRole
            );
            sendJson(["status" => "success", "message" => "Data orang tua berhasil dihapus"]);
        } catch (Exception $e) {
            $conn->rollback();
            sendJson(["status" => "error", "message" => "Gagal menghapus: " . $e->getMessage()], 500);
        }
    }

    sendJson(["status" => "error", "message" => "Action '$action' tidak dikenali"], 400);
}

sendJson(["status" => "error", "message" => "Method tidak diizinkan"], 405);
?>