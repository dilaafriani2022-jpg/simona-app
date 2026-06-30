<?php
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

// ── Auto-migration: buat tabel ekstrakurikuler ────────────────────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS ekstrakurikuler (
        id              INT AUTO_INCREMENT PRIMARY KEY,
        nama            VARCHAR(100) NOT NULL,
        deskripsi       TEXT DEFAULT NULL,
        created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
");

// ── Tabel: Partisipasi anak di ekstrakurikuler ────────────────────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS anak_ekstrakurikuler (
        id                  INT AUTO_INCREMENT PRIMARY KEY,
        id_anak            INT NOT NULL,
        id_guru             INT NOT NULL,
        id_ekstrakurikuler  INT NOT NULL,
        semester            TINYINT DEFAULT 1,
        prestasi            VARCHAR(255) DEFAULT NULL,
        catatan             TEXT DEFAULT NULL,
        tanggal_input       DATE DEFAULT CURRENT_DATE,
        created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (id_anak) REFERENCES anak(id),
        FOREIGN KEY (id_guru) REFERENCES users(id),
        FOREIGN KEY (id_ekstrakurikuler) REFERENCES ekstrakurikuler(id),
        UNIQUE KEY unique_anak_ekstra (id_anak, id_ekstrakurikuler, semester)
    )
");

// ─────────────────────────────────────────────────────────────────────────────
$method = $_SERVER['REQUEST_METHOD'];

// ════════════════════════════════════════════════════════════════════════════
// GET
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $type = isset($_GET['type']) ? $_GET['type'] : 'list'; // list, anak-ekstra
    $id_guru = isset($_GET['id_guru']) ? intval($_GET['id_guru']) : null;
    $id_anak = isset($_GET['id_anak']) ? intval($_GET['id_anak']) : null;
    $semester = isset($_GET['semester']) ? intval($_GET['semester']) : null;
    $search = isset($_GET['search']) ? $conn->real_escape_string($_GET['search']) : '';

    if ($type === 'list') {
        // Daftar ekstrakurikuler
        $sql = "SELECT * FROM ekstrakurikuler";
        if ($search) $sql .= " WHERE nama LIKE '%$search%'";
        $sql .= " ORDER BY nama ASC";
        
        $result = $conn->query($sql);
        if (!$result) {
            echo json_encode(["status" => "error", "message" => $conn->error]);
            exit;
        }
        
        $data = [];
        while ($row = $result->fetch_assoc()) $data[] = $row;
        echo json_encode(["status" => "success", "data" => $data]);
    } 
    elseif ($type === 'anak-ekstra') {
        // Partisipasi ekstrakurikuler per anak
        $sql = "SELECT
                    se.*,
                    s.nama_anak AS nama_anak, s.nisn,
                    e.nama AS nama_ekstrakurikuler, e.deskripsi,
                    g.name AS nama_guru
                FROM anak_ekstrakurikuler se
                JOIN anak s ON se.id_anak = s.id
                JOIN ekstrakurikuler e ON se.id_ekstrakurikuler = e.id
                JOIN users g ON se.id_guru = g.id
                WHERE 1=1";
        
        if ($id_anak) $sql .= " AND se.id_anak = $id_anak";
        if ($id_guru) {
            $sql .= " AND se.id_guru = $id_guru";
        }
        if ($semester) $sql .= " AND se.semester = $semester";
        if ($search) $sql .= " AND (s.nama_anak LIKE '%$search%' OR e.nama LIKE '%$search%')";
        
        $sql .= " ORDER BY s.nama_anak ASC, e.nama ASC";
        
        $result = $conn->query($sql);
        if (!$result) {
            echo json_encode(["status" => "error", "message" => $conn->error]);
            exit;
        }
        
        $data = [];
        while ($row = $result->fetch_assoc()) $data[] = $row;
        echo json_encode(["status" => "success", "data" => $data]);
    }

// ════════════════════════════════════════════════════════════════════════════
// POST
// ════════════════════════════════════════════════════════════════════════════
} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);
    $action = $input['action'] ?? '';

    $s = fn($v) => isset($v) && $v !== ''
        ? "'" . $conn->real_escape_string((string)$v) . "'"
        : "NULL";

    // ── ADD / UPDATE Ekstrakurikuler ───────────────────────────────────────
    if ($action === 'add_ekstra') {
        $nama = $conn->real_escape_string($input['nama'] ?? '');
        $deskripsi = $conn->real_escape_string($input['deskripsi'] ?? '');

        if (empty($nama)) {
            echo json_encode(["status" => "error", "message" => "Nama ekstrakurikuler wajib diisi"]);
            exit;
        }

        $sql = "INSERT INTO ekstrakurikuler (nama, deskripsi)
                VALUES ('$nama', {$s($deskripsi)})
                ON DUPLICATE KEY UPDATE
                deskripsi = {$s($deskripsi)}";

        if ($conn->query($sql)) {
            echo json_encode(["status" => "success", "message" => "Ekstrakurikuler berhasil ditambahkan", "id" => $conn->insert_id]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    // ── ADD / UPDATE Partisipasi Anak ──────────────────────────────────────
    } elseif ($action === 'add_anak_ekstra') {
        $id_anak = intval($input['id_anak'] ?? 0);
        $id_guru = intval($input['id_guru'] ?? 0);
        $id_ekstrakurikuler = intval($input['id_ekstrakurikuler'] ?? 0);
        $semester = intval($input['semester'] ?? 1);
        $prestasi = $conn->real_escape_string($input['prestasi'] ?? '');
        $catatan = $conn->real_escape_string($input['catatan'] ?? '');

        if ($id_anak <= 0 || $id_ekstrakurikuler <= 0) {
            echo json_encode(["status" => "error", "message" => "Anak dan ekstrakurikuler wajib dipilih"]);
            exit;
        }

        $sql = "INSERT INTO anak_ekstrakurikuler 
                    (id_anak, id_guru, id_ekstrakurikuler, semester, prestasi, catatan)
                VALUES 
                    ($id_anak, $id_guru, $id_ekstrakurikuler, $semester, {$s($prestasi)}, {$s($catatan)})
                ON DUPLICATE KEY UPDATE
                prestasi = {$s($prestasi)},
                catatan = {$s($catatan)}";

        if ($conn->query($sql)) {
            echo json_encode(["status" => "success", "message" => "Data ekstrakurikuler anak berhasil disimpan"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    // ── DELETE Partisipasi Anak ────────────────────────────────────────────
    } elseif ($action === 'delete_anak_ekstra') {
        $id = intval($input['id'] ?? 0);

        if ($id <= 0) {
            echo json_encode(["status" => "error", "message" => "ID tidak valid"]);
            exit;
        }

        if ($conn->query("DELETE FROM anak_ekstrakurikuler WHERE id = $id")) {
            echo json_encode(["status" => "success", "message" => "Data berhasil dihapus"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    } else {
        echo json_encode(["status" => "error", "message" => "Action tidak dikenali"]);
    }
}

$conn->close();
?>
