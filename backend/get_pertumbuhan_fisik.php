<?php
require_once 'config.php';
require_once 'cors.php';

// GET - Fetch history pertumbuhan fisik (berat dan tinggi badan)
// Menampilkan data terakhir dari kolom berat_badan dan tinggi_badan anak
// Untuk history penuh, akan di-track di tabel terpisah atau melalui table history
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $anak_id = isset($_GET['id_anak']) ? (int)$_GET['id_anak'] : null;
        $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 6;

        if (!$anak_id) {
            http_response_code(400);
            echo json_encode([
                'status' => 'error',
                'message' => 'ID Anak harus disediakan'
            ]);
            exit;
        }

        // Verify anak exist
        $verify_sql = "SELECT id, nama_anak AS nama_anak, berat_badan, tinggi_badan, tanggal_lahir FROM anak WHERE id = $anak_id LIMIT 1";
        $verify_result = $conn->query($verify_sql);

        if ($verify_result->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                'status' => 'error',
                'message' => 'Anak tidak ditemukan'
            ]);
            exit;
        }

        $anak = $verify_result->fetch_assoc();
        $berat_sekarang = $anak['berat_badan'];
        $tinggi_sekarang = $anak['tinggi_badan'];

        // Check apakah ada tabel history_pertumbuhan (untuk future enhancement)
        // Untuk sekarang, kita return current weight/height dengan placeholder history
        $check_table = "SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '" . $db . "' AND TABLE_NAME = 'history_pertumbuhan'";
        $table_exists = $conn->query($check_table)->num_rows > 0;

        if ($table_exists) {
            // Jika ada history table, ambil data dari sana
            $sql = "SELECT
                        hp.id,
                        hp.id_anak,
                        hp.tanggal_ukur,
                        hp.berat_badan,
                        hp.tinggi_badan,
                        hp.catatan
                    FROM history_pertumbuhan hp
                    WHERE hp.id_anak = $anak_id
                    ORDER BY hp.tanggal_ukur DESC
                    LIMIT $limit";

            $result = $conn->query($sql);

            if ($result->num_rows > 0) {
                $history_list = [];
                while ($row = $result->fetch_assoc()) {
                    $history_list[] = $row;
                }

                // Sort ascending untuk chart (oldest first)
                $history_list = array_reverse($history_list);

                http_response_code(200);
                echo json_encode([
                    'status' => 'success',
                    'message' => 'Data pertumbuhan berhasil diambil',
                    'current' => [
                        'berat_badan' => $berat_sekarang,
                        'tinggi_badan' => $tinggi_sekarang
                    ],
                    'data' => $history_list,
                    'total' => count($history_list)
                ]);
            } else {
                http_response_code(200);
                echo json_encode([
                    'status' => 'success',
                    'message' => 'Tidak ada data history pertumbuhan',
                    'current' => [
                        'berat_badan' => $berat_sekarang,
                        'tinggi_badan' => $tinggi_sekarang
                    ],
                    'data' => [],
                    'total' => 0
                ]);
            }
        } else {
            // Jika belum ada history table, kembalikan current data saja
            http_response_code(200);
            echo json_encode([
                'status' => 'success',
                'message' => 'Data pertumbuhan terakhir',
                'current' => [
                    'berat_badan' => $berat_sekarang,
                    'tinggi_badan' => $tinggi_sekarang
                ],
                'data' => [],
                'note' => 'History tracking belum diaktifkan. Menampilkan data terakhir saja.'
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
