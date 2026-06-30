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

// ── Auto-migration ────────────────────────────────────────────────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS jadwal_kelas (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        id_kelas    INT NOT NULL,
        id_guru     INT DEFAULT NULL,
        hari        ENUM('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu') NOT NULL,
        jam_mulai   TIME NOT NULL,
        jam_selesai TIME NOT NULL,
        kegiatan    VARCHAR(150) NOT NULL,
        ruangan     VARCHAR(100) DEFAULT NULL,
        warna       VARCHAR(20)  DEFAULT NULL,
        created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_kelas) REFERENCES kelas(id),
        FOREIGN KEY (id_guru)  REFERENCES users(id)
    )
");

// Tambah kolom warna jika belum ada
$conn->query("ALTER TABLE jadwal_kelas ADD COLUMN IF NOT EXISTS warna VARCHAR(20) DEFAULT NULL");

// ─────────────────────────────────────────────────────────────────────────────
$method = $_SERVER['REQUEST_METHOD'];
$s = fn($v) => isset($v) && $v !== '' ? "'" . $conn->real_escape_string((string)$v) . "'" : "NULL";

// ════════════════════════════════════════════════════════════════════════════
// GET
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $id_guru  = isset($_GET['id_guru'])  ? intval($_GET['id_guru'])  : null;
    $id_kelas = isset($_GET['id_kelas']) ? intval($_GET['id_kelas']) : null;

    $sql = "SELECT jk.*, k.nama_kelas, g.name AS nama_guru
            FROM jadwal_kelas jk
            JOIN kelas k ON jk.id_kelas = k.id
            LEFT JOIN users g ON jk.id_guru = g.id
            WHERE 1=1";

    if ($id_guru) {
        $sql .= " AND jk.id_guru = $id_guru";
    }
    if ($id_kelas) $sql .= " AND jk.id_kelas = $id_kelas";

    $sql .= " ORDER BY FIELD(hari,'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'), jam_mulai ASC";

    $result = $conn->query($sql);
    if (!$result) { echo json_encode(["status" => "error", "message" => $conn->error]); exit; }

    $data = [];
    while ($row = $result->fetch_assoc()) $data[] = $row;
    echo json_encode(["status" => "success", "data" => $data]);

// ════════════════════════════════════════════════════════════════════════════
// POST
// ════════════════════════════════════════════════════════════════════════════
} elseif ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true);
    $action = $input['action'] ?? '';

    // ── ADD ────────────────────────────────────────────────────────────────
    if ($action === 'add') {
        $id_kelas   = intval($input['id_kelas']   ?? 0);
        $id_guru = !empty($input['id_guru']) ? intval($input['id_guru']) : null;
        $id_guru_sql = $id_guru ? $id_guru : 'NULL';
        $hari       = $conn->real_escape_string($input['hari']        ?? '');
        $jam_mulai  = $conn->real_escape_string($input['jam_mulai']   ?? '');
        $jam_sel    = $conn->real_escape_string($input['jam_selesai'] ?? '');
        $kegiatan   = $conn->real_escape_string($input['kegiatan']    ?? '');
        $ruangan    = $conn->real_escape_string($input['ruangan']     ?? '');
        $warna      = $conn->real_escape_string($input['warna']       ?? '');

        if ($id_kelas <= 0 || empty($hari) || empty($jam_mulai) || empty($jam_sel) || empty($kegiatan)) {
            echo json_encode(["status" => "error", "message" => "Data kelas, hari, jam, dan kegiatan wajib diisi"]);
            exit;
        }

        $sql = "INSERT INTO jadwal_kelas (id_kelas, id_guru, hari, jam_mulai, jam_selesai, kegiatan, ruangan, warna)
                VALUES ($id_kelas, $id_guru_sql, '$hari', '$jam_mulai', '$jam_sel', '$kegiatan', '$ruangan', '$warna')";

        if ($conn->query($sql)) {
            echo json_encode(["status" => "success", "message" => "Jadwal berhasil ditambahkan", "id" => $conn->insert_id]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    // ── UPDATE ─────────────────────────────────────────────────────────────
    } elseif ($action === 'update') {
        $id       = intval($input['id'] ?? 0);
        $id_guru_user = !empty($input['id_guru']) ? intval($input['id_guru']) : null;
        $id_guru_upd = $id_guru_user ? $id_guru_user : 'NULL';
        $hari     = $conn->real_escape_string($input['hari']        ?? '');
        $jam_mul  = $conn->real_escape_string($input['jam_mulai']   ?? '');
        $jam_sel  = $conn->real_escape_string($input['jam_selesai'] ?? '');
        $kegiatan = $conn->real_escape_string($input['kegiatan']    ?? '');
        $ruangan  = $conn->real_escape_string($input['ruangan']     ?? '');
        $warna    = $conn->real_escape_string($input['warna']       ?? '');

        $sql = "UPDATE jadwal_kelas SET
                    id_guru     = $id_guru_upd,
                    hari        = '$hari',
                    jam_mulai   = '$jam_mul',
                    jam_selesai = '$jam_sel',
                    kegiatan    = '$kegiatan',
                    ruangan     = '$ruangan',
                    warna       = '$warna'
                WHERE id = $id";

        if ($conn->query($sql)) {
            echo json_encode(["status" => "success", "message" => "Jadwal berhasil diperbarui"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    // ── DELETE ─────────────────────────────────────────────────────────────
    } elseif ($action === 'delete') {
        $id = intval($input['id'] ?? 0);
        if ($conn->query("DELETE FROM jadwal_kelas WHERE id = $id")) {
            echo json_encode(["status" => "success", "message" => "Jadwal berhasil dihapus"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Action tidak dikenali"]);
    }
}

$conn->close();
?>