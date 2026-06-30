<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET, PUT");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

include 'koneksi.php'; // sesuaikan path koneksi database kamu

$method = $_SERVER['REQUEST_METHOD'];

// GET /api/profil_sekolah — ambil data profil
if ($method === 'GET') {
    $query = "SELECT * FROM profil_sekolah LIMIT 1";
    $result = mysqli_query($conn, $query);
    $data = mysqli_fetch_assoc($result);

    if ($data) {
        echo json_encode([
            'status'  => 'success',
            'data'    => $data
        ]);
    } else {
        echo json_encode([
            'status'  => 'error',
            'message' => 'Data profil tidak ditemukan'
        ]);
    }
}

// PUT /api/profil_sekolah — update data profil (hanya operator)
if ($method === 'PUT') {
    $input = json_decode(file_get_contents("php://input"), true);

    // Validasi token operator di sini sesuai sistem auth kamu
    // ...

    $fields = [
        'nama_sekolah', 'npsn', 'jenjang', 'status', 'alamat',
        'kelurahan', 'kecamatan', 'kabupaten', 'provinsi', 'kode_pos',
        'no_telp', 'email', 'website', 'kepala_sekolah',
        'operator_nama', 'tahun_berdiri', 'akreditasi', 'visi', 'misi'
    ];

    $setParts = [];
    foreach ($fields as $field) {
        if (isset($input[$field])) {
            $val = mysqli_real_escape_string($conn, $input[$field]);
            $setParts[] = "$field = '$val'";
        }
    }

    if (empty($setParts)) {
        echo json_encode(['status' => 'error', 'message' => 'Tidak ada data yang diubah']);
        exit;
    }

    $setQuery = implode(", ", $setParts);
    $query    = "UPDATE profil_sekolah SET $setQuery WHERE id = 1";
    $result   = mysqli_query($conn, $query);

    if ($result) {
        echo json_encode(['status' => 'success', 'message' => 'Profil sekolah berhasil diperbarui']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui profil']);
    }
}
?>