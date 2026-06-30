<?php
// log_activity.php — include di setiap file PHP CRUD
// Cara pakai: require_once 'log_activity.php';
// - Dengan user: logActivity($pdo, $judul, $desc, $jenis, $aksi, $userId, $userRole)
// - Tanpa user: logActivity($pdo, $judul, $desc, $jenis, $aksi)

if (!function_exists('getPdo')) {
    function getPdo(): PDO {
        static $pdo = null;
        if ($pdo === null) {
            global $host, $user, $pass, $db;
            if (!isset($host) || empty($host)) {
                $configPath = __DIR__ . '/config.php';
                if (file_exists($configPath)) {
                    include $configPath;
                }
            }
            $pdo = new PDO(
                "mysql:host={$host};dbname={$db};charset=utf8mb4",
                $user,
                $pass,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
            );
        }
        return $pdo;
    }
}

function logActivity(
    PDO    $pdo,
    string $judul,
    string $deskripsi = '',
    string $jenis     = 'info',
    string $aksi      = 'info',
    ?int   $createdBy = null,
    ?string $role    = null
): void {
    // Graceful fallback jika parameter user tidak dikirim
    // Ini memastikan backward compatibility dengan request lama
    $stmt = $pdo->prepare("
        INSERT INTO activity_log (judul, deskripsi, jenis, aksi, created_by, role)
        VALUES (:judul, :deskripsi, :jenis, :aksi, :created_by, :role)
    ");
    $stmt->execute([
        ':judul'      => $judul,
        ':deskripsi'  => $deskripsi,
        ':jenis'      => $jenis,
        ':aksi'       => $aksi,
        ':created_by' => $createdBy,  // null jika tidak ada user
        ':role'       => $role,        // null jika tidak ada role
    ]);
}