<?php
header('Content-Type: text/plain');

$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "monak_db";

echo "=== DATABASE SCHEMA RELATION AUDIT ===\n\n";

$conn = @new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo "❌ Gagal terhubung ke monak_db: " . $conn->connect_error . "\n";
    exit();
}

echo "✅ Berhasil terhubung ke monak_db\n\n";

// 1. Ambil daftar semua tabel
$tables = [];
$res = $conn->query("SHOW TABLES");
while ($row = $res->fetch_row()) {
    $tables[] = $row[0];
}

echo "📂 Daftar Tabel yang Ditemukan (" . count($tables) . "):\n";
foreach ($tables as $t) {
    echo " - $t\n";
}
echo "\n" . str_repeat("=", 50) . "\n\n";

// 2. Audit Foreign Keys yang Ada
echo "🔍 FOREIGN KEY CONSTRAINTS YANG SUDAH ADA:\n\n";
$fk_sql = "
    SELECT 
        TABLE_NAME, 
        COLUMN_NAME, 
        CONSTRAINT_NAME, 
        REFERENCED_TABLE_NAME, 
        REFERENCED_COLUMN_NAME 
    FROM 
        information_schema.KEY_COLUMN_USAGE 
    WHERE 
        TABLE_SCHEMA = '$db' 
        AND REFERENCED_TABLE_NAME IS NOT NULL
";
$fk_res = $conn->query($fk_sql);
$existing_fks = [];
if ($fk_res) {
    while ($row = $fk_res->fetch_assoc()) {
        echo " 🔗 Tabel [{$row['TABLE_NAME']}] kolom [{$row['COLUMN_NAME']}]\n";
        echo "    ➔ Merujuk ke [{$row['REFERENCED_TABLE_NAME']}] kolom [{$row['REFERENCED_COLUMN_NAME']}]\n";
        echo "    (Nama Constraint: {$row['CONSTRAINT_NAME']})\n\n";
        
        $existing_fks[$row['TABLE_NAME']][$row['COLUMN_NAME']] = [
            'ref_table' => $row['REFERENCED_TABLE_NAME'],
            'ref_col' => $row['REFERENCED_COLUMN_NAME']
        ];
    }
}

echo str_repeat("=", 50) . "\n\n";

// 3. Deteksi Kolom Relasional yang Kehilangan Foreign Key
echo "⚠️ DETEKSI KOLOM ID RELASIONAL TANPA FOREIGN KEY CONSTRAINTS:\n\n";

$found_missing = false;
foreach ($tables as $table) {
    $cols_res = $conn->query("DESCRIBE `$table`");
    if (!$cols_res) continue;
    
    while ($col = $cols_res->fetch_assoc()) {
        $col_name = $col['Field'];
        
        // Cari kolom yang namanya berawalan "id_" atau berakhiran "_id" (tapi bukan primary key "id")
        $is_relational_name = (strpos($col_name, 'id_') === 0 || substr($col_name, -3) === '_id') && $col_name !== 'id';
        
        if ($is_relational_name) {
            // Cek apakah sudah terdaftar sebagai foreign key
            $has_fk = isset($existing_fks[$table][$col_name]);
            
            if (!$has_fk) {
                $found_missing = true;
                
                // Tebak tabel tujuan berdasarkan nama kolom
                $guessed_table = '';
                if (strpos($col_name, 'id_') === 0) {
                    $guessed_table = substr($col_name, 3);
                } elseif (substr($col_name, -3) === '_id') {
                    $guessed_table = substr($col_name, 0, -3);
                }
                
                // Koreksi beberapa nama tabel (jika ada singkatan atau nama khusus)
                if ($guessed_table === 'ortu') $guessed_table = 'orang_tua';
                if ($guessed_table === 'guru') $guessed_table = 'users'; // Guru di sini akunnya merujuk ke users.id
                
                $status_msg = " [KOSONG/BELUM ADA]";
                if (in_array($guessed_table, $tables)) {
                    $status_msg = " ➔ (Tabel Tujuan Terdeteksi: `$guessed_table`)";
                } else {
                    $status_msg = " ➔ (Tabel Tujuan Tidak Jelas: `$guessed_table`)";
                }
                
                echo " ❌ Tabel [`$table`] ➔ Kolom [`$col_name`]$status_msg\n";
            }
        }
    }
}

if (!$found_missing) {
    echo " ✅ Luar biasa! Semua kolom ID relasional sudah memiliki Foreign Key Constraints.\n";
}

$conn->close();
?>
