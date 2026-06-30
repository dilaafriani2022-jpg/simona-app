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

// ── Auto-migration: buat tabel refleksi ────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
$method = $_SERVER['REQUEST_METHOD'];

// ════════════════════════════════════════════════════════════════════════════
// GET
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $id_guru = isset($_GET['id_guru']) ? intval($_GET['id_guru']) : null;
    $id_kelas = isset($_GET['id_kelas']) ? intval($_GET['id_kelas']) : null;
    $id_anak = isset($_GET['id_anak']) ? intval($_GET['id_anak']) : null;
    $semester = isset($_GET['semester']) ? intval($_GET['semester']) : null;
    $minggu_ke = isset($_GET['minggu_ke']) ? intval($_GET['minggu_ke']) : null;

    $sql = "SELECT
                r.*,
                r.id_user AS id_guru,
                g.name AS nama_guru,
                k.nama_kelas,
                a.nama_anak AS nama_anak
            FROM refleksi r
            JOIN users  g ON r.id_user  = g.id
            JOIN kelas k ON r.id_kelas = k.id
            LEFT JOIN anak a ON r.id_anak = a.id
            WHERE r.tipe = 'guru'";

    if ($id_guru) {
        $sql .= " AND r.id_user = $id_guru";
    }
    if ($id_kelas) $sql .= " AND r.id_kelas = $id_kelas";
    if ($id_anak) $sql .= " AND r.id_anak = $id_anak";
    if ($semester) $sql .= " AND r.semester = $semester";
    if ($minggu_ke) $sql .= " AND r.minggu_ke = $minggu_ke";

    $sql .= " ORDER BY r.tanggal DESC, r.minggu_ke DESC";

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
    $input = json_decode(file_get_contents("php://input"), true);
    $action = $input['action'] ?? '';

    $s = fn($v) => isset($v) && $v !== ''
        ? "'" . $conn->real_escape_string((string)$v) . "'"
        : "NULL";

    // ── ADD ────────────────────────────────────────────────────────────────
    if ($action === 'add') {
        $id_guru = intval($input['id_guru'] ?? 0);
        $id_kelas = intval($input['id_kelas'] ?? 0);
        $id_anak = isset($input['id_anak']) && intval($input['id_anak']) > 0 ? intval($input['id_anak']) : null;
        $semester = intval($input['semester'] ?? 1);
        $minggu_ke = intval($input['minggu_ke'] ?? 1);
        $tanggal = $conn->real_escape_string($input['tanggal'] ?? date('Y-m-d'));

        if ($id_guru <= 0 || $id_kelas <= 0) {
            echo json_encode(["status" => "error", "message" => "Guru dan kelas wajib diisi"]);
            exit;
        }

        $sql = "INSERT INTO refleksi 
                    (tipe, id_user, id_kelas, id_anak, semester, minggu_ke, tanggal,
                     pencapaian, hambatan, solusi, rencana_tindak_lanjut,
                     catatan_perilaku, catatan_pembelajaran, catatan_sosial,
                     kinerja_guru, kehadiran_guru, kesiapan_materi)
                VALUES 
                    ('guru', $id_guru, $id_kelas, " . ($id_anak !== null ? $id_anak : "NULL") . ", $semester, $minggu_ke, '$tanggal',
                     {$s($input['pencapaian'])}, {$s($input['hambatan'])}, 
                     {$s($input['solusi'])}, {$s($input['rencana_tindak_lanjut'])},
                     {$s($input['catatan_perilaku'])}, {$s($input['catatan_pembelajaran'])},
                     {$s($input['catatan_sosial'])},
                     {$s($input['kinerja_guru'])}, 
                     " . intval($input['kehadiran_guru'] ?? 0) . ",
                     {$s($input['kesiapan_materi'])})
                ON DUPLICATE KEY UPDATE
                pencapaian = {$s($input['pencapaian'])},
                hambatan = {$s($input['hambatan'])},
                solusi = {$s($input['solusi'])},
                rencana_tindak_lanjut = {$s($input['rencana_tindak_lanjut'])},
                catatan_perilaku = {$s($input['catatan_perilaku'])},
                catatan_pembelajaran = {$s($input['catatan_pembelajaran'])},
                catatan_sosial = {$s($input['catatan_sosial'])},
                kinerja_guru = {$s($input['kinerja_guru'])},
                kehadiran_guru = " . intval($input['kehadiran_guru'] ?? 0) . ",
                kesiapan_materi = {$s($input['kesiapan_materi'])}";

        if ($conn->query($sql)) {
            echo json_encode(["status" => "success", "message" => "Refleksi guru berhasil disimpan", "id" => $conn->insert_id]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    // ── UPDATE ─────────────────────────────────────────────────────────────
    } elseif ($action === 'update') {
        $id = intval($input['id'] ?? 0);

        if ($id <= 0) {
            echo json_encode(["status" => "error", "message" => "ID tidak valid"]);
            exit;
        }

        $sql = "UPDATE refleksi SET
                    pencapaian = {$s($input['pencapaian'])},
                    hambatan = {$s($input['hambatan'])},
                    solusi = {$s($input['solusi'])},
                    rencana_tindak_lanjut = {$s($input['rencana_tindak_lanjut'])},
                    catatan_perilaku = {$s($input['catatan_perilaku'])},
                    catatan_pembelajaran = {$s($input['catatan_pembelajaran'])},
                    catatan_sosial = {$s($input['catatan_sosial'])},
                    kinerja_guru = {$s($input['kinerja_guru'])},
                    kehadiran_guru = " . intval($input['kehadiran_guru'] ?? 0) . ",
                    kesiapan_materi = {$s($input['kesiapan_materi'])}
                WHERE id = $id AND tipe = 'guru'";

        if ($conn->query($sql)) {
            echo json_encode(["status" => "success", "message" => "Refleksi guru berhasil diperbarui"]);
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

        if ($conn->query("DELETE FROM refleksi WHERE id = $id AND tipe = 'guru'")) {
            echo json_encode(["status" => "success", "message" => "Refleksi guru berhasil dihapus"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    } else {
        echo json_encode(["status" => "error", "message" => "Action tidak dikenali"]);
    }
}

$conn->close();
?>
