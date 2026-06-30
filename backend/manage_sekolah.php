<?php
header('Content-Type: application/json');
require_once 'config.php';
require_once 'cors.php';

try {
    if (!$conn) {
        http_response_code(500);
        die(json_encode(['status' => 'error', 'message' => 'Database connection failed']));
    }

    $raw       = file_get_contents('php://input');
    $data_json = json_decode($raw, true) ?? [];
    $action    = $data_json['action'] ?? $_POST['action'] ?? $_GET['action'] ?? null;

    // ─────────────────────────────────────────────────────────────
    // GET – Ambil profil sekolah
    // ─────────────────────────────────────────────────────────────
    if ($_SERVER['REQUEST_METHOD'] === 'GET' || $action === 'get') {

        $result = $conn->query("SELECT * FROM sekolah ORDER BY id ASC LIMIT 1");

        if ($result && $result->num_rows > 0) {
            $row = $result->fetch_assoc();

            // ── Hitung jumlah anak dari tabel anak ──────────────
            $resAnak   = $conn->query("SELECT COUNT(*) as total FROM anak");
            $jumlahAnak = ($resAnak) ? (int) $resAnak->fetch_assoc()['total'] : 0;

            // ── Hitung guru dari tabel users WHERE role = 'guru' ──
            // Sesuaikan nilai role dengan yang ada di tabel users kamu
            $resGuru    = $conn->query("SELECT COUNT(*) as total FROM users WHERE role = 'guru'");
            $jumlahGuru = ($resGuru) ? (int) $resGuru->fetch_assoc()['total'] : 0;

            // ── Hitung ortu dari tabel users WHERE role = 'orang_tua' ──
            // Sesuaikan nilai role ('orang_tua', 'ortu', 'parent', dll)
            $resOrtu    = $conn->query("SELECT COUNT(*) as total FROM users WHERE role = 'orang_tua'");
            $jumlahOrtu = ($resOrtu) ? (int) $resOrtu->fetch_assoc()['total'] : 0;

            $normalized = [
                'id'             => $row['id']             ?? null,
                'nama_sekolah'   => $row['nama_sekolah']   ?? '',
                'npsn'           => $row['npsn']           ?? '',
                'jenjang'        => $row['jenjang']        ?? '',
                'status'         => $row['status']         ?? '',
                'akreditasi'     => $row['akreditasi']     ?? '',
                'tahun_berdiri'  => (string)($row['tahun_berdiri'] ?? ''),
                'alamat'         => $row['alamat']         ?? '',
                'kelurahan'      => $row['kelurahan']      ?? '',
                'kecamatan'      => $row['kecamatan']      ?? '',
                'kabupaten'      => ($row['kabupaten'] ?? '') !== ''
                                     ? $row['kabupaten']
                                     : ($row['kota_kabupaten'] ?? ''),
                'provinsi'       => $row['provinsi']       ?? '',
                'kode_pos'       => $row['kode_pos']       ?? '',
                'no_telp'        => ($row['no_telp'] ?? '') !== ''
                                     ? $row['no_telp']
                                     : ($row['telepon'] ?? ''),
                'email'          => $row['email']          ?? '',
                'website'        => $row['website']        ?? '',
                'kepala_sekolah' => $row['kepala_sekolah'] ?? '',
                'operator_nama'  => $row['operator_nama']  ?? '',
                'nip_kepala_sekolah' => $row['nip_kepala_sekolah'] ?? '',
                'visi'           => $row['visi']           ?? '',
                'misi'           => $row['misi']           ?? '',
                'logo_url'       => $row['logo_url']       ?? '',
                'updated_at'     => $row['updated_at']     ?? '',

                // Jumlah dinamis
                'jumlah_anak'    => $jumlahAnak,
                'jumlah_guru'    => $jumlahGuru,
                'jumlah_ortu'    => $jumlahOrtu,
            ];

            http_response_code(200);
            echo json_encode(['status' => 'success', 'data' => $normalized]);

        } else {
            http_response_code(404);
            echo json_encode([
                'status'  => 'error',
                'message' => 'Profil sekolah tidak ditemukan',
                'data'    => null,
            ]);
        }
        exit;
    }

    // ─────────────────────────────────────────────────────────────
    // POST – Buat atau Update profil sekolah
    // ─────────────────────────────────────────────────────────────
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && in_array($action, ['add', 'update'])) {

        $g = function ($key) use ($data_json) {
            return isset($data_json[$key])
                ? trim($data_json[$key])
                : (isset($_POST[$key]) ? trim($_POST[$key]) : '');
        };

        $nama_sekolah   = $g('nama_sekolah');
        $npsn           = $g('npsn');
        $jenjang        = $g('jenjang');
        $status         = $g('status');
        $akreditasi     = $g('akreditasi');
        $tahun_berdiri  = $g('tahun_berdiri');
        $alamat         = $g('alamat');
        $kelurahan      = $g('kelurahan');
        $kecamatan      = $g('kecamatan');
        $kabupaten      = $g('kabupaten') !== '' ? $g('kabupaten') : $g('kota_kabupaten');
        $provinsi       = $g('provinsi');
        $kode_pos       = $g('kode_pos');
        $no_telp        = $g('no_telp') !== '' ? $g('no_telp') : $g('telepon');
        $email          = $g('email');
        $website        = $g('website');
        $kepala_sekolah = $g('kepala_sekolah');
        $operator_nama  = $g('operator_nama');
        $nip_kepala_sekolah = $g('nip_kepala_sekolah');
        $visi           = $g('visi');
        $misi           = $g('misi');
        $logo_url       = $g('logo_url');

        if (empty($nama_sekolah)) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Nama sekolah wajib diisi']);
            exit;
        }

        // Ambil id aktual dari database
        $check   = $conn->query("SELECT id FROM sekolah ORDER BY id ASC LIMIT 1");
        $exists  = ($check && $check->num_rows > 0);
        $existId = $exists ? (int) $check->fetch_assoc()['id'] : null;

        if ($action === 'update' || $exists) {
            // ── UPDATE ────────────────────────────────────────────
            $sql = "UPDATE sekolah SET
                        nama_sekolah   = ?,
                        npsn           = ?,
                        jenjang        = ?,
                        `status`       = ?,
                        akreditasi     = ?,
                        tahun_berdiri  = ?,
                        alamat         = ?,
                        kelurahan      = ?,
                        kecamatan      = ?,
                        kabupaten      = ?,
                        kota_kabupaten = ?,
                        provinsi       = ?,
                        kode_pos       = ?,
                        no_telp        = ?,
                        telepon        = ?,
                        email          = ?,
                        website        = ?,
                        kepala_sekolah = ?,
                        operator_nama  = ?,
                        nip_kepala_sekolah = ?,
                        visi           = ?,
                        misi           = ?,
                        logo_url       = ?,
                        updated_at     = NOW()
                    WHERE id = ?";

            $stmt = $conn->prepare($sql);
            if (!$stmt) {
                http_response_code(500);
                echo json_encode(['status' => 'error', 'message' => 'Prepare gagal: ' . $conn->error]);
                exit;
            }

            $stmt->bind_param(
                'sssssssssssssssssssssssi',
                $nama_sekolah, $npsn, $jenjang, $status, $akreditasi, $tahun_berdiri,
                $alamat, $kelurahan, $kecamatan, $kabupaten, $kabupaten,
                $provinsi, $kode_pos, $no_telp, $no_telp,
                $email, $website, $kepala_sekolah, $operator_nama, $nip_kepala_sekolah,
                $visi, $misi, $logo_url,
                $existId
            );

            if ($stmt->execute()) {
                http_response_code(200);
                echo json_encode(['status' => 'success', 'message' => 'Profil sekolah berhasil diperbarui']);
            } else {
                http_response_code(500);
                echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui: ' . $stmt->error]);
            }
            $stmt->close();

        } else {
            // ── INSERT ────────────────────────────────────────────
            $sql = "INSERT INTO sekolah (
                        nama_sekolah, npsn, jenjang, `status`, akreditasi, tahun_berdiri,
                        alamat, kelurahan, kecamatan, kabupaten, kota_kabupaten,
                        provinsi, kode_pos, no_telp, telepon,
                        email, website, kepala_sekolah, operator_nama, nip_kepala_sekolah,
                        visi, misi, logo_url,
                        created_at, updated_at
                    ) VALUES (
                        ?, ?, ?, ?, ?, ?,
                        ?, ?, ?, ?, ?,
                        ?, ?, ?, ?,
                        ?, ?, ?, ?, ?,
                        ?, ?, ?,
                        NOW(), NOW()
                    )";

            $stmt = $conn->prepare($sql);
            if (!$stmt) {
                http_response_code(500);
                echo json_encode(['status' => 'error', 'message' => 'Prepare gagal: ' . $conn->error]);
                exit;
            }

            $stmt->bind_param(
                'sssssssssssssssssssssss',
                $nama_sekolah, $npsn, $jenjang, $status, $akreditasi, $tahun_berdiri,
                $alamat, $kelurahan, $kecamatan, $kabupaten, $kabupaten,
                $provinsi, $kode_pos, $no_telp, $no_telp,
                $email, $website, $kepala_sekolah, $operator_nama, $nip_kepala_sekolah,
                $visi, $misi, $logo_url
            );

            if ($stmt->execute()) {
                http_response_code(201);
                echo json_encode(['status' => 'success', 'message' => 'Profil sekolah berhasil dibuat']);
            } else {
                http_response_code(500);
                echo json_encode(['status' => 'error', 'message' => 'Gagal membuat profil: ' . $stmt->error]);
            }
            $stmt->close();
        }

        exit;
    }

    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Request tidak valid']);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}

$conn->close();
?>