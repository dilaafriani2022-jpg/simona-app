<?php
require_once 'config.php';
require_once 'cors.php';

// GET - Fetch galeri/karya anak untuk orang tua
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $anak_id = isset($_GET['id_anak']) ? (int)$_GET['id_anak'] : null;
        $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
        $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;

        if (!$anak_id) {
            http_response_code(400);
            echo json_encode([
                'status' => 'error',
                'message' => 'ID Anak harus disediakan'
            ]);
            exit;
        }

        // Verify anak exist
        $verify_sql = "SELECT id FROM anak WHERE id = $anak_id LIMIT 1";
        $verify_result = $conn->query($verify_sql);

        if ($verify_result->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                'status' => 'error',
                'message' => 'Anak tidak ditemukan'
            ]);
            exit;
        }

        // Query karya anak dengan info guru
        $sql = "SELECT
                    k.id,
                    k.id_anak,
                    k.id_guru,
                    k.judul,
                    k.deskripsi,
                    k.tanggal,
                    k.kategori,
                    k.url_foto,
                    u.name as nama_guru
                FROM penilaian k
                LEFT JOIN users u ON k.id_guru = u.id
                WHERE k.id_anak = $anak_id AND k.tipe = 'karya'
                ORDER BY k.tanggal DESC
                LIMIT $limit OFFSET $offset";

        $result = $conn->query($sql);

        // Get total count
        $count_sql = "SELECT COUNT(*) as total FROM penilaian WHERE id_anak = $anak_id AND tipe = 'karya'";
        $count_result = $conn->query($count_sql);
        $count_row = $count_result->fetch_assoc();
        $total = $count_row['total'];

        if ($result->num_rows > 0) {
            $karya_list = [];
            while ($row = $result->fetch_assoc()) {
                $karya_list[] = $row;
            }

            http_response_code(200);
            echo json_encode([
                'status' => 'success',
                'message' => 'Data karya berhasil diambil',
                'data' => $karya_list,
                'total' => $total,
                'limit' => $limit,
                'offset' => $offset
            ]);
        } else {
            http_response_code(200);
            echo json_encode([
                'status' => 'success',
                'message' => 'Tidak ada karya anak',
                'data' => [],
                'total' => 0,
                'limit' => $limit,
                'offset' => $offset
            ]);
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => 'Error: ' . $e->getMessage()
        ]);
    }
} else {
    http_response_code(405);
    echo json_encode([
        'status' => 'error',
        'message' => 'Method tidak didukung'
    ]);
}

$conn->close();
?>
