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

// ── Auto-migration: memastikan tabel ekstrakurikuler tunggal ada ────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS ekstrakurikuler (
        id                  INT AUTO_INCREMENT PRIMARY KEY,
        id_anak             INT NOT NULL,
        id_guru             INT NOT NULL,
        nama_ekstrakurikuler VARCHAR(100) NOT NULL,
        semester            TINYINT DEFAULT 1,
        prestasi            VARCHAR(255) DEFAULT NULL,
        catatan             TEXT DEFAULT NULL,
        tanggal_input       DATE DEFAULT CURRENT_DATE,
        created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
        FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE KEY unique_anak_ekstra (id_anak, nama_ekstrakurikuler, semester)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

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
        // Mengembalikan daftar nama ekstrakurikuler unik untuk autocomplete/saran dropdown
        $sql = "SELECT DISTINCT nama_ekstrakurikuler AS nama FROM ekstrakurikuler";
        if ($search) $sql .= " WHERE nama_ekstrakurikuler LIKE '%$search%'";
        $sql .= " ORDER BY nama_ekstrakurikuler ASC";
        
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
                    se.nama_ekstrakurikuler AS nama_ekstrakurikuler,
                    s.nama_anak AS nama_anak, s.nisn,
                    g.name AS nama_guru
                FROM ekstrakurikuler se
                JOIN anak s ON se.id_anak = s.id
                JOIN users g ON se.id_guru = g.id
                WHERE 1=1";
        
        if ($id_anak) $sql .= " AND se.id_anak = $id_anak";
        if ($id_guru) $sql .= " AND se.id_guru = $id_guru";
        if ($semester) $sql .= " AND se.semester = $semester";
        if ($search) $sql .= " AND (s.nama_anak LIKE '%$search%' OR se.nama_ekstrakurikuler LIKE '%$search%')";
        
        $sql .= " ORDER BY s.nama_anak ASC, se.nama_ekstrakurikuler ASC";
        
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

    // ── ADD / UPDATE Partisipasi Anak ──────────────────────────────────────
    if ($action === 'add_anak_ekstra') {
        $id = intval($input['id'] ?? 0);
        $id_anak = intval($input['id_anak'] ?? 0);
        $id_guru = intval($input['id_guru'] ?? 0);
        $nama_ekstrakurikuler = trim($input['nama_ekstrakurikuler'] ?? '');
        $semester = intval($input['semester'] ?? 1);
        $prestasi = $conn->real_escape_string($input['prestasi'] ?? '');
        $catatan = $conn->real_escape_string($input['catatan'] ?? '');

        if ($id_anak <= 0 || empty($nama_ekstrakurikuler)) {
            echo json_encode(["status" => "error", "message" => "Anak dan nama ekstrakurikuler wajib diisi"]);
            exit;
        }

        if ($id > 0) {
            // Update mode
            $sql = "UPDATE ekstrakurikuler SET
                        id_anak = $id_anak,
                        id_guru = $id_guru,
                        nama_ekstrakurikuler = '$nama_ekstrakurikuler',
                        semester = $semester,
                        prestasi = {$s($prestasi)},
                        catatan = {$s($catatan)}
                    WHERE id = $id";
        } else {
            // Insert mode
            $sql = "INSERT INTO ekstrakurikuler 
                        (id_anak, id_guru, nama_ekstrakurikuler, semester, prestasi, catatan)
                    VALUES 
                        ($id_anak, $id_guru, '$nama_ekstrakurikuler', $semester, {$s($prestasi)}, {$s($catatan)})
                    ON DUPLICATE KEY UPDATE
                    id_guru = $id_guru,
                    prestasi = {$s($prestasi)},
                    catatan = {$s($catatan)}";
        }

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

        if ($conn->query("DELETE FROM ekstrakurikuler WHERE id = $id")) {
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
