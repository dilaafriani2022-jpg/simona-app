<?php
require 'backend/config.php';
$res = $conn->query("SHOW CREATE TABLE anak");
print_r($res->fetch_assoc());
?>
