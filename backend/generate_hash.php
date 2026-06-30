<?php
// Generate bcrypt hashes for seed data
$passwords = [
    'password123',  // admin operator
    'guru123',      // guru
    'kepsek123',    // kepsek
    'ortu123'       // orang_tua
];

foreach ($passwords as $pwd) {
    $hash = password_hash($pwd, PASSWORD_BCRYPT, ['cost' => 10]);
    echo "Password: '$pwd'\n";
    echo "Hash: '$hash'\n\n";
}
?>
