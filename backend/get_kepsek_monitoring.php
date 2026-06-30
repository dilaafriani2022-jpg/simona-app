<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php';
require_once 'cors.php';

$semester = isset($_GET['semester']) ? (int)$_GET['semester'] : 1;
$bulan = isset($_GET['bulan']) ? (int)$_GET['bulan'] : 6; // default to semester report month

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
                WHERE bulan = $bulan AND semester = $semester 
                  AND id_anak IN (SELECT id FROM anak WHERE id_kelas = $id_kelas)
            ");
            $completed_count = $c_res ? (int)$c_res->fetch_assoc()['c'] : 0;
        }
        
        // Hitung anak yang sudah punya minimal 1 penilaian checklist semester ini
        $anak_sudah_dinilai = 0;
        if ($id_kelas > 0) {
            $p_res = $conn->query("
                SELECT COUNT(DISTINCT id_anak) AS c
                FROM penilaian
                WHERE tipe = 'checklist' AND semester = $semester
                  AND id_anak IN (SELECT id FROM anak WHERE id_kelas = $id_kelas)
            ");
            $anak_sudah_dinilai = $p_res ? (int)$p_res->fetch_assoc()['c'] : 0;
        }
        
        // Cek apakah guru sudah melapor siap raport
        $raport_siap = false;
        $laporan_catatan = '';
        $laporan_waktu = '';
        $l_res = $conn->query("
            SELECT catatan, created_at FROM laporan_raport_siap
            WHERE id_guru = $id_guru AND semester = $semester AND status = 'siap'
            ORDER BY created_at DESC LIMIT 1
        ");
        if ($l_res && $l_res->num_rows > 0) {
            $l_row = $l_res->fetch_assoc();
            $raport_siap = true;
            $laporan_catatan = $l_row['catatan'] ?? '';
            $laporan_waktu = $l_row['created_at'] ?? '';
        }
        
        // Hitung persentase progress
        $progress = $student_count > 0 ? round(($anak_sudah_dinilai / $student_count) * 100) : 0;
        $status = $raport_siap ? "Siap Raport" : ($progress >= 100 ? "Selesai" : "Belum");
        
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
        
        // Cari rating perkembangan terakhir dari penilaian_checklist
        $r_res = $conn->query("
            SELECT status FROM penilaian 
            WHERE id_anak = $anak_id AND tipe = 'checklist'
            ORDER BY id DESC LIMIT 1
        ");
        $db_status = $r_res && $r_res->num_rows > 0 ? $r_res->fetch_assoc()['status'] : '';
        $rating = mapRating($db_status);
        
        // Jika anak belum pernah dinilai, tampilkan tanda '-' saja (tidak ada fallback dummy)
        // $rating sudah bernilai '-' dari mapRating jika tidak ada status
        
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

// 3. STATISTIK PERKEMBANGAN ASPEK
$aspek_stats = [];
// Aspek 1: Agama & Budi Pekerti
$res_agama = $conn->query("
    SELECT COUNT(*) AS c FROM penilaian pc
    JOIN kegiatan_pembelajaran kg ON pc.id_kegiatan = kg.id
    JOIN tujuan_pembelajaran tp ON kg.id_tujuan = tp.id
    WHERE tp.id_aspek = 1 AND pc.tipe = 'checklist' AND pc.status IN ('M', 'BSH', 'BSB')
");
$c_agama = $res_agama ? (int)$res_agama->fetch_assoc()['c'] : 0;

// Aspek 2 & 5: Jati Diri
$res_jati = $conn->query("
    SELECT COUNT(*) AS c FROM penilaian pc
    JOIN kegiatan_pembelajaran kg ON pc.id_kegiatan = kg.id
    JOIN tujuan_pembelajaran tp ON kg.id_tujuan = tp.id
    WHERE tp.id_aspek IN (2, 5) AND pc.tipe = 'checklist' AND pc.status IN ('M', 'BSH', 'BSB')
");
$c_jati = $res_jati ? (int)$res_jati->fetch_assoc()['c'] : 0;

// Aspek 3, 4, 6: Dasar Literasi & STEAM
$res_steam = $conn->query("
    SELECT COUNT(*) AS c FROM penilaian pc
    JOIN kegiatan_pembelajaran kg ON pc.id_kegiatan = kg.id
    JOIN tujuan_pembelajaran tp ON kg.id_tujuan = tp.id
    WHERE tp.id_aspek IN (3, 4, 6) AND pc.tipe = 'checklist' AND pc.status IN ('M', 'BSH', 'BSB')
");
$c_steam = $res_steam ? (int)$res_steam->fetch_assoc()['c'] : 0;

// Tidak ada fallback dummy — tampilkan data asli dari database

$aspek_stats = [
    "agama" => $c_agama,
    "jati_diri" => $c_jati,
    "steam" => $c_steam,
    "total" => $c_agama + $c_jati + $c_steam
];

// 4. STATISTIK ABSENSI SEMESTER
$res_hadir = $conn->query("SELECT COUNT(*) AS c FROM absensi WHERE status = 'Hadir'");
$c_hadir = $res_hadir ? (int)$res_hadir->fetch_assoc()['c'] : 0;

$res_sakit = $conn->query("SELECT COUNT(*) AS c FROM absensi WHERE status = 'Sakit'");
$c_sakit = $res_sakit ? (int)$res_sakit->fetch_assoc()['c'] : 0;

$res_izin = $conn->query("SELECT COUNT(*) AS c FROM absensi WHERE status = 'Izin'");
$c_izin = $res_izin ? (int)$res_izin->fetch_assoc()['c'] : 0;

$res_alpa = $conn->query("SELECT COUNT(*) AS c FROM absensi WHERE status = 'Alpa'");
$c_alpa = $res_alpa ? (int)$res_alpa->fetch_assoc()['c'] : 0;

// Tidak ada fallback dummy — tampilkan data asli dari database

$absensi_stats = [
    "hadir" => $c_hadir,
    "sakit" => $c_sakit,
    "izin" => $c_izin,
    "alpa" => $c_alpa
];

echo json_encode([
    "status" => "success",
    "data" => [
        "guru_monitoring" => $guru_list,
        "anak_monitoring" => $anak_list,
        "aspek_stats" => $aspek_stats,
        "absensi_stats" => $absensi_stats
    ]
]);

$conn->close();
?>
