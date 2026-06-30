<?php

// ── Extract user dari request body yang sudah di-parse ────────────────────
// Catatan: PHP hanya bisa baca php://input SEKALI, jadi jangan gunakan 
// function ini di file yang sudah membaca input sebelumnya.
// Gunakan extractUserFromData() dengan passing $data yang sudah di-parse.
function get_user_from_request() {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true) ?? [];
    return $data['user'] ?? null;
}

// ── Extract user dari object/array yang sudah di-parse ────────────────────
// Ini lebih aman untuk digunakan di file yang sudah baca input
function extractUserFromData($data) {
    if (is_object($data)) {
        return isset($data->user) ? (array)$data->user : null;
    }
    if (is_array($data)) {
        return $data['user'] ?? null;
    }
    return null;
}

function check_role($user, $required_role) {
    return $user && isset($user['role']) && $user['role'] === $required_role;
}

function require_auth() {
    $user = get_user_from_request();
    if (!$user) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Unauthorized - user not authenticated']);
        exit;
    }
    return $user;
}

function require_role($required_role) {
    $user = require_auth();
    if (!check_role($user, $required_role)) {
        http_response_code(403);
        echo json_encode(['status' => 'error', 'message' => 'Forbidden - insufficient permissions']);
        exit;
    }
    return $user;
}

?>
