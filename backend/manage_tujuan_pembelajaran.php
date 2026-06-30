<?php
require_once 'cors.php';
header("Content-Type: application/json");

require_once 'config.php';
require_once 'log_activity.php';

// ── Ensure tables exist ────────────────────────────────────────────────────
$conn->query("CREATE TABLE IF NOT EXISTS tujuan_pembelajaran (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_guru INT NOT NULL,
    id_aspek INT NOT NULL,
    nama_tujuan VARCHAR(255) NOT NULL,
    deskripsi TEXT,
    indikator TEXT,
    bulan TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (id_aspek) REFERENCES aspek_penilaian(id) ON DELETE CASCADE
)");

// ── Helper response ───────────────────────────────────────────────────────
function respond(array $data): void {
    echo json_encode($data);
    exit;
}

// ── Helper validasi ──────────────────────────────────────────────────────
function requireString(array $input, string $key, string $label): string {
    $val = trim($input[$key] ?? '');
    if ($val === '') {
        respond(["status" => "error", "message" => "$label wajib diisi"]);
    }
    return $val;
}

function getPdo(): PDO {
    static $pdo = null;
    if ($pdo === null) {
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

// ════════════════════════════════════════════════════════════════════════════
// GET
// ════════════════════════════════════════════════════════════════════════════
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $id_guru = isset($_GET['id_guru']) ? intval($_GET['id_guru']) : null;
    $bulan = isset($_GET['bulan']) ? intval($_GET['bulan']) : null;
    
    if (!$id_guru) {
        respond(["status" => "error", "message" => "ID guru wajib diisi"]);
    }
    
    $real_guru_id = $id_guru;

    $sql = "SELECT tp.*, ap.nama_aspek 
            FROM tujuan_pembelajaran tp 
            JOIN aspek_penilaian ap ON tp.id_aspek = ap.id 
            WHERE tp.id_guru = ?";
    if ($bulan) {
        $sql .= " AND tp.bulan = $bulan";
    }
    $sql .= " ORDER BY tp.nama_tujuan ASC";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $real_guru_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
    respond(["status" => "success", "data" => $data]);
}

// ════════════════════════════════════════════════════════════════════════════
// POST
// ════════════════════════════════════════════════════════════════════════════
elseif ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true) ?? [];
    $action = $input['action'] ?? '';
    
    // ── Ambil user yang melakukan aktivitas (graceful fallback) ──
    $currentUser = $input['user'] ?? null;
    $currentUserId = $currentUser['id'] ?? null;
    $currentUserRole = $currentUser['role'] ?? null;

    // ── ADD ──────────────────────────────────────────────────────────────
    if ($action === 'add') {
        $id_guru = intval($input['id_guru'] ?? 0);
        $id_aspek = intval($input['id_aspek'] ?? 0);
        $nama = requireString($input, 'nama_tujuan', 'Nama tujuan');
        $desk = trim($input['deskripsi'] ?? '');
        $indikator = trim($input['indikator'] ?? '');
        $bulan = intval($input['bulan'] ?? 1);

        if ($id_guru <= 0) {
            respond(["status" => "error", "message" => "ID guru tidak valid"]);
        }
        if ($id_aspek <= 0) {
            respond(["status" => "error", "message" => "ID aspek tidak valid"]);
        }

        $stmt = $conn->prepare(
            "INSERT INTO tujuan_pembelajaran (id_guru, id_aspek, nama_tujuan, deskripsi, indikator, bulan) 
             VALUES (?, ?, ?, ?, ?, ?)"
        );
        $stmt->bind_param("iisssi", $id_guru, $id_aspek, $nama, $desk, $indikator, $bulan);

        if ($stmt->execute()) {
            $id = $conn->insert_id;
            logActivity(
                getPdo(),
                "Tujuan pembelajaran ditambahkan",
                "Tujuan '{$nama}' berhasil dibuat",
                "aspek",
                "tambah",
                $currentUserId,
                $currentUserRole
            );
            respond(["status" => "success", "message" => "Tujuan pembelajaran berhasil ditambahkan", "id" => $id]);
        } else {
            respond(["status" => "error", "message" => "Error: " . $stmt->error]);
        }
    }

    // ── UPDATE ───────────────────────────────────────────────────────────
    elseif ($action === 'update') {
        $id   = intval($input['id'] ?? 0);
        $id_guru = intval($input['id_guru'] ?? 0);
        $id_aspek = intval($input['id_aspek'] ?? 0);
        $nama = requireString($input, 'nama_tujuan', 'Nama tujuan');
        $desk = trim($input['deskripsi'] ?? '');
        $indikator = trim($input['indikator'] ?? '');
        $bulan = intval($input['bulan'] ?? 1);

        if ($id <= 0) {
            respond(["status" => "error", "message" => "ID tidak valid"]);
        }
        if ($id_guru <= 0 || $id_aspek <= 0) {
            respond(["status" => "error", "message" => "ID guru/aspek tidak valid"]);
        }

        $stmt = $conn->prepare(
            "UPDATE tujuan_pembelajaran 
             SET id_aspek=?, nama_tujuan=?, deskripsi=?, indikator=?, bulan=?
             WHERE id=? AND id_guru=?"
        );
        $stmt->bind_param("isssiii", $id_aspek, $nama, $desk, $indikator, $bulan, $id, $id_guru);

        if ($stmt->execute()) {
            logActivity(
                getPdo(),
                "Tujuan pembelajaran diperbarui",
                "Tujuan '{$nama}' berhasil diperbarui",
                "aspek",
                "edit",
                $currentUserId,
                $currentUserRole
            );
            respond(["status" => "success", "message" => "Tujuan pembelajaran berhasil diperbarui"]);
        } else {
            respond(["status" => "error", "message" => $stmt->error]);
        }
    }

    // ── DELETE ───────────────────────────────────────────────────────────
    elseif ($action === 'delete') {
        $id = intval($input['id'] ?? 0);
        $id_guru = intval($input['id_guru'] ?? 0);

        if ($id <= 0 || $id_guru <= 0) {
            respond(["status" => "error", "message" => "ID tidak valid"]);
        }

        // Check if tujuan is used in kegiatan
        $checkStmt = $conn->prepare("SELECT COUNT(*) as cnt FROM kegiatan_pembelajaran WHERE id_tujuan = ?");
        $checkStmt->bind_param("i", $id);
        $checkStmt->execute();
        $checkRow = $checkStmt->get_result()->fetch_assoc();

        if ($checkRow['cnt'] > 0) {
            respond(["status" => "error", "message" => "Tujuan tidak bisa dihapus karena sudah digunakan dalam " . $checkRow['cnt'] . " kegiatan pembelajaran"]);
        }

        // Get name for logging
        $stmtGet = $conn->prepare("SELECT nama_tujuan FROM tujuan_pembelajaran WHERE id=? AND id_guru=?");
        $stmtGet->bind_param("ii", $id, $id_guru);
        $stmtGet->execute();
        $row = $stmtGet->get_result()->fetch_assoc();
        $nama = $row['nama_tujuan'] ?? "ID $id";

        $stmt = $conn->prepare("DELETE FROM tujuan_pembelajaran WHERE id=? AND id_guru=?");
        $stmt->bind_param("ii", $id, $id_guru);

        if ($stmt->execute()) {
            logActivity(
                getPdo(),
                "Tujuan pembelajaran dihapus",
                "Tujuan '{$nama}' dihapus dari sistem",
                "aspek",
                "hapus",
                $currentUserId,
                $currentUserRole
            );
            respond(["status" => "success", "message" => "Tujuan pembelajaran berhasil dihapus"]);
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
