<?php
require '../config.php';
$res = $conn->query("SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = 'monak_db' AND COLUMN_NAME IN ('id_guru', 'id_siswa', 'id_ortu')");
while($r = $res->fetch_assoc()) {
    echo $r['TABLE_NAME'] . " - " . $r['COLUMN_NAME'] . "\n";
}
?>
