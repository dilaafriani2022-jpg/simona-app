<?php
require_once 'cors.php';
header("Content-Type: application/json");

require_once 'config.php';
require_once 'log_activity.php';

// ── Ensure table exists ────────────────────────────────────────────────────
$conn->query("CREATE TABLE IF NOT EXISTS kegiatan_pembelajaran (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_guru INT NOT NULL,
    id_tujuan INT NOT NULL,
    nama_kegiatan VARCHAR(255) NOT NULL,
    deskripsi TEXT,
    bulan TINYINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (id_tujuan) REFERENCES tujuan_pembelajaran(id) ON DELETE CASCADE
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
    $id_tujuan = isset($_GET['id_tujuan']) ? intval($_GET['id_tujuan']) : null;
    $bulan = isset($_GET['bulan']) ? intval($_GET['bulan']) : null;
    
    if (!$id_guru) {
        respond(["status" => "error", "message" => "ID guru wajib diisi"]);
    }
    
    $real_guru_id = $id_guru;

    if ($id_tujuan) {
        // Get kegiatan for specific tujuan
        $sql = "SELECT kg.*, tp.nama_tujuan, ap.nama_aspek, tp.bulan as tujuan_bulan
                FROM kegiatan_pembelajaran kg 
                JOIN tujuan_pembelajaran tp ON kg.id_tujuan = tp.id 
                JOIN aspek_penilaian ap ON tp.id_aspek = ap.id 
                WHERE kg.id_guru = ? AND kg.id_tujuan = ?";
        if ($bulan) $sql .= " AND kg.bulan = $bulan";
        $sql .= " ORDER BY kg.nama_kegiatan ASC";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $real_guru_id, $id_tujuan);
    } else {
        // Get all kegiatan for guru
        $sql = "SELECT kg.*, tp.nama_tujuan, ap.nama_aspek, tp.bulan as tujuan_bulan
                FROM kegiatan_pembelajaran kg 
                JOIN tujuan_pembelajaran tp ON kg.id_tujuan = tp.id 
                JOIN aspek_penilaian ap ON tp.id_aspek = ap.id 
                WHERE kg.id_guru = ?";
        if ($bulan) $sql .= " AND kg.bulan = $bulan";
        $sql .= " ORDER BY kg.nama_kegiatan ASC";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $real_guru_id);
    }
    
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
        $id_tujuan = intval($input['id_tujuan'] ?? 0);
        $nama = requireString($input, 'nama_kegiatan', 'Nama kegiatan');
        $desk = trim($input['deskripsi'] ?? '');
        $bulan = intval($input['bulan'] ?? 1);

        if ($id_guru <= 0) {
            respond(["status" => "error", "message" => "ID guru tidak valid"]);
        }
        if ($id_tujuan <= 0) {
            respond(["status" => "error", "message" => "ID tujuan tidak valid"]);
        }

        // Verify tujuan belongs to this guru
        $checkStmt = $conn->prepare("SELECT id FROM tujuan_pembelajaran WHERE id = ? AND id_guru = ?");
        $checkStmt->bind_param("ii", $id_tujuan, $id_guru);
        $checkStmt->execute();
        if ($checkStmt->get_result()->num_rows === 0) {
            respond(["status" => "error", "message" => "Tujuan tidak ditemukan atau bukan milik Anda"]);
        }

        $stmt = $conn->prepare(
            "INSERT INTO kegiatan_pembelajaran (id_guru, id_tujuan, nama_kegiatan, deskripsi, bulan) 
             VALUES (?, ?, ?, ?, ?)"
        );
        $stmt->bind_param("iissi", $id_guru, $id_tujuan, $nama, $desk, $bulan);

        if ($stmt->execute()) {
            $id = $conn->insert_id;
            logActivity(
                getPdo(),
                "Kegiatan pembelajaran ditambahkan",
                "Kegiatan '{$nama}' berhasil dibuat",
                "aspek",
                "tambah",
                $currentUserId,
                $currentUserRole
            );
            respond(["status" => "success", "message" => "Kegiatan pembelajaran berhasil ditambahkan", "id" => $id]);
        } else {
            respond(["status" => "error", "message" => "Error: " . $stmt->error]);
        }
    }

    // ── UPDATE ───────────────────────────────────────────────────────────
    elseif ($action === 'update') {
        $id   = intval($input['id'] ?? 0);
        $id_guru = intval($input['id_guru'] ?? 0);
        $id_tujuan = intval($input['id_tujuan'] ?? 0);
        $nama = requireString($input, 'nama_kegiatan', 'Nama kegiatan');
        $desk = trim($input['deskripsi'] ?? '');
        $bulan = intval($input['bulan'] ?? 1);

        if ($id <= 0 || $id_guru <= 0 || $id_tujuan <= 0) {
            respond(["status" => "error", "message" => "ID tidak valid"]);
        }

        // Verify tujuan belongs to this guru
        $checkStmt = $conn->prepare("SELECT id FROM tujuan_pembelajaran WHERE id = ? AND id_guru = ?");
        $checkStmt->bind_param("ii", $id_tujuan, $id_guru);
        $checkStmt->execute();
        if ($checkStmt->get_result()->num_rows === 0) {
            respond(["status" => "error", "message" => "Tujuan tidak ditemukan atau bukan milik Anda"]);
        }

        $stmt = $conn->prepare(
            "UPDATE kegiatan_pembelajaran 
             SET id_tujuan=?, nama_kegiatan=?, deskripsi=?, bulan=? 
             WHERE id=? AND id_guru=?"
        );
        $stmt->bind_param("issiii", $id_tujuan, $nama, $desk, $bulan, $id, $id_guru);

        if ($stmt->execute()) {
            logActivity(
                getPdo(),
                "Kegiatan pembelajaran diperbarui",
                "Kegiatan '{$nama}' berhasil diperbarui",
                "aspek",
                "edit",
                $currentUserId,
                $currentUserRole
            );
            respond(["status" => "success", "message" => "Kegiatan pembelajaran berhasil diperbarui"]);
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

        // Get name for logging
        $stmtGet = $conn->prepare("SELECT nama_kegiatan FROM kegiatan_pembelajaran WHERE id=? AND id_guru=?");
        $stmtGet->bind_param("ii", $id, $id_guru);
        $stmtGet->execute();
        $row = $stmtGet->get_result()->fetch_assoc();
        $nama = $row['nama_kegiatan'] ?? "ID $id";

        $stmt = $conn->prepare("DELETE FROM kegiatan_pembelajaran WHERE id=? AND id_guru=?");
        $stmt->bind_param("ii", $id, $id_guru);

        if ($stmt->execute()) {
            logActivity(
                getPdo(),
                "Kegiatan pembelajaran dihapus",
                "Kegiatan '{$nama}' dihapus dari sistem",
                "aspek",
                "hapus",
                $currentUserId,
                $currentUserRole
            );
            respond(["status" => "success", "message" => "Kegiatan pembelajaran berhasil dihapus"]);
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
