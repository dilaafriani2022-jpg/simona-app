<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php';
require_once 'cors.php';
require_once 'log_activity.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method == 'GET') {
    $search = isset($_GET['search']) ? $conn->real_escape_string($_GET['search']) : '';
    $id_kelas = isset($_GET['id_kelas']) ? intval($_GET['id_kelas']) : null;
    $semester = isset($_GET['semester']) ? intval($_GET['semester']) : 1;

    $sql = "SELECT 
                s.id, s.nisn, s.nik, s.jenis_kelamin, s.tempat_lahir, s.tanggal_lahir, 
                s.agama, s.status_anak, s.anak_ke, s.berat_badan, s.tinggi_badan, 
                s.alamat, s.id_kelas, s.created_at, s.updated_at,
                s.nama_anak AS nama_anak,
                s.nama_anak,
                u.id        AS id_ortu,
                u.id        AS ortu_id,
                u.name      AS nama_ortu,
                u.email     AS email_ortu,
                u.username  AS username_ortu,
                u.nisn      AS nisn_ortu,
                u.no_hp     AS no_hp_ortu,
                u.pekerjaan AS pekerjaan_ortu,
                u.alamat    AS alamat_ortu_detail,
                u.rt_rw, u.kelurahan, u.kecamatan, u.kota, u.provinsi, u.kode_pos,
                u.ayah_nama, u.ayah_nik, u.ayah_ttl, u.ayah_agama,
                u.ayah_pendidikan, u.ayah_pekerjaan, u.ayah_penghasilan, u.ayah_hp,
                u.ayah_status,
                u.ibu_nama, u.ibu_nik, u.ibu_ttl, u.ibu_agama,
                u.ibu_pendidikan, u.ibu_pekerjaan, u.ibu_penghasilan, u.ibu_hp,
                u.ibu_status,
                u.wali_nama, u.wali_hubungan, u.wali_pekerjaan, u.wali_hp,
                k.nama_kelas,
                ta.tahun    AS tahun_ajaran,
                ta.id       AS id_tahun_ajaran
            FROM anak s
            LEFT JOIN kelas k         ON s.id_kelas = k.id
            LEFT JOIN tahun_ajaran ta ON k.id_tahun_ajaran = ta.id
            LEFT JOIN users u         ON s.id_ortu = u.id";

    $where = [];
    if (!empty($search)) {
        $where[] = "(s.nama_anak LIKE '%$search%'
                     OR s.nisn       LIKE '%$search%'
                     OR k.nama_kelas LIKE '%$search%'
                     OR ta.tahun     LIKE '%$search%')";
    }
    if ($id_kelas) {
        $where[] = "s.id_kelas = $id_kelas";
    }

    if (!empty($where)) {
        $sql .= " WHERE " . implode(" AND ", $where);
    }

    $sql .= " ORDER BY ta.tahun DESC, s.nama_anak ASC";

    $result = $conn->query($sql);

    if (!$result) {
        echo json_encode(["status" => "error", "message" => $conn->error]);
        exit;
    }

    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }

    echo json_encode(["status" => "success", "data" => $data]);

} elseif ($method == 'POST') {

    $data   = json_decode(file_get_contents("php://input"));
    $action = $data->action ?? '';
    
    // ── Ambil user yang melakukan aktivitas (graceful fallback) ──
    $currentUser = $data->user ?? null;
    $currentUserId = $currentUser->id ?? null;
    $currentUserRole = $currentUser->role ?? null;

    // ── Helper: ambil & escape nilai, kembalikan NULL jika kosong ──
    $str  = fn($v) => !empty($v) ? "'" . $conn->real_escape_string($v) . "'" : "NULL";
    $num  = fn($v) => !empty($v) ? intval($v)   : "NULL";
    $dec  = fn($v) => !empty($v) ? floatval($v) : "NULL";

    if ($action == 'add') {

        $nama         = $str($data->nama_anak    ?? '');
        $nisn         = $str($data->nisn          ?? '');
        $nik          = $str($data->nik           ?? '');
        $tempat_lahir = $str($data->tempat_lahir  ?? '');
        $jk           = $str($data->jenis_kelamin ?? '');
        $agama        = $str($data->agama         ?? '');
        $status_anak  = $str($data->status_anak   ?? '');
        $anak_ke      = $num($data->anak_ke       ?? '');
        $tgl_lahir    = $str($data->tanggal_lahir ?? '');
        $berat        = $dec($data->berat_badan   ?? '');
        $tinggi       = $dec($data->tinggi_badan  ?? '');
        $alamat       = $str($data->alamat        ?? '');
        $id_kelas     = $num($data->id_kelas      ?? '');
        $id_ortu      = $data->id_ortu            ?? '';

        $realOrtuId = !empty($id_ortu) ? intval($id_ortu) : "NULL";

        $sql = "INSERT INTO anak 
                    (nama_anak, nisn, nik, tempat_lahir, jenis_kelamin, agama,
                     status_anak, anak_ke, tanggal_lahir, berat_badan, tinggi_badan,
                     alamat, id_kelas, id_ortu)
                VALUES
                    ($nama, $nisn, $nik, $tempat_lahir, $jk, $agama,
                     $status_anak, $anak_ke, $tgl_lahir, $berat, $tinggi,
                     $alamat, $id_kelas, $realOrtuId)";

        if ($conn->query($sql)) {
            // Sinkronisasi NISN ke tabel users untuk orang tua
            if (!empty($id_ortu) && !empty($data->nisn)) {
                $ortuId = intval($id_ortu);
                $newNisn = $data->nisn;
                $escapedNisn = $conn->real_escape_string($newNisn);
                $hashedPassword = password_hash($newNisn, PASSWORD_BCRYPT);
                $conn->query("UPDATE users SET nisn = '$escapedNisn', password = '$hashedPassword' WHERE id = $ortuId AND role = 'orang_tua'");
            }
            logActivity(getPdo(), "Data anak ditambahkan", "Anak " . $nama . " berhasil dibuat", "anak", "tambah", $currentUserId, $currentUserRole);
            echo json_encode(["status" => "success", "message" => "Anak berhasil ditambahkan"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    } elseif ($action == 'update') {

        $id           = intval($data->id);
        $nama         = $str($data->nama_anak    ?? '');
        $nisn         = $str($data->nisn          ?? '');
        $nik          = $str($data->nik           ?? '');
        $tempat_lahir = $str($data->tempat_lahir  ?? '');
        $jk           = $str($data->jenis_kelamin ?? '');
        $agama        = $str($data->agama         ?? '');
        $status_anak  = $str($data->status_anak   ?? '');
        $anak_ke      = $num($data->anak_ke       ?? '');
        $tgl_lahir    = $str($data->tanggal_lahir ?? '');
        $berat        = $dec($data->berat_badan   ?? '');
        $tinggi       = $dec($data->tinggi_badan  ?? '');
        $alamat       = $str($data->alamat        ?? '');
        $id_kelas     = $num($data->id_kelas      ?? '');
        $id_ortu      = $data->id_ortu            ?? '';

        $realOrtuId = !empty($id_ortu) ? intval($id_ortu) : "NULL";

        $sql = "UPDATE anak SET
                    nama_anak     = $nama,
                    nisn          = $nisn,
                    nik           = $nik,
                    tempat_lahir  = $tempat_lahir,
                    jenis_kelamin = $jk,
                    agama         = $agama,
                    status_anak   = $status_anak,
                    anak_ke       = $anak_ke,
                    tanggal_lahir = $tgl_lahir,
                    berat_badan   = $berat,
                    tinggi_badan  = $tinggi,
                    alamat        = $alamat,
                    id_kelas      = $id_kelas,
                    id_ortu       = $realOrtuId
                WHERE id = $id";

        if ($conn->query($sql)) {
            // Sinkronisasi NISN ke tabel users untuk orang tua
            if (!empty($id_ortu) && !empty($data->nisn)) {
                $ortuId = intval($id_ortu);
                $newNisn = $data->nisn;
                $escapedNisn = $conn->real_escape_string($newNisn);
                $hashedPassword = password_hash($newNisn, PASSWORD_BCRYPT);
                $conn->query("UPDATE users SET nisn = '$escapedNisn', password = '$hashedPassword' WHERE id = $ortuId AND role = 'orang_tua'");
            }
            logActivity(getPdo(), "Data anak diperbarui", "Anak " . $nama . " berhasil diperbarui", "anak", "edit", $currentUserId, $currentUserRole);
            echo json_encode(["status" => "success", "message" => "Anak berhasil diperbarui"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }

    } elseif ($action == 'delete') {

        $id  = intval($data->id);
        
        $get_name = $conn->query("SELECT nama_anak FROM anak WHERE id = $id LIMIT 1");
        $nama_anak = "ID $id";
        if ($get_name && $row = $get_name->fetch_assoc()) {
            $nama_anak = $row['nama_anak'];
        }

        $sql = "DELETE FROM anak WHERE id = $id";

        if ($conn->query($sql)) {
            logActivity(getPdo(), "Data anak dihapus", "Anak '{$nama_anak}' berhasil dihapus", "anak", "hapus", $currentUserId, $currentUserRole);
            echo json_encode(["status" => "success", "message" => "Anak berhasil dihapus"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
    }
}

$conn->close();
?>