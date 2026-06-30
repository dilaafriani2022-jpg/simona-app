<?php
require_once 'cors.php';
header("Content-Type: application/json");
require_once 'config.php';

$alerts = [];
$role = $_GET['role'] ?? 'admin';
$id_guru = isset($_GET['id_guru']) ? (int)$_GET['id_guru'] : null;
$id_kelas = isset($_GET['id_kelas']) ? (int)$_GET['id_kelas'] : null;
$semester = isset($_GET['semester']) ? (int)$_GET['semester'] : 1;

if ($role === 'guru') {
    // ── GURU NOTIFICATIONS ──────────────────────────────────────────────
    if ($id_kelas) {
        // 1. Cek Absensi Hari Ini
        $tanggal_hari_ini = date('Y-m-d');
        
        // Total anak di kelas
        $res_anak = $conn->query("SELECT COUNT(*) AS total FROM anak WHERE id_kelas = $id_kelas");
        $total_anak = (int)($res_anak ? $res_anak->fetch_assoc()['total'] : 0);
        
        // Anak yang sudah diabsen hari ini
        $res_absen = $conn->query("SELECT COUNT(*) AS total FROM absensi WHERE tanggal = '$tanggal_hari_ini' AND id_anak IN (SELECT id FROM anak WHERE id_kelas = $id_kelas)");
        $total_absen = (int)($res_absen ? $res_absen->fetch_assoc()['total'] : 0);
        
        $belum_absen = $total_anak - $total_absen;
        
        if ($belum_absen > 0) {
            $alerts[] = [
                "id"      => "guru_absensi_belum",
                "jenis"   => "absensi",
                "level"   => "warning",
                "judul"   => "Absensi Belum Lengkap",
                "pesan"   => "Ada {$belum_absen} anak yang belum dicatat kehadirannya hari ini.",
                "count"   => $belum_absen,
                "aksi"    => "Isi Absensi",
                "route"   => "manage_absensi",
            ];
        }

        // 2. Persiapan Bahan Mengajar (RPPH besok)
        // Mock notification for now to remind teachers to prepare tomorrow's RPPH
        $alerts[] = [
            "id"      => "guru_rpph_besok",
            "jenis"   => "jadwal",
            "level"   => "info",
            "judul"   => "Persiapan RPPH Besok",
            "pesan"   => "Jangan lupa siapkan bahan ajar dan RPPH untuk kegiatan besok.",
            "count"   => 1,
            "aksi"    => "Cek Jadwal",
            "route"   => "jadwal_screen",
        ];
    }
} elseif ($role === 'kepsek') {
    // ── KEPALA SEKOLAH NOTIFICATIONS ────────────────────────────────────
    // 1. Cek guru belum mengisi / telah menyelesaikan penilaian
    $res_guru = $conn->query("
        SELECT u.name AS nama_guru, u.id AS id_guru, u.id_kelas
        FROM users u
        WHERE u.role = 'guru'
        ORDER BY u.name ASC
    ");
    
    if ($res_guru) {
        while ($row = $res_guru->fetch_assoc()) {
            $id_kelas = (int)$row['id_kelas'];
            $nama_guru = $row['nama_guru'];
            
            if ($id_kelas > 0) {
                // Hitung total murid
                $s_res = $conn->query("SELECT COUNT(*) AS c FROM anak WHERE id_kelas = $id_kelas");
                $student_count = $s_res ? (int)$s_res->fetch_assoc()['c'] : 0;
                
                if ($student_count > 0) {
                    // Hitung anak yang sudah punya minimal 1 penilaian checklist semester ini
                    $p_res = $conn->query("
                        SELECT COUNT(DISTINCT id_anak) AS c
                        FROM penilaian
                        WHERE tipe = 'checklist' AND semester = $semester
                          AND id_anak IN (SELECT id FROM anak WHERE id_kelas = $id_kelas)
                    ");
                    $completed_count = $p_res ? (int)$p_res->fetch_assoc()['c'] : 0;

                    // Cek apakah guru sudah melapor siap raport
                    $l_res = $conn->query("
                        SELECT catatan, created_at FROM laporan_raport_siap
                        WHERE id_guru = {$row['id_guru']} AND semester = $semester AND status = 'siap'
                        LIMIT 1
                    ");
                    $raport_siap = $l_res && $l_res->num_rows > 0;
                    
                    if ($raport_siap) {
                        $alerts[] = [
                            "id"      => "kepsek_guru_siap_raport_" . $row['id_guru'],
                            "jenis"   => "guru",
                            "level"   => "success",
                            "judul"   => "Rapor Siap Cetak",
                            "pesan"   => "$nama_guru telah melapor: $student_count anak siap cetak rapor.",
                            "count"   => 0,
                            "aksi"    => "Pantau",
                            "route"   => "monitoring",
                        ];
                    } else if ($completed_count < $student_count) {
                        $alerts[] = [
                            "id"      => "kepsek_guru_belum_nilai_" . $row['id_guru'],
                            "jenis"   => "guru",
                            "level"   => "warning",
                            "judul"   => "Penilaian Belum Lengkap",
                            "pesan"   => "$nama_guru belum selesai menilai (baru $completed_count dari $student_count anak).",
                            "count"   => $student_count - $completed_count,
                            "aksi"    => "Pantau",
                            "route"   => "monitoring",
                        ];
                    } else {
                        $alerts[] = [
                            "id"      => "kepsek_guru_sudah_nilai_" . $row['id_guru'],
                            "jenis"   => "guru",
                            "level"   => "success", // Level success untuk selesai menilai
                            "judul"   => "Penilaian Selesai",
                            "pesan"   => "$nama_guru telah selesai menilai seluruh anak (checklist).",
                            "count"   => 0,
                            "aksi"    => "Pantau",
                            "route"   => "monitoring",
                        ];
                    }
                }
            }
        }
    }
    
    // 2. Semester berakhir 5 hari lagi
    $alerts[] = [
        "id"      => "kepsek_semester_ends",
        "jenis"   => "jadwal",
        "level"   => "info",
        "judul"   => "Kalender Akademik",
        "pesan"   => "Semester berakhir 5 hari lagi.",
        "count"   => 1,
        "aksi"    => "Cek Kalender",
        "route"   => "jadwal",
    ];
} else {
    // ── ADMIN / OPERATOR NOTIFICATIONS ─────────────────────────────────
    // 1. Anak belum terhubung ke orang tua
    $res = $conn->query("SELECT COUNT(*) AS c FROM anak WHERE id_ortu IS NULL");
    $count_no_ortu = (int)($res ? $res->fetch_assoc()['c'] : 0);
    if ($count_no_ortu > 0) {
        $alerts[] = [
            "id"      => "anak_no_ortu",
            "jenis"   => "anak",
            "level"   => "warning",
            "judul"   => "Anak belum terhubung",
            "pesan"   => "{$count_no_ortu} anak belum dihubungkan ke akun orang tua",
            "count"   => $count_no_ortu,
            "aksi"    => "Hubungkan",
            "route"   => "manage_ortu",
        ];
    }

    // 2. Anak belum masuk kelas
    $res2 = $conn->query("SELECT COUNT(*) AS c FROM anak WHERE id_kelas IS NULL");
    $count_no_kelas = (int)($res2 ? $res2->fetch_assoc()['c'] : 0);
    if ($count_no_kelas > 0) {
        $alerts[] = [
            "id"      => "anak_no_kelas",
            "jenis"   => "anak",
            "level"   => "warning",
            "judul"   => "Anak belum ada kelas",
            "pesan"   => "{$count_no_kelas} anak belum masuk ke kelas mana pun",
            "count"   => $count_no_kelas,
            "aksi"    => "Atur kelas",
            "route"   => "manage_anak",
        ];
    }

    // 3. Guru belum ditetapkan kelas
    $res3 = $conn->query("SELECT COUNT(*) AS c FROM users WHERE role = 'guru' AND (id_kelas IS NULL OR id_kelas = 0)");
    $count_guru_no_kelas = (int)($res3 ? $res3->fetch_assoc()['c'] : 0);
    if ($count_guru_no_kelas > 0) {
        $alerts[] = [
            "id"      => "guru_no_kelas",
            "jenis"   => "guru",
            "level"   => "warning",
            "judul"   => "Guru belum ada kelas",
            "pesan"   => "{$count_guru_no_kelas} guru belum ditetapkan kelas",
            "count"   => $count_guru_no_kelas,
            "aksi"    => "Tetapkan",
            "route"   => "manage_guru",
        ];
    }
}

echo json_encode([
    "status"       => "success",
    "total_alerts" => count($alerts),
    "data"         => $alerts,
]);

$conn->close();
?>
