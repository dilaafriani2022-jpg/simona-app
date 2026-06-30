<?php
require 'backend/config.php';
$res = $conn->query("
SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_SCHEMA = 'monak_db' 
  AND TABLE_NAME IN ('absensi', 'anekdot', 'catatan_pembelajaran', 'jadwal_kelas', 'karya_siswa', 'kegiatan_pembelajaran', 'penilaian_checklist', 'refleksi_guru', 'siswa_ekstrakurikuler', 'spp', 'tujuan_pembelajaran')
  AND COLUMN_NAME IN ('id_guru', 'id_siswa', 'id_ortu')
");
while($r = $res->fetch_assoc()) {
    echo $r['TABLE_NAME'] . " - " . $r['COLUMN_NAME'] . " -> " . $r['REFERENCED_TABLE_NAME'] . "\n";
}
?>
