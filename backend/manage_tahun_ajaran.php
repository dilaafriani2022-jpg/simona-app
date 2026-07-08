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
    $sql = "SELECT id, tahun, status, tanggal_mulai_semester_1, tanggal_akhir_semester_1, tanggal_mulai_semester_2, tanggal_akhir_semester_2 FROM tahun_ajaran";
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

    if ($action == 'add') {
        $tahun  = $conn->real_escape_string($data->tahun);
        $status = $conn->real_escape_string($data->status);
        // Jika status aktif, nonaktifkan yang lain terlebih dahulu
        if ($status === 'aktif') {
            $conn->query("UPDATE tahun_ajaran SET status = 'nonaktif'");
        }
        $sql = "INSERT INTO tahun_ajaran (tahun, status) VALUES ('$tahun', '$status')";
        if ($conn->query($sql)) {
            logActivity(getPdo(), "Tahun ajaran ditambahkan", "Tahun ajaran '{$tahun}' ({$status}) berhasil dibuat", "tahun", "tambah");
            echo json_encode(["status" => "success", "message" => "Tahun ajaran berhasil ditambahkan"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
    } 
    elseif ($action == 'update') {
        $id     = intval($data->id);
        $tahun  = $conn->real_escape_string($data->tahun);
        $status = $conn->real_escape_string($data->status);
        // Tanggal semester (opsional)
        $tgl_m1 = isset($data->tanggal_mulai_semester_1) && $data->tanggal_mulai_semester_1 ? "'" . $conn->real_escape_string($data->tanggal_mulai_semester_1) . "'" : 'NULL';
        $tgl_a1 = isset($data->tanggal_akhir_semester_1) && $data->tanggal_akhir_semester_1 ? "'" . $conn->real_escape_string($data->tanggal_akhir_semester_1) . "'" : 'NULL';
        $tgl_m2 = isset($data->tanggal_mulai_semester_2) && $data->tanggal_mulai_semester_2 ? "'" . $conn->real_escape_string($data->tanggal_mulai_semester_2) . "'" : 'NULL';
        $tgl_a2 = isset($data->tanggal_akhir_semester_2) && $data->tanggal_akhir_semester_2 ? "'" . $conn->real_escape_string($data->tanggal_akhir_semester_2) . "'" : 'NULL';
        // Jika diubah ke aktif, nonaktifkan yang lain terlebih dahulu
        if ($status === 'aktif') {
            $conn->query("UPDATE tahun_ajaran SET status = 'nonaktif' WHERE id != $id");
        }
        $sql = "UPDATE tahun_ajaran SET
            tahun = '$tahun',
            status = '$status',
            tanggal_mulai_semester_1 = $tgl_m1,
            tanggal_akhir_semester_1 = $tgl_a1,
            tanggal_mulai_semester_2 = $tgl_m2,
            tanggal_akhir_semester_2 = $tgl_a2
            WHERE id = $id";
        if ($conn->query($sql)) {
            logActivity(getPdo(), "Tahun ajaran diperbarui", "Tahun ajaran '{$tahun}' ({$status}) berhasil diperbarui", "tahun", "edit");
            echo json_encode(["status" => "success", "message" => "Tahun ajaran berhasil diperbarui"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
    }
    elseif ($action == 'set_aktif') {
        $id = intval($data->id);
        // Nonaktifkan semua dahulu, lalu aktifkan yang dipilih
        $conn->query("UPDATE tahun_ajaran SET status = 'nonaktif'");
        $sql = "UPDATE tahun_ajaran SET status = 'aktif' WHERE id = $id";
        if ($conn->query($sql)) {
            $get_name = $conn->query("SELECT tahun FROM tahun_ajaran WHERE id = $id LIMIT 1");
            $tahun = "ID $id";
            if ($get_name && $row = $get_name->fetch_assoc()) {
                $tahun = $row['tahun'];
            }
            logActivity(getPdo(), "Tahun ajaran diaktifkan", "Tahun ajaran '{$tahun}' berhasil diaktifkan", "tahun", "sync");
            echo json_encode(["status" => "success", "message" => "Tahun ajaran berhasil diaktifkan"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
    }
    elseif ($action == 'delete') {
        $id = intval($data->id);

        $get_name = $conn->query("SELECT tahun FROM tahun_ajaran WHERE id = $id LIMIT 1");
        $tahun = "ID $id";
        if ($get_name && $row = $get_name->fetch_assoc()) {
            $tahun = $row['tahun'];
        }

        $sql = "DELETE FROM tahun_ajaran WHERE id = $id";
        if ($conn->query($sql)) {
            logActivity(getPdo(), "Tahun ajaran dihapus", "Tahun ajaran '{$tahun}' berhasil dihapus", "tahun", "hapus");
            echo json_encode(["status" => "success", "message" => "Tahun ajaran berhasil dihapus"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
    }
}

$conn->close();
?>
