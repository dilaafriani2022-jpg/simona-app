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

        // 2. Persiapan Bahan Mengajar (Modul Ajar besok)
        // Mock notification for now to remind teachers to prepare tomorrow's Modul Ajar
        $alerts[] = [
            "id"      => "guru_modul_ajar_besok",
            "jenis"   => "rencana_belajar",
            "level"   => "info",
            "judul"   => "Persiapan Modul Ajar Besok",
            "pesan"   => "Jangan lupa siapkan bahan ajar dan Modul Ajar untuk kegiatan besok.",
            "count"   => 1,
            "aksi"    => "Cek Rencana Belajar",
            "route"   => "rencana_belajar_screen",
        ];
    }
} elseif ($role === 'kepsek') {
    // ── KEPALA SEKOLAH NOTIFICATIONS ────────────────────────────────────

    $tanggal_hari_ini   = date('Y-m-d');
    $tujuh_hari_lalu    = date('Y-m-d', strtotime('-7 days'));

    // 1. Status penilaian per guru — berbasis aktivitas HARI INI
    $res_guru = $conn->query("
        SELECT u.name AS nama_guru, u.id AS id_guru, u.id_kelas
        FROM users u
        WHERE u.role = 'guru'
        ORDER BY u.name ASC
    ");

    if ($res_guru) {
        while ($row = $res_guru->fetch_assoc()) {
            $id_kelas  = (int)$row['id_kelas'];
            $nama_guru = $row['nama_guru'];
            $id_guru   = (int)$row['id_guru'];

            if ($id_kelas > 0) {
                // Total murid di kelas
                $s_res = $conn->query("SELECT COUNT(*) AS c FROM anak WHERE id_kelas = $id_kelas");
                $student_count = $s_res ? (int)$s_res->fetch_assoc()['c'] : 0;

                if ($student_count > 0) {
                    // Anak yang sudah dinilai HARI INI (checklist)
                    $p_today = $conn->query("
                        SELECT COUNT(DISTINCT id_anak) AS c
                        FROM penilaian
                        WHERE tipe = 'checklist'
                          AND id_guru = $id_guru
                          AND tanggal = '$tanggal_hari_ini'
                          AND id_anak IN (SELECT id FROM anak WHERE id_kelas = $id_kelas)
                    ");
                    $today_count = $p_today ? (int)$p_today->fetch_assoc()['c'] : 0;

                    // Logika notifikasi bertingkat untuk hari ini:
                    if ($today_count >= $student_count) {
                        // Semua anak sudah dinilai hari ini
                        $alerts[] = [
                            "id"    => "kepsek_guru_selesai_hari_ini_" . $id_guru,
                            "jenis" => "guru",
                            "level" => "success",
                            "judul" => "Penilaian Hari Ini Selesai",
                            "pesan" => "$nama_guru telah selesai menilai seluruh $student_count anak hari ini.",
                            "count" => 0,
                            "aksi"  => "Pantau",
                            "route" => "monitoring",
                        ];
                    } elseif ($today_count > 0) {
                        // Sedang mencatat hari ini (baru sebagian)
                        $sisa = $student_count - $today_count;
                        $alerts[] = [
                            "id"    => "kepsek_guru_aktif_hari_ini_" . $id_guru,
                            "jenis" => "guru",
                            "level" => "info",
                            "judul" => "Penilaian Sedang Berlangsung",
                            "pesan" => "$nama_guru baru selesai menilai $today_count dari $student_count anak hari ini ($sisa anak lagi menunggu).",
                            "count" => $sisa,
                            "aksi"  => "Pantau",
                            "route" => "monitoring",
                        ];
                    } else {
                        // Belum menilai sama sekali hari ini
                        $alerts[] = [
                            "id"    => "kepsek_guru_belum_nilai_hari_ini_" . $id_guru,
                            "jenis" => "guru",
                            "level" => "warning",
                            "judul" => "Belum Ada Penilaian Hari Ini",
                            "pesan" => "$nama_guru belum melakukan penilaian hari ini (0 dari $student_count anak).",
                            "count" => $student_count,
                            "aksi"  => "Pantau",
                            "route" => "monitoring",
                        ];
                    }
                }
            }
        }
    }

    // 2. Sisa hari semester — dihitung dari tabel prosem (atau fallback ke tahun_ajaran)
    $tgl_mulai = null;
    $tgl_akhir = null;

    // Ambil tahun ajaran aktif
    $res_ta_aktif = $conn->query("SELECT tahun FROM tahun_ajaran WHERE status = 'aktif' LIMIT 1");
    $ta_aktif = null;
    if ($res_ta_aktif && $row_ta = $res_ta_aktif->fetch_assoc()) {
        $ta_aktif = $row_ta['tahun'];
    }

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

    $pesan_semester = null;
    $level_semester = "info";

    if ($tgl_mulai && $tgl_akhir) {
        $today_ts = strtotime($tanggal_hari_ini);
        $mulai_ts = strtotime($tgl_mulai);
        $akhir_ts = strtotime($tgl_akhir);

        if ($today_ts < $mulai_ts) {
            // Semester belum dimulai
            $selisih = (int)floor(($mulai_ts - $today_ts) / 86400);
            $pesan_semester = "Semester " . ($semester == 1 ? "Ganjil" : "Genap") . " dimulai dalam $selisih hari lagi (" . date('d M Y', $mulai_ts) . ").";
            $level_semester = "info";
        } elseif ($today_ts > $akhir_ts) {
            // Semester sudah berakhir
            $pesan_semester = "Semester " . ($semester == 1 ? "Ganjil" : "Genap") . " telah berakhir pada " . date('d M Y', $akhir_ts) . ". Pastikan semua rekap sudah dikumpulkan.";
            $level_semester = "warning";
        } else {
            // Semester sedang berjalan
            $selisih = (int)floor(($akhir_ts - $today_ts) / 86400);
            if ($selisih == 0) {
                $pesan_semester = "Hari ini adalah hari terakhir semester " . ($semester == 1 ? "Ganjil" : "Genap") . "!";
                $level_semester = "warning";
            } elseif ($selisih <= 7) {
                $pesan_semester = "Semester " . ($semester == 1 ? "Ganjil" : "Genap") . " berakhir dalam $selisih hari lagi. Segera lengkapi rekap penilaian.";
                $level_semester = "warning";
            } else {
                $pesan_semester = "Semester " . ($semester == 1 ? "Ganjil" : "Genap") . " berakhir dalam $selisih hari lagi (" . date('d M Y', $akhir_ts) . ").";
                $level_semester = "info";
            }
        }
    }

    if (!$pesan_semester) {
        $pesan_semester = "Jadwal semester belum diatur di Program Semester (Prosem) maupun Tahun Ajaran.";
        $level_semester = "warning";
    }

    $alerts[] = [
        "id"    => "kepsek_semester_ends",
        "jenis" => "kalender",
        "level" => $level_semester,
        "judul" => "Kalender Akademik",
        "pesan" => $pesan_semester,
        "count" => 1,
        "aksi"  => "Lihat Kalender",
        "route" => "rencana_belajar",
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
