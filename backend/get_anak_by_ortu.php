<?php
require_once 'config.php';
require_once 'cors.php';

// GET - Fetch data anak berdasarkan orang tua yang login
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $ortu_id = isset($_GET['id_ortu']) ? (int)$_GET['id_ortu'] : null;

        if (!$ortu_id) {
            http_response_code(400);
            echo json_encode([
                'status' => 'error',
                'message' => 'ID Orang Tua harus disediakan'
            ]);
            exit;
        }

        // Verify bahwa orang tua ini exist di users
        $verify_sql = "SELECT id, name FROM users WHERE id = $ortu_id AND role = 'orang_tua' LIMIT 1";
        $verify_result = $conn->query($verify_sql);

        if (!$verify_result || $verify_result->num_rows === 0) {
            http_response_code(403);
            echo json_encode([
                'status' => 'error',
                'message' => 'Orang tua tidak ditemukan atau tidak memiliki akses'
            ]);
            exit;
        }

        // Query fetch semua anak dari orang tua ini dengan detail lengkap
        $sql = "SELECT
                    s.id,
                    s.nama_anak AS nama_anak,
                    s.nisn,
                    s.nik,
                    s.jenis_kelamin,
                    s.tempat_lahir,
                    s.tanggal_lahir,
                    s.agama,
                    s.status_anak,
                    s.anak_ke,
                    s.alamat,
                    s.berat_badan,
                    s.tinggi_badan,
                    k.id as id_kelas,
                    k.nama_kelas,
                    COALESCE(g.name, '-') AS nama_guru,
                    ta.id as id_tahun_ajaran,
                    ta.tahun,
                    u.name as nama_ortu,
                    u.email as email_ortu,
                    u.no_hp as no_telp_ortu
                FROM anak s
                LEFT JOIN kelas k ON s.id_kelas = k.id
                LEFT JOIN users g ON k.id = g.id_kelas AND g.role = 'guru'
                LEFT JOIN tahun_ajaran ta ON k.id_tahun_ajaran = ta.id
                LEFT JOIN users u ON s.id_ortu = u.id
                WHERE s.id_ortu = $ortu_id
                ORDER BY s.nama_anak ASC";

        $result = $conn->query($sql);

        if ($result && $result->num_rows > 0) {
            $anak_list = [];
            while ($row = $result->fetch_assoc()) {
                $anak_list[] = $row;
            }

            http_response_code(200);
            echo json_encode([
                'status' => 'success',
                'message' => 'Data anak berhasil diambil',
                'data' => $anak_list,
                'total' => count($anak_list)
            ]);
        } else {
            http_response_code(200);
            echo json_encode([
                'status' => 'success',
                'message' => 'Tidak ada data anak',
                'data' => [],
                'total' => 0
            ]);
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
}

// Method tidak didukung
else {
    http_response_code(405);
    echo json_encode([
        'status' => 'error',
        'message' => 'Method tidak didukung'
    ]);
}

$conn->close();
?>
