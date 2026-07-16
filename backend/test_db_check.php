<?php
header('Content-Type: text/plain');

$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "monak_db";

echo "=== DIAGNOSIS DATA TAHUN AJARAN MONAK_DB ===\n\n";

$conn = @new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo "❌ Gagal terhubung ke monak_db: " . $conn->connect_error . "\n";
    exit();
}

echo "✅ Berhasil terhubung ke monak_db\n\n";

$res = $conn->query("SELECT * FROM tahun_ajaran");
if ($res) {
    echo "📊 Tabel 'tahun_ajaran':\n";
    while ($row = $res->fetch_assoc()) {
        echo " - ID: {$row['id']}\n";
        echo "   Tahun: {$row['tahun']}\n";
        echo "   Status: {$row['status']}\n";
        echo "   Semester Aktif: {$row['semester_aktif']}\n";
        echo "   Sem 1 Mulai: {$row['tanggal_mulai_semester_1']}\n";
        echo "   Sem 1 Akhir: {$row['tanggal_akhir_semester_1']}\n";
        echo "   Sem 2 Mulai: {$row['tanggal_mulai_semester_2']}\n";
        echo "   Sem 2 Akhir: {$row['tanggal_akhir_semester_2']}\n";
        echo "-----------------------------------------\n";
    }
} else {
    echo "❌ Gagal query tabel 'tahun_ajaran': " . $conn->error . "\n";
}

$conn->close();
?>
