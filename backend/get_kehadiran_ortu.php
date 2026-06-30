<?php
require_once 'config.php';
require_once 'cors.php';

// GET - Fetch kehadiran anak untuk dashboard orang tua
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $anak_id = isset($_GET['id_anak']) ? (int)$_GET['id_anak'] : null;
        $bulan = isset($_GET['bulan']) ? (int)$_GET['bulan'] : date('m');
        $tahun = isset($_GET['tahun']) ? (int)$_GET['tahun'] : date('Y');

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

        // Query kehadiran dengan filter bulan dan tahun
        $sql = "SELECT
                    a.id,
                    a.id_anak,
                    a.id_guru,
                    a.tanggal,
                    a.status,
                    a.keterangan,
                    u.name as nama_guru
                FROM absensi a
                LEFT JOIN users u ON a.id_guru = u.id
                WHERE a.id_anak = $anak_id
                    AND MONTH(a.tanggal) = $bulan
                    AND YEAR(a.tanggal) = $tahun
                ORDER BY a.tanggal ASC";

        $result = $conn->query($sql);

        if ($result->num_rows > 0) {
            $kehadiran_list = [];
            $stats = [
                'Hadir' => 0,
                'Sakit' => 0,
                'Izin' => 0,
                'Alpa' => 0
            ];

            while ($row = $result->fetch_assoc()) {
                $kehadiran_list[] = $row;
                if (isset($stats[$row['status']])) {
                    $stats[$row['status']]++;
                }
            }

            http_response_code(200);
            echo json_encode([
                'status' => 'success',
                'message' => 'Data kehadiran berhasil diambil',
                'data' => $kehadiran_list,
                'stats' => $stats,
                'bulan' => $bulan,
                'tahun' => $tahun
            ]);
        } else {
            http_response_code(200);
            echo json_encode([
                'status' => 'success',
                'message' => 'Tidak ada data kehadiran',
                'data' => [],
                'stats' => [
                    'Hadir' => 0,
                    'Sakit' => 0,
                    'Izin' => 0,
                    'Alpa' => 0
                ],
                'bulan' => $bulan,
                'tahun' => $tahun
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
