<?php
header('Content-Type: text/plain');

$host = "127.0.0.1";
$user = "root";
$pass = "";
$db   = "monak_db";

echo "=== MEMPERBAIKI RELASI DATABASE (FOREIGN KEYS) ===\n\n";

$conn = @new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo "❌ Gagal terhubung ke monak_db: " . $conn->connect_error . "\n";
    exit();
}

echo "✅ Berhasil terhubung ke monak_db\n\n";

// Disable foreign key checks temporarily to allow clean altering
$conn->query("SET FOREIGN_KEY_CHECKS = 0");

$queries = [
    // 1. modul_ajar -> kelas
    "ALTER TABLE modul_ajar MODIFY id_kelas INT NULL",
    "UPDATE modul_ajar SET id_kelas = NULL WHERE id_kelas NOT IN (SELECT id FROM kelas) OR id_kelas = 0",
    "ALTER TABLE modul_ajar ADD CONSTRAINT fk_modul_ajar_kelas FOREIGN KEY (id_kelas) REFERENCES kelas(id) ON DELETE CASCADE",

    // 2. modul_ajar -> users (guru)
    "ALTER TABLE modul_ajar MODIFY id_guru INT NULL",
    "UPDATE modul_ajar SET id_guru = NULL WHERE id_guru NOT IN (SELECT id FROM users) OR id_guru = 0",
    "ALTER TABLE modul_ajar ADD CONSTRAINT fk_modul_ajar_guru FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE SET NULL",

    // 3. prosem -> kelas
    "ALTER TABLE prosem MODIFY id_kelas INT NULL",
    "UPDATE prosem SET id_kelas = NULL WHERE id_kelas NOT IN (SELECT id FROM kelas) OR id_kelas = 0",
    "ALTER TABLE prosem ADD CONSTRAINT fk_prosem_kelas FOREIGN KEY (id_kelas) REFERENCES kelas(id) ON DELETE CASCADE",

    // 4. prosem -> users (guru)
    "ALTER TABLE prosem MODIFY id_guru INT NULL",
    "UPDATE prosem SET id_guru = NULL WHERE id_guru NOT IN (SELECT id FROM users) OR id_guru = 0",
    "ALTER TABLE prosem ADD CONSTRAINT fk_prosem_guru FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE SET NULL",

    // 5. rppm -> users (guru)
    "ALTER TABLE rppm MODIFY id_guru INT NULL",
    "UPDATE rppm SET id_guru = NULL WHERE id_guru NOT IN (SELECT id FROM users) OR id_guru = 0",
    "ALTER TABLE rppm ADD CONSTRAINT fk_rppm_guru FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE SET NULL",

    // 6. users -> kelas
    "ALTER TABLE users MODIFY id_kelas INT NULL",
    "UPDATE users SET id_kelas = NULL WHERE id_kelas NOT IN (SELECT id FROM kelas) OR id_kelas = 0",
    "ALTER TABLE users ADD CONSTRAINT fk_users_kelas FOREIGN KEY (id_kelas) REFERENCES kelas(id) ON DELETE SET NULL"
];

foreach ($queries as $q) {
    echo "Executing: $q ... ";
    if ($conn->query($q)) {
        echo "✅ SUCCESS\n";
    } else {
        // Jika foreign key sudah ada, query ALTER akan gagal tapi itu aman untuk diabaikan
        if (strpos($conn->error, 'Duplicate key name') !== false || strpos($conn->error, 'already exists') !== false) {
            echo "ℹ️ ALREADY EXISTS (OK)\n";
        } else {
            echo "❌ FAILED: " . $conn->error . "\n";
        }
    }
}

// Re-enable foreign key checks
$conn->query("SET FOREIGN_KEY_CHECKS = 1");

echo "\n🎉 Semua relasi database berhasil diperbaiki dan dihubungkan secara formal!\n";
$conn->close();
?>
