<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';
require_once 'cors.php';

$method = $_SERVER['REQUEST_METHOD'];

// ─── Helper ───────────────────────────────────────────────────────────────────
function respond(array $payload, int $code = 200): void {
    http_response_code($code);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit();
}

// ─── GET ──────────────────────────────────────────────────────────────────────
if ($method === 'GET') {
    $id_guru  = isset($_GET['id_guru'])  ? intval($_GET['id_guru'])  : null;
    $id_anak = isset($_GET['id_anak']) ? intval($_GET['id_anak']) : null;
    $id_kelas = isset($_GET['id_kelas']) ? intval($_GET['id_kelas']) : null;

    $sql = "SELECT
                k.id,
                k.id_anak,
                k.id_guru,
                k.tanggal,
                k.waktu_kegiatan,
                k.kategori,
                k.judul,
                k.deskripsi,
                k.bahan,
                k.catatan_guru,
                s.nama_anak AS nama_anak,
                g.name AS nama_guru
            FROM penilaian k
            JOIN anak  s ON k.id_anak = s.id
            JOIN users  g ON k.id_guru  = g.id
            WHERE k.tipe = 'karya'";

    $params = [];
    $types  = '';

    if ($id_guru) {
        $sql     .= " AND k.id_guru = ?";
        $params[] = $id_guru;
        $types   .= 'i';
    }
    if ($id_anak) {
        $sql     .= " AND k.id_anak = ?";
        $params[] = $id_anak;
        $types   .= 'i';
    }
    if ($id_kelas) {
        $sql     .= " AND s.id_kelas = ?";
        $params[] = $id_kelas;
        $types   .= 'i';
    }

    $sql .= " ORDER BY k.tanggal DESC, k.id DESC";

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
        // Hapus kolom url_foto dari response agar bersih
        unset($row['url_foto']);
        $data[] = $row;
    }
    $stmt->close();

    respond(['status' => 'success', 'data' => $data]);
}

// ─── POST ─────────────────────────────────────────────────────────────────────
if ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true);
    if (empty($input)) $input = $_POST;

    $action = trim($input['action'] ?? '');

    // ── ADD ──────────────────────────────────────────────────────────────────
    if ($action === 'add') {
        $id_anak       = intval($input['id_anak']        ?? 0);
        $id_guru = intval($input['id_guru']         ?? 0);
        $tanggal        = $input['tanggal']                ?? date('Y-m-d');
        $waktu_kegiatan = trim($input['waktu_kegiatan']    ?? 'Pagi');
        $kategori       = trim($input['kategori']          ?? 'Lainnya');
        $judul          = trim($input['judul']             ?? '');
        $deskripsi      = trim($input['deskripsi']         ?? '');
        $bahan          = trim($input['bahan']             ?? '');
        $catatan_guru   = trim($input['catatan_guru']      ?? '');

        // Validasi wajib
        if (!$id_anak || !$id_guru || empty($judul) || empty($kategori)) {
            respond([
                'status'  => 'error',
                'message' => 'id_anak, id_guru, judul, dan kategori wajib diisi.'
            ], 422);
        }

        // Sanitasi tanggal
        $tanggal = date('Y-m-d', strtotime($tanggal)) ?: date('Y-m-d');

        // Validasi waktu_kegiatan
        $waktuValid = ['Pagi', 'Siang', 'Sore'];
        if (!in_array($waktu_kegiatan, $waktuValid)) $waktu_kegiatan = 'Pagi';

        $stmt = $conn->prepare(
            "INSERT INTO penilaian
                (tipe, id_anak, id_guru, tanggal, waktu_kegiatan, kategori, judul, deskripsi, bahan, catatan_guru)
             VALUES ('karya', ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );

        if (!$stmt) {
            respond(['status' => 'error', 'message' => 'Prepare failed: ' . $conn->error], 500);
        }

        $stmt->bind_param(
            'iisssssss',
            $id_anak, $id_guru,
            $tanggal, $waktu_kegiatan, $kategori,
            $judul, $deskripsi, $bahan, $catatan_guru
        );

        if ($stmt->execute()) {
            $new_id = $conn->insert_id;
            $stmt->close();
            respond([
                'status'  => 'success',
                'message' => 'Karya berhasil ditambahkan',
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
        $id             = intval($input['id']              ?? 0);
        $kategori       = trim($input['kategori']          ?? 'Lainnya');
        $judul          = trim($input['judul']             ?? '');
        $deskripsi      = trim($input['deskripsi']         ?? '');
        $bahan          = trim($input['bahan']             ?? '');
        $catatan_guru   = trim($input['catatan_guru']      ?? '');
        $waktu_kegiatan = trim($input['waktu_kegiatan']    ?? 'Pagi');

        if (!$id || empty($judul)) {
            respond(['status' => 'error', 'message' => 'id dan judul wajib diisi.'], 422);
        }

        $stmt = $conn->prepare(
            "UPDATE penilaian
             SET kategori = ?, judul = ?, deskripsi = ?, bahan = ?, catatan_guru = ?, waktu_kegiatan = ?
             WHERE id = ? AND tipe = 'karya'"
        );

        if (!$stmt) {
            respond(['status' => 'error', 'message' => 'Prepare failed: ' . $conn->error], 500);
        }

        $stmt->bind_param('ssssssi',
            $kategori, $judul, $deskripsi, $bahan, $catatan_guru, $waktu_kegiatan, $id);

        if ($stmt->execute()) {
            $stmt->close();
            respond(['status' => 'success', 'message' => 'Karya berhasil diperbarui']);
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

        $stmt = $conn->prepare("DELETE FROM penilaian WHERE id = ? AND tipe = 'karya'");

        if (!$stmt) {
            respond(['status' => 'error', 'message' => 'Prepare failed: ' . $conn->error], 500);
        }

        $stmt->bind_param('i', $id);

        if ($stmt->execute()) {
            $stmt->close();
            respond(['status' => 'success', 'message' => 'Karya berhasil dihapus']);
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