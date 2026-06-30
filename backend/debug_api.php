<?php
require_once 'cors.php';
header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents("php://input"), true) ?? [];

$debug = [
    'method' => $method,
    'uri' => $_SERVER['REQUEST_URI'],
    'query_params' => $_GET,
    'request_body' => $input,
    'headers' => getallheaders(),
    'timestamp' => date('Y-m-d H:i:s'),
];

// Log to file
$logFile = __DIR__ . '/debug_log.json';
$currentLog = file_exists($logFile) ? json_decode(file_get_contents($logFile), true) : [];
if (!is_array($currentLog)) $currentLog = [];
$currentLog[] = $debug;

// Keep only last 50 entries
if (count($currentLog) > 50) {
    $currentLog = array_slice($currentLog, -50);
}

file_put_contents($logFile, json_encode($currentLog, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

echo json_encode([
    'status' => 'success',
    'message' => 'Debug data logged',
    'debug' => $debug,
]);
?>
