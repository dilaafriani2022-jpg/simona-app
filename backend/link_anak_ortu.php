<?php
header("Content-Type: application/json");
require_once 'config.php';

// Update anak untuk menghubungkan dengan orang tua yang ada
// ID 2 = Ibu Siti (Wali Ani)
// ID 3 = Pak Ahmad (Wali Budi)

$updates = [
    // Update anak yang seharusnya anak dari Ibu Siti
    "UPDATE anak SET id_ortu = 2 WHERE id IN (1, 3, 4)", // Ani Wijaya, Anindya Vosbein, Siti Salmah
    // Update anak yang seharusnya anak dari Pak Ahmad  
    "UPDATE anak SET id_ortu = 3 WHERE id IN (5)" // Dila Afrinani
];

foreach ($updates as $sql) {
    if ($conn->query($sql)) {
        echo "✓ Update berhasil: " . substr($sql, 0, 50) . "...\n";
    } else {
        echo "✗ Error: " . $conn->error . "\n";
    }
}

echo "\n✓ Semua anak berhasil dihubungkan dengan orang tua!";
$conn->close();
?>
