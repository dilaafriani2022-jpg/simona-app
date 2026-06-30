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

// ── Auto-migration: pastikan tabel absensi ada ────────────────────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS absensi (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        id_anak    INT NOT NULL,
        id_guru     INT NOT NULL,
        tanggal     DATE NOT NULL,
        status      ENUM('Hadir','Sakit','Izin','Alpa') DEFAULT 'Hadir',
        keterangan  TEXT DEFAULT NULL,
        created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_anak_tanggal (id_anak, tanggal),
        FOREIGN KEY (id_anak) REFERENCES anak(id),
        FOREIGN KEY (id_guru)  REFERENCES users(id)
    )
");

// ─────────────────────────────────────────────────────────────────────────────
$method = $_SERVER['REQUEST_METHOD'];

// ════════════════════════════════════════════════════════════════════════════
// GET
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $id_guru  = isset($_GET['id_guru'])  ? intval($_GET['id_guru'])  : null;
    $id_kelas = isset($_GET['id_kelas']) ? intval($_GET['id_kelas']) : null;
    $tanggal  = isset($_GET['tanggal'])
        ? $conn->real_escape_string($_GET['tanggal'])
        : date('Y-m-d');

    $sql = "SELECT
                a.*,
                s.nama_anak AS nama_anak,
                s.id_kelas,
                k.nama_kelas
            FROM absensi a
            JOIN anak        s ON a.id_anak = s.id
            LEFT JOIN kelas  k ON s.id_kelas = k.id
            WHERE a.tanggal = '$tanggal'";

    if ($id_guru) {
        $sql .= " AND a.id_guru  = $id_guru";
    }
    if ($id_kelas) $sql .= " AND s.id_kelas = $id_kelas";

    $sql .= " ORDER BY s.nama_anak ASC";

    $result = $conn->query($sql);
    if (!$result) {
        echo json_encode(["status" => "error", "message" => $conn->error]);
        exit;
    }

    $data = [];
    while ($row = $result->fetch_assoc()) $data[] = $row;

    echo json_encode(["status" => "success", "data" => $data]);

// ════════════════════════════════════════════════════════════════════════════
// POST
// ════════════════════════════════════════════════════════════════════════════
} elseif ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true);
    $action = $input['action'] ?? '';

    $validStatus = ['Hadir', 'Sakit', 'Izin', 'Alpa'];

    // ── ADD / UPDATE (upsert) ──────────────────────────────────────────────
    if ($action === 'add' || $action === 'update') {
        $id_anak   = intval($input['id_anak']  ?? 0);
        $id_guru = intval($input['id_guru']   ?? 0);
        
        $tanggal    = $conn->real_escape_string($input['tanggal']    ?? date('Y-m-d'));
        $status     = $conn->real_escape_string($input['status']     ?? 'Hadir');
        $keterangan = $conn->real_escape_string($input['keterangan'] ?? '');

        if (!in_array($status, $validStatus)) {
            echo json_encode(["status" => "error", "message" => "Status tidak valid"]);
            exit;
        }

        if ($id_anak <= 0 || $id_guru <= 0) {
            echo json_encode(["status" => "error", "message" => "Data anak dan guru wajib diisi"]);
            exit;
        }

        // Cek apakah sudah ada record untuk anak + tanggal ini
        $check = $conn->query(
            "SELECT id FROM absensi WHERE id_anak = $id_anak AND tanggal = '$tanggal'"
        );

        if ($check && $check->num_rows > 0) {
            // Update
            $sql = "UPDATE absensi
                    SET status     = '$status',
                        keterangan = '$keterangan',
                        id_guru    = $id_guru
                    WHERE id_anak = $id_anak AND tanggal = '$tanggal'";
            $msg = "Absensi berhasil diperbarui";
        } else {
            // Insert
            $sql = "INSERT INTO absensi (id_anak, id_guru, tanggal, status, keterangan)
                    VALUES ($id_anak, $id_guru, '$tanggal', '$status', '$keterangan')";
            $msg = "Absensi berhasil disimpan";
        }

        if ($conn->query($sql)) {
            echo json_encode(["status" => "success", "message" => $msg]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    // ── DELETE ─────────────────────────────────────────────────────────────
    } elseif ($action === 'delete') {
        $id = intval($input['id'] ?? 0);

        if ($id <= 0) {
            echo json_encode(["status" => "error", "message" => "ID tidak valid"]);
            exit;
        }

        if ($conn->query("DELETE FROM absensi WHERE id = $id")) {
            echo json_encode(["status" => "success", "message" => "Absensi berhasil dihapus"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    } else {
        echo json_encode(["status" => "error", "message" => "Action tidak dikenali"]);
    }
}

$conn->close();
?>