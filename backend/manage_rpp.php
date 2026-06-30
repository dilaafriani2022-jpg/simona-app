<?php
require_once 'cors.php';
header("Content-Type: application/json");
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

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
        // Fix: pastikan kolom UNIQUE untuk upsert
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
    
    if ($type === 'rpph') {
        $id_kelas = isset($_GET['id_kelas']) ? (int)$_GET['id_kelas'] : 0;
        $tanggal = $_GET['tanggal'] ?? ''; // YYYY-MM-DD
        
        $where = "id_kelas = $id_kelas";
        if ($tanggal) $where .= " AND tanggal = '$tanggal'";
        
        $res = $conn->query("SELECT * FROM rpph WHERE $where ORDER BY tanggal DESC");
        $data = [];
        if ($res) {
            while ($row = $res->fetch_assoc()) {
                $data[] = $row;
            }
        }
        echo json_encode(["status" => "success", "data" => $data]);
        exit;
    }

    if ($type === 'bahan') {
        $id_rpph = isset($_GET['id_rpph']) ? (int)$_GET['id_rpph'] : 0;
        $res = $conn->query("SELECT * FROM rpph_bahan WHERE id_rpph = $id_rpph ORDER BY id ASC");
        $data = [];
        if ($res) {
            while ($row = $res->fetch_assoc()) {
                $row['is_checked'] = (bool)$row['is_checked'];
                $data[] = $row;
            }
        }
        echo json_encode(["status" => "success", "data" => $data]);
        exit;
    }
    
    echo json_encode(["status" => "error", "message" => "Invalid GET type"]);
    exit;
}

if ($method === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true) ?? $_POST;
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

    // -- RPPM delete (lama, tetap didukung) --
    if ($action === 'add_rppm') {
        // Alias ke save_rppm untuk backward compat
        $input['action'] = 'save_rppm';
        // jatuh ke save_rppm ↑ — tidak perlu handle lebih lanjut
        echo json_encode(['status' => 'error', 'message' => 'Gunakan save_rppm']);
        exit;
    }

    if ($action === 'delete_rppm') {
        $id = (int)$input['id'];
        if ($conn->query("DELETE FROM rppm WHERE id = $id")) {
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    // -- RPPH --
    if ($action === 'save_rpph') { // add or update
        $id_kelas = (int)$input['id_kelas'];
        $tanggal = $conn->real_escape_string($input['tanggal']);
        $kegiatan_pembuka = $conn->real_escape_string($input['kegiatan_pembuka'] ?? '');
        $kegiatan_inti = $conn->real_escape_string($input['kegiatan_inti'] ?? '');
        $kegiatan_penutup = $conn->real_escape_string($input['kegiatan_penutup'] ?? '');
        
        $sql = "INSERT INTO rpph (id_kelas, tanggal, kegiatan_pembuka, kegiatan_inti, kegiatan_penutup) 
                VALUES ($id_kelas, '$tanggal', '$kegiatan_pembuka', '$kegiatan_inti', '$kegiatan_penutup')
                ON DUPLICATE KEY UPDATE 
                kegiatan_pembuka = '$kegiatan_pembuka', 
                kegiatan_inti = '$kegiatan_inti', 
                kegiatan_penutup = '$kegiatan_penutup'";
                
        if ($conn->query($sql)) {
            // Get ID after insert/update
            $res = $conn->query("SELECT id FROM rpph WHERE id_kelas = $id_kelas AND tanggal = '$tanggal'");
            $id = $res->fetch_assoc()['id'];
            echo json_encode(["status" => "success", "id" => $id]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    // -- BAHAN --
    if ($action === 'add_bahan') {
        $id_rpph = (int)$input['id_rpph'];
        $nama_bahan = $conn->real_escape_string($input['nama_bahan']);
        if ($conn->query("INSERT INTO rpph_bahan (id_rpph, nama_bahan) VALUES ($id_rpph, '$nama_bahan')")) {
            echo json_encode(["status" => "success", "id" => $conn->insert_id]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    if ($action === 'toggle_bahan') {
        $id = (int)$input['id'];
        $is_checked = (int)$input['is_checked'];
        if ($conn->query("UPDATE rpph_bahan SET is_checked = $is_checked WHERE id = $id")) {
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    if ($action === 'delete_bahan') {
        $id = (int)$input['id'];
        if ($conn->query("DELETE FROM rpph_bahan WHERE id = $id")) {
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
