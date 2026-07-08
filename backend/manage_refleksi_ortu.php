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

// ── Auto-migration: buat tabel refleksi ─────────────────────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS refleksi (
        id INT AUTO_INCREMENT PRIMARY KEY,
        tipe ENUM('guru', 'orang_tua') NOT NULL,
        id_user INT NOT NULL, -- merujuk langsung ke users.id
        id_anak INT DEFAULT NULL,
        id_kelas INT DEFAULT NULL,
        semester TINYINT DEFAULT 1,
        minggu_ke TINYINT DEFAULT 1,
        bulan TINYINT DEFAULT 1,
        tanggal DATE DEFAULT NULL,
        
        -- Khusus Orang Tua
        judul VARCHAR(200) DEFAULT NULL,
        isi TEXT DEFAULT NULL,
        
        -- Khusus Guru
        pencapaian TEXT DEFAULT NULL,
        hambatan TEXT DEFAULT NULL,
        solusi TEXT DEFAULT NULL,
        rencana_tindak_lanjut TEXT DEFAULT NULL,
        catatan_perilaku TEXT DEFAULT NULL,
        catatan_pembelajaran TEXT DEFAULT NULL,
        catatan_sosial TEXT DEFAULT NULL,
        kinerja_guru ENUM('sangat_baik', 'baik', 'cukup', 'kurang') DEFAULT NULL,
        kehadiran_guru TINYINT DEFAULT 0,
        kesiapan_materi ENUM('siap', 'cukup_siap', 'belum_siap') DEFAULT NULL,
        
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        
        FOREIGN KEY (id_user) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
        FOREIGN KEY (id_kelas) REFERENCES kelas(id) ON DELETE SET NULL,
        UNIQUE KEY unique_refleksi (id_user, id_kelas, id_anak, semester, minggu_ke)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

$method = $_SERVER['REQUEST_METHOD'];

// ════════════════════════════════════════════════════════════════════════════
// GET — ambil refleksi orang tua untuk anak tertentu
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $id_anak = isset($_GET['id_anak']) ? intval($_GET['id_anak']) : null;
    $id_ortu  = isset($_GET['id_ortu'])  ? intval($_GET['id_ortu'])  : null;
    $id_kelas = isset($_GET['id_kelas']) ? intval($_GET['id_kelas']) : null;
    $semester = isset($_GET['semester']) ? intval($_GET['semester']) : null;

    if (!$id_anak && !$id_kelas) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'id_anak atau id_kelas wajib diisi']);
        exit;
    }

    $where = "WHERE ro.tipe = 'orang_tua'";
    if ($id_anak) $where .= " AND ro.id_anak = $id_anak";
    if ($id_kelas) $where .= " AND a.id_kelas = $id_kelas";
    if ($id_ortu)  $where .= " AND ro.id_user = $id_ortu";
    if ($semester) $where .= " AND ro.semester = $semester";

    $sql = "SELECT ro.*,
                   ro.id_user AS id_ortu,
                   a.nama_anak AS nama_anak,
                   ot.name    AS nama_ortu
            FROM refleksi ro
            LEFT JOIN anak       a  ON ro.id_anak = a.id
            LEFT JOIN users      ot ON ro.id_user  = ot.id
            $where
            ORDER BY ro.created_at DESC";

    $result = $conn->query($sql);
    if (!$result) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => $conn->error]);
        exit;
    }

    $data = [];
    while ($row = $result->fetch_assoc()) $data[] = $row;

    echo json_encode(['status' => 'success', 'data' => $data, 'total' => count($data)]);
    exit;
}

// ════════════════════════════════════════════════════════════════════════════
// POST — simpan refleksi baru dari orang tua
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'POST') {
    $body = json_decode(file_get_contents('php://input'), true) ?? [];
    $action = $body['action'] ?? '';

    // -- DELETE action --
    if ($action === 'delete') {
        $id = intval($body['id'] ?? 0);
        if ($id <= 0) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'ID tidak valid']);
            exit;
        }
        if ($conn->query("DELETE FROM refleksi WHERE id = $id AND tipe = 'orang_tua'")) {
            echo json_encode(['status' => 'success', 'message' => 'Refleksi berhasil dihapus']);
        } else {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $conn->error]);
        }
        exit;
    }

    // -- UPDATE action --
    if ($action === 'update') {
        $id = intval($body['id'] ?? 0);
        $judul = $conn->real_escape_string($body['judul'] ?? '');
        $isi   = $conn->real_escape_string($body['isi'] ?? '');

        if ($id <= 0 || !$isi) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'ID dan isi wajib diisi']);
            exit;
        }

        $sql = "UPDATE refleksi SET judul = '$judul', isi = '$isi' WHERE id = $id AND tipe = 'orang_tua'";
        if ($conn->query($sql)) {
            echo json_encode(['status' => 'success', 'message' => 'Refleksi berhasil diperbarui']);
        } else {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $conn->error]);
        }
        exit;
    }

    // -- SAVE action (default) --
    $id_ortu  = isset($body['id_ortu'])  ? intval($body['id_ortu'])  : null;
    $id_anak = isset($body['id_anak']) ? intval($body['id_anak']) : null;
    $id_kelas = isset($body['id_kelas']) ? intval($body['id_kelas']) : null;
    $semester = isset($body['semester']) ? intval($body['semester']) : 1;
    $bulan    = isset($body['bulan'])    ? intval($body['bulan'])    : date('n');
    $judul    = $conn->real_escape_string($body['judul'] ?? '');
    $isi      = $conn->real_escape_string($body['isi']   ?? '');

    if (!$id_anak || !$isi) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'id_anak dan isi wajib diisi']);
        exit;
    }

    $db_kelas = $id_kelas ? $id_kelas : "NULL";

    $sql = "INSERT INTO refleksi (tipe, id_user, id_anak, id_kelas, semester, bulan, judul, isi)
            VALUES ('orang_tua', $id_ortu, $id_anak, $db_kelas, $semester, $bulan, '$judul', '$isi')
            ON DUPLICATE KEY UPDATE judul = VALUES(judul), isi = VALUES(isi), bulan = VALUES(bulan)";

    if ($conn->query($sql)) {
        $insert_id = $conn->insert_id ?: 0;
        echo json_encode(['status' => 'success', 'message' => 'Refleksi berhasil disimpan', 'id' => $insert_id]);
    } else {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => $conn->error]);
    }
    exit;
}

http_response_code(405);
echo json_encode(['status' => 'error', 'message' => 'Method tidak didukung']);
$conn->close();
?>
