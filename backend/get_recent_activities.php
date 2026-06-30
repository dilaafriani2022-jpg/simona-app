<?php
// get_recent_activities.php
// Endpoint: GET /monak/backend/get_recent_activities.php?limit=10

require_once 'cors.php';
header("Content-Type: application/json");

require_once 'config.php'; // menyediakan $host, $user, $pass, $db

// ── Koneksi PDO pakai variabel dari config.php ────────────────
try {
    $pdo = new PDO(
        "mysql:host={$host};dbname={$db};charset=utf8mb4",
        $user,
        $pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $e) {
    echo json_encode([
        "status"  => "error",
        "message" => "Koneksi database gagal: " . $e->getMessage()
    ]);
    exit;
}

// ── Parameter ─────────────────────────────────────────────────
$limit  = isset($_GET['limit'])  ? (int)$_GET['limit']  : 10;
$offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
$limit  = max(1, min($limit, 50)); // clamp 1–50
$offset = max(0, $offset);

// ── Query aktivitas terbaru dengan info user & role ───────────────────────────────────
try {
    $stmt = $pdo->prepare("
        SELECT
            al.id,
            al.judul,
            al.deskripsi,
            al.jenis,
            al.aksi,
            al.role,
            COALESCE(u.name, 'Unknown') AS nama_user,
            COALESCE(u.username, 'N/A') AS username,
            COALESCE(al.role, COALESCE(u.role, 'N/A')) AS role_actual,
            CASE
                WHEN TIMESTAMPDIFF(MINUTE, al.created_at, NOW()) < 1
                    THEN 'Baru saja'
                WHEN TIMESTAMPDIFF(MINUTE, al.created_at, NOW()) < 60
                    THEN CONCAT(TIMESTAMPDIFF(MINUTE, al.created_at, NOW()), ' menit lalu')
                WHEN TIMESTAMPDIFF(HOUR, al.created_at, NOW()) < 24
                    THEN CONCAT(TIMESTAMPDIFF(HOUR, al.created_at, NOW()), ' jam lalu')
                WHEN TIMESTAMPDIFF(DAY, al.created_at, NOW()) < 7
                    THEN CONCAT(TIMESTAMPDIFF(DAY, al.created_at, NOW()), ' hari lalu')
                ELSE DATE_FORMAT(al.created_at, '%d %b %Y')
            END AS waktu_label,
            al.created_at
        FROM activity_log al
        LEFT JOIN users u ON al.created_by = u.id
        ORDER BY al.created_at DESC
        LIMIT :limit OFFSET :offset
    ");
    $stmt->bindValue(':limit',  $limit,  PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "data"   => $rows
    ]);

} catch (PDOException $e) {
    echo json_encode([
        "status"  => "error",
        "message" => "Query gagal: " . $e->getMessage()
    ]);
}