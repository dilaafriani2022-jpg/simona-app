<?php
/**
 * Migration: Add created_by and role columns to activity_log table
 * Run: php migrations/add_activity_log_columns.php
 */

require_once dirname(__DIR__) . '/config.php';

try {
    $conn = new mysqli($host, $user, $pass, $db);
    if ($conn->connect_error) {
        throw new Exception("Connection failed: {$conn->connect_error}");
    }
    
    $conn->set_charset("utf8mb4");
    
    // Check if columns exist
    $result = $conn->query("SHOW COLUMNS FROM activity_log LIKE 'created_by'");
    if ($result && $result->num_rows === 0) {
        echo "⏳ Adding column created_by...\n";
        $conn->query("ALTER TABLE activity_log ADD COLUMN created_by INT");
        echo "✓ Column created_by added\n";
    } else {
        echo "✓ Column created_by already exists\n";
    }
    
    $result = $conn->query("SHOW COLUMNS FROM activity_log LIKE 'role'");
    if ($result && $result->num_rows === 0) {
        echo "⏳ Adding column role...\n";
        $conn->query("ALTER TABLE activity_log ADD COLUMN role VARCHAR(50)");
        echo "✓ Column role added\n";
    } else {
        echo "✓ Column role already exists\n";
    }
    
    // Check if foreign key exists
    $result = $conn->query("
        SELECT CONSTRAINT_NAME 
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
        WHERE TABLE_NAME = 'activity_log' 
        AND COLUMN_NAME = 'created_by' 
        AND REFERENCED_TABLE_NAME = 'users'
    ");
    
    if ($result && $result->num_rows === 0) {
        echo "⏳ Adding foreign key...\n";
        $conn->query("
            ALTER TABLE activity_log 
            ADD CONSTRAINT fk_activity_log_user 
            FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
        ");
        echo "✓ Foreign key added\n";
    } else {
        echo "✓ Foreign key already exists\n";
    }
    
    echo "\n✅ Migration completed successfully!\n";
    $conn->close();
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    exit(1);
}
?>
