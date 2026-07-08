<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';
require_once 'cors.php';

// ── Helper ─────────────────────────────────────────────────────────────────
function respond(array $data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

// Helper: hitung bulan ke-N dari minggu ke-N (Bulan 1 = Minggu 1-4, dst.)
function bulanDariMinggu(int $minggu): int {
    return (int) ceil($minggu / 4);
}

// Helper: rentang minggu dari bulan ke-N
function rentangMinggu(int $bulan): array {
    $min = ($bulan - 1) * 4 + 1;
    $max = $bulan * 4;
    if ($bulan === 5) {
        $max = 18;
    }
    return [
        'min' => $min,
        'max' => $max
    ];
}

// Helper: konversi status enum ke nilai angka untuk perbandingan
function nilaiStatus(string $status): int {
    return match($status) {
        'M'  => 3,
        'MM' => 2,
        'TM' => 1,
        default => 0
    };
}

// ── Auto-migration: pastikan tabel rekap_aspek_bulanan & rekap_penilaian_bulanan ada ──────────────────
$conn->query("
    CREATE TABLE IF NOT EXISTS rekap_aspek_bulanan (
        id INT AUTO_INCREMENT PRIMARY KEY,
        id_anak INT NOT NULL,
        id_guru INT NOT NULL,
        bulan TINYINT NOT NULL,
        semester TINYINT DEFAULT 1,
        narasi_agama TEXT DEFAULT NULL,
        narasi_jati_diri TEXT DEFAULT NULL,
        narasi_literasi_steam TEXT DEFAULT NULL,
        narasi_kokurikuler TEXT DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
        FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE KEY unique_student_month (id_anak, bulan, semester)
    )
");

$conn->query("
    CREATE TABLE IF NOT EXISTS rekap_penilaian_bulanan (
        id INT AUTO_INCREMENT PRIMARY KEY,
        id_anak INT NOT NULL,
        id_guru INT NOT NULL,
        id_kegiatan INT NOT NULL,
        bulan TINYINT NOT NULL,
        semester TINYINT DEFAULT 1,
        status_akhir ENUM('TM', 'MM', 'M') NOT NULL,
        catatan_perkembangan TEXT DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
        FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (id_kegiatan) REFERENCES kegiatan_pembelajaran(id) ON DELETE CASCADE,
        UNIQUE KEY unique_rekap (id_anak, id_kegiatan, bulan, semester)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
");

$method = $_SERVER['REQUEST_METHOD'];

// ════════════════════════════════════════════════════════════════════════════
// GET
// ════════════════════════════════════════════════════════════════════════════
if ($method === 'GET') {
    $type     = $_GET['type']     ?? 'view'; // 'view' | 'rekomendasi' | 'narasi_aspek'
    $id_guru  = isset($_GET['id_guru'])  ? intval($_GET['id_guru'])  : null;
    $id_anak = isset($_GET['id_anak']) ? intval($_GET['id_anak']) : null;
    $id_kelas = isset($_GET['id_kelas']) ? intval($_GET['id_kelas']) : null;
    $bulan    = isset($_GET['bulan'])    ? intval($_GET['bulan'])    : null;
    $semester = isset($_GET['semester']) ? intval($_GET['semester']) : 1;

    // id_guru wajib untuk rekomendasi; view dan narasi_aspek bisa diakses tanpa id_guru
    if (!$id_guru && $type === 'rekomendasi') {
        respond(["status" => "error", "message" => "ID guru wajib diisi untuk type rekomendasi"]);
    }

    $real_guru_id = -1;
    if ($id_guru) {
        $real_guru_id = $id_guru;
    }


    // ── REKOMENDASI: Hitung status terbaik dari penilaian checklist mingguan ─
    if ($type === 'rekomendasi') {
        if (!$id_anak || !$bulan) {
            respond(["status" => "error", "message" => "id_anak dan bulan wajib diisi untuk rekomendasi"]);
        }

        // Hitung rentang minggu untuk bulan ini
        $range = rentangMinggu($bulan);
        $min_minggu = $range['min'];
        $max_minggu = $range['max'];

        // Ambil semua penilaian checklist anak di bulan ini (berdasarkan minggu_ke)
        $sql = "SELECT
                    pc.id_kegiatan,
                    kg.nama_kegiatan,
                    tp.id_aspek,
                    ap.nama_aspek,
                    tp.nama_tujuan,
                    tp.id AS id_tujuan,
                    pc.status,
                    pc.minggu_ke
                FROM penilaian pc
                JOIN kegiatan_pembelajaran kg ON pc.id_kegiatan = kg.id
                JOIN tujuan_pembelajaran tp ON kg.id_tujuan = tp.id
                JOIN aspek_penilaian ap ON tp.id_aspek = ap.id
                WHERE pc.id_anak = $id_anak
                  AND pc.id_guru = $real_guru_id
                  AND pc.semester = $semester
                  AND pc.tipe = 'checklist'
                  AND pc.minggu_ke BETWEEN $min_minggu AND $max_minggu
                ORDER BY pc.id_kegiatan ASC, pc.minggu_ke ASC";

        $result = $conn->query($sql);
        if (!$result) {
            respond(["status" => "error", "message" => $conn->error]);
        }

        // Kelompokkan per kegiatan, ambil status tertinggi (capaian terbaik)
        $kegiatanMap = [];
        while ($row = $result->fetch_assoc()) {
            $kid = $row['id_kegiatan'];
            if (!isset($kegiatanMap[$kid])) {
                $kegiatanMap[$kid] = [
                    'id_kegiatan'  => $kid,
                    'nama_kegiatan' => $row['nama_kegiatan'],
                    'id_tujuan'    => $row['id_tujuan'],
                    'nama_tujuan'  => $row['nama_tujuan'],
                    'id_aspek'     => $row['id_aspek'],
                    'nama_aspek'   => $row['nama_aspek'],
                    'status_rekomendasi' => 'TM',
                    'detail_mingguan'    => []
                ];
            }
            // Simpan detail per minggu
            $kegiatanMap[$kid]['detail_mingguan'][] = [
                'minggu_ke' => $row['minggu_ke'],
                'status'    => $row['status']
            ];
            // Ambil status tertinggi sebagai rekomendasi
            if (nilaiStatus($row['status']) > nilaiStatus($kegiatanMap[$kid]['status_rekomendasi'])) {
                $kegiatanMap[$kid]['status_rekomendasi'] = $row['status'];
            }
        }

        // Load already saved monthly summaries
        $savedSql = "SELECT id_kegiatan, status_akhir, catatan_perkembangan 
                     FROM rekap_penilaian_bulanan 
                     WHERE id_anak = $id_anak 
                       AND semester = $semester 
                       AND bulan = $bulan";
        $savedRes = $conn->query($savedSql);
        $savedMap = [];
        if ($savedRes) {
            while ($sRow = $savedRes->fetch_assoc()) {
                $savedMap[(int)$sRow['id_kegiatan']] = [
                    'status_akhir' => $sRow['status_akhir'],
                    'catatan_perkembangan' => $sRow['catatan_perkembangan']
                ];
            }
        }

        // Set values and check if already saved
        foreach ($kegiatanMap as &$item) {
            $kid = $item['id_kegiatan'];
            if (isset($savedMap[$kid])) {
                $item['sudah_direkap'] = true;
                // Send both key names for Flutter compatibility
                $item['status_akhir']      = $savedMap[$kid]['status_akhir'];
                $item['status_tersimpan']  = $savedMap[$kid]['status_akhir'];       // alias for Flutter
                $item['catatan_perkembangan'] = $savedMap[$kid]['catatan_perkembangan'];
                $item['catatan_tersimpan'] = $savedMap[$kid]['catatan_perkembangan']; // alias for Flutter
            } else {
                $item['sudah_direkap'] = false;
                $item['status_akhir']  = $item['status_rekomendasi']; // default to recommendation
                $item['status_tersimpan']  = null;
                $item['catatan_perkembangan'] = '';
                $item['catatan_tersimpan']    = null;
            }
        }

        respond([
            "status"   => "success",
            "bulan"    => $bulan,
            "semester" => $semester,
            "minggu_range" => "$min_minggu - $max_minggu",
            "data"     => array_values($kegiatanMap)
        ]);
    }

    // ── NARASI ASPEK: Ambil narasi bulanan (3 aspek) ───────────────────────
    if ($type === 'narasi_aspek') {
        if (!$id_anak || !$bulan) {
            respond(["status" => "error", "message" => "id_anak dan bulan wajib diisi"]);
        }

        $force_draft = isset($_GET['force_draft']) && $_GET['force_draft'] == '1';

        // Cari data yang sudah disimpan (jika bukan force_draft)
        if (!$force_draft) {
            $stmt = $conn->prepare(
                "SELECT r.*, g.name AS nama_guru, g.nip AS nip_guru 
                 FROM rekap_aspek_bulanan r
                 LEFT JOIN users g ON r.id_guru = g.id
                 WHERE r.id_anak = ? AND r.bulan = ? AND r.semester = ?"
            );
            $stmt->bind_param("iii", $id_anak, $bulan, $semester);
            $stmt->execute();
            $res = $stmt->get_result();
            
            if ($res && $res->num_rows > 0) {
                $data = $res->fetch_assoc();
                respond(["status" => "success", "data" => $data]);
            }
        }

        // Data belum ada atau force_draft=1! Generate DRAFT otomatis
        if ($bulan == 6) {
            // Rapor Akhir Semester: Ambil seluruh minggu (1-18) dan seluruh bulan dalam semester
            $min_minggu = 1;
            $max_minggu = 18;
            $month_condition = ($semester == 1) ? "MONTH(tanggal) BETWEEN 7 AND 12" : "MONTH(tanggal) BETWEEN 1 AND 6";
        } else {
            $range = rentangMinggu($bulan);
            $min_minggu = $range['min'];
            $max_minggu = $range['max'];
            $calendar_month = ($semester == 1) ? ($bulan + 6) : $bulan;
            $month_condition = "MONTH(tanggal) = $calendar_month";
        }

        $year = date('Y');

        $catatan_agama = [];
        $catatan_jati_diri = [];
        $catatan_literasi_steam = [];

        // 1. Ambil dari penilaian_checklist (sesuai rentang minggu)
        $checklist_sql = "SELECT id_aspek, catatan 
                          FROM penilaian 
                          WHERE id_anak = $id_anak 
                            AND semester = $semester 
                            AND tipe = 'checklist'
                            AND minggu_ke BETWEEN $min_minggu AND $max_minggu 
                            AND catatan IS NOT NULL 
                            AND catatan != ''";
        $checklist_res = $conn->query($checklist_sql);
        if ($checklist_res) {
            while ($row = $checklist_res->fetch_assoc()) {
                $asp = (int)$row['id_aspek'];
                $text = trim($row['catatan']);
                if ($asp == 1) {
                    $catatan_agama[] = $text;
                } elseif ($asp == 3) {
                    $catatan_jati_diri[] = $text;
                } elseif ($asp == 6) {
                    $catatan_literasi_steam[] = $text;
                } else {
                    $catatan_literasi_steam[] = $text;
                }
            }
        }

        // 2. Ambil dari anekdot (sesuai kondisi bulan)
        $anekdot_sql = "SELECT peristiwa, interpretasi, aspek_perkembangan 
                        FROM penilaian 
                        WHERE id_anak = $id_anak 
                          AND tipe = 'anekdot'
                          AND $month_condition";
        $anekdot_res = $conn->query($anekdot_sql);
        if ($anekdot_res) {
            while ($row = $anekdot_res->fetch_assoc()) {
                $aspek = strtolower($row['aspek_perkembangan'] ?? '');
                $peristiwa = trim($row['peristiwa']);
                $interpretasi = trim($row['interpretasi']);
                
                $text = "Peristiwa: $peristiwa";
                if (!empty($interpretasi)) {
                    $text .= " (Analisis guru: $interpretasi)";
                }
                
                if (strpos($aspek, 'agama') !== false || strpos($aspek, 'budi') !== false || strpos($aspek, 'moral') !== false) {
                    $catatan_agama[] = $text;
                } elseif (strpos($aspek, 'jati') !== false || strpos($aspek, 'diri') !== false || strpos($aspek, 'sosial') !== false || strpos($aspek, 'emosional') !== false || strpos($aspek, 'motorik') !== false || strpos($aspek, 'fisik') !== false) {
                    $catatan_jati_diri[] = $text;
                } else {
                    $catatan_literasi_steam[] = $text;
                }
            }
        }

        // 3. Ambil dari karya_anak (sesuai kondisi bulan)
        $karya_sql = "SELECT judul, deskripsi, catatan_guru 
                      FROM penilaian 
                      WHERE id_anak = $id_anak 
                        AND tipe = 'karya'
                        AND $month_condition";
        $karya_res = $conn->query($karya_sql);
        if ($karya_res) {
            while ($row = $karya_res->fetch_assoc()) {
                $judul = trim($row['judul']);
                $desc = trim($row['deskripsi']);
                $catatan = trim($row['catatan_guru']);
                
                $text = "Membuat karya '$judul'";
                if (!empty($catatan)) {
                    $text .= ": $catatan";
                } elseif (!empty($desc)) {
                    $text .= " ($desc)";
                }
                
                $catatan_literasi_steam[] = $text;
            }
        }


            // Menghilangkan duplikasi catatan
            $catatan_agama = array_unique($catatan_agama);
            $catatan_jati_diri = array_unique($catatan_jati_diri);
            $catatan_literasi_steam = array_unique($catatan_literasi_steam);

            $draft_agama = implode(". ", $catatan_agama);
            $draft_jati_diri = implode(". ", $catatan_jati_diri);
            $draft_literasi = implode(". ", $catatan_literasi_steam);

            // Fungsi pembantu menambahkan tanda titik di akhir jika belum ada
            $add_dot = function($str) {
                $str = trim($str);
                if (empty($str)) return $str;
                $last = substr($str, -1);
                if (in_array($last, ['.', '!', '?'])) {
                    return $str;
                }
                return $str . ".";
            };

            $draft_agama = $add_dot($draft_agama);
            $draft_jati_diri = $add_dot($draft_jati_diri);
            $draft_literasi = $add_dot($draft_literasi);

            // Fallback default jika tidak ada catatan sama sekali
            if (empty($draft_agama)) {
                $draft_agama = "Anak menunjukkan perkembangan yang baik pada aspek nilai agama dan budi pekerti.";
            }
            if (empty($draft_jati_diri)) {
                $draft_jati_diri = "Anak menunjukkan perkembangan yang baik pada aspek jati diri dan kemandirian.";
            }
            if (empty($draft_literasi)) {
                $draft_literasi = "Anak menunjukkan perkembangan yang baik pada aspek dasar literasi dan STEAM.";
            }

            $guru_name = '-';
            $guru_nip = '';
            if ($real_guru_id > 0) {
                $gRes = $conn->query("SELECT name as nama, nip FROM users WHERE id = $real_guru_id LIMIT 1");
                if ($gRes && $gRes->num_rows > 0) {
                    $gRow = $gRes->fetch_assoc();
                    $guru_name = $gRow['nama'];
                    $guru_nip = $gRow['nip'];
                }
            }

            respond([
                "status" => "success",
                "data" => [
                    "id_anak" => $id_anak,
                    "bulan" => $bulan,
                    "semester" => $semester,
                    "narasi_agama" => $draft_agama,
                    "narasi_jati_diri" => $draft_jati_diri,
                    "narasi_literasi_steam" => $draft_literasi,
                    "nama_guru" => $guru_name,
                    "nip_guru" => $guru_nip,
                    "is_draft" => true
                ]
            ]);
    }

    // ── REKAP KEGIATAN ORTU: Tampilkan rekap yg sudah disimpan guru untuk ortu ─
    if ($type === 'rekap_kegiatan_ortu') {
        if (!$id_anak || !$bulan) {
            respond(["status" => "error", "message" => "id_anak dan bulan wajib diisi"]);
        }

        // Ambil rekap yang sudah disimpan guru dari rekap_penilaian_bulanan
        $sql = "SELECT 
                    rpb.id,
                    rpb.id_kegiatan,
                    rpb.status_akhir,
                    rpb.catatan_perkembangan,
                    kg.nama_kegiatan,
                    tp.id_aspek,
                    tp.nama_tujuan,
                    ap.nama_aspek
                FROM rekap_penilaian_bulanan rpb
                JOIN kegiatan_pembelajaran kg ON rpb.id_kegiatan = kg.id
                JOIN tujuan_pembelajaran tp ON kg.id_tujuan = tp.id
                JOIN aspek_penilaian ap ON tp.id_aspek = ap.id
                WHERE rpb.id_anak = $id_anak
                  AND rpb.semester = $semester
                  AND rpb.bulan = $bulan
                ORDER BY ap.nama_aspek ASC, kg.nama_kegiatan ASC";

        $result = $conn->query($sql);
        if (!$result) {
            respond(["status" => "error", "message" => $conn->error]);
        }

        $data = [];
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }

        // Group by aspek
        $grouped = [];
        foreach ($data as $item) {
            $aspekName = $item['nama_aspek'];
            if (!isset($grouped[$aspekName])) {
                $grouped[$aspekName] = [
                    'nama_aspek' => $aspekName,
                    'id_aspek' => $item['id_aspek'],
                    'kegiatan' => []
                ];
            }
            $grouped[$aspekName]['kegiatan'][] = [
                'id_kegiatan' => $item['id_kegiatan'],
                'nama_kegiatan' => $item['nama_kegiatan'],
                'nama_tujuan' => $item['nama_tujuan'],
                'status_akhir' => $item['status_akhir'],
                'catatan_perkembangan' => $item['catatan_perkembangan'] ?? ''
            ];
        }

        respond([
            "status" => "success",
            "bulan" => $bulan,
            "semester" => $semester,
            "total_kegiatan" => count($data),
            "data" => array_values($grouped)
        ]);
    }

    respond(["status" => "error", "message" => "Parameter type tidak valid. Gunakan 'view', 'rekomendasi', 'narasi_aspek', atau 'rekap_kegiatan_ortu'"]);
}

// ════════════════════════════════════════════════════════════════════════════
// POST
// ════════════════════════════════════════════════════════════════════════════
elseif ($method === 'POST') {
    $input  = json_decode(file_get_contents("php://input"), true) ?? [];
    $action = $input['action'] ?? '';


    $id_guru_user = intval($input['id_guru'] ?? 0);
    if ($id_guru_user <= 0) {
        respond(["status" => "error", "message" => "ID guru wajib diisi"]);
    }
    // Resolve users.id
    $resG = $conn->query("SELECT id FROM users WHERE id = $id_guru_user AND role = 'guru' LIMIT 1");
    $real_guru_id = ($resG && $resG->num_rows > 0) ? $id_guru_user : 0;
    if ($real_guru_id <= 0) {
        respond(["status" => "error", "message" => "Guru tidak ditemukan"]);
    }


    // ── SAVE / UPDATE NARASI ASPEK BULANAN ──────────────────────────────────
    if ($action === 'save_narasi_aspek') {
        $id_anak = intval($input['id_anak'] ?? 0);
        $bulan    = intval($input['bulan']    ?? 0);
        $semester = intval($input['semester'] ?? 1);
        $narasi_agama = trim($input['narasi_agama'] ?? '');
        $narasi_jati_diri = trim($input['narasi_jati_diri'] ?? '');
        $narasi_literasi_steam = trim($input['narasi_literasi_steam'] ?? '');
        $narasi_kokurikuler = trim($input['narasi_kokurikuler'] ?? '');

        if ($id_anak <= 0 || $bulan <= 0) {
            respond(["status" => "error", "message" => "id_anak dan bulan wajib diisi"]);
        }

        $stmt = $conn->prepare(
            "INSERT INTO rekap_aspek_bulanan
                (id_anak, id_guru, bulan, semester, narasi_agama, narasi_jati_diri, narasi_literasi_steam, narasi_kokurikuler)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
                narasi_agama = VALUES(narasi_agama),
                narasi_jati_diri = VALUES(narasi_jati_diri),
                narasi_literasi_steam = VALUES(narasi_literasi_steam),
                narasi_kokurikuler = VALUES(narasi_kokurikuler)"
        );
        
        $stmt->bind_param("iiiissss",
            $id_anak, $real_guru_id, $bulan,
            $semester, $narasi_agama, $narasi_jati_diri, $narasi_literasi_steam, $narasi_kokurikuler
        );

        if ($stmt->execute()) {
            respond(["status" => "success", "message" => "Narasi rekap bulanan berhasil disimpan"]);
        } else {
            respond(["status" => "error", "message" => $stmt->error]);
        }
    }

    // ── SAVE BATCH REKAP PENILAIAN BULANAN ──────────────────────────────────
    elseif ($action === 'save_batch' || $action === 'save') {
        $id_anak = intval($input['id_anak'] ?? 0);
        $bulan    = intval($input['bulan']    ?? 0);
        $semester = intval($input['semester'] ?? 1);
        $items    = $input['items'] ?? [];

        if ($id_anak <= 0 || $bulan <= 0) {
            respond(["status" => "error", "message" => "id_anak dan bulan wajib diisi"]);
        }

        if (!is_array($items)) {
            respond(["status" => "error", "message" => "items harus berupa array"]);
        }

        // Start transaction for consistency
        $conn->begin_transaction();
        try {
            $stmt = $conn->prepare(
                "INSERT INTO rekap_penilaian_bulanan
                    (id_anak, id_guru, id_kegiatan, bulan, semester, status_akhir, catatan_perkembangan)
                 VALUES (?, ?, ?, ?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE
                    status_akhir = VALUES(status_akhir),
                    catatan_perkembangan = VALUES(catatan_perkembangan)"
            );

            foreach ($items as $item) {
                $id_kegiatan = intval($item['id_kegiatan'] ?? 0);
                $status_akhir = trim($item['status_akhir'] ?? '');
                $catatan = isset($item['catatan_perkembangan']) ? trim($item['catatan_perkembangan']) : null;

                if ($id_kegiatan <= 0 || !in_array($status_akhir, ['TM', 'MM', 'M'])) {
                    continue; // Skip invalid entries
                }

                $stmt->bind_param("iiiiiss",
                    $id_anak, $real_guru_id, $id_kegiatan,
                    $bulan, $semester, $status_akhir, $catatan
                );
                $stmt->execute();
            }

            $conn->commit();
            respond(["status" => "success", "message" => "Rekap penilaian bulanan berhasil disimpan"]);
        } catch (Exception $e) {
            $conn->rollback();
            respond(["status" => "error", "message" => "Database error: " . $e->getMessage()]);
        }
    }

    // ── DELETE ───────────────────────────────────────────────────────────────
    elseif ($action === 'delete') {
        $id = intval($input['id'] ?? 0);
        if ($id <= 0) {
            respond(["status" => "error", "message" => "ID rekap tidak valid"]);
        }
        if ($conn->query("DELETE FROM rekap_aspek_bulanan WHERE id = $id AND id_guru = $real_guru_id")) {
            respond(["status" => "success", "message" => "Rekap bulanan berhasil dihapus"]);
        } else {
            respond(["status" => "error", "message" => $conn->error]);
        }
    }

    else {
        respond(["status" => "error", "message" => "Action tidak dikenali. Gunakan: save, save_batch, save_narasi_aspek, atau delete"]);
    }
}

else {
    respond(["status" => "error", "message" => "Method tidak didukung"], 405);
}

$conn->close();
?>
