<?php
require_once 'config.php';
require_once 'cors.php';

// GET - Fetch kehadiran anak untuk dashboard orang tua
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $anak_id = isset($_GET['id_anak']) ? (int)$_GET['id_anak'] : null;
        $bulan = isset($_GET['bulan']) ? (int)$_GET['bulan'] : date('m');
        $tahun = isset($_GET['tahun']) ? (int)$_GET['tahun'] : date('Y');
        $semester = isset($_GET['semester']) ? (int)$_GET['semester'] : null;

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

        $use_academic_range = false;
        $start_date = null;
        $end_date = null;

        if ($semester !== null) {
            // Get student's class
            $class_sql = "SELECT id_kelas FROM anak WHERE id = $anak_id LIMIT 1";
            $class_res = $conn->query($class_sql);
            if ($class_res && $class_row = $class_res->fetch_assoc()) {
                $id_kelas = (int)$class_row['id_kelas'];
                if ($id_kelas > 0) {
                    $min_week = ($bulan - 1) * 4 + 1;
                    $max_week = $bulan * 4;
                    if ($bulan === 5) {
                        $max_week = 20;
                    }
                    
                    // Fetch date range from prosem
                    $date_sql = "SELECT MIN(tanggal_mulai) as start_d, MAX(tanggal_selesai) as end_d 
                                 FROM prosem 
                                 WHERE id_kelas = $id_kelas 
                                   AND semester = $semester 
                                   AND minggu_ke BETWEEN $min_week AND $max_week";
                    $date_res = $conn->query($date_sql);
                    if ($date_res && $date_row = $date_res->fetch_assoc()) {
                        if ($date_row['start_d'] && $date_row['end_d']) {
                            $start_date = $date_row['start_d'];
                            $end_date = $date_row['end_d'];
                            $use_academic_range = true;
                        }
                    }
                }
            }
        }

        // Query kehadiran
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
                WHERE a.id_anak = $anak_id";

        if ($use_academic_range) {
            $sql .= " AND a.tanggal BETWEEN '$start_date' AND '$end_date'";
        } else {
            // Fallback to calendar month calculation
            $cal_month = $semester !== null ? ($semester == 1 ? $bulan + 6 : $bulan) : $bulan;
            $sql .= " AND MONTH(a.tanggal) = $cal_month AND YEAR(a.tanggal) = $tahun";
        }
        $sql .= " ORDER BY a.tanggal ASC";

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
