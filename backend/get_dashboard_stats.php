<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
require_once 'config.php';
require_once 'cors.php';

// ─── Helper: hitung selisih & buat label trend ─────────────────────────────
function buildTrend(int $sekarang, int $bulanLalu): array {
    $selisih = $sekarang - $bulanLalu;

    if ($selisih > 0) {
        return [
            'label'    => "+{$selisih} bulan ini",
            'positive' => true,
        ];
    } elseif ($selisih < 0) {
        return [
            'label'    => "{$selisih} bulan ini",
            'positive' => false,
        ];
    } else {
        return [
            'label'    => 'Stabil',
            'positive' => null,   // null = netral (abu-abu)
        ];
    }
}

// ─── Rentang bulan ────────────────────────────────────────────────────────
$bulanIniMulai  = date('Y-m-01');
$bulanIniAkhir  = date('Y-m-t 23:59:59');
$bulanLaluMulai = date('Y-m-01', strtotime('-1 month'));
$bulanLaluAkhir = date('Y-m-t 23:59:59', strtotime('-1 month'));

// ─── 1. ANAK ──────────────────────────────────────────────────────────────
$anak_total = (int) $conn
    ->query("SELECT COUNT(*) AS c FROM anak")
    ->fetch_assoc()['c'];

// Anak ditambahkan bulan ini
$anak_ini = (int) $conn->query("
    SELECT COUNT(*) AS c FROM anak
    WHERE created_at BETWEEN '$bulanIniMulai' AND '$bulanIniAkhir'
")->fetch_assoc()['c'];

// Anak ditambahkan bulan lalu
$anak_lalu = (int) $conn->query("
    SELECT COUNT(*) AS c FROM anak
    WHERE created_at BETWEEN '$bulanLaluMulai' AND '$bulanLaluAkhir'
")->fetch_assoc()['c'];

$trend_anak = buildTrend($anak_ini, $anak_lalu);

// Jika bulan ini & lalu sama-sama 0 (data lama tanpa created_at), beri label default
if ($anak_ini === 0 && $anak_lalu === 0) {
    $trend_anak = ['label' => 'Data tersedia', 'positive' => null];
}

// ─── 2. GURU ──────────────────────────────────────────────────────────────
$guru_total = (int) $conn->query("
    SELECT COUNT(*) AS c FROM users WHERE role = 'guru'
")->fetch_assoc()['c'];

$guru_ini = (int) $conn->query("
    SELECT COUNT(*) AS c FROM users
    WHERE role = 'guru'
      AND created_at BETWEEN '$bulanIniMulai' AND '$bulanIniAkhir'
")->fetch_assoc()['c'];

$guru_lalu = (int) $conn->query("
    SELECT COUNT(*) AS c FROM users
    WHERE role = 'guru'
      AND created_at BETWEEN '$bulanLaluMulai' AND '$bulanLaluAkhir'
")->fetch_assoc()['c'];

$trend_guru = buildTrend($guru_ini, $guru_lalu);

// Guru stabil & semua aktif → label khusus
if ($trend_guru['label'] === 'Stabil' && $guru_total > 0) {
    $trend_guru = ['label' => 'Aktif semua', 'positive' => true];
}

// ─── 3. ORANG TUA ─────────────────────────────────────────────────────────
$ortu_total = (int) $conn->query("
    SELECT COUNT(*) AS c FROM users WHERE role = 'orang_tua'
")->fetch_assoc()['c'];

$ortu_ini = (int) $conn->query("
    SELECT COUNT(*) AS c FROM users
    WHERE role = 'orang_tua'
      AND created_at BETWEEN '$bulanIniMulai' AND '$bulanIniAkhir'
")->fetch_assoc()['c'];

$ortu_lalu = (int) $conn->query("
    SELECT COUNT(*) AS c FROM users
    WHERE role = 'orang_tua'
      AND created_at BETWEEN '$bulanLaluMulai' AND '$bulanLaluAkhir'
")->fetch_assoc()['c'];

$trend_ortu = buildTrend($ortu_ini, $ortu_lalu);

// ─── 4. ASPEK PENILAIAN ───────────────────────────────────────────────────
$aspek_total = (int) $conn->query("
    SELECT COUNT(*) AS c FROM aspek_penilaian
")->fetch_assoc()['c'];

// Aspek baru bulan ini (aspek_penilaian tidak punya created_at di schema
// asli — tambahkan via ALTER di bawah, atau gunakan fallback COUNT saja)
$aspek_ini_row = $conn->query("
    SELECT COUNT(*) AS c FROM aspek_penilaian
    WHERE created_at BETWEEN '$bulanIniMulai' AND '$bulanIniAkhir'
");

if ($aspek_ini_row) {
    $aspek_ini  = (int) $aspek_ini_row->fetch_assoc()['c'];
    $aspek_lalu = (int) $conn->query("
        SELECT COUNT(*) AS c FROM aspek_penilaian
        WHERE created_at BETWEEN '$bulanLaluMulai' AND '$bulanLaluAkhir'
    ")->fetch_assoc()['c'];
    $trend_aspek = buildTrend($aspek_ini, $aspek_lalu);
    if ($trend_aspek['label'] === 'Stabil') {
        $trend_aspek = ['label' => 'Tidak berubah', 'positive' => null];
    }
} else {
    // Fallback jika kolom created_at belum ditambahkan
    $trend_aspek = ['label' => 'Tidak berubah', 'positive' => null];
}

// ─── 5. KEPALA SEKOLAH ADDITIONAL STATS ───────────────────────────────────
$kelas_total = 0;
$kelas_res = $conn->query("SELECT COUNT(*) AS c FROM kelas");
if ($kelas_res) {
    $kelas_total = (int)$kelas_res->fetch_assoc()['c'];
}

$laporan_selesai = 0;
$lap_selesai_res = $conn->query("SELECT COUNT(*) AS c FROM rekap_aspek_bulanan WHERE bulan = 6");
if ($lap_selesai_res) {
    $laporan_selesai = (int)$lap_selesai_res->fetch_assoc()['c'];
}

$laporan_menunggu = 0;
$lap_menunggu_res = $conn->query("SELECT COUNT(*) AS c FROM rekap_aspek_bulanan WHERE bulan = 6 AND status_validasi = 'menunggu'");
if ($lap_menunggu_res) {
    $laporan_menunggu = (int)$lap_menunggu_res->fetch_assoc()['c'];
}

$laporan_disetujui = 0;
$lap_disetujui_res = $conn->query("SELECT COUNT(*) AS c FROM rekap_aspek_bulanan WHERE bulan = 6 AND status_validasi = 'disetujui'");
if ($lap_disetujui_res) {
    $laporan_disetujui = (int)$lap_disetujui_res->fetch_assoc()['c'];
}

$nama_sekolah = "TK Negeri 2 Bengkalis";
$profil_res = $conn->query("SELECT nama_sekolah FROM sekolah LIMIT 1");
if ($profil_res && $profil_res->num_rows > 0) {
    $nama_sekolah = $profil_res->fetch_assoc()['nama_sekolah'];
}

$tahun_ajaran_aktif = "-";
$ta_res = $conn->query("SELECT tahun FROM tahun_ajaran WHERE status = 'aktif' LIMIT 1");
if ($ta_res && $ta_res->num_rows > 0) {
    $tahun_ajaran_aktif = $ta_res->fetch_assoc()['tahun'];
}

$monthly_stats = [];
for ($m = 1; $m <= 6; $m++) {
    $res_m = $conn->query("SELECT COUNT(*) AS c FROM rekap_aspek_bulanan WHERE bulan = $m");
    $monthly_stats[$m] = $res_m ? (int)$res_m->fetch_assoc()['c'] : 0;
}

// ─── Response ─────────────────────────────────────────────────────────────
echo json_encode([
    "status" => "success",
    "data"   => [
        "jumlah_anak"       => $anak_total,
        "jumlah_guru"       => $guru_total,
        "jumlah_ortu"       => $ortu_total,
        "aspek_penilaian"   => $aspek_total,
        "laporan_semester"  => $anak_total,
        "jumlah_kelas"      => $kelas_total,
        "laporan_selesai"   => $laporan_selesai,
        "laporan_menunggu"  => $laporan_menunggu,
        "laporan_disetujui" => $laporan_disetujui,
        "nama_sekolah"      => $nama_sekolah,
        "tahun_ajaran_aktif"=> $tahun_ajaran_aktif,
        "monthly_stats"     => $monthly_stats,

        // Field trend baru — dibaca oleh Flutter
        "trend_anak"  => $trend_anak,
        "trend_guru"  => $trend_guru,
        "trend_ortu"  => $trend_ortu,
        "trend_aspek" => $trend_aspek,
    ],
]);

$conn->close();
?>