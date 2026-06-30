<?php
require_once 'cors.php';
header("Content-Type: application/json");
require_once 'config.php';

// ── Auto-migration ─────────────────────────────────────────────────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS modul_ajar (
        id                  INT AUTO_INCREMENT PRIMARY KEY,
        id_kelas            INT NOT NULL,
        id_guru             INT DEFAULT NULL,
        semester            TINYINT NOT NULL DEFAULT 1,
        minggu_ke           TINYINT NOT NULL,
        tanggal_mulai       DATE DEFAULT NULL,
        tanggal_selesai     DATE DEFAULT NULL,
        kelompok            VARCHAR(50) DEFAULT NULL,
        topik               VARCHAR(255) DEFAULT NULL,
        sub_topik           TEXT DEFAULT NULL,
        bulan               VARCHAR(30) DEFAULT NULL,
        -- Informasi Umum
        nama_sekolah        VARCHAR(150) DEFAULT NULL,
        kelas_info          VARCHAR(50) DEFAULT NULL,
        jenjang             VARCHAR(50) DEFAULT 'TK',
        durasi              VARCHAR(50) DEFAULT '90 - 150 menit',
        jumlah_anak         VARCHAR(20) DEFAULT NULL,
        model_pembelajaran  VARCHAR(100) DEFAULT NULL,
        atp                 TEXT DEFAULT NULL,
        elemen_cp           TEXT DEFAULT NULL,
        -- Komponen Inti
        curah_ide           TEXT DEFAULT NULL,
        pembiasaan          TEXT DEFAULT NULL,
        -- Kegiatan Inti per hari
        kegiatan_senin      TEXT DEFAULT NULL,
        kegiatan_selasa     TEXT DEFAULT NULL,
        kegiatan_rabu       TEXT DEFAULT NULL,
        kegiatan_kamis      TEXT DEFAULT NULL,
        kegiatan_jumat      TEXT DEFAULT NULL,
        kegiatan_sabtu      TEXT DEFAULT NULL,
        -- Penutup & Refleksi
        kegiatan_penutup    TEXT DEFAULT NULL,
        pertanyaan_refleksi TEXT DEFAULT NULL,
        pengayaan           TEXT DEFAULT NULL,
        remedial            TEXT DEFAULT NULL,
        -- Asesmen
        teknik_asesmen      TEXT DEFAULT NULL,
        diagnostik          TEXT DEFAULT NULL,
        formatif            TEXT DEFAULT NULL,
        -- Sarana & Prasarana
        kata_kunci          TEXT DEFAULT NULL,
        dialog_sarana       TEXT DEFAULT NULL,
        alat_bahan          TEXT DEFAULT NULL,
        sumber_belajar      TEXT DEFAULT NULL,
        created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uk_modul (id_kelas, semester, minggu_ke)
    )
");

// Tambah kolom bila belum ada (backward-compat)
$cols = ['atp TEXT', 'elemen_cp TEXT', 'curah_ide TEXT', 'pembiasaan TEXT',
         'pertanyaan_refleksi TEXT', 'pengayaan TEXT', 'remedial TEXT',
         'diagnostik TEXT', 'formatif TEXT', 'kata_kunci TEXT',
         'dialog_sarana TEXT', 'alat_bahan TEXT', 'sumber_belajar TEXT'];
foreach ($cols as $col) {
    $name = explode(' ', $col)[0];
    $conn->query("ALTER TABLE modul_ajar ADD COLUMN IF NOT EXISTS $col");
}

$method = $_SERVER['REQUEST_METHOD'];

// ── GET ────────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    $id_kelas  = isset($_GET['id_kelas'])  ? (int)$_GET['id_kelas']  : 0;
    $semester  = isset($_GET['semester'])  ? (int)$_GET['semester']  : 1;
    $minggu_ke = isset($_GET['minggu_ke']) ? (int)$_GET['minggu_ke'] : 0;

    if ($minggu_ke > 0) {
        $res = $conn->query("
            SELECT m.*, k.nama_kelas, u.name AS nama_guru
            FROM modul_ajar m
            LEFT JOIN kelas k ON m.id_kelas = k.id
            LEFT JOIN users u ON m.id_guru  = u.id
            WHERE m.id_kelas = $id_kelas AND m.semester = $semester AND m.minggu_ke = $minggu_ke
            LIMIT 1
        ");
        $row = $res ? $res->fetch_assoc() : null;
        echo json_encode(['status' => 'success', 'data' => $row]);
    } else {
        $res = $conn->query("
            SELECT m.*, k.nama_kelas, u.name AS nama_guru
            FROM modul_ajar m
            LEFT JOIN kelas k ON m.id_kelas = k.id
            LEFT JOIN users u ON m.id_guru  = u.id
            WHERE m.id_kelas = $id_kelas AND m.semester = $semester
            ORDER BY m.minggu_ke ASC
        ");
        $data = [];
        if ($res) while ($row = $res->fetch_assoc()) $data[] = $row;
        echo json_encode(['status' => 'success', 'data' => $data]);
    }
    exit;
}

// ── POST ───────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true) ?? $_POST;
    $action = $input['action'] ?? '';

    if ($action === 'save') {
        $id_kelas  = (int)($input['id_kelas'] ?? 0);
        $id_guru   = !empty($input['id_guru']) ? (int)$input['id_guru'] : null;
        $semester  = (int)($input['semester'] ?? 1);
        $minggu_ke = (int)($input['minggu_ke'] ?? 0);

        // Helper: escape or NULL
        $esc = fn($k) => isset($input[$k]) && $input[$k] !== ''
            ? "'" . $conn->real_escape_string($input[$k]) . "'"
            : 'NULL';

        $id_guru_val = $id_guru ? $id_guru : 'NULL';

        $fields = [
            'tanggal_mulai', 'tanggal_selesai', 'kelompok', 'topik', 'sub_topik', 'bulan',
            'nama_sekolah', 'kelas_info', 'jenjang', 'durasi', 'jumlah_anak', 'model_pembelajaran',
            'atp', 'elemen_cp', 'curah_ide', 'pembiasaan',
            'kegiatan_senin', 'kegiatan_selasa', 'kegiatan_rabu',
            'kegiatan_kamis', 'kegiatan_jumat', 'kegiatan_sabtu',
            'kegiatan_penutup', 'pertanyaan_refleksi', 'pengayaan', 'remedial',
            'teknik_asesmen', 'diagnostik', 'formatif',
            'kata_kunci', 'dialog_sarana', 'alat_bahan', 'sumber_belajar',
        ];

        $colList = implode(', ', $fields);
        $valList = implode(', ', array_map($esc, $fields));
        $updList = implode(', ', array_map(fn($f) => "$f = " . $esc($f), $fields));

        $sql = "INSERT INTO modul_ajar
                    (id_kelas, id_guru, semester, minggu_ke, $colList)
                VALUES
                    ($id_kelas, $id_guru_val, $semester, $minggu_ke, $valList)
                ON DUPLICATE KEY UPDATE
                    id_guru = $id_guru_val,
                    $updList";

        if ($conn->query($sql)) {
            echo json_encode(['status' => 'success', 'id' => $conn->insert_id ?: 0]);
        } else {
            echo json_encode(['status' => 'error', 'message' => $conn->error]);
        }
        exit;
    }

    if ($action === 'delete') {
        $id = (int)($input['id'] ?? 0);
        if ($conn->query("DELETE FROM modul_ajar WHERE id = $id")) {
            echo json_encode(['status' => 'success']);
        } else {
            echo json_encode(['status' => 'error', 'message' => $conn->error]);
        }
        exit;
    }

    echo json_encode(['status' => 'error', 'message' => 'Invalid action']);
    exit;
}

$conn->close();
?>
