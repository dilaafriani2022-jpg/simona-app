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

$method = $_SERVER['REQUEST_METHOD'];

// ─── Helper: kirim JSON response ─────────────────────────────────────────────
function respond(array $payload, int $code = 200): void {
    http_response_code($code);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit();
}

// ─── Helper: bersihkan string waktu dari format Flutter TimeOfDay ─────────────
function sanitizeTime(string $raw): string {
    if (preg_match('/(\d{1,2}):(\d{1,2})/', $raw, $m)) {
        $h = str_pad($m[1], 2, '0', STR_PAD_LEFT);
        $i = str_pad($m[2], 2, '0', STR_PAD_LEFT);
        return "$h:$i:00";
    }
    return date('H:i:s');
}

// ─── GET ──────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    $id_guru  = isset($_GET['id_guru'])  ? intval($_GET['id_guru'])  : null;
    $id_kelas = isset($_GET['id_kelas']) ? intval($_GET['id_kelas']) : null;
    $id_anak = isset($_GET['id_anak']) ? intval($_GET['id_anak']) : null;

    $sql = "SELECT 
                a.id,
                a.id_anak,
                a.id_guru,
                a.tanggal,
                a.waktu,
                a.lokasi,
                a.aspek_perkembangan,
                a.peristiwa,
                a.interpretasi,
                a.tindak_lanjut,
                s.nama_anak AS nama_anak,
                g.name AS nama_guru
            FROM penilaian a
            JOIN anak  s ON a.id_anak = s.id
            JOIN users  g ON a.id_guru  = g.id
            WHERE a.tipe = 'anekdot'";

    $params = [];
    $types  = '';

    if ($id_guru) {
        $sql    .= " AND a.id_guru = ?";
        $params[] = $id_guru;
        $types   .= 'i';
    }
    if ($id_anak) {
        $sql    .= " AND a.id_anak = ?";
        $params[] = $id_anak;
        $types   .= 'i';
    }
    if ($id_kelas) {
        $sql    .= " AND s.id_kelas = ?";
        $params[] = $id_kelas;
        $types   .= 'i';
    }

    $sql .= " ORDER BY a.tanggal DESC, a.waktu DESC";

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        respond(['status' => 'error', 'message' => 'Prepare failed: ' . $conn->error], 500);
    }

    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }

    $stmt->execute();
    $result = $stmt->get_result();

    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
    $stmt->close();

    respond(['status' => 'success', 'data' => $data]);
}

// ─── POST ─────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true);

    if (empty($input)) {
        $input = $_POST;
    }

    $action = trim($input['action'] ?? '');

    // ── ADD ──────────────────────────────────────────────────────────────────
    if ($action === 'add') {
        $id_anak          = intval($input['id_anak'] ?? 0);
        $id_guru          = intval($input['id_guru']  ?? 0); // users.id directly
        $tanggal           = $input['tanggal']           ?? date('Y-m-d');
        $waktu_raw         = $input['waktu']             ?? date('H:i:s');
        $lokasi            = trim($input['lokasi']       ?? '');
        $aspek             = trim($input['aspek_perkembangan'] ?? '');
        $peristiwa         = trim($input['peristiwa']    ?? '');
        $interpretasi      = trim($input['interpretasi'] ?? '');
        $tindak_lanjut     = trim($input['tindak_lanjut'] ?? '');

        // Validasi wajib
        if (!$id_anak || !$id_guru || empty($peristiwa)) {
            respond([
                'status'  => 'error',
                'message' => 'id_anak, id_guru, dan peristiwa wajib diisi.'
            ], 422);
        }

        $tanggal = date('Y-m-d', strtotime($tanggal)) ?: date('Y-m-d');
        $waktu   = sanitizeTime($waktu_raw);

        $stmt = $conn->prepare(
            "INSERT INTO penilaian 
                (tipe, id_anak, id_guru, tanggal, waktu, lokasi, aspek_perkembangan, peristiwa, interpretasi, tindak_lanjut)
             VALUES ('anekdot', ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );

        if (!$stmt) {
            respond(['status' => 'error', 'message' => 'Prepare failed: ' . $conn->error], 500);
        }

        $stmt->bind_param(
            'iisssssss',
            $id_anak, $id_guru,
            $tanggal, $waktu,
            $lokasi, $aspek,
            $peristiwa, $interpretasi, $tindak_lanjut
        );

        if ($stmt->execute()) {
            $new_id = $conn->insert_id;
            $stmt->close();
            respond([
                'status'  => 'success',
                'message' => 'Anekdot berhasil ditambahkan',
                'id'      => $new_id
            ]);
        } else {
            $err = $stmt->error;
            $stmt->close();
            respond(['status' => 'error', 'message' => $err], 500);
        }
    }

    // ── UPDATE ───────────────────────────────────────────────────────────────
    if ($action === 'update') {
        $id                = intval($input['id'] ?? 0);
        $lokasi            = trim($input['lokasi']            ?? '');
        $aspek             = trim($input['aspek_perkembangan'] ?? '');
        $peristiwa         = trim($input['peristiwa']         ?? '');
        $interpretasi      = trim($input['interpretasi']      ?? '');
        $tindak_lanjut     = trim($input['tindak_lanjut']     ?? '');

        if (!$id || empty($peristiwa)) {
            respond(['status' => 'error', 'message' => 'id dan peristiwa wajib diisi.'], 422);
        }

        $stmt = $conn->prepare(
            "UPDATE penilaian 
             SET lokasi = ?, aspek_perkembangan = ?, peristiwa = ?, interpretasi = ?, tindak_lanjut = ?
             WHERE id = ? AND tipe = 'anekdot'"
        );

        if (!$stmt) {
            respond(['status' => 'error', 'message' => 'Prepare failed: ' . $conn->error], 500);
        }

        $stmt->bind_param('sssssi', $lokasi, $aspek, $peristiwa, $interpretasi, $tindak_lanjut, $id);

        if ($stmt->execute()) {
            $stmt->close();
            respond(['status' => 'success', 'message' => 'Anekdot berhasil diperbarui']);
        } else {
            $err = $stmt->error;
            $stmt->close();
            respond(['status' => 'error', 'message' => $err], 500);
        }
    }

    // ── DELETE ───────────────────────────────────────────────────────────────
    if ($action === 'delete') {
        $id = intval($input['id'] ?? 0);

        if (!$id) {
            respond(['status' => 'error', 'message' => 'id wajib diisi.'], 422);
        }

        $stmt = $conn->prepare("DELETE FROM penilaian WHERE id = ? AND tipe = 'anekdot'");

        if (!$stmt) {
            respond(['status' => 'error', 'message' => 'Prepare failed: ' . $conn->error], 500);
        }

        $stmt->bind_param('i', $id);

        if ($stmt->execute()) {
            $stmt->close();
            respond(['status' => 'success', 'message' => 'Anekdot berhasil dihapus']);
        } else {
            $err = $stmt->error;
            $stmt->close();
            respond(['status' => 'error', 'message' => $err], 500);
        }
    }

    respond(['status' => 'error', 'message' => "Action '$action' tidak dikenal."], 400);
}

respond(['status' => 'error', 'message' => 'Method not allowed.'], 405);
$conn->close();
?>