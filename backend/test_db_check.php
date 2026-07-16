<?php
header('Content-Type: text/plain');

$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "monak_db";

echo "=== DIAGNOSIS get_kehadiran_ortu.php LOGIC ===\n\n";

$conn = @new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo "❌ Gagal terhubung ke monak_db: " . $conn->connect_error . "\n";
    exit();
}

$anak_id = 1;
$bulan = 1;
$semester = 1;

// 1. Cek prosem date range
$use_academic_range = false;
$start_date = null;
$end_date = null;

$class_sql = "SELECT id_kelas FROM anak WHERE id = $anak_id LIMIT 1";
$class_res = $conn->query($class_sql);
if ($class_res && $class_row = $class_res->fetch_assoc()) {
    $id_kelas = (int)$class_row['id_kelas'];
    echo "👦 Anak ID: $anak_id, Kelas ID: $id_kelas\n";
    
    if ($id_kelas > 0) {
        $min_week = ($bulan - 1) * 4 + 1;
        $max_week = $bulan * 4;
        echo "📅 Filter Minggu Ke: $min_week s/d $max_week\n";
        
        $date_sql = "SELECT MIN(tanggal_mulai) as start_d, MAX(tanggal_selesai) as end_d 
                     FROM prosem 
                     WHERE id_kelas = $id_kelas 
                       AND semester = $semester 
                       AND minggu_ke BETWEEN $min_week AND $max_week";
        $date_res = $conn->query($date_sql);
        if ($date_res && $date_row = $date_res->fetch_assoc()) {
            $start_date = $date_row['start_d'];
            $end_date = $date_row['end_d'];
            echo "🔍 Prosem Date Range: $start_date s/d $end_date\n";
            if ($start_date && $end_date) {
                $use_academic_range = true;
            }
        }
    }
}

// 2. Query Kehadiran
$sql = "SELECT
            a.id,
            a.id_anak,
            a.tanggal,
            a.status
        FROM absensi a
        WHERE a.id_anak = $anak_id";

if ($use_academic_range) {
    $sql .= " AND a.tanggal BETWEEN '$start_date' AND '$end_date'";
    echo "⚙️ Menggunakan rentang tanggal akademik (Prosem)\n";
} else {
    $ta_sql = "SELECT ta.tahun FROM anak a LEFT JOIN kelas k ON a.id_kelas = k.id LEFT JOIN tahun_ajaran ta ON k.id_tahun_ajaran = ta.id WHERE a.id = $anak_id LIMIT 1";
    $ta_res = $conn->query($ta_sql);
    $ta_tahun = '2026/2027';
    if ($ta_res && $ta_row = $ta_res->fetch_assoc()) {
        $ta_tahun = $ta_row['tahun'] ?? '2026/2027';
    }
    $years = explode('/', $ta_tahun);
    $year_sem1 = intval(trim($years[0]));
    $year_sem2 = isset($years[1]) ? intval(trim($years[1])) : $year_sem1 + 1;
    $tahun = ($semester === 2) ? $year_sem2 : $year_sem1;
    
    $cal_month = $semester == 1 ? $bulan + 6 : $bulan;
    $sql .= " AND MONTH(a.tanggal) = $cal_month AND YEAR(a.tanggal) = $tahun";
    echo "⚙️ Menggunakan rentang tanggal kalender (Bulan: $cal_month, Tahun: $tahun)\n";
}

$sql .= " ORDER BY a.tanggal ASC";
echo "📝 SQL Query: $sql\n\n";

$result = $conn->query($sql);
$stats = [
    'Hadir' => 0,
    'Sakit' => 0,
    'Izin' => 0,
    'Alpa' => 0
];

echo "📊 Data absensi yang cocok:\n";
while ($row = $result->fetch_assoc()) {
    echo "   - Tanggal: {$row['tanggal']} | Status: {$row['status']}\n";
    if (isset($stats[$row['status']])) {
        $stats[$row['status']]++;
    }
}

echo "\n📊 Statistik Kehadiran Final:\n";
print_r($stats);

$conn->close();
?>
