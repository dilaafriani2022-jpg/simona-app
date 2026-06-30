<?php
require_once 'cors.php';
header("Content-Type: application/json");

require_once 'config.php';      // sediakan $conn (MySQLi) + $host,$user,$pass,$db
require_once 'log_activity.php';

// ── Pastikan kolom deskripsi ada ────────────────────────
$conn->query("ALTER TABLE aspek_penilaian ADD COLUMN IF NOT EXISTS deskripsi TEXT DEFAULT NULL");

// ── PDO pakai variabel dari config.php ($host,$user,$pass,$db) ─
function getPdo(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        // Akses variabel global dari config.php
        global $host, $user, $pass, $db;
        $pdo = new PDO(
            "mysql:host={$host};dbname={$db};charset=utf8mb4",
            $user,
            $pass,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
        );
    }
    return $pdo;
}

// ── Helper response ───────────────────────────────────────────
function respond(array $data): void {
    echo json_encode($data);
    exit;
}

// ── Helper validasi string wajib ──────────────────────────────
function requireString(array $input, string $key, string $label): string {
    $val = trim($input[$key] ?? '');
    if ($val === '') {
        respond(["status" => "error", "message" => "$label wajib diisi"]);
    }
    return $val;
}

// ════════════════════════════════════════════════════════════
// GET
// ════════════════════════════════════════════════════════════
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $stmt = $conn->prepare("SELECT * FROM aspek_penilaian ORDER BY nama_aspek ASC");
    $stmt->execute();
    $result = $stmt->get_result();
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
    respond(["status" => "success", "data" => $data]);
}

// ════════════════════════════════════════════════════════════
// POST
// ════════════════════════════════════════════════════════════
elseif ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true) ?? [];
    $action = $input['action'] ?? '';
    
    // ── Ambil user yang melakukan aktivitas (graceful fallback) ──
    $currentUser = $input['user'] ?? null;
    $currentUserId = $currentUser['id'] ?? null;
    $currentUserRole = $currentUser['role'] ?? null;

    // ── ADD ──────────────────────────────────────────────────
    if ($action === 'add') {
        $nama = requireString($input, 'nama_aspek', 'Nama aspek');
        $desk = trim($input['deskripsi'] ?? '');

        $stmt = $conn->prepare(
            "INSERT INTO aspek_penilaian (nama_aspek, deskripsi) VALUES (?, ?)"
        );
        $stmt->bind_param("ss", $nama, $desk);

        if ($stmt->execute()) {
            logActivity(
                getPdo(),
                "Aspek penilaian ditambahkan",
                "Aspek '{$nama}' berhasil dibuat",
                "aspek",
                "tambah",
                $currentUserId,
                $currentUserRole
            );
            respond(["status" => "success", "message" => "Aspek berhasil ditambahkan"]);
        } else {
            respond(["status" => "error", "message" => $stmt->error]);
        }
    }

    // ── UPDATE ───────────────────────────────────────────────
    elseif ($action === 'update') {
        $id   = intval($input['id'] ?? 0);
        $nama = requireString($input, 'nama_aspek', 'Nama aspek');
        $desk = trim($input['deskripsi'] ?? '');

        if ($id <= 0) {
            respond(["status" => "error", "message" => "ID tidak valid"]);
        }

        $stmt = $conn->prepare(
            "UPDATE aspek_penilaian SET nama_aspek=?, deskripsi=? WHERE id=?"
        );
        $stmt->bind_param("ssi", $nama, $desk, $id);

        if ($stmt->execute()) {
            logActivity(
                getPdo(),
                "Aspek penilaian diperbarui",
                "Aspek '{$nama}' berhasil diperbarui",
                "aspek",
                "edit",
                $currentUserId,
                $currentUserRole
            );
            respond(["status" => "success", "message" => "Aspek berhasil diperbarui"]);
        } else {
            respond(["status" => "error", "message" => $stmt->error]);
        }
    }

    // ── DELETE ───────────────────────────────────────────────
    elseif ($action === 'delete') {
        $id = intval($input['id'] ?? 0);

        if ($id <= 0) {
            respond(["status" => "error", "message" => "ID tidak valid"]);
        }

        // Cek apakah aspek sudah digunakan di tujuan pembelajaran
        $checkStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM tujuan_pembelajaran WHERE id_aspek = ?");
        $checkStmt->bind_param("i", $id);
        $checkStmt->execute();
        $checkRow = $checkStmt->get_result()->fetch_assoc();
        
        if ($checkRow['cnt'] > 0) {
            respond(["status" => "error", "message" => "Aspek tidak bisa dihapus karena sudah digunakan dalam " . $checkRow['cnt'] . " tujuan pembelajaran"]);
        }

        // Ambil nama sebelum dihapus untuk dicatat di log
        $stmtGet = $conn->prepare("SELECT nama_aspek FROM aspek_penilaian WHERE id=?");
        $stmtGet->bind_param("i", $id);
        $stmtGet->execute();
        $row  = $stmtGet->get_result()->fetch_assoc();
        $nama = $row['nama_aspek'] ?? "ID $id";

        $stmt = $conn->prepare("DELETE FROM aspek_penilaian WHERE id=?");
        $stmt->bind_param("i", $id);

        if ($stmt->execute()) {
            logActivity(
                getPdo(),
                "Aspek penilaian dihapus",
                "Aspek '{$nama}' dihapus dari sistem",
                "aspek",
                "hapus",
                $currentUserId,
                $currentUserRole
            );
            respond(["status" => "success", "message" => "Aspek berhasil dihapus"]);
        } else {
            respond(["status" => "error", "message" => $stmt->error]);
        }
    }

    else {
        respond(["status" => "error", "message" => "Action tidak dikenali"]);
    }
}

else {
    respond(["status" => "error", "message" => "Method tidak didukung"]);
}

$conn->close();
?>