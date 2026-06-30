<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require_once 'config.php';
require_once 'cors.php';

$sql = "SELECT id, name, role, username, nip, nisn, email, no_telp, pekerjaan, alamat, tempat_lahir, tanggal_lahir, agama, jenis_kelamin, status_nikah, pendidikan, jurusan, rt_rw, kelurahan, kecamatan, kota, provinsi, kode_pos FROM users ORDER BY id DESC";
$result = $conn->query($sql);

$users = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $users[] = $row;
    }
}

echo json_encode(["status" => "success", "data" => $users]);
$conn->close();
?>
