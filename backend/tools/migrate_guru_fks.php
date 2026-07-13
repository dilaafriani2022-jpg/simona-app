<?php
require_once '../config.php';

$tables = [
    'absensi',
    'anekdot',
    'catatan_pembelajaran',
    'jadwal_kelas',
    'karya_siswa',
    'kegiatan_pembelajaran',
    'penilaian_checklist',
    'refleksi_guru',
    'siswa_ekstrakurikuler',
    'tujuan_pembelajaran'
];

$conn->begin_transaction();

try {
    foreach ($tables as $table) {
        // 1. Get FK constraint name for id_guru
        $res = $conn->query("SELECT CONSTRAINT_NAME 
                             FROM information_schema.KEY_COLUMN_USAGE 
                             WHERE TABLE_SCHEMA = 'monak_db' 
                               AND TABLE_NAME = '$table' 
                               AND COLUMN_NAME = 'id_guru' 
                               AND REFERENCED_TABLE_NAME IS NOT NULL");
        
        while ($row = $res->fetch_assoc()) {
            $fkName = $row['CONSTRAINT_NAME'];
            // Drop FK
            $conn->query("ALTER TABLE $table DROP FOREIGN KEY $fkName");
            echo "Dropped FK $fkName from $table\n";
        }
        
        // 2. Update data: Set id_guru = guru.id where guru.id_user = current id_guru
        $updateSql = "UPDATE $table t 
                      JOIN guru g ON t.id_guru = g.id_user 
                      SET t.id_guru = g.id";
        $conn->query($updateSql);
        echo "Updated rows in $table\n";
        
        // 3. Add new FK to guru(id)
        $conn->query("ALTER TABLE $table ADD CONSTRAINT fk_{$table}_guru FOREIGN KEY (id_guru) REFERENCES guru(id) ON DELETE CASCADE");
        echo "Added new FK to $table referencing guru(id)\n";
    }
    
    $conn->commit();
    echo "Migration completed successfully.\n";
    
} catch (Exception $e) {
    $conn->rollback();
    echo "Error: " . $e->getMessage() . "\n";
}
?>
