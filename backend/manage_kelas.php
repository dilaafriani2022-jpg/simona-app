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
    $sql = "SELECT 
                k.*,
                t.tahun,
                t.status AS status_tahun,
                COUNT(DISTINCT s.id)  AS jumlah_anak,
                g.name                AS nama_guru,
                g.id                  AS id_guru
            FROM kelas k
            LEFT JOIN tahun_ajaran t ON k.id_tahun_ajaran = t.id
            LEFT JOIN anak s         ON s.id_kelas = k.id
            LEFT JOIN users g        ON g.id_kelas = k.id AND g.role = 'guru'
            GROUP BY k.id, k.nama_kelas, k.id_tahun_ajaran, t.tahun, t.status, g.name, g.id
            ORDER BY t.tahun DESC, k.nama_kelas ASC";
    $result = $conn->query($sql);
    $data = [];
    while($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
    echo json_encode(["status" => "success", "data" => $data]);
} 

elseif ($method == 'POST') {
    $data = json_decode(file_get_contents("php://input"));
    $action = $data->action ?? '';
    
    // ── Ambil user yang melakukan aktivitas (graceful fallback) ──
    $currentUser = $data->user ?? null;
    $currentUserId = $currentUser->id ?? null;
    $currentUserRole = $currentUser->role ?? null;

    if ($action == 'add') {
        $nama = $conn->real_escape_string($data->nama_kelas);
        $id_tahun = intval($data->id_tahun_ajaran);
        $sql = "INSERT INTO kelas (nama_kelas, id_tahun_ajaran) VALUES ('$nama', $id_tahun)";
        if ($conn->query($sql)) {
            logActivity(getPdo(), "Kelas ditambahkan", "Kelas '{$nama}' berhasil dibuat", "kelas", "tambah", $currentUserId, $currentUserRole);
            echo json_encode(["status" => "success", "message" => "Kelas berhasil ditambahkan"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
    } 
    elseif ($action == 'update') {
        $id = intval($data->id);
        $nama = $conn->real_escape_string($data->nama_kelas);
        $id_tahun = intval($data->id_tahun_ajaran);
        $sql = "UPDATE kelas SET nama_kelas = '$nama', id_tahun_ajaran = $id_tahun WHERE id = $id";
        if ($conn->query($sql)) {
            logActivity(getPdo(), "Kelas diperbarui", "Kelas '{$nama}' berhasil diperbarui", "kelas", "edit", $currentUserId, $currentUserRole);
            echo json_encode(["status" => "success", "message" => "Kelas berhasil diperbarui"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
    }
    elseif ($action == 'delete') {
        $id = intval($data->id);

        $get_name = $conn->query("SELECT nama_kelas FROM kelas WHERE id = $id LIMIT 1");
        $nama = "ID $id";
        if ($get_name && $row = $get_name->fetch_assoc()) {
            $nama = $row['nama_kelas'];
        }

        // Jalankan dalam transaksi database agar data konsisten
        $conn->begin_transaction();
        try {
            // 1. Set id_kelas = NULL untuk anak (agar data anak tidak terhapus)
            $conn->query("UPDATE anak SET id_kelas = NULL WHERE id_kelas = $id");

            // 2. Set id_kelas = NULL untuk guru di tabel users
            $conn->query("UPDATE users SET id_kelas = NULL WHERE id_kelas = $id");

            // 3. Set id_kelas = NULL untuk tabel refleksi
            $conn->query("UPDATE refleksi SET id_kelas = NULL WHERE id_kelas = $id");

            // 4. Hapus jadwal kelas
            $conn->query("DELETE FROM jadwal_kelas WHERE id_kelas = $id");

            // 5. Hapus RPPH
            $conn->query("DELETE FROM rpph WHERE id_kelas = $id");

            // 6. Hapus RPPM
            $conn->query("DELETE FROM rppm WHERE id_kelas = $id");

            // 7. Hapus kelas
            $sql = "DELETE FROM kelas WHERE id = $id";
            if ($conn->query($sql)) {
                $conn->commit();
                logActivity(getPdo(), "Kelas dihapus", "Kelas '{$nama}' berhasil dihapus", "kelas", "hapus", $currentUserId, $currentUserRole);
                echo json_encode(["status" => "success", "message" => "Kelas berhasil dihapus"]);
            } else {
                throw new Exception($conn->error);
            }
        } catch (Exception $e) {
            $conn->rollback();
            echo json_encode(["status" => "error", "message" => "Gagal menghapus kelas: " . $e->getMessage()]);
        }
    }
}

$conn->close();
?>
