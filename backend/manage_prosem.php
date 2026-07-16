<?php
require_once 'cors.php';
header("Content-Type: application/json");
require_once 'config.php';

// ── Auto-migration ─────────────────────────────────────────────────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS prosem (
        id              INT AUTO_INCREMENT PRIMARY KEY,
        id_kelas        INT NOT NULL,
        id_guru         INT DEFAULT NULL,
        semester        TINYINT NOT NULL DEFAULT 1,
        tahun_ajaran    VARCHAR(20) DEFAULT NULL,
        bulan           VARCHAR(30) DEFAULT NULL,
        minggu_ke       TINYINT NOT NULL,
        tanggal_mulai   DATE DEFAULT NULL,
        tanggal_selesai DATE DEFAULT NULL,
        topik           VARCHAR(255) DEFAULT NULL,
        sub_topik       TEXT DEFAULT NULL,
        sub_sub_topik   TEXT DEFAULT NULL,
        catatan         TEXT DEFAULT NULL,
        created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uk_prosem (id_kelas, semester, minggu_ke)
    )
");

$method = $_SERVER['REQUEST_METHOD'];

// ── GET ────────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    $id_kelas  = isset($_GET['id_kelas'])  ? (int)$_GET['id_kelas']  : 0;
    $semester  = isset($_GET['semester'])  ? (int)$_GET['semester']  : 1;
    $minggu_ke = isset($_GET['minggu_ke']) ? (int)$_GET['minggu_ke'] : 0;

    // Load semester start date dari tahun_ajaran kelas
    $sem_start_date = null;
    if ($id_kelas > 0) {
        $ta_sql = "SELECT ta.tanggal_mulai_semester_1, ta.tanggal_mulai_semester_2 
                   FROM kelas k 
                   LEFT JOIN tahun_ajaran ta ON k.id_tahun_ajaran = ta.id 
                   WHERE k.id = $id_kelas LIMIT 1";
        $ta_res = $conn->query($ta_sql);
        if ($ta_res && $ta_row = $ta_res->fetch_assoc()) {
            $sem_start_date = ($semester == 1) ? $ta_row['tanggal_mulai_semester_1'] : $ta_row['tanggal_mulai_semester_2'];
        }
    }

    $autoCalc = function($row, $sem_start_date, $m_ke) use ($id_kelas, $semester) {
        if ($row) {
            if (empty($row['tanggal_mulai']) || $row['tanggal_mulai'] == '0000-00-00') {
                if ($sem_start_date) {
                    $start_ts = strtotime($sem_start_date);
                    $week_start_ts = $start_ts + (($m_ke - 1) * 7 * 24 * 60 * 60);
                    $week_end_ts = $week_start_ts + (4 * 24 * 60 * 60);
                    $row['tanggal_mulai'] = date('Y-m-d', $week_start_ts);
                    $row['tanggal_selesai'] = date('Y-m-d', $week_end_ts);
                }
            }
        } else {
            // Pre-fill even if row doesn't exist in DB
            if ($sem_start_date && $m_ke > 0) {
                $start_ts = strtotime($sem_start_date);
                $week_start_ts = $start_ts + (($m_ke - 1) * 7 * 24 * 60 * 60);
                $week_end_ts = $week_start_ts + (4 * 24 * 60 * 60);
                $row = [
                    'id' => 0,
                    'id_kelas' => $id_kelas,
                    'id_guru' => 0,
                    'semester' => $semester,
                    'tahun_ajaran' => '',
                    'bulan' => '',
                    'minggu_ke' => $m_ke,
                    'tanggal_mulai' => date('Y-m-d', $week_start_ts),
                    'tanggal_selesai' => date('Y-m-d', $week_end_ts),
                    'topik' => '',
                    'sub_topik' => '',
                    'sub_sub_topik' => '',
                    'catatan' => ''
                ];
            }
        }
        return $row;
    };

    if ($minggu_ke > 0) {
        // Ambil satu minggu spesifik
        $res = $conn->query("
            SELECT p.*, k.nama_kelas, u.name AS nama_guru
            FROM prosem p
            LEFT JOIN kelas k ON p.id_kelas = k.id
            LEFT JOIN users u ON p.id_guru  = u.id
            WHERE p.id_kelas = $id_kelas AND p.semester = $semester AND p.minggu_ke = $minggu_ke
            LIMIT 1
        ");
        $row = $res ? $res->fetch_assoc() : null;
        $row = $autoCalc($row, $sem_start_date, $minggu_ke);
        echo json_encode(['status' => 'success', 'data' => $row]);
    } else {
        // Ambil semua minggu untuk kelas+semester
        $res = $conn->query("
            SELECT p.*, k.nama_kelas, u.name AS nama_guru
            FROM prosem p
            LEFT JOIN kelas k ON p.id_kelas = k.id
            LEFT JOIN users u ON p.id_guru  = u.id
            WHERE p.id_kelas = $id_kelas AND p.semester = $semester
            ORDER BY p.minggu_ke ASC
        ");
        $data = [];
        if ($res) {
            while ($row = $res->fetch_assoc()) {
                $row = $autoCalc($row, $sem_start_date, intval($row['minggu_ke']));
                $data[] = $row;
            }
        }
        echo json_encode(['status' => 'success', 'data' => $data]);
    }
    exit;
}

// ── POST ───────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true) ?? $_POST;
    $action = $input['action'] ?? '';

    if ($action === 'save') {
        $id_kelas        = (int)($input['id_kelas'] ?? 0);
        $id_guru         = !empty($input['id_guru']) ? (int)$input['id_guru'] : 'NULL';
        $semester        = (int)($input['semester'] ?? 1);
        $tahun_ajaran    = $conn->real_escape_string($input['tahun_ajaran'] ?? '');
        $bulan           = $conn->real_escape_string($input['bulan'] ?? '');
        $minggu_ke       = (int)($input['minggu_ke'] ?? 0);
        $tanggal_mulai   = $conn->real_escape_string($input['tanggal_mulai'] ?? '');
        $tanggal_selesai = $conn->real_escape_string($input['tanggal_selesai'] ?? '');
        $topik           = $conn->real_escape_string($input['topik'] ?? '');
        $sub_topik       = $conn->real_escape_string($input['sub_topik'] ?? '');
        $sub_sub_topik   = $conn->real_escape_string($input['sub_sub_topik'] ?? '');
        $catatan         = $conn->real_escape_string($input['catatan'] ?? '');

        // Hitung otomatis jika kosong
        if ((empty($tanggal_mulai) || $tanggal_mulai === 'null') && $id_kelas > 0 && $minggu_ke > 0) {
            $ta_sql = "SELECT ta.tanggal_mulai_semester_1, ta.tanggal_mulai_semester_2 
                       FROM kelas k 
                       LEFT JOIN tahun_ajaran ta ON k.id_tahun_ajaran = ta.id 
                       WHERE k.id = $id_kelas LIMIT 1";
            $ta_res = $conn->query($ta_sql);
            if ($ta_res && $ta_row = $ta_res->fetch_assoc()) {
                $sem_start_date = ($semester == 1) ? $ta_row['tanggal_mulai_semester_1'] : $ta_row['tanggal_mulai_semester_2'];
                if ($sem_start_date) {
                    $start_ts = strtotime($sem_start_date);
                    $week_start_ts = $start_ts + (($minggu_ke - 1) * 7 * 24 * 60 * 60);
                    $week_end_ts = $week_start_ts + (4 * 24 * 60 * 60);
                    $tanggal_mulai = date('Y-m-d', $week_start_ts);
                    $tanggal_selesai = date('Y-m-d', $week_end_ts);
                }
            }
        }

        $id_guru_val = is_int($id_guru) ? $id_guru : 'NULL';
        $tm  = $tanggal_mulai   ? "'$tanggal_mulai'"   : 'NULL';
        $ts  = $tanggal_selesai ? "'$tanggal_selesai'" : 'NULL';

        $sql = "INSERT INTO prosem 
                    (id_kelas, id_guru, semester, tahun_ajaran, bulan, minggu_ke,
                     tanggal_mulai, tanggal_selesai, topik, sub_topik, sub_sub_topik, catatan)
                VALUES
                    ($id_kelas, $id_guru_val, $semester, '$tahun_ajaran', '$bulan', $minggu_ke,
                     $tm, $ts, '$topik', '$sub_topik', '$sub_sub_topik', '$catatan')
                ON DUPLICATE KEY UPDATE
                    id_guru         = $id_guru_val,
                    tahun_ajaran    = '$tahun_ajaran',
                    bulan           = '$bulan',
                    tanggal_mulai   = $tm,
                    tanggal_selesai = $ts,
                    topik           = '$topik',
                    sub_topik       = '$sub_topik',
                    sub_sub_topik   = '$sub_sub_topik',
                    catatan         = '$catatan'";

        if ($conn->query($sql)) {
            echo json_encode(['status' => 'success', 'id' => $conn->insert_id]);
        } else {
            echo json_encode(['status' => 'error', 'message' => $conn->error]);
        }
        exit;
    }

    if ($action === 'delete') {
        $id = (int)($input['id'] ?? 0);
        if ($conn->query("DELETE FROM prosem WHERE id = $id")) {
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
