<?php
require_once 'cors.php';
require_once 'config.php';
require_once 'log_activity.php';
header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];

// ── GET: ambil status laporan per guru / kepsek ───────────────────────────
if ($method === 'GET') {
    $id_guru  = isset($_GET['id_guru'])  ? (int)$_GET['id_guru']  : null;
    $semester = isset($_GET['semester']) ? (int)$_GET['semester'] : 1;
    $kepsek   = isset($_GET['kepsek'])   && $_GET['kepsek'] === '1';

    if ($kepsek) {
        // Kepsek: ambil semua laporan siap dari semua guru semester ini
        $res = $conn->query("
            SELECT l.*, u.name AS nama_guru, k.nama_kelas
            FROM laporan_raport_siap l
            JOIN users u ON l.id_guru = u.id
            JOIN kelas k ON l.id_kelas = k.id
            WHERE l.semester = $semester AND l.status = 'siap'
            ORDER BY l.created_at DESC
        ");
        $rows = [];
        if ($res) {
            while ($row = $res->fetch_assoc()) $rows[] = $row;
        }
        echo json_encode(['status' => 'success', 'data' => $rows]);
        exit;
    }

    if (!$id_guru) {
        echo json_encode(['status' => 'error', 'message' => 'id_guru required']);
        exit;
    }

    // Guru: cek apakah sudah melapor untuk semester ini
    $res = $conn->query("
        SELECT * FROM laporan_raport_siap
        WHERE id_guru = $id_guru AND semester = $semester AND status = 'siap'
        ORDER BY created_at DESC LIMIT 1
    ");
    if ($res && $res->num_rows > 0) {
        $row = $res->fetch_assoc();
        // Hitung jumlah anak di kelas ini yang punya penilaian
        $id_kelas = (int)$row['id_kelas'];
        $total_res = $conn->query("SELECT COUNT(*) AS c FROM anak WHERE id_kelas = $id_kelas");
        $total_anak = $total_res ? (int)$total_res->fetch_assoc()['c'] : 0;
        echo json_encode([
            'status'       => 'success',
            'sudah_lapor'  => true,
            'laporan'      => $row,
            'total_anak'   => $total_anak,
        ]);
    } else {
        // Hitung progress penilaian guru
        $kelas_res = $conn->query("SELECT id_kelas FROM users WHERE id = $id_guru LIMIT 1");
        $id_kelas = 0;
        if ($kelas_res && $row = $kelas_res->fetch_assoc()) {
            $id_kelas = (int)$row['id_kelas'];
        }
        $total_anak = 0;
        $anak_sudah_dinilai = 0;
        if ($id_kelas > 0) {
            $t = $conn->query("SELECT COUNT(*) AS c FROM anak WHERE id_kelas = $id_kelas");
            $total_anak = $t ? (int)$t->fetch_assoc()['c'] : 0;
            // Anak yang sudah punya minimal 1 penilaian checklist semester ini
            $p = $conn->query("
                SELECT COUNT(DISTINCT id_anak) AS c
                FROM penilaian
                WHERE tipe = 'checklist' AND semester = $semester
                  AND id_anak IN (SELECT id FROM anak WHERE id_kelas = $id_kelas)
            ");
            $anak_sudah_dinilai = $p ? (int)$p->fetch_assoc()['c'] : 0;
        }
        echo json_encode([
            'status'             => 'success',
            'sudah_lapor'        => false,
            'total_anak'         => $total_anak,
            'anak_sudah_dinilai' => $anak_sudah_dinilai,
        ]);
    }
    exit;
}

// ── POST: guru mengirim laporan siap raport ───────────────────────────────
if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'));

    $id_guru  = isset($data->id_guru)  ? (int)$data->id_guru  : 0;
    $semester = isset($data->semester) ? (int)$data->semester : 1;
    $catatan  = isset($data->catatan)  ? $conn->real_escape_string($data->catatan) : '';
    $batalkan = isset($data->batalkan) && $data->batalkan === true;

    if (!$id_guru) {
        echo json_encode(['status' => 'error', 'message' => 'id_guru required']);
        exit;
    }

    // Ambil id_kelas guru
    $kelas_res = $conn->query("SELECT id_kelas, name FROM users WHERE id = $id_guru LIMIT 1");
    if (!$kelas_res || $kelas_res->num_rows === 0) {
        echo json_encode(['status' => 'error', 'message' => 'Guru tidak ditemukan']);
        exit;
    }
    $guru_row = $kelas_res->fetch_assoc();
    $id_kelas  = (int)$guru_row['id_kelas'];
    $nama_guru = $guru_row['name'];

    if ($batalkan) {
        // Batalkan laporan
        $conn->query("UPDATE laporan_raport_siap SET status = 'dibatalkan' WHERE id_guru = $id_guru AND semester = $semester AND status = 'siap'");
        logActivity(getPdo(), "Laporan dibatalkan", "Guru '{$nama_guru}' membatalkan laporan siap raport semester $semester", "raport", "cancel");
        echo json_encode(['status' => 'success', 'message' => 'Laporan berhasil dibatalkan']);
        exit;
    }

    if ($id_kelas === 0) {
        echo json_encode(['status' => 'error', 'message' => 'Guru belum ditetapkan ke kelas']);
        exit;
    }

    // Hitung jumlah anak di kelas
    $t = $conn->query("SELECT COUNT(*) AS c FROM anak WHERE id_kelas = $id_kelas");
    $jumlah_anak = $t ? (int)$t->fetch_assoc()['c'] : 0;

    // Cek sudah lapor?
    $cek = $conn->query("SELECT id FROM laporan_raport_siap WHERE id_guru = $id_guru AND semester = $semester AND status = 'siap' LIMIT 1");
    if ($cek && $cek->num_rows > 0) {
        echo json_encode(['status' => 'error', 'message' => 'Anda sudah mengirimkan laporan untuk semester ini']);
        exit;
    }

    // Simpan laporan
    $ins = $conn->query("
        INSERT INTO laporan_raport_siap (id_guru, id_kelas, semester, jumlah_anak, catatan)
        VALUES ($id_guru, $id_kelas, $semester, $jumlah_anak, '$catatan')
    ");

    if ($ins) {
        logActivity(getPdo(), "Siap raport", "Guru '{$nama_guru}' melaporkan {$jumlah_anak} anak siap raport semester $semester", "raport", "submit");
        echo json_encode(['status' => 'success', 'message' => 'Laporan berhasil dikirim ke Kepala Sekolah']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan laporan: ' . $conn->error]);
    }
    exit;
}

echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
