<?php
// migrate_db.php
header("Content-Type: application/json; charset=UTF-8");
require_once 'config.php';

$response = [
    "status" => "success",
    "messages" => []
];

// 1. Disable Foreign Key Checks
$conn->query("SET FOREIGN_KEY_CHECKS = 0");
$response["messages"][] = "Foreign key checks disabled.";

// 2. Create Guru Table
$sqlCreateGuru = "CREATE TABLE IF NOT EXISTS guru (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_user INT NOT NULL,
    nama VARCHAR(100) NOT NULL,
    nip VARCHAR(20) UNIQUE DEFAULT NULL,
    nik VARCHAR(20) DEFAULT NULL,
    jenis_kelamin ENUM('L', 'P') DEFAULT NULL,
    tempat_lahir VARCHAR(100) DEFAULT NULL,
    tanggal_lahir DATE DEFAULT NULL,
    agama VARCHAR(30) DEFAULT NULL,
    status_nikah ENUM('Belum Menikah','Menikah','Cerai') DEFAULT NULL,
    status_kepeg ENUM('PNS','PPPK','Honorer','GTT','PTT') DEFAULT NULL,
    jabatan VARCHAR(100) DEFAULT NULL,
    pendidikan ENUM('SMA/SMK','D3','S1','S2','S3') DEFAULT NULL,
    jurusan VARCHAR(100) DEFAULT NULL,
    tahun_mulai YEAR DEFAULT NULL,
    no_telp VARCHAR(20) DEFAULT NULL,
    email_guru VARCHAR(100) DEFAULT NULL,
    alamat TEXT DEFAULT NULL,
    id_kelas INT DEFAULT NULL,
    FOREIGN KEY (id_user) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";

if ($conn->query($sqlCreateGuru)) {
    $response["messages"][] = "Table 'guru' verified/created.";
} else {
    $response["status"] = "error";
    $response["messages"][] = "Error creating 'guru' table: " . $conn->error;
    echo json_encode($response);
    exit;
}

// 3. Create Orang Tua Table
$sqlCreateOrangTua = "CREATE TABLE IF NOT EXISTS orang_tua (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_user INT NOT NULL,
    nama VARCHAR(100) NOT NULL,
    no_hp VARCHAR(20) DEFAULT NULL,
    pekerjaan VARCHAR(100) DEFAULT NULL,
    alamat TEXT DEFAULT NULL,
    -- Ayah
    ayah_nama VARCHAR(100) DEFAULT NULL,
    ayah_nik VARCHAR(20) DEFAULT NULL,
    ayah_ttl VARCHAR(100) DEFAULT NULL,
    ayah_agama VARCHAR(30) DEFAULT NULL,
    ayah_pendidikan VARCHAR(50) DEFAULT NULL,
    ayah_pekerjaan VARCHAR(100) DEFAULT NULL,
    ayah_penghasilan VARCHAR(50) DEFAULT NULL,
    ayah_hp VARCHAR(20) DEFAULT NULL,
    ayah_status VARCHAR(20) DEFAULT 'Hidup',
    -- Ibu
    ibu_nama VARCHAR(100) DEFAULT NULL,
    ibu_nik VARCHAR(20) DEFAULT NULL,
    ibu_ttl VARCHAR(100) DEFAULT NULL,
    ibu_agama VARCHAR(30) DEFAULT NULL,
    ibu_pendidikan VARCHAR(50) DEFAULT NULL,
    ibu_pekerjaan VARCHAR(100) DEFAULT NULL,
    ibu_penghasilan VARCHAR(50) DEFAULT NULL,
    ibu_hp VARCHAR(20) DEFAULT NULL,
    ibu_status VARCHAR(20) DEFAULT 'Hidup',
    -- Wali
    wali_nama VARCHAR(100) DEFAULT NULL,
    wali_hubungan VARCHAR(50) DEFAULT NULL,
    wali_pekerjaan VARCHAR(100) DEFAULT NULL,
    wali_hp VARCHAR(20) DEFAULT NULL,
    -- Alamat detail
    rt_rw VARCHAR(20) DEFAULT NULL,
    kelurahan VARCHAR(100) DEFAULT NULL,
    kecamatan VARCHAR(100) DEFAULT NULL,
    kota VARCHAR(100) DEFAULT NULL,
    provinsi VARCHAR(100) DEFAULT NULL,
    kode_pos VARCHAR(10) DEFAULT NULL,
    FOREIGN KEY (id_user) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;";

if ($conn->query($sqlCreateOrangTua)) {
    $response["messages"][] = "Table 'orang_tua' verified/created.";
} else {
    $response["status"] = "error";
    $response["messages"][] = "Error creating 'orang_tua' table: " . $conn->error;
    echo json_encode($response);
    exit;
}

// 4. Migrate Guru Data from users
$resGuru = $conn->query("SELECT * FROM users WHERE role = 'guru'");
if ($resGuru) {
    $count = 0;
    while ($row = $resGuru->fetch_assoc()) {
        $userId = $row['id'];
        // Check if already in guru
        $check = $conn->query("SELECT id FROM guru WHERE id_user = $userId");
        if ($check && $check->num_rows == 0) {
            $stmt = $conn->prepare("INSERT INTO guru (
                id_user, nama, nip, nik, jenis_kelamin, tempat_lahir, tanggal_lahir,
                agama, status_nikah, status_kepeg, jabatan, pendidikan, jurusan,
                tahun_mulai, no_telp, email_guru, alamat, id_kelas
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
            
            $id_kelas_val = !empty($row['id_kelas']) ? intval($row['id_kelas']) : null;
            $stmt->bind_param(
                "issssssssssssssssi",
                $userId, $row['name'], $row['nip'], $row['nik'], $row['jenis_kelamin'],
                $row['tempat_lahir'], $row['tanggal_lahir'], $row['agama'], $row['status_nikah'],
                $row['status_kepeg'], $row['jabatan'], $row['pendidikan'], $row['jurusan'],
                $row['tahun_mulai'], $row['no_telp'], $row['email_guru'], $row['alamat'], $id_kelas_val
            );
            $stmt->execute();
            $count++;
        }
    }
    $response["messages"][] = "Migrated $count guru records.";
}

// 5. Migrate Orang Tua Data from users
$resOrtu = $conn->query("SELECT * FROM users WHERE role = 'orang_tua'");
if ($resOrtu) {
    $count = 0;
    while ($row = $resOrtu->fetch_assoc()) {
        $userId = $row['id'];
        // Check if already in orang_tua
        $check = $conn->query("SELECT id FROM orang_tua WHERE id_user = $userId");
        if ($check && $check->num_rows == 0) {
            $stmt = $conn->prepare("INSERT INTO orang_tua (
                id_user, nama, no_hp, pekerjaan, alamat,
                ayah_nama, ayah_nik, ayah_ttl, ayah_agama, ayah_pendidikan, ayah_pekerjaan, ayah_penghasilan, ayah_hp, ayah_status,
                ibu_nama, ibu_nik, ibu_ttl, ibu_agama, ibu_pendidikan, ibu_pekerjaan, ibu_penghasilan, ibu_hp, ibu_status,
                wali_nama, wali_hubungan, wali_pekerjaan, wali_hp,
                rt_rw, kelurahan, kecamatan, kota, provinsi, kode_pos
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
            
            // Map no_telp/no_hp
            $noHp = !empty($row['no_hp']) ? $row['no_hp'] : (!empty($row['no_telp']) ? $row['no_telp'] : null);
            
            $stmt->bind_param(
                "issssssssssssssssssssssssssssssss",
                $userId, $row['name'], $noHp, $row['pekerjaan'], $row['alamat'],
                $row['ayah_nama'], $row['ayah_nik'], $row['ayah_ttl'], $row['ayah_agama'], $row['ayah_pendidikan'], $row['ayah_pekerjaan'], $row['ayah_penghasilan'], $row['ayah_hp'], $row['ayah_status'],
                $row['ibu_nama'], $row['ibu_nik'], $row['ibu_ttl'], $row['ibu_agama'], $row['ibu_pendidikan'], $row['ibu_pekerjaan'], $row['ibu_penghasilan'], $row['ibu_hp'], $row['ibu_status'],
                $row['wali_nama'], $row['wali_hubungan'], $row['wali_pekerjaan'], $row['wali_hp'],
                $row['rt_rw'], $row['kelurahan'], $row['kecamatan'], $row['kota'], $row['provinsi'], $row['kode_pos']
            );
            $stmt->execute();
            $count++;
        }
    }
    $response["messages"][] = "Migrated $count orang_tua records.";
}

// 6. Rename 'anak' to 'anak'
$checkAnak = $conn->query("SHOW TABLES LIKE 'anak'");
if ($checkAnak && $checkAnak->num_rows > 0) {
    if ($conn->query("RENAME TABLE anak TO anak")) {
        $response["messages"][] = "Table 'anak' renamed to 'anak'.";
    } else {
        $response["status"] = "error";
        $response["messages"][] = "Error renaming 'anak' table: " . $conn->error;
        echo json_encode($response);
        exit;
    }
} else {
    $response["messages"][] = "Table 'anak' already renamed or doesn't exist.";
}

// 7. Rename column 'nama_anak' to 'nama_anak' in table 'anak' if exists
$checkCol = $conn->query("SHOW COLUMNS FROM anak LIKE 'nama_anak'");
if ($checkCol && $checkCol->num_rows > 0) {
    if ($conn->query("ALTER TABLE anak CHANGE COLUMN nama_anak nama_anak VARCHAR(100) NOT NULL")) {
        $response["messages"][] = "Column 'nama_anak' renamed to 'nama_anak' in table 'anak'.";
    } else {
        $response["status"] = "error";
        $response["messages"][] = "Error renaming column 'nama_anak': " . $conn->error;
        echo json_encode($response);
        exit;
    }
}

// 8. Map old 'id_ortu' (which pointed to users.id) to new 'orang_tua.id'
$resMap = $conn->query("SELECT a.id, a.id_ortu, o.id AS new_ortu_id 
                        FROM anak a 
                        JOIN users u ON a.id_ortu = u.id 
                        JOIN orang_tua o ON u.id = o.id_user 
                        WHERE u.role = 'orang_tua'");
if ($resMap && $resMap->num_rows > 0) {
    $mappedCount = 0;
    while ($row = $resMap->fetch_assoc()) {
        $anakId = $row['id'];
        $newOrtuId = $row['new_ortu_id'];
        $conn->query("UPDATE anak SET id_ortu = $newOrtuId WHERE id = $anakId");
        $mappedCount++;
    }
    $response["messages"][] = "Remapped $mappedCount children to the new 'orang_tua' ID.";
} else {
    $response["messages"][] = "No child mapping needed or already mapped.";
}

// 9. Drop old Foreign Key pointing to 'users' and add new FK pointing to 'orang_tua'
// Find the exact constraint name on table 'anak' for column 'id_ortu' referencing 'users'
$sqlFindFK = "SELECT CONSTRAINT_NAME 
              FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
              WHERE TABLE_SCHEMA = 'monak_db' 
                AND TABLE_NAME = 'anak' 
                AND COLUMN_NAME = 'id_ortu' 
                AND REFERENCED_TABLE_NAME = 'users'";
$resFK = $conn->query($sqlFindFK);
if ($resFK && $rowFK = $resFK->fetch_assoc()) {
    $fkName = $rowFK['CONSTRAINT_NAME'];
    if ($conn->query("ALTER TABLE anak DROP FOREIGN KEY $fkName")) {
        $response["messages"][] = "Old Foreign Key constraint '$fkName' dropped.";
    }
}

// Add new FK referencing orang_tua
$sqlAddFK = "ALTER TABLE anak ADD CONSTRAINT fk_anak_ortu FOREIGN KEY (id_ortu) REFERENCES orang_tua(id) ON DELETE SET NULL;";
$conn->query($sqlAddFK);
$response["messages"][] = "New Foreign Key pointing to 'orang_tua' table created.";

// 10. Re-enable Foreign Key Checks
$conn->query("SET FOREIGN_KEY_CHECKS = 1");
$response["messages"][] = "Foreign key checks enabled.";

echo json_encode($response);
?>
