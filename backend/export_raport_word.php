<?php
require_once 'config.php';
require_once 'cors.php';

// Menyetujui request GET saja
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Method not allowed"]);
    exit;
}

$id_anak  = isset($_GET['id_anak']) ? intval($_GET['id_anak']) : null;
$semester = isset($_GET['semester']) ? intval($_GET['semester']) : 1;

if (!$id_anak) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "ID Anak harus disediakan"]);
    exit;
}

// 1. FETCH DATA SEKOLAH
$sekolah = [];
$res_sekolah = $conn->query("SELECT * FROM sekolah LIMIT 1");
if ($res_sekolah && $res_sekolah->num_rows > 0) {
    $sekolah = $res_sekolah->fetch_assoc();
} else {
    // Fallback data sekolah jika belum terisi
    $sekolah = [
        "nama_sekolah" => "TK NEGERI 2 BENGKALIS",
        "npsn" => "10497150",
        "nstk" => "002090201009",
        "alamat" => "JL.AWANG MAHMUDA",
        "kelurahan" => "SUNGAI ALAM",
        "kecamatan" => "BENGKALIS",
        "kabupaten" => "BENGKALIS",
        "provinsi" => "RIAU",
        "kode_pos" => "28751",
        "kepala_sekolah" => "H. Ahmad, M.Pd",
        "nip_kepala_sekolah" => ""
    ];
}

// Convert logo to Base64 to embed it natively in Word HTML
$logo_base64 = '';
$logo_path = __DIR__ . '/../assets/logo.png';
if (file_exists($logo_path)) {
    $logo_data = @file_get_contents($logo_path);
    if ($logo_data !== false) {
        $logo_base64 = 'data:image/png;base64,' . base64_encode($logo_data);
    }
}

// 2. FETCH DATA ANAK & KELAS
$anak = [];
$stmt_anak = $conn->prepare("
    SELECT a.*, k.nama_kelas, o.ayah_nama, o.ibu_nama, o.ayah_pekerjaan, o.ibu_pekerjaan, 
           o.no_hp as no_hp_ortu, o.rt_rw, o.kelurahan, o.kecamatan, o.kota, o.provinsi, o.kode_pos
    FROM anak a
    LEFT JOIN kelas k ON a.id_kelas = k.id
    LEFT JOIN users o ON a.id_ortu = o.id
    WHERE a.id = ?
    LIMIT 1
");
$stmt_anak->bind_param("i", $id_anak);
$stmt_anak->execute();
$res_anak = $stmt_anak->get_result();
if ($res_anak && $res_anak->num_rows > 0) {
    $anak = $res_anak->fetch_assoc();
} else {
    http_response_code(404);
    echo json_encode(["status" => "error", "message" => "Anak tidak ditemukan"]);
    exit;
}
$stmt_anak->close();

// Helper untuk membersihkan text dari karakter aneh
function cleanText($text) {
    if ($text === null) return '';
    $bad_chars = [
        "\xe2\x80\x9c", // left double quote
        "\xe2\x80\x9d", // right double quote
        "\xe2\x80\x98", // left single quote
        "\xe2\x80\x99", // right single quote
        "\xe2\x80\x93", // en dash
        "\xe2\x80\x94", // em dash
        "\xe2\x80\xa6", // ellipsis
        "\xc2\x96",
        "\xc2\x97",
        "\xc2\x91",
        "\xc2\x92",
        "\xc2\x93",
        "\xc2\x94",
        "\xc2\x95"
    ];
    $good_chars = [
        '"', '"', "'", "'", '-', '-', '...', '-', '-', "'", "'", '"', '"', '-'
    ];
    $text = str_replace($bad_chars, $good_chars, $text);
    return htmlspecialchars($text, ENT_QUOTES, 'UTF-8');
}

$nama_anak_clean = cleanText($anak['nama_anak']);

// Cek apakah siswa Kelompok B dan Semester 2
$nama_kelas = $anak['nama_kelas'] ?? '';
$is_kelompok_b = (strpos(strtolower($nama_kelas), 'kelompok b') !== false || strtolower($nama_kelas) === 'b' || strpos(strtolower($nama_kelas), ' b') !== false);
$hide_refleksi_ortu = ($is_kelompok_b && $semester == 2);

// 3. FETCH NARASI RAPOR SEMESTER (BULAN 6)
$narasi = [
    "narasi_agama" => "-",
    "narasi_jati_diri" => "-",
    "narasi_literasi_steam" => "-",
    "narasi_kokurikuler" => "",
    "nama_guru" => "-",
    "nip_guru" => ""
];

// Bulan = 6 digunakan untuk rapor semester
$stmt_narasi = $conn->prepare("
    SELECT r.*, u.name AS nama_guru, u.nip AS nip_guru
    FROM rekap_aspek_bulanan r
    LEFT JOIN users u ON r.id_guru = u.id
    WHERE r.id_anak = ? AND r.bulan = 6 AND r.semester = ?
    LIMIT 1
");
$stmt_narasi->bind_param("ii", $id_anak, $semester);
$stmt_narasi->execute();
$res_narasi = $stmt_narasi->get_result();
if ($res_narasi && $res_narasi->num_rows > 0) {
    $row_narasi = $res_narasi->fetch_assoc();
    $narasi['narasi_agama'] = $row_narasi['narasi_agama'] ?: "-";
    $narasi['narasi_jati_diri'] = $row_narasi['narasi_jati_diri'] ?: "-";
    $narasi['narasi_literasi_steam'] = $row_narasi['narasi_literasi_steam'] ?: "-";
    $narasi['narasi_kokurikuler'] = $row_narasi['narasi_kokurikuler'] ?: "";
    $narasi['nama_guru'] = $row_narasi['nama_guru'] ?: "-";
    $narasi['nip_guru'] = $row_narasi['nip_guru'] ?: "";
}
$stmt_narasi->close();

// Jika guru rapor belum ter-link di rekap_aspek_bulanan, coba ambil dari wali kelas/guru kelas
if ($narasi['nama_guru'] === "-") {
    $stmt_guru = $conn->prepare("
        SELECT u.name, u.nip 
        FROM users u 
        WHERE u.id_kelas = ? AND u.role = 'guru'
        LIMIT 1
    ");
    $stmt_guru->bind_param("i", $anak['id_kelas']);
    $stmt_guru->execute();
    $res_guru = $stmt_guru->get_result();
    if ($res_guru && $res_guru->num_rows > 0) {
        $row_g = $res_guru->fetch_assoc();
        $narasi['nama_guru'] = $row_g['name'];
        $narasi['nip_guru'] = $row_g['nip'] ?: "";
    }
    $stmt_guru->close();
}

// 4. FETCH EKSTRAKURIKULER
$ekskul_list = [];
$stmt_ekskul = $conn->prepare("
    SELECT se.*, e.nama AS nama_ekstrakurikuler
    FROM anak_ekstrakurikuler se
    JOIN ekstrakurikuler e ON se.id_ekstrakurikuler = e.id
    WHERE se.id_anak = ? AND se.semester = ?
    ORDER BY e.nama ASC
");
$stmt_ekskul->bind_param("ii", $id_anak, $semester);
$stmt_ekskul->execute();
$res_ekskul = $stmt_ekskul->get_result();
while ($row = $res_ekskul->fetch_assoc()) {
    $ekskul_list[] = $row;
}
$stmt_ekskul->close();

// 5. FETCH ASPEK PENILAIAN DESKRIPSI (HALAMAN 4)
$aspek_list = [];
$res_aspek = $conn->query("SELECT * FROM aspek_penilaian ORDER BY id ASC");
while ($row = $res_aspek->fetch_assoc()) {
    $aspek_list[] = $row;
}

// 6. FETCH REFLEKSI GURU & ORANG TUA
$refleksi_guru = [];
$stmt_rg = $conn->prepare("
    SELECT pencapaian FROM refleksi 
    WHERE tipe = 'guru' AND id_anak = ? AND semester = ?
    ORDER BY id ASC
");
$stmt_rg->bind_param("ii", $id_anak, $semester);
$stmt_rg->execute();
$res_rg = $stmt_rg->get_result();
while ($row = $res_rg->fetch_assoc()) {
    if (!empty($row['pencapaian'])) $refleksi_guru[] = $row['pencapaian'];
}
$stmt_rg->close();

$ref_guru_text = !empty($refleksi_guru) ? implode("<br><br>", $refleksi_guru) : "";
if (empty($ref_guru_text)) {
    $ref_guru_text = "Kemampuan komunikasi Ananda " . $nama_anak_clean . " sudah aktif, jelas, dan percaya diri. Ananda juga mampu memahami dan melaksanakan instruksi yang diberikan ibuk guru dengan benar dan cepat.";
}

$refleksi_ortu = [];
$stmt_ro = $conn->prepare("
    SELECT isi FROM refleksi 
    WHERE tipe = 'orang_tua' AND id_anak = ? AND semester = ?
    ORDER BY id ASC
");
$stmt_ro->bind_param("ii", $id_anak, $semester);
$stmt_ro->execute();
$res_ro = $stmt_ro->get_result();
while ($row = $res_ro->fetch_assoc()) {
    if (!empty($row['isi'])) $refleksi_ortu[] = $row['isi'];
}
$stmt_ro->close();

if (empty($refleksi_ortu)) {
    $refleksi_ortu = [
        "Saya merasa sangat puas dengan perkembangan anak saya disekolah.",
        "Anak saya bisa lebih cepat bangun dipagi hari.",
        "Saya ingin lebih terlibat dalam kegiatan sekolah anak saya.",
        "Saya berharap anak saya lebih mandiri, dan percaya diri.",
        "Anak saya sudah bisa berhitung, mengenal huruf bahkan membaca do'a.",
        "Anak saya lebih aktif dan kreatif seperti menggambar, mewarnai membuat mainan dari kertas.",
        "Anak saya semakin percaya diri dalam menyampaikan pikiran."
    ];
}

// 7. FETCH KEHADIRAN (SAKIT, IZIN, ALPA)
$bulan_list = ($semester === 1) ? [7, 8, 9, 10, 11] : [1, 2, 3, 4, 5];
$tahun_kehadiran = date('Y');

$sakit = 0;
$izin = 0;
$alpa = 0;

$bulan_in = implode(',', $bulan_list);
$sql_absensi = "
    SELECT status, COUNT(*) as jumlah 
    FROM absensi 
    WHERE id_anak = ? 
      AND MONTH(tanggal) IN ($bulan_in) 
      AND YEAR(tanggal) = ?
    GROUP BY status
";
$stmt_abs = $conn->prepare($sql_absensi);
$stmt_abs->bind_param("ii", $id_anak, $tahun_kehadiran);
$stmt_abs->execute();
$res_abs = $stmt_abs->get_result();
while ($row = $res_abs->fetch_assoc()) {
    if ($row['status'] === 'Sakit') $sakit = intval($row['jumlah']);
    if ($row['status'] === 'Izin') $izin = intval($row['jumlah']);
    if ($row['status'] === 'Alpa') $alpa = intval($row['jumlah']);
}
$stmt_abs->close();

// 8. PREPARE VARIABLE DISPLAY
$semester_label = ($semester === 1) ? "1 (SATU)" : "2 (DUA)";
$tahun_ajaran = cleanText($anak['tahun_ajaran'] ?? '2025/2026');
$clean_kelas = cleanText($anak['nama_kelas']);
$clean_kelas = trim(preg_replace('/\bkelompok\b/i', '', $clean_kelas));
$clean_kelas = "Kelompok " . $clean_kelas;

// Format tanggal lahir anak
$tgl_lahir_raw = $anak['tanggal_lahir'];
$tgl_lahir_str = $tgl_lahir_raw;
try {
    if (!empty($tgl_lahir_raw)) {
        $parsed = new DateTime($tgl_lahir_raw);
        $bulans = [
            1 => 'Januari', 2 => 'Februari', 3 => 'Maret', 4 => 'April', 5 => 'Mei', 6 => 'Juni',
            7 => 'Juli', 8 => 'Agustus', 9 => 'September', 10 => 'Oktober', 11 => 'November', 12 => 'Desember'
        ];
        $tgl_lahir_str = $parsed->format('d') . ' ' . $bulans[intval($parsed->format('m'))] . ' ' . $parsed->format('Y');
    }
} catch (Exception $e) {}

$tempat_tgl_lahir = cleanText($anak['tempat_lahir'] ?? '-') . ', ' . $tgl_lahir_str;

// Konversi Anak Ke ke Kata
function numberToWords($n) {
    $words = ['', 'Satu', 'Dua', 'Tiga', 'Empat', 'Lima', 'Enam', 'Tujuh', 'Delapan', 'Sembilan', 'Sepuluh'];
    if ($n <= 0 || $n >= count($words)) return strval($n);
    return $words[$n];
}
$anak_ke_val = intval($anak['anak_ke']);
$anak_ke_words = numberToWords($anak_ke_val);
$anak_ke_label = $anak_ke_val > 0 ? "$anak_ke_val ($anak_ke_words)" : "-";

$jenis_kelamin = ($anak['jenis_kelamin'] === 'L') ? 'Laki-laki' : 'Perempuan';

// Alamat Orang Tua
$alamat_jalan = cleanText(($anak['alamat_ortu_detail'] ?? $anak['alamat'] ?? '') ?: '-');
$alamat_telp = cleanText($anak['no_hp_ortu'] ?: '-');
$alamat_kelurahan = cleanText($anak['kelurahan'] ?: '-');
$alamat_kecamatan = strtoupper(cleanText($anak['kecamatan'] ?: '-'));
$alamat_kota = strtoupper(cleanText($anak['kota'] ?: '-'));
$alamat_provinsi = strtoupper(cleanText($anak['provinsi'] ?: '-'));

// Data Orang Tua
$ayah_nama = strtoupper(cleanText($anak['ayah_nama'] ?: '-'));
$ibu_nama = strtoupper(cleanText($anak['ibu_nama'] ?: '-'));
$ayah_pekerjaan = cleanText($anak['ayah_pekerjaan'] ?: '-');
$ibu_pekerjaan = cleanText($anak['ibu_pekerjaan'] ?: '-');

// Info Sekolah
$nama_sekolah = cleanText($sekolah['nama_sekolah']);
$full_school_name = strtoupper($nama_sekolah);
if (strpos(strtoupper($nama_sekolah), 'TK ') === 0) {
    $full_school_name = 'TAMAN KANAK-KANAK ' . substr(strtoupper($nama_sekolah), 3);
}
$npsn = cleanText($sekolah['npsn']);
$nstk = cleanText(($sekolah['nstk'] ?? '') ?: '002090201009');
$sekolah_alamat = cleanText($sekolah['alamat']);
$sekolah_kelurahan = cleanText($sekolah['kelurahan'] ?: 'SUNGAI ALAM');
$sekolah_kecamatan = cleanText($sekolah['kecamatan'] ?: 'BENGKALIS');
$sekolah_kabupaten = cleanText($sekolah['kabupaten'] ?: 'BENGKALIS');
$sekolah_provinsi = cleanText($sekolah['provinsi'] ?: 'RIAU');
$sekolah_kode_pos = cleanText($sekolah['kode_pos'] ?: '28751');
$kepala_sekolah = cleanText($sekolah['kepala_sekolah'] ?: 'H. Ahmad, M.Pd');
$nip_kepala_sekolah = cleanText($sekolah['nip_kepala_sekolah'] ?: '');

$tanggal_cetak = date('d') . ' ' . [
    1 => 'Januari', 2 => 'Februari', 3 => 'Maret', 4 => 'April', 5 => 'Mei', 6 => 'Juni',
    7 => 'Juli', 8 => 'Agustus', 9 => 'September', 10 => 'Oktober', 11 => 'November', 12 => 'Desember'
][intval(date('m'))] . ' ' . date('Y');

// 9. GENERATE WORD-COMPATIBLE HTML HEADER
header("Content-Type: application/vnd.ms-word");
header("Content-Disposition: attachment; filename=\"Rapor_{$nama_anak_clean}_Semester_{$semester}.doc\"");
header("Cache-Control: private, max-age=0, must-revalidate");
header("Pragma: public");

?>
<html xmlns:o='urn:schemas-microsoft-com:office:office' xmlns:w='urn:schemas-microsoft-com:office:word' xmlns='http://www.w3.org/TR/REC-html40'>
<head>
<meta charset="utf-8">
<title>Buku LPPA - <?php echo $nama_anak_clean; ?></title>
<!--[if gte mso 9]>
<xml>
  <w:WordDocument>
    <w:View>Print</w:View>
    <w:Zoom>100</w:Zoom>
    <w:DoNotOptimizeForBrowser/>
  </w:WordDocument>
</xml>
<![endif]-->
<style>
    @page {
        size: A4;
        margin: 2cm 1.5cm 2cm 1.5cm;
    }
    body {
        font-family: 'Times New Roman', Times, serif;
        font-size: 11pt;
        line-height: 1.5;
        color: #000000;
    }
    h1, h2, h3 {
        font-family: 'Times New Roman', Times, serif;
        text-align: center;
        margin-top: 0;
        margin-bottom: 20px;
        font-weight: bold;
    }
    h1 {
        font-size: 16pt;
    }
    h2 {
        font-size: 14pt;
    }
    h3 {
        font-size: 12pt;
    }
    .text-center {
        text-align: center;
    }
    .text-right {
        text-align: right;
    }
    .text-justify {
        text-align: justify;
    }
    .bold {
        font-weight: bold;
    }
    .italic {
        font-style: italic;
    }
    .underline {
        text-decoration: underline;
    }
    .page-break {
        page-break-after: always;
        clear: both;
    }
    table {
        border-collapse: collapse;
        width: 100%;
        margin-top: 10px;
        margin-bottom: 15px;
        font-family: 'Times New Roman', Times, serif;
        font-size: 11pt;
    }
    table.border-all th, table.border-all td {
        border: 1px solid #000000;
        padding: 8px 10px;
        vertical-align: top;
        font-family: 'Times New Roman', Times, serif;
        font-size: 11pt;
        line-height: 1.2;
    }
    table.border-none th, table.border-none td {
        border: none;
        padding: 2px 4px;
        vertical-align: top;
        font-family: 'Times New Roman', Times, serif;
        font-size: 11pt;
        line-height: 1.2;
    }
    .photo-placeholder-grid {
        width: 100%;
        margin-top: 15px;
    }
    .cover-logo-placeholder {
        text-align: center;
        margin: 0;
        padding: 0;
        line-height: 1.5;
        font-size: 11pt;
    }
    .stamp-box {
        width: 80px;
        height: 90px;
        border: 1px solid #000000;
        background-color: #ffffff;
    }
    .kehadiran-num {
        font-weight: bold;
        text-align: center;
        font-size: 11pt;
        padding: 8px;
        border: 1px solid #000000;
        font-family: 'Times New Roman', Times, serif;
    }
    .kehadiran-label {
        font-size: 10pt;
        text-align: center;
        padding: 4px;
        border: 1px solid #000000;
        font-family: 'Times New Roman', Times, serif;
    }
</style>
</head>
<body>

<!-- ----------------------------------------------------------------------------
     HALAMAN 1: COVER RAPOR
     ---------------------------------------------------------------------------- -->
<div style="font-family: 'Times New Roman', Times, serif;">
    <!-- Logo Sekolah -->
    <p style="text-align: center; margin-top: 10px; margin-bottom: 10px;">
        <?php if (!empty($logo_base64)): ?>
        <img src="<?php echo $logo_base64; ?>" width="100" height="100" style="display:inline-block;" alt="Logo Sekolah">
        <?php else: ?>
        &nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;
        <?php endif; ?>
    </p>
    
    <p class="bold text-center" style="font-size: 18pt; line-height: 1.5; margin-top: 15px; margin-bottom: 30px;">
        LAPORAN<br>
        PENILAIAN PERKEMBANGAN ANAK DIDIK<br>
        <?php echo $full_school_name; ?>
    </p>
    
    <!-- Info lembaga - plain paragraph per baris, rata kiri, bebas diedit di Word -->
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5; margin-top: 40px;">Nama Lembaga&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <?php echo strtoupper($nama_sekolah); ?></p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5;">NPSN&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <?php echo $npsn; ?></p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5;">NSTK&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <?php echo $nstk; ?></p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5;">Alamat&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <?php echo strtoupper($sekolah_alamat); ?></p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5;">Desa/Kelurahan&nbsp;&nbsp;: <?php echo strtoupper($sekolah_kelurahan); ?></p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5;">Kecamatan&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <?php echo strtoupper($sekolah_kecamatan); ?></p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5;">Kabupaten/Kota&nbsp;&nbsp;: <?php echo strtoupper($sekolah_kabupaten); ?></p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5;">Propinsi&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <?php echo strtoupper($sekolah_provinsi); ?></p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5; margin-bottom: 40px;">Kode Pos&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <?php echo $sekolah_kode_pos; ?></p>

    <!-- Nama murid & NISN - paragraph biasa rata kiri -->
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5; margin-top: 10px;">Nama Anak Didik</p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5;">&nbsp;</p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5;"><span class="bold underline"><?php echo strtoupper($nama_anak_clean); ?></span></p>
    <p style="text-align: left; margin: 0; padding: 0; font-size: 11pt; line-height: 1.5; margin-bottom: 60px;"><span class="underline" style="color: #0000ff;">NISN : <?php echo cleanText($anak['nisn'] ?: '-'); ?></span></p>

    <p class="bold text-center" style="font-size: 18pt; margin-top: 60px;">
        <?php echo $full_school_name; ?>
    </p>
</div>

<div class="page-break"></div>

<!-- ----------------------------------------------------------------------------
     HALAMAN 2: KETERANGAN ANAK DIDIK
     ---------------------------------------------------------------------------- -->
<div>
    <h2 style="font-size: 14pt; margin-bottom: 20px;">KETERANGAN ANAK DIDIK</h2>
    
    <p style="font-family: 'Times New Roman', Times, serif; font-size: 11pt; line-height: 1.5; tab-stops: 0.8cm 5.5cm; mso-tab-stops: 0.8cm 5.5cm; margin-bottom: 25px; text-align: left;">
        1.&#9;Nama Anak Didik<br>
        &#9;a. Nama Lengkap&#9;: <span class="bold underline"><?php echo $nama_anak_clean; ?></span><br>
        &#9;b. Nama Panggilan&#9;: <?php echo cleanText(($anak['nama_panggilan'] ?? '') ?: '-'); ?><br>
        2.&#9;Nomor NISN / Nomor Induk&#9;: <?php echo cleanText($anak['nisn'] ?: '-'); ?><?php echo !empty($anak['nik']) ? ' / ' . cleanText($anak['nik']) : ''; ?><br>
        3.&#9;Jenis Kelamin&#9;: <?php echo $jenis_kelamin; ?><br>
        4.&#9;Tempat, Tanggal Lahir&#9;: <?php echo $tempat_tgl_lahir; ?><br>
        5.&#9;Agama&#9;: <?php echo cleanText($anak['agama'] ?: 'Islam'); ?><br>
        6.&#9;Anak Ke&#9;: <?php echo $anak_ke_label; ?><br>
        7.&#9;Nama Orang Tua/Wali*)<br>
        &#9;a. Ayah&#9;: <?php echo $ayah_nama; ?><br>
        &#9;b. Ibu&#9;: <?php echo $ibu_nama; ?><br>
        8.&#9;Pekerjaan Orang Tua/Wali*)<br>
        &#9;a. Ayah&#9;: <?php echo $ayah_pekerjaan; ?><br>
        &#9;b. Ibu&#9;: <?php echo $ibu_pekerjaan; ?><br>
        9.&#9;Alamat Orang Tua/Wali*)<br>
        &#9;a. Jalan&#9;: <?php echo $alamat_jalan; ?><br>
        &#9;b. Telepon&#9;: <?php echo $alamat_telp; ?><br>
        &#9;c. Desa/Kelurahan&#9;: <?php echo $alamat_kelurahan; ?><br>
        &#9;d. Kecamatan&#9;: <?php echo $alamat_kecamatan; ?><br>
        &#9;e. Kabupaten/Kota&#9;: <?php echo $alamat_kota; ?><br>
        &#9;f. Propinsi&#9;: <?php echo $alamat_provinsi; ?><br>
    </p>

    <br><br>
    
    <table class="border-none" style="width: 100%;">
        <tr>
            <td style="width: 150px; text-align: left; vertical-align: top;">
                <div class="stamp-box"></div>
                <span style="font-size: 9pt; display: block; margin-top: 5px;">*) Coret yang tidak sesuai</span>
            </td>
            <td></td>
            <td style="width: 250px; text-align: center; vertical-align: top; font-size: 11pt;">
                Bengkalis, <?php echo $tanggal_cetak; ?><br>
                <span class="bold">KEPALA <?php echo strtoupper($nama_sekolah); ?></span>
                <br><br><br><br><br>
                <span class="bold underline"><?php echo $kepala_sekolah; ?></span><br>
                <?php if (!empty($nip_kepala_sekolah)): ?>
                    <span>NIP. <?php echo $nip_kepala_sekolah; ?></span>
                <?php endif; ?>
            </td>
        </tr>
    </table>
</div>

<div class="page-break"></div>

<!-- ----------------------------------------------------------------------------
     HALAMAN 3: PETUNJUK PENGGUNAAN
     ---------------------------------------------------------------------------- -->
<div>
    <h2 style="font-size: 14pt; margin-bottom: 25px;">PETUNJUK PENGGUNAAN</h2>
    
    <div style="font-family: 'Times New Roman', Times, serif; font-size: 11pt; line-height: 1.6; text-align: justify; tab-stops: 0.8cm; mso-tab-stops: 0.8cm;">
        <p style="margin-left: 0.8cm; text-indent: -0.8cm; margin-bottom: 8px;">1.&#9;Raport PAUD yang selanjutnya disebut Buku Laporan Penilaian Perkembangan Anak (LPPA) Kurikulum Merdeka PAUD dipergunakan selama Anak didik mengikuti seluruh Program Pembelajaran di Sekolah</p>
        <p style="margin-left: 0.8cm; text-indent: -0.8cm; margin-bottom: 8px;">2.&#9;Apabila Anak didik pindah sekolah, buku LPPA dibawa oleh Anak didik yang bersangkutan untuk dipergunakan di sekolah baru sebagai bukti pencapaian kompetensi dengan meninggalkan arsip di Sekolah asal;</p>
        <p style="margin-left: 0.8cm; text-indent: -0.8cm; margin-bottom: 8px;">3.&#9;Identitas Satuan PAUD dan identitas Anak didik diisi sesuai dengan data riil lembaga dan data Anak didik bersangkutan;</p>
        <p style="margin-left: 0.8cm; text-indent: -0.8cm; margin-bottom: 8px;">4.&#9;Buku Laporan Penilaian Perkembangan Anak Didik TK dilengkapi dengan Pasfhoto <span class="underline">ukuran 3</span> x 4 Cm;</p>
        <p style="margin-left: 0.8cm; text-indent: -0.8cm; margin-bottom: 8px;">5.&#9;Penilaian Perkembangan Anak Didik TK diberikan secara kualitatif dalam <span class="underline">bentuk uraian</span> (deskripsi) yang dikelompokkan dalam 2 program kegiatan belajar yaitu:</p>
        <p style="margin-left: 1.6cm; text-indent: -0.8cm; margin-bottom: 4px;">a.&#9;Pembentukan Perilaku</p>
        <p style="margin-left: 1.6cm; text-indent: -0.8cm; margin-bottom: 8px;">b.&#9;Pengembangan Kemampuan Dasar</p>
        <p style="margin-left: 0.8cm; text-indent: -0.8cm; margin-bottom: 8px;">6.&#9;Penilaian tersebut dilakukan dengan menggunakan teknik-teknik penilaian yang berlaku di TK secara <span class="underline">terus menerus</span>.</p>
    </div>
</div>

<div class="page-break"></div>

<!-- ----------------------------------------------------------------------------
     HALAMAN 4: KETERANGAN NILAI KUALITATIF CAPAIAN PEMBELAJARAN
     ---------------------------------------------------------------------------- -->
<div>
    <h2 style="margin-bottom: 5px; font-size: 14pt;">KETERANGAN NILAI KUALITATIF</h2>
    <h2 style="margin-bottom: 25px; font-size: 14pt;">CAPAIAN PEMBELAJARAN</h2>
    
    <table class="border-none" style="line-height: 1.5; font-size: 11pt;">
        <?php foreach ($aspek_list as $idx => $aspek): 
            $bullets = array_filter(array_map('trim', explode("\n", $aspek['deskripsi'])));
        ?>
            <tr>
                <td style="width: 25px; font-weight: bold; font-size: 11pt;"><?php echo ($idx + 1); ?>.</td>
                <td class="bold" style="font-size: 11pt;"><?php echo cleanText($aspek['nama_aspek']); ?></td>
            </tr>
            <tr>
                <td></td>
                <td style="padding-bottom: 10px; font-size: 11pt;">
                    <?php if (empty($bullets)): ?>
                        <span class="italic">-</span>
                    <?php else: ?>
                        <ul style="margin: 3px 0 3px 15px; padding: 0;">
                            <?php foreach ($bullets as $b): ?>
                                <li style="text-align: justify; margin-bottom: 2px; font-size: 11pt;"><?php echo cleanText($b); ?></li>
                            <?php endforeach; ?>
                        </ul>
                    <?php endif; ?>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
</div>

<div class="page-break"></div>

<!-- ----------------------------------------------------------------------------
     HALAMAN 5: IDENTITAS & NILAI AGAMA
     ---------------------------------------------------------------------------- -->
<div>
    <h2 style="font-size: 12pt; margin-bottom: 20px;">LAPORAN PENILAIAN PERKEMBANGAN ANAK</h2>
    
    <table class="border-none" style="width: 100%; font-size: 11pt;">
        <tr>
            <td style="width: 50%; vertical-align: top;">
                <table class="border-none" style="font-size: 11pt; margin: 0;">
                    <tr>
                        <td style="width: 100px; font-size: 11pt;">Nama Sekolah</td>
                        <td style="width: 8px; font-size: 11pt;">:</td>
                        <td style="font-size: 11pt;"><?php echo $nama_sekolah; ?></td>
                    </tr>
                    <tr>
                        <td class="bold" style="font-size: 11pt;">Nama Anak Didik</td>
                        <td class="bold">:</td>
                        <td class="bold" style="font-size: 11pt;"><?php echo $nama_anak_clean; ?></td>
                    </tr>
                    <tr>
                        <td style="font-size: 11pt;">Tahun Ajaran</td>
                        <td style="font-size: 11pt;">:</td>
                        <td style="font-size: 11pt;"><?php echo $tahun_ajaran; ?></td>
                    </tr>
                    <tr>
                        <td style="font-size: 11pt;">Semester</td>
                        <td style="font-size: 11pt;">:</td>
                        <td style="font-size: 11pt;"><?php echo $semester_label; ?></td>
                    </tr>
                </table>
            </td>
            <td style="width: 50%; vertical-align: top;">
                <table class="border-none" style="font-size: 11pt; margin: 0;">
                    <tr>
                        <td style="width: 100px; font-size: 11pt;">Kelompok</td>
                        <td style="width: 8px; font-size: 11pt;">:</td>
                        <td style="font-size: 11pt;"><?php echo $clean_kelas; ?></td>
                    </tr>
                    <tr>
                        <td style="font-size: 11pt;">Fase</td>
                        <td style="font-size: 11pt;">:</td>
                        <td style="font-size: 11pt;">Fondasi</td>
                    </tr>
                    <tr>
                        <td style="font-size: 11pt;">Tinggi Badan</td>
                        <td style="font-size: 11pt;">:</td>
                        <td style="font-size: 11pt;"><?php echo cleanText($anak['tinggi_badan'] ?: '-'); ?> Cm</td>
                    </tr>
                    <tr>
                        <td style="font-size: 11pt;">Berat Badan</td>
                        <td style="font-size: 11pt;">:</td>
                        <td style="font-size: 11pt;"><?php echo cleanText($anak['berat_badan'] ?: '-'); ?> Kg</td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
    
    <br>

    <!-- Aspek 1: Agama & Budi Pekerti (Menggunakan Table agar gampang di-format) -->
    <table class="border-all" style="width: 100%;">
        <tr style="background-color: #A2D149;">
            <th class="bold" style="padding: 10px; font-size: 12pt; text-align: center;">Nilai Agama dan Budi Pekerti</th>
        </tr>
        <tr>
            <td class="text-justify" style="padding: 15px; line-height: 1.5; font-size: 11pt;">
                <?php 
                    $agama_paras = array_filter(array_map('trim', explode("\n", $narasi['narasi_agama'])));
                    if (empty($agama_paras) || $narasi['narasi_agama'] === '-') {
                        echo '<span class="italic">Belum diisi.</span>';
                    } else {
                        echo implode("<br><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;", array_map('cleanText', $agama_paras));
                    }
                ?>
            </td>
        </tr>
    </table>
</div>

<div class="page-break"></div>

<!-- ----------------------------------------------------------------------------
     HALAMAN 6: JATI DIRI & STEAM
     ---------------------------------------------------------------------------- -->
<div>
    <!-- Aspek 2: Jati Diri -->
    <table class="border-all" style="width: 100%;">
        <tr style="background-color: #29B6F6;">
            <th class="bold" style="padding: 10px; font-size: 12pt; text-align: center;">Jati Diri</th>
        </tr>
        <tr>
            <td class="text-justify" style="padding: 15px; line-height: 1.5; font-size: 11pt;">
                <?php 
                    $jati_paras = array_filter(array_map('trim', explode("\n", $narasi['narasi_jati_diri'])));
                    if (empty($jati_paras) || $narasi['narasi_jati_diri'] === '-') {
                        echo '<span class="italic">Belum diisi.</span>';
                    } else {
                        echo implode("<br><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;", array_map('cleanText', $jati_paras));
                    }
                ?>
            </td>
        </tr>
    </table>
    
    <br>

    <!-- Aspek 3: Dasar Literasi & STEAM -->
    <table class="border-all" style="width: 100%;">
        <tr style="background-color: #F27B79;">
            <th class="bold" style="padding: 10px; font-size: 12pt; text-align: center;">Dasar Literasi dan STEAM</th>
        </tr>
        <tr>
            <td class="text-justify" style="padding: 15px; line-height: 1.5; font-size: 11pt;">
                <?php 
                    $steam_paras = array_filter(array_map('trim', explode("\n", $narasi['narasi_literasi_steam'])));
                    if (empty($steam_paras) || $narasi['narasi_literasi_steam'] === '-') {
                        echo '<span class="italic">Belum diisi.</span>';
                    } else {
                        echo implode("<br><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;", array_map('cleanText', $steam_paras));
                    }
                ?>
            </td>
        </tr>
    </table>
</div>

<div class="page-break"></div>

<!-- ----------------------------------------------------------------------------
     HALAMAN 7: FOTO KEGIATAN ANAK
     ---------------------------------------------------------------------------- -->
<div>
    <table class="border-all" style="width: 100%; border: 1px solid #000000;">
        <tr style="background-color: #E74C3C;">
            <th class="text-center" style="color: #ffffff; font-weight: bold; font-size: 12pt; padding: 10px;">Foto Kegiatan Anak</th>
        </tr>
        <tr>
            <td style="height: 450px; vertical-align: top; padding: 15px;">
                <p style="color: #7f8c8d; text-align: center; font-style: italic; margin-top: 180px; font-family: 'Times New Roman', Times, serif; font-size: 11pt;">[Tempel atau Sisipkan Foto Kegiatan Anak secara Bebas di Sini]</p>
            </td>
        </tr>
    </table>
</div>

<div class="page-break"></div>

<!-- ----------------------------------------------------------------------------
     HALAMAN 8: REFLEKSI & KOKURIKULER
     ---------------------------------------------------------------------------- -->
<div>
    <!-- Refleksi Guru -->
    <table class="border-all" style="width: 100%;">
        <tr style="background-color: #A2D149;">
            <th class="bold" style="padding: 10px; font-size: 12pt; text-align: center;">Refleksi Guru</th>
        </tr>
        <tr>
            <td class="text-justify" style="padding: 15px; line-height: 1.5; font-size: 11pt;">
                <?php echo cleanText($ref_guru_text); ?>
            </td>
        </tr>
    </table>
    
    <?php if (!$hide_refleksi_ortu): ?>
    <br>

    <!-- Refleksi Orang Tua -->
    <table class="border-all" style="width: 100%;">
        <tr style="background-color: #FFD966;">
            <th class="bold" style="padding: 10px; font-size: 12pt; text-align: center;">Refleksi Orang Tua</th>
        </tr>
        <tr>
            <td style="padding: 15px; line-height: 1.5; font-size: 11pt;">
                <table class="border-none" style="margin: 0; font-size: 11pt;">
                    <?php foreach ($refleksi_ortu as $idx => $r_text): ?>
                        <tr>
                            <td style="width: 20px; font-size: 11pt;" valign="top"><?php echo ($idx + 1); ?>.</td>
                            <td class="text-justify" style="font-size: 11pt;"><?php echo cleanText($r_text); ?></td>
                        </tr>
                    <?php endforeach; ?>
                </table>
            </td>
        </tr>
    </table>
    <?php endif; ?>

    <br>

    <!-- Kokurikuler -->
    <table class="border-all" style="width: 100%;">
        <tr style="background-color: #29B6F6;">
            <th class="bold" style="padding: 10px; font-size: 11pt; text-align: center;">KOKURIKULER GERAKAN 7 KEBIASAAN ANAK INDONESIA HEBAT</th>
        </tr>
        <tr>
            <td class="text-justify" style="padding: 15px; line-height: 1.5; font-size: 11pt;">
                <?php echo cleanText($narasi['narasi_kokurikuler'] ?: ''); ?>
            </td>
        </tr>
    </table>

    <br>

    <!-- Foto Kokurikuler -->
    <table class="border-all" style="width: 100%; border: 1px solid #000000;">
        <tr style="background-color: #BDD7EE;">
            <th class="bold" style="padding: 10px; font-size: 12pt; text-align: center;">FOTO KEGIATAN KOKURIKULER</th>
        </tr>
        <tr>
            <td style="height: 250px; vertical-align: top; padding: 15px;">
                <p style="color: #7f8c8d; text-align: center; font-style: italic; margin-top: 90px; font-family: 'Times New Roman', Times, serif; font-size: 11pt;">[Tempel atau Sisipkan Foto Kegiatan Kokurikuler secara Bebas di Sini]</p>
            </td>
        </tr>
    </table>
</div>

<div class="page-break"></div>

<!-- ----------------------------------------------------------------------------
     HALAMAN 9: EKSKUL, KEHADIRAN, TANDA TANGAN
     ---------------------------------------------------------------------------- -->
<div>
    <span class="bold" style="font-size: 11pt;">A. KEGIATAN EKSTRAKURIKULER</span>
    <table class="border-all" style="font-size: 11pt; margin-top: 5px;">
        <tr style="background-color: #C55A11;">
            <th class="text-center" style="width: 40px; color: #ffffff; font-weight: bold; font-size: 11pt;">No</th>
            <th class="text-center" style="width: 160px; color: #ffffff; font-weight: bold; font-size: 11pt;">Ekstrakurikuler</th>
            <th class="text-center" style="color: #ffffff; font-weight: bold; font-size: 11pt;">Keterangan</th>
        </tr>
        <?php if (empty($ekskul_list)): ?>
            <tr>
                <td class="text-center" style="font-size: 11pt;">-</td>
                <td class="text-center" style="font-size: 11pt;">-</td>
                <td class="text-center" style="font-size: 11pt;">-</td>
            </tr>
        <?php else: ?>
            <?php foreach ($ekskul_list as $idx => $e): ?>
                <tr>
                    <td class="text-center" style="font-size: 11pt;"><?php echo ($idx + 1); ?>.</td>
                    <td class="bold" style="font-size: 11pt;"><?php echo cleanText($e['nama_ekstrakurikuler']); ?></td>
                    <td style="font-size: 11pt;"><?php echo cleanText($e['catatan'] ?: '-'); ?></td>
                </tr>
            <?php endforeach; ?>
        <?php endif; ?>
    </table>

    <br>

    <span class="bold" style="font-size: 11pt;">B. PRESTASI</span>
    <table class="border-all" style="font-size: 11pt; margin-top: 5px;">
        <tr style="background-color: #A9D08E;">
            <th class="text-center" style="width: 40px; font-weight: bold; font-size: 11pt;">No</th>
            <th class="text-center" style="width: 160px; font-weight: bold; font-size: 11pt;">JENIS PRESTASI</th>
            <th class="text-center" style="font-weight: bold; font-size: 11pt;">Keterangan</th>
        </tr>
        <tr>
            <td class="text-center" style="font-size: 11pt;">-</td>
            <td class="text-center" style="font-size: 11pt;">-</td>
            <td class="text-center" style="font-size: 11pt;">-</td>
        </tr>
    </table>

    <br>

    <table class="border-all" style="font-size: 11pt; width: 100%;">
        <tr style="background-color: #A9D08E;">
            <th class="text-center" style="font-weight: bold; padding: 6px; font-size: 11pt;">TINGKAT KEHADIRAN</th>
        </tr>
    </table>
    <table class="border-none" style="width: 100%; margin-top: 5px; font-size: 11pt;">
        <tr>
            <td style="width: 32%;">
                <table class="border-all" style="margin: 0; width: 100%; font-size: 11pt;">
                    <tr><td class="kehadiran-num" style="font-size: 11pt;"><?php echo $sakit; ?></td></tr>
                    <tr style="background-color: #FCE4D6;">
                        <td class="kehadiran-label" style="font-size: 11pt;">Sakit</td>
                    </tr>
                </table>
            </td>
            <td style="width: 2%;"></td>
            <td style="width: 32%;">
                <table class="border-all" style="margin: 0; width: 100%; font-size: 11pt;">
                    <tr><td class="kehadiran-num" style="font-size: 11pt;"><?php echo $izin; ?></td></tr>
                    <tr style="background-color: #FFF2CC;">
                        <td class="kehadiran-label" style="font-size: 11pt;">Izin</td>
                    </tr>
                </table>
            </td>
            <td style="width: 2%;"></td>
            <td style="width: 32%;">
                <table class="border-all" style="margin: 0; width: 100%; font-size: 11pt;">
                    <tr><td class="kehadiran-num" style="font-size: 11pt;"><?php echo ($alpa === 0) ? '-' : $alpa; ?></td></tr>
                    <tr style="background-color: #E7E6E6;">
                        <td class="kehadiran-label" style="font-size: 11pt;">Tanpa Keterangan</td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>

    <table class="border-none" style="width: 100%; font-size: 11pt; margin-top: 15px;">
        <tr>
            <td style="width: 50%;"></td>
            <td style="width: 50%; font-size: 11pt;">
                <div class="text-left" style="line-height: 1.5; padding-left: 80px; font-size: 11pt;">
                    Diberikan di &nbsp;: Bengkalis<br>
                    Tanggal &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;: <?php echo $tanggal_cetak; ?>
                </div>
            </td>
        </tr>
    </table>

    <br><br>

    <!-- Signatures -->
    <table class="border-none" style="width: 100%; font-size: 11pt; text-align: center;">
        <tr>
            <td style="width: 50%; padding-left: 20px; font-size: 11pt;">
                Orang Tua/Wali<br><br><br><br>
                ( &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; )
            </td>
            <td style="width: 50%; padding-right: 20px; font-size: 11pt;">
                Guru Kelompok<br><br><br><br>
                <span class="bold underline" style="font-size: 11pt;"><?php echo strtoupper(cleanText($narasi['nama_guru'])); ?></span>
                <?php if (!empty($narasi['nip_guru'])): ?>
                    <br><span style="font-size: 11pt;">NIP. <?php echo cleanText($narasi['nip_guru']); ?></span>
                <?php endif; ?>
            </td>
        </tr>
        <tr>
            <td colspan="2" style="height: 25px;"></td>
        </tr>
        <tr>
            <td colspan="2" style="font-size: 11pt;">
                Kepala <?php echo $nama_sekolah; ?><br><br><br><br>
                <span class="bold underline" style="font-size: 11pt;"><?php echo strtoupper($kepala_sekolah); ?></span>
                <?php if (!empty($nip_kepala_sekolah)): ?>
                    <br><span style="font-size: 11pt;">NIP. <?php echo $nip_kepala_sekolah; ?></span>
                <?php endif; ?>
            </td>
        </tr>
    </table>
</div>

</body>
</html>
