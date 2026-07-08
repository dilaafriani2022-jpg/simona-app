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

// ── Auto-migration: pastikan tabel penilaian ada ──────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS penilaian (
        id INT AUTO_INCREMENT PRIMARY KEY,
        tipe ENUM('checklist', 'anekdot', 'karya') NOT NULL,
        id_anak INT NOT NULL,
        id_guru INT NOT NULL,
        tanggal DATE NOT NULL,

        -- Checklist
        id_aspek INT DEFAULT NULL,
        id_tujuan INT DEFAULT NULL,
        id_kegiatan INT DEFAULT NULL,
        status ENUM('TM', 'MM', 'M') DEFAULT NULL,
        catatan TEXT DEFAULT NULL,
        konteks TEXT DEFAULT NULL,
        hasil TEXT DEFAULT NULL,
        kejadian TEXT DEFAULT NULL,

        -- Anekdot
        waktu TIME DEFAULT NULL,
        lokasi VARCHAR(255) DEFAULT NULL,
        aspek_perkembangan VARCHAR(100) DEFAULT NULL,
        peristiwa TEXT DEFAULT NULL,
        interpretasi TEXT DEFAULT NULL,
        tindak_lanjut TEXT DEFAULT NULL,

        -- Karya
        waktu_kegiatan VARCHAR(20) DEFAULT NULL,
        kategori VARCHAR(50) DEFAULT NULL,
        judul VARCHAR(255) DEFAULT NULL,
        deskripsi TEXT DEFAULT NULL,
        bahan TEXT DEFAULT NULL,
        url_foto VARCHAR(255) DEFAULT NULL,
        catatan_guru TEXT DEFAULT NULL,

        -- Metadata
        semester TINYINT DEFAULT 1,
        minggu_ke TINYINT DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

        FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
        FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (id_aspek) REFERENCES aspek_penilaian(id) ON DELETE SET NULL,
        FOREIGN KEY (id_tujuan) REFERENCES tujuan_pembelajaran(id) ON DELETE SET NULL,
        FOREIGN KEY (id_kegiatan) REFERENCES kegiatan_pembelajaran(id) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");


$method = $_SERVER['REQUEST_METHOD'];

// ════════════════════════════════════════════════════════════════════════════
// GET
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $id_guru  = isset($_GET['id_guru'])  ? intval($_GET['id_guru'])  : null;
    $id_kelas = isset($_GET['id_kelas']) ? intval($_GET['id_kelas']) : null;
    $id_anak = isset($_GET['id_anak']) ? intval($_GET['id_anak']) : null;
    $semester = isset($_GET['semester']) ? intval($_GET['semester']) : null;
    $search   = isset($_GET['search'])   ? $conn->real_escape_string($_GET['search']) : '';

    $sql = "SELECT
                pc.*,
                s.nama_anak AS nama_anak, s.nisn,
                ap.nama_aspek,
                tp.nama_tujuan,
                kp.nama_kegiatan,
                g.name AS nama_guru
            FROM penilaian pc
            JOIN anak               s  ON pc.id_anak  = s.id
            LEFT JOIN aspek_penilaian ap ON pc.id_aspek   = ap.id
            JOIN users              g  ON pc.id_guru    = g.id
            LEFT JOIN kegiatan_pembelajaran  kp ON pc.id_kegiatan = kp.id
            LEFT JOIN tujuan_pembelajaran    tp ON COALESCE(pc.id_tujuan, kp.id_tujuan) = tp.id
            WHERE pc.tipe = 'checklist'";

    if ($id_guru)  $sql .= " AND pc.id_guru  = $id_guru";
    if ($id_kelas) $sql .= " AND s.id_kelas  = $id_kelas";
    if ($id_anak)  $sql .= " AND pc.id_anak = $id_anak";
    if ($semester) $sql .= " AND pc.semester = $semester";
    if ($search)   $sql .= " AND (s.nama_anak LIKE '%$search%' OR ap.nama_aspek LIKE '%$search%')";

    $sql .= " ORDER BY pc.tanggal DESC, s.nama_anak ASC";

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

    $s = fn($v) => isset($v) && $v !== ''
        ? "'" . $conn->real_escape_string((string)$v) . "'"
        : "NULL";

    $validStatus = ['TM', 'MM', 'M'];

    // ── ADD ────────────────────────────────────────────────────────────────
    if ($action === 'add') {
        $id_anak    = intval($input['id_anak']  ?? 0);
        $id_guru    = intval($input['id_guru']   ?? 0); // users.id directly
        $id_aspek    = intval($input['id_aspek']  ?? 0);
        $id_kegiatan = intval($input['id_kegiatan'] ?? 0);
        $tanggal     = $conn->real_escape_string($input['tanggal']   ?? date('Y-m-d'));
        $status      = $conn->real_escape_string($input['status']    ?? 'TM');
        $semester    = intval($input['semester']  ?? 1);
        $minggu_ke   = intval($input['minggu_ke'] ?? 1);

        if (!in_array($status, $validStatus)) {
            echo json_encode(["status" => "error", "message" => "Status tidak valid. Gunakan: TM, MM, atau M"]);
            exit;
        }

        if ($id_anak <= 0 || $id_guru <= 0 || $id_aspek <= 0) {
            echo json_encode(["status" => "error", "message" => "Data anak, guru, dan aspek wajib diisi"]);
            exit;
        }

        $id_tujuan = intval($input['id_tujuan'] ?? 0);
        if ($id_kegiatan > 0) {
            $resKeg = $conn->query("SELECT id_tujuan FROM kegiatan_pembelajaran WHERE id = $id_kegiatan LIMIT 1");
            if ($resKeg && $resKeg->num_rows > 0) {
                $id_tujuan = (int)$resKeg->fetch_assoc()['id_tujuan'];
            }
        }

        $sql = "INSERT INTO penilaian
                    (tipe, id_anak, id_guru, id_aspek, id_tujuan, id_kegiatan, tanggal, semester, minggu_ke,
                     status, konteks, hasil, kejadian, catatan)
                VALUES
                    ('checklist', $id_anak, $id_guru, $id_aspek, " . ($id_tujuan > 0 ? $id_tujuan : "NULL") . ", " . ($id_kegiatan > 0 ? $id_kegiatan : "NULL") . ", '$tanggal', $semester, $minggu_ke,
                     '$status',
                     {$s($input['konteks'])},
                     {$s($input['hasil'])},
                     {$s($input['kejadian'])},
                     {$s($input['catatan'])})";

        if ($conn->query($sql)) {
            echo json_encode([
                "status"  => "success",
                "message" => "Penilaian berhasil ditambahkan",
                "id"      => $conn->insert_id
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    // ── UPDATE ─────────────────────────────────────────────────────────────
    } elseif ($action === 'update') {
        $id          = intval($input['id'] ?? 0);
        $id_anak    = intval($input['id_anak']  ?? 0);
        $id_aspek    = intval($input['id_aspek']  ?? 0);
        $id_kegiatan = intval($input['id_kegiatan'] ?? 0);
        $tanggal     = $conn->real_escape_string($input['tanggal']   ?? date('Y-m-d'));
        $status      = $conn->real_escape_string($input['status'] ?? 'TM');
        $semester    = intval($input['semester']  ?? 1);
        $minggu_ke   = intval($input['minggu_ke'] ?? 1);

        if (!in_array($status, $validStatus)) {
            echo json_encode(["status" => "error", "message" => "Status tidak valid. Gunakan: TM, MM, atau M"]);
            exit;
        }

        if ($id <= 0) {
            echo json_encode(["status" => "error", "message" => "ID penilaian tidak valid"]);
            exit;
        }

        if ($id_anak <= 0 || $id_aspek <= 0) {
            echo json_encode(["status" => "error", "message" => "Data anak dan aspek wajib diisi"]);
            exit;
        }

        $id_tujuan = intval($input['id_tujuan'] ?? 0);
        if ($id_kegiatan > 0) {
            $resKeg = $conn->query("SELECT id_tujuan FROM kegiatan_pembelajaran WHERE id = $id_kegiatan LIMIT 1");
            if ($resKeg && $resKeg->num_rows > 0) {
                $id_tujuan = (int)$resKeg->fetch_assoc()['id_tujuan'];
            }
        }

        $sql = "UPDATE penilaian SET
                    id_anak    = $id_anak,
                    id_aspek    = $id_aspek,
                    id_tujuan   = " . ($id_tujuan > 0 ? $id_tujuan : "NULL") . ",
                    id_kegiatan = " . ($id_kegiatan > 0 ? $id_kegiatan : "NULL") . ",
                    tanggal     = '$tanggal',
                    semester    = $semester,
                    minggu_ke   = $minggu_ke,
                    status      = '$status',
                    konteks     = {$s($input['konteks'])},
                    hasil       = {$s($input['hasil'])},
                    kejadian    = {$s($input['kejadian'])},
                    catatan     = {$s($input['catatan'])}
                WHERE id = $id AND tipe = 'checklist'";

        if ($conn->query($sql)) {
            echo json_encode(["status" => "success", "message" => "Penilaian berhasil diperbarui"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    // ── DELETE ─────────────────────────────────────────────────────────────
    } elseif ($action === 'delete') {
        $id = intval($input['id'] ?? 0);

        if ($id <= 0) {
            echo json_encode(["status" => "error", "message" => "ID penilaian tidak valid"]);
            exit;
        }

        if ($conn->query("DELETE FROM penilaian WHERE id = $id AND tipe = 'checklist'")) {
            echo json_encode(["status" => "success", "message" => "Penilaian berhasil dihapus"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    } else {
        echo json_encode(["status" => "error", "message" => "Action tidak dikenali"]);
    }
}

$conn->close();
?>