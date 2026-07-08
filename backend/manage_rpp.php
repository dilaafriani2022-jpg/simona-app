<?php
require_once 'cors.php';
header("Content-Type: application/json");
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

// ── GET ───────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    $type = $_GET['type'] ?? '';

    if ($type === 'rppm') {
        // Auto-migrate kolom RPPM baru (Kurikulum Merdeka)
        $new_cols = [
            'kelompok VARCHAR(50)',
            'tujuan_kegiatan TEXT',
            'kegiatan_senin TEXT',
            'kegiatan_selasa TEXT',
            'kegiatan_rabu TEXT',
            'kegiatan_kamis TEXT',
            'kegiatan_jumat TEXT',
            'kegiatan_sabtu TEXT',
            'refleksi_guru TEXT',
            'id_guru INT',
        ];
        foreach ($new_cols as $col) {
            $conn->query("ALTER TABLE rppm ADD COLUMN IF NOT EXISTS $col");
        }
        $conn->query("ALTER TABLE rppm ADD UNIQUE IF NOT EXISTS uk_rppm (id_kelas, semester, minggu_ke)");

        $id_kelas  = isset($_GET['id_kelas'])  ? (int)$_GET['id_kelas']  : 0;
        $semester  = isset($_GET['semester'])  ? (int)$_GET['semester']  : 1;
        $minggu_ke = isset($_GET['minggu_ke']) ? (int)$_GET['minggu_ke'] : 0;

        if ($minggu_ke > 0) {
            $res = $conn->query("
                SELECT r.*, k.nama_kelas
                FROM rppm r
                LEFT JOIN kelas k ON r.id_kelas = k.id
                WHERE r.id_kelas = $id_kelas AND r.semester = $semester AND r.minggu_ke = $minggu_ke
                LIMIT 1
            ");
            $row = $res ? $res->fetch_assoc() : null;
            echo json_encode(['status' => 'success', 'data' => $row]);
        } else {
            $res = $conn->query("
                SELECT r.*, k.nama_kelas
                FROM rppm r
                LEFT JOIN kelas k ON r.id_kelas = k.id
                WHERE r.id_kelas = $id_kelas AND r.semester = $semester
                ORDER BY r.minggu_ke ASC
            ");
            $data = [];
            if ($res) while ($row = $res->fetch_assoc()) $data[] = $row;
            echo json_encode(['status' => 'success', 'data' => $data]);
        }
        exit;
    }

    echo json_encode(["status" => "error", "message" => "Invalid GET type"]);
    exit;
}

// ── POST ──────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true) ?? $_POST;
    $action = $input['action'] ?? '';

    // -- RPPM save (add or update) --
    if ($action === 'save_rppm') {
        $id_kelas  = (int)($input['id_kelas'] ?? 0);
        $id_guru   = !empty($input['id_guru']) ? (int)$input['id_guru'] : null;
        $semester  = (int)($input['semester'] ?? 1);
        $minggu_ke = (int)($input['minggu_ke'] ?? 0);

        $esc = fn($k) => isset($input[$k]) && $input[$k] !== ''
            ? "'" . $conn->real_escape_string($input[$k]) . "'"
            : 'NULL';

        $id_guru_val = $id_guru ? $id_guru : 'NULL';

        $fields = [
            'tanggal_mulai', 'tanggal_selesai',
            'tema', 'sub_tema', 'kelompok', 'tujuan_kegiatan',
            'kegiatan_senin', 'kegiatan_selasa', 'kegiatan_rabu',
            'kegiatan_kamis', 'kegiatan_jumat', 'kegiatan_sabtu',
            'refleksi_guru',
        ];

        $colList = implode(', ', $fields);
        $valList = implode(', ', array_map($esc, $fields));
        $updList = implode(', ', array_map(fn($f) => "$f = " . $esc($f), $fields));

        $sql = "INSERT INTO rppm
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

    // -- RPPM delete --
    if ($action === 'delete_rppm') {
        $id = (int)$input['id'];
        if ($conn->query("DELETE FROM rppm WHERE id = $id")) {
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    echo json_encode(["status" => "error", "message" => "Invalid POST action"]);
    exit;
}

$conn->close();
?>
