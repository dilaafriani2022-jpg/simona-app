<?php
// migrate_rekap_feature.php
header("Content-Type: application/json; charset=UTF-8");
require_once 'config.php';

$response = [
    "status" => "success",
    "messages" => []
];

// Helper to check and add column
function addColIfMissing(mysqli $conn, string $table, string $col, string $def): string {
    $check = $conn->query("SHOW COLUMNS FROM `$table` LIKE '$col'");
    if ($check && $check->num_rows === 0) {
        $sql = "ALTER TABLE `$table` ADD COLUMN `$col` $def";
        if ($conn->query($sql)) {
            return "✅ Added column: `$table`.`$col`";
        } else {
            return "❌ Failed to add `$table`.`$col`: " . $conn->error;
        }
    } else {
        return "⏭️ Column already exists: `$table`.`$col`";
    }
}

// 1. Disable Foreign Key Checks
$conn->query("SET FOREIGN_KEY_CHECKS = 0");
$response["messages"][] = "Foreign key checks disabled.";

// 2. Add 'bulan' to tujuan_pembelajaran
$response["messages"][] = addColIfMissing($conn, 'tujuan_pembelajaran', 'bulan', "TINYINT DEFAULT 1");

// 3. Add 'bulan' to kegiatan_pembelajaran
$response["messages"][] = addColIfMissing($conn, 'kegiatan_pembelajaran', 'bulan', "TINYINT DEFAULT 1");

// 4. Create rekap_penilaian_bulanan Table
$sqlCreateRekap = "CREATE TABLE IF NOT EXISTS rekap_penilaian_bulanan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_anak INT NOT NULL,
    id_guru INT NOT NULL,
    id_kegiatan INT NOT NULL,
    bulan TINYINT NOT NULL,
    semester TINYINT DEFAULT 1,
    status_akhir ENUM('TM', 'MM', 'M') NOT NULL,
    catatan_perkembangan TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
    FOREIGN KEY (id_guru) REFERENCES guru(id) ON DELETE CASCADE,
    FOREIGN KEY (id_kegiatan) REFERENCES kegiatan_pembelajaran(id) ON DELETE CASCADE,
    UNIQUE KEY unique_rekap (id_anak, id_kegiatan, bulan, semester)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;";

if ($conn->query($sqlCreateRekap)) {
    $response["messages"][] = "✅ Table 'rekap_penilaian_bulanan' verified/created.";
} else {
    $response["status"] = "error";
    $response["messages"][] = "❌ Error creating 'rekap_penilaian_bulanan' table: " . $conn->error;
}

// 5. Re-enable Foreign Key Checks
$conn->query("SET FOREIGN_KEY_CHECKS = 1");
$response["messages"][] = "Foreign key checks enabled.";

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
