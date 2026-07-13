<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php';
require_once 'cors.php';

$semester = isset($_GET['semester']) ? (int)$_GET['semester'] : 1;
$bulan_report = ($semester == 1) ? 12 : 6;
$bulan_filter_val = isset($_GET['bulan']) ? (int)$_GET['bulan'] : 0; // 0 = Semua Bulan
$id_kelas_filter = isset($_GET['id_kelas']) ? (int)$_GET['id_kelas'] : 0; // 0 = Semua Kelas

// Ambil tahun ajaran aktif
$res_ta_aktif = $conn->query("SELECT id, tahun FROM tahun_ajaran WHERE status = 'aktif' LIMIT 1");
$ta_id = 0;
$ta_aktif = '';
if ($res_ta_aktif && $row_ta = $res_ta_aktif->fetch_assoc()) {
    $ta_id = (int)$row_ta['id'];
    $ta_aktif = $row_ta['tahun'];
}

$tgl_mulai = null;
$tgl_akhir = null;

if ($ta_aktif) {
    // Query min(tanggal_mulai) dan max(tanggal_selesai) dari prosem
    $res_prosem = $conn->query("
        SELECT MIN(tanggal_mulai) AS tgl_mulai, MAX(tanggal_selesai) AS tgl_selesai
        FROM prosem
        WHERE tahun_ajaran = '" . $conn->real_escape_string($ta_aktif) . "'
          AND semester = $semester
    ");
    if ($res_prosem && $row_ps = $res_prosem->fetch_assoc()) {
        $tgl_mulai = $row_ps['tgl_mulai'];
        $tgl_akhir = $row_ps['tgl_selesai'];
    }
}

// Fallback ke tabel tahun_ajaran jika prosem belum memiliki rentang tanggal
if (!$tgl_mulai || !$tgl_akhir) {
    $kolom_mulai = ($semester == 1) ? 'tanggal_mulai_semester_1' : 'tanggal_mulai_semester_2';
    $kolom_akhir = ($semester == 1) ? 'tanggal_akhir_semester_1' : 'tanggal_akhir_semester_2';
    $res_ta = $conn->query("
        SELECT $kolom_mulai AS tanggal_mulai, $kolom_akhir AS tanggal_akhir
        FROM tahun_ajaran
        WHERE status = 'aktif'
        LIMIT 1
    ");
    if ($res_ta && $row_ta = $res_ta->fetch_assoc()) {
        $tgl_mulai = $row_ta['tanggal_mulai'];
        $tgl_akhir = $row_ta['tanggal_akhir'];
    }
}

if (!$tgl_mulai) $tgl_mulai = '1970-01-01';
if (!$tgl_akhir) $tgl_akhir = '2099-12-31';

// Helper mapping rating
function mapRating($status) {
    if (in_array($status, ['TM', 'MM', 'M'])) {
        return $status;
    }
    return match($status) {
        'BB' => 'TM',
        'MB' => 'MM',
        'BSH' => 'M',
        'BSB' => 'M',
        default => '-'
    };
}

$data = [];

// 1. MONITORING GURU & PENILAIAN
$guru_list = [];
$res_guru = $conn->query("
    SELECT u.id AS id_user, u.name AS nama_guru, u.id AS id_guru, u.id_kelas, k.nama_kelas
    FROM users u
    LEFT JOIN kelas k ON u.id_kelas = k.id
    WHERE u.role = 'guru'
    ORDER BY u.name ASC
");

if ($res_guru) {
    while ($row = $res_guru->fetch_assoc()) {
        $id_kelas = (int)$row['id_kelas'];
        $id_guru = (int)$row['id_guru'];
        
        // Hitung jumlah murid di kelas tersebut
        $student_count = 0;
        if ($id_kelas > 0) {
            $s_res = $conn->query("SELECT COUNT(*) AS c FROM anak WHERE id_kelas = $id_kelas");
            $student_count = $s_res ? (int)$s_res->fetch_assoc()['c'] : 0;
        }
        
        // Hitung rapor selesai (bulan 6 / semester report)
        $completed_count = 0;
        if ($id_kelas > 0) {
            $c_res = $conn->query("
                SELECT COUNT(*) AS c 
                FROM rekap_aspek_bulanan 
                WHERE bulan = $bulan_report AND semester = $semester 
                  AND id_anak IN (SELECT id FROM anak WHERE id_kelas = $id_kelas)
            ");
            $completed_count = $c_res ? (int)$c_res->fetch_assoc()['c'] : 0;
        }
        
        // Hitung anak yang sudah punya minimal 1 penilaian checklist hari ini
        $anak_sudah_dinilai = 0;
        if ($id_kelas > 0) {
            $today = date('Y-m-d');
            $p_res = $conn->query("
                SELECT COUNT(DISTINCT id_anak) AS c
                FROM penilaian
                WHERE tipe = 'checklist' AND tanggal = '$today'
                  AND id_anak IN (SELECT id FROM anak WHERE id_kelas = $id_kelas)
            ");
            $anak_sudah_dinilai = $p_res ? (int)$p_res->fetch_assoc()['c'] : 0;
        }
        
        // Hitung persentase progress
        $progress = $student_count > 0 ? round(($anak_sudah_dinilai / $student_count) * 100) : 0;
        
        // Rapor siap otomatis jika seluruh siswa sudah dinilai (progress >= 100%)
        $raport_siap = ($progress >= 100 && $student_count > 0);
        $status = $raport_siap ? "Siap Rapor" : "Belum";
        $laporan_catatan = '';
        $laporan_waktu = '';
        
        $guru_list[] = [
            "id_kelas" => $id_kelas,
            "id_guru" => $id_guru,
            "nama_guru" => $row['nama_guru'],
            "nama_kelas" => $row['nama_kelas'] ?? '-',
            "student_count" => $student_count,
            "completed_count" => $completed_count,
            "anak_sudah_dinilai" => $anak_sudah_dinilai,
            "progress_percent" => $progress,
            "status" => $status,
            "raport_siap" => $raport_siap,
            "laporan_catatan" => $laporan_catatan,
            "laporan_waktu" => $laporan_waktu,
        ];
    }
}

// 2. MONITORING ANAK
$anak_list = [];
$res_anak = $conn->query("
    SELECT a.id, a.nama_anak, a.nisn, k.nama_kelas, a.id_kelas, g.id AS id_guru
    FROM anak a
    LEFT JOIN kelas k ON a.id_kelas = k.id
    LEFT JOIN users g ON k.id = g.id_kelas AND g.role = 'guru'
    ORDER BY k.nama_kelas ASC, a.nama_anak ASC
");

if ($res_anak) {
    while ($row = $res_anak->fetch_assoc()) {
        $anak_id = (int)$row['id'];
        
        // Cari rating perkembangan terakhir dari penilaian_checklist semester ini
        $r_res = $conn->query("
            SELECT status FROM penilaian 
            WHERE id_anak = $anak_id AND tipe = 'checklist' AND semester = $semester
            ORDER BY id DESC LIMIT 1
        ");
        $db_status = $r_res && $r_res->num_rows > 0 ? $r_res->fetch_assoc()['status'] : '';
        $rating = mapRating($db_status);
        
        $anak_list[] = [
            "id" => $anak_id,
            "id_kelas" => (int)$row['id_kelas'],
            "id_guru" => $row['id_guru'] ? (int)$row['id_guru'] : null,
            "nama_anak" => $row['nama_anak'],
            "nisn" => $row['nisn'] ?? '-',
            "nama_kelas" => $row['nama_kelas'] ?? 'Belum ada kelas',
            "rating" => $rating
        ];
    }
}

// Helper to get TM, MM, M counts for a list of aspects, month filter, and class filter
function getRatingCounts($conn, $aspek_ids, $semester, $bulan_filter_val, $id_kelas_filter) {
    $aspek_str = implode(',', $aspek_ids);
    $bulan_filter = "";
    if ($bulan_filter_val > 0) {
        $bulan_filter = " AND MONTH(pc.tanggal) = $bulan_filter_val ";
    }
    
    $kelas_filter = "";
    if ($id_kelas_filter > 0) {
        $kelas_filter = " AND pc.id_anak IN (SELECT id FROM anak WHERE id_kelas = $id_kelas_filter) ";
    }
    
    $sql = "
        SELECT pc.status, COUNT(*) AS c 
        FROM penilaian pc
        JOIN kegiatan_pembelajaran kg ON pc.id_kegiatan = kg.id
        JOIN tujuan_pembelajaran tp ON kg.id_tujuan = tp.id
        WHERE tp.id_aspek IN ($aspek_str) 
          AND pc.tipe = 'checklist' 
          AND pc.semester = $semester
          $bulan_filter
          $kelas_filter
        GROUP BY pc.status
    ";
    
    $res = $conn->query($sql);
    $counts = ["TM" => 0, "MM" => 0, "M" => 0];
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            $status = $row['status'];
            $count = (int)$row['c'];
            
            if ($status === 'TM' || $status === 'BB') {
                $counts['TM'] += $count;
            } elseif ($status === 'MM' || $status === 'MB') {
                $counts['MM'] += $count;
            } elseif ($status === 'M' || $status === 'BSH' || $status === 'BSB') {
                $counts['M'] += $count;
            }
        }
    }
    return $counts;
}

// 3. STATISTIK PERKEMBANGAN ASPEK
$aspek_stats = [
    "agama" => getRatingCounts($conn, [1], $semester, $bulan_filter_val, $id_kelas_filter),
    "jati_diri" => getRatingCounts($conn, [2, 5], $semester, $bulan_filter_val, $id_kelas_filter),
    "steam" => getRatingCounts($conn, [3, 4, 6], $semester, $bulan_filter_val, $id_kelas_filter)
];

// 4. STATISTIK ABSENSI SEMESTER
$absensi_bulan_filter = "";
if ($bulan_filter_val > 0) {
    $absensi_bulan_filter = " AND MONTH(ab.tanggal) = $bulan_filter_val ";
} else {
    $absensi_bulan_filter = " AND ab.tanggal BETWEEN '$tgl_mulai' AND '$tgl_akhir' ";
}

$absensi_kelas_filter = "";
if ($id_kelas_filter > 0) {
    $absensi_kelas_filter = " AND ab.id_anak IN (SELECT id FROM anak WHERE id_kelas = $id_kelas_filter) ";
}

$res_hadir = $conn->query("SELECT COUNT(*) AS c FROM absensi ab WHERE ab.status = 'Hadir' $absensi_bulan_filter $absensi_kelas_filter");
$c_hadir = $res_hadir ? (int)$res_hadir->fetch_assoc()['c'] : 0;

$res_sakit = $conn->query("SELECT COUNT(*) AS c FROM absensi ab WHERE ab.status = 'Sakit' $absensi_bulan_filter $absensi_kelas_filter");
$c_sakit = $res_sakit ? (int)$res_sakit->fetch_assoc()['c'] : 0;

$res_izin = $conn->query("SELECT COUNT(*) AS c FROM absensi ab WHERE ab.status = 'Izin' $absensi_bulan_filter $absensi_kelas_filter");
$c_izin = $res_izin ? (int)$res_izin->fetch_assoc()['c'] : 0;

$res_alpa = $conn->query("SELECT COUNT(*) AS c FROM absensi ab WHERE ab.status = 'Alpa' $absensi_bulan_filter $absensi_kelas_filter");
$c_alpa = $res_alpa ? (int)$res_alpa->fetch_assoc()['c'] : 0;

$absensi_stats = [
    "hadir" => $c_hadir,
    "sakit" => $c_sakit,
    "izin" => $c_izin,
    "alpa" => $c_alpa
];

// Ambil list kelas untuk filter di UI Kepsek
$res_kelas = $conn->query("SELECT id, nama_kelas FROM kelas ORDER BY nama_kelas ASC");
$kelas_list = [];
if ($res_kelas) {
    while ($row = $res_kelas->fetch_assoc()) {
        $kelas_list[] = [
            "id" => (int)$row['id'],
            "nama_kelas" => $row['nama_kelas']
        ];
    }
}

echo json_encode([
    "status" => "success",
    "data" => [
        "guru_monitoring" => $guru_list,
        "anak_monitoring" => $anak_list,
        "aspek_stats" => $aspek_stats,
        "absensi_stats" => $absensi_stats,
        "kelas_list" => $kelas_list
    ]
]);

$conn->close();
?>
