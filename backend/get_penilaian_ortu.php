<?php
require_once 'config.php';
require_once 'cors.php';

// GET - Fetch penilaian anak untuk dashboard orang tua
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $anak_id = isset($_GET['id_anak']) ? (int)$_GET['id_anak'] : null;
        $bulan    = isset($_GET['bulan'])    ? (int)$_GET['bulan']    : null;
        $semester = isset($_GET['semester']) ? (int)$_GET['semester'] : 1;
        $type     = $_GET['type'] ?? 'detail'; // 'detail' | 'rekap_bulanan'
        $limit    = isset($_GET['limit'])    ? (int)$_GET['limit']    : 100;

        if (!$anak_id) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'ID Anak harus disediakan']);
            exit;
        }

        // Verify anak exist
        if (!$conn->query("SELECT id FROM anak WHERE id = $anak_id LIMIT 1")->num_rows) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Anak tidak ditemukan']);
            exit;
        }

        // ── MODE: REKAP BULANAN (Rangkuman per bulan untuk Orang Tua) ─────────
        if ($type === 'rekap_bulanan') {
            $sql = "SELECT
                        rb.id,
                        rb.bulan,
                        rb.semester,
                        rb.status_akhir,
                        rb.catatan_perkembangan,
                        rb.created_at,
                        kg.nama_kegiatan,
                        tp.nama_tujuan,
                        ap.nama_aspek,
                        g.name AS nama_guru
                    FROM rekap_penilaian_bulanan rb
                    JOIN kegiatan_pembelajaran kg ON rb.id_kegiatan = kg.id
                    JOIN tujuan_pembelajaran tp ON kg.id_tujuan = tp.id
                    JOIN aspek_penilaian ap ON tp.id_aspek = ap.id
                    JOIN users g ON rb.id_guru = g.id
                    WHERE rb.id_anak = $anak_id
                      AND rb.semester = $semester";

            if ($bulan) $sql .= " AND rb.bulan = $bulan";
            $sql .= " ORDER BY rb.bulan ASC, ap.nama_aspek ASC";

            $result = $conn->query($sql);
            if (!$result) {
                http_response_code(500);
                echo json_encode(['status' => 'error', 'message' => $conn->error]);
                exit;
            }

            $rekap_list = [];
            $bulan_map  = [];

            while ($row = $result->fetch_assoc()) {
                $rekap_list[] = $row;
                $b = $row['bulan'];
                if (!isset($bulan_map[$b])) {
                    $bulan_map[$b] = ['bulan' => $b, 'aspek' => [], 'catatan' => ''];
                }
                $aspek = $row['nama_aspek'];
                if (!isset($bulan_map[$b]['aspek'][$aspek])) {
                    $bulan_map[$b]['aspek'][$aspek] = $row['status_akhir'];
                }
                // Ambil catatan perkembangan (non-empty)
                if (!empty($row['catatan_perkembangan'])) {
                    $bulan_map[$b]['catatan'] = $row['catatan_perkembangan'];
                }
            }

            echo json_encode([
                'status'   => 'success',
                'message'  => 'Rekap penilaian bulanan berhasil diambil',
                'data'     => $rekap_list,
                'ringkasan' => array_values($bulan_map),
                'total'    => count($rekap_list)
            ]);
            exit;
        }

        // ── MODE: DETAIL CHECKLIST (Data mentah per minggu untuk orang tua) ──
        $sql = "SELECT
                    pc.id,
                    pc.id_anak,
                    pc.id_aspek,
                    pc.id_guru,
                    pc.tanggal,
                    pc.semester,
                    pc.minggu_ke,
                    pc.status,
                    pc.catatan,
                    pc.konteks,
                    pc.hasil,
                    pc.kejadian,
                    pc.id_kegiatan,
                    kg.nama_kegiatan,
                    tp.nama_tujuan,
                    ap.nama_aspek,
                    g.name AS nama_guru
                FROM penilaian pc
                LEFT JOIN aspek_penilaian ap ON pc.id_aspek = ap.id
                LEFT JOIN users g ON pc.id_guru = g.id
                LEFT JOIN kegiatan_pembelajaran kg ON pc.id_kegiatan = kg.id
                LEFT JOIN tujuan_pembelajaran tp ON COALESCE(pc.id_tujuan, kg.id_tujuan) = tp.id
                WHERE pc.id_anak = $anak_id
                  AND pc.semester = $semester
                  AND pc.tipe = 'checklist'";

        if ($bulan) {
            // Filter berdasarkan bulan: Bulan 1 = Minggu 1-4, Bulan 2 = Minggu 5-8, dst.
            $min_minggu = ($bulan - 1) * 4 + 1;
            $max_minggu = $bulan * 4;
            $sql .= " AND pc.minggu_ke BETWEEN $min_minggu AND $max_minggu";
        }

        $sql .= " ORDER BY pc.tanggal DESC, ap.nama_aspek ASC LIMIT $limit";

        $result = $conn->query($sql);
        if (!$result) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $conn->error]);
            exit;
        }

        $penilaian_list  = [];
        $summary_by_aspek = [];

        while ($row = $result->fetch_assoc()) {
            $penilaian_list[] = $row;
            $aspek_name = $row['nama_aspek'];
            if (!isset($summary_by_aspek[$aspek_name])) {
                $summary_by_aspek[$aspek_name] = [
                    'nama_aspek'    => $aspek_name,
                    'statuses'      => [],
                    'status_terakhir' => $row['status']
                ];
            }
            if (!in_array($row['status'], $summary_by_aspek[$aspek_name]['statuses'])) {
                $summary_by_aspek[$aspek_name]['statuses'][] = $row['status'];
            }
        }

        echo json_encode([
            'status'  => 'success',
            'message' => 'Data penilaian berhasil diambil',
            'data'    => $penilaian_list,
            'summary' => array_values($summary_by_aspek),
            'total'   => count($penilaian_list)
        ]);

    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Error: ' . $e->getMessage()]);
    }
} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method tidak didukung']);
}

$conn->close();
?>

