<?php
/**
 * migrate_schema_v2.php
 * Skrip migrasi untuk menggabungkan tabel:
 * 1. guru & orang_tua -> users
 * 2. penilaian_checklist, anekdot, karya_anak -> penilaian
 * 3. refleksi_guru, refleksi_ortu -> refleksi
 *
 * Jalankan via browser: http://127.0.0.1/monak/backend/migrate_schema_v2.php
 */

header("Content-Type: text/html; charset=UTF-8");
require_once 'config.php';

$results = [];

function logMsg(string $msg, string $type = 'info'): void {
    global $results;
    $prefix = match($type) {
        'success' => '✅ ',
        'error' => '❌ ',
        'warning' => '⚠️ ',
        default => 'ℹ️ '
    };
    $results[] = ["msg" => $prefix . $msg, "type" => $type];
}

function querySilent(mysqli $conn, string $sql): bool {
    try {
        return $conn->query($sql);
    } catch (Throwable $e) {
        return false;
    }
}

// 1. Matikan checks foreign key
$conn->query("SET FOREIGN_KEY_CHECKS = 0");
logMsg("Foreign key checks dinonaktifkan.", 'info');

// ─── TAHAP 1: KONSOLIDASI TABEL USERS ──────────────────────────────────────────
logMsg("Memulai konsolidasi profil guru dan orang tua ke tabel 'users'...", 'info');

// Definisikan kolom tambahan untuk users
$columnsToAdd = [
    'nik'              => "VARCHAR(20) DEFAULT NULL",
    'jenis_kelamin'    => "ENUM('L', 'P') DEFAULT NULL",
    'tempat_lahir'     => "VARCHAR(100) DEFAULT NULL",
    'tanggal_lahir'    => "DATE DEFAULT NULL",
    'agama'            => "VARCHAR(30) DEFAULT NULL",
    'status_nikah'     => "ENUM('Belum Menikah','Menikah','Cerai') DEFAULT NULL",
    'status_kepeg'     => "ENUM('PNS','PPPK','Honorer','GTT','PTT') DEFAULT NULL",
    'jabatan'          => "VARCHAR(100) DEFAULT NULL",
    'pendidikan'       => "ENUM('SMA/SMK','D3','S1','S2','S3') DEFAULT NULL",
    'jurusan'          => "VARCHAR(100) DEFAULT NULL",
    'tahun_mulai'      => "YEAR DEFAULT NULL",
    'no_hp'            => "VARCHAR(20) DEFAULT NULL",
    'no_telp'          => "VARCHAR(20) DEFAULT NULL",
    'email_guru'       => "VARCHAR(100) DEFAULT NULL",
    'alamat'           => "TEXT DEFAULT NULL",
    'id_kelas'         => "INT DEFAULT NULL",
    'pekerjaan'        => "VARCHAR(100) DEFAULT NULL",
    // Data Ayah
    'ayah_nama'        => "VARCHAR(100) DEFAULT NULL",
    'ayah_nik'         => "VARCHAR(20) DEFAULT NULL",
    'ayah_ttl'         => "VARCHAR(100) DEFAULT NULL",
    'ayah_agama'       => "VARCHAR(30) DEFAULT NULL",
    'ayah_pendidikan'  => "VARCHAR(50) DEFAULT NULL",
    'ayah_pekerjaan'   => "VARCHAR(100) DEFAULT NULL",
    'ayah_penghasilan' => "VARCHAR(50) DEFAULT NULL",
    'ayah_hp'          => "VARCHAR(20) DEFAULT NULL",
    'ayah_status'      => "VARCHAR(20) DEFAULT 'Hidup'",
    // Data Ibu
    'ibu_nama'         => "VARCHAR(100) DEFAULT NULL",
    'ibu_nik'          => "VARCHAR(20) DEFAULT NULL",
    'ibu_ttl'          => "VARCHAR(100) DEFAULT NULL",
    'ibu_agama'        => "VARCHAR(30) DEFAULT NULL",
    'ibu_pendidikan'   => "VARCHAR(50) DEFAULT NULL",
    'ibu_pekerjaan'    => "VARCHAR(100) DEFAULT NULL",
    'ibu_penghasilan'  => "VARCHAR(50) DEFAULT NULL",
    'ibu_hp'           => "VARCHAR(20) DEFAULT NULL",
    'ibu_status'       => "VARCHAR(20) DEFAULT 'Hidup'",
    // Data Wali
    'wali_nama'        => "VARCHAR(100) DEFAULT NULL",
    'wali_hubungan'    => "VARCHAR(50) DEFAULT NULL",
    'wali_pekerjaan'   => "VARCHAR(100) DEFAULT NULL",
    'wali_hp'          => "VARCHAR(20) DEFAULT NULL",
    // Alamat Detail
    'rt_rw'            => "VARCHAR(20) DEFAULT NULL",
    'kelurahan'        => "VARCHAR(100) DEFAULT NULL",
    'kecamatan'        => "VARCHAR(100) DEFAULT NULL",
    'kota'             => "VARCHAR(100) DEFAULT NULL",
    'provinsi'         => "VARCHAR(100) DEFAULT NULL",
    'kode_pos'         => "VARCHAR(10) DEFAULT NULL"
];

foreach ($columnsToAdd as $col => $def) {
    $check = $conn->query("SHOW COLUMNS FROM `users` LIKE '$col'");
    if ($check && $check->num_rows === 0) {
        if ($conn->query("ALTER TABLE `users` ADD COLUMN `$col` $def")) {
            logMsg("Kolom `users`.`$col` berhasil ditambahkan.", 'success');
        } else {
            logMsg("Gagal menambahkan `users`.`$col`: " . $conn->error, 'error');
        }
    } else {
        logMsg("Kolom `users`.`$col` sudah ada.", 'info');
    }
}

// Salin data dari guru ke users jika tabel guru masih ada
$checkGuruTable = $conn->query("SHOW TABLES LIKE 'guru'");
if ($checkGuruTable && $checkGuruTable->num_rows > 0) {
    $sqlMigrateGuru = "UPDATE users u 
                       JOIN guru g ON u.id = g.id_user 
                       SET u.nik = IFNULL(u.nik, g.nik),
                           u.jenis_kelamin = IFNULL(u.jenis_kelamin, g.jenis_kelamin),
                           u.tempat_lahir = IFNULL(u.tempat_lahir, g.tempat_lahir),
                           u.tanggal_lahir = IFNULL(u.tanggal_lahir, g.tanggal_lahir),
                           u.agama = IFNULL(u.agama, g.agama),
                           u.status_nikah = IFNULL(u.status_nikah, g.status_nikah),
                           u.status_kepeg = IFNULL(u.status_kepeg, g.status_kepeg),
                           u.jabatan = IFNULL(u.jabatan, g.jabatan),
                           u.pendidikan = IFNULL(u.pendidikan, g.pendidikan),
                           u.jurusan = IFNULL(u.jurusan, g.jurusan),
                           u.tahun_mulai = IFNULL(u.tahun_mulai, g.tahun_mulai),
                           u.no_telp = IFNULL(u.no_telp, g.no_telp),
                           u.email_guru = IFNULL(u.email_guru, g.email_guru),
                           u.alamat = IFNULL(u.alamat, g.alamat),
                           u.id_kelas = IFNULL(u.id_kelas, g.id_kelas)";
    if ($conn->query($sqlMigrateGuru)) {
        logMsg("Data dari tabel 'guru' berhasil dipindahkan ke 'users'.", 'success');
    } else {
        logMsg("Gagal memindahkan data 'guru': " . $conn->error, 'error');
    }
} else {
    logMsg("Tabel 'guru' tidak ditemukan atau sudah dipindahkan sebelumnya.", 'warning');
}

// Salin data dari orang_tua ke users jika tabel orang_tua masih ada
$checkOrtuTable = $conn->query("SHOW TABLES LIKE 'orang_tua'");
if ($checkOrtuTable && $checkOrtuTable->num_rows > 0) {
    $sqlMigrateOrtu = "UPDATE users u 
                       JOIN orang_tua o ON u.id = o.id_user 
                       SET u.no_hp = IFNULL(u.no_hp, o.no_hp),
                           u.no_telp = IFNULL(u.no_telp, o.no_hp),
                           u.pekerjaan = IFNULL(u.pekerjaan, o.pekerjaan),
                           u.alamat = IFNULL(u.alamat, o.alamat),
                           u.ayah_nama = IFNULL(u.ayah_nama, o.ayah_nama),
                           u.ayah_nik = IFNULL(u.ayah_nik, o.ayah_nik),
                           u.ayah_ttl = IFNULL(u.ayah_ttl, o.ayah_ttl),
                           u.ayah_agama = IFNULL(u.ayah_agama, o.ayah_agama),
                           u.ayah_pendidikan = IFNULL(u.ayah_pendidikan, o.ayah_pendidikan),
                           u.ayah_pekerjaan = IFNULL(u.ayah_pekerjaan, o.ayah_pekerjaan),
                           u.ayah_penghasilan = IFNULL(u.ayah_penghasilan, o.ayah_penghasilan),
                           u.ayah_hp = IFNULL(u.ayah_hp, o.ayah_hp),
                           u.ayah_status = IFNULL(u.ayah_status, o.ayah_status),
                           u.ibu_nama = IFNULL(u.ibu_nama, o.ibu_nama),
                           u.ibu_nik = IFNULL(u.ibu_nik, o.ibu_nik),
                           u.ibu_ttl = IFNULL(u.ibu_ttl, o.ibu_ttl),
                           u.ibu_agama = IFNULL(u.ibu_agama, o.ibu_agama),
                           u.ibu_pendidikan = IFNULL(u.ibu_pendidikan, o.ibu_pendidikan),
                           u.ibu_pekerjaan = IFNULL(u.ibu_pekerjaan, o.ibu_pekerjaan),
                           u.ibu_penghasilan = IFNULL(u.ibu_penghasilan, o.ibu_penghasilan),
                           u.ibu_hp = IFNULL(u.ibu_hp, o.ibu_hp),
                           u.ibu_status = IFNULL(u.ibu_status, o.ibu_status),
                           u.wali_nama = IFNULL(u.wali_nama, o.wali_nama),
                           u.wali_hubungan = IFNULL(u.wali_hubungan, o.wali_hubungan),
                           u.wali_pekerjaan = IFNULL(u.wali_pekerjaan, o.wali_pekerjaan),
                           u.wali_hp = IFNULL(u.wali_hp, o.wali_hp),
                           u.rt_rw = IFNULL(u.rt_rw, o.rt_rw),
                           u.kelurahan = IFNULL(u.kelurahan, o.kelurahan),
                           u.kecamatan = IFNULL(u.kecamatan, o.kecamatan),
                           u.kota = IFNULL(u.kota, o.kota),
                           u.provinsi = IFNULL(u.provinsi, o.provinsi),
                           u.kode_pos = IFNULL(u.kode_pos, o.kode_pos)";
    if ($conn->query($sqlMigrateOrtu)) {
        logMsg("Data dari tabel 'orang_tua' berhasil dipindahkan ke 'users'.", 'success');
    } else {
        logMsg("Gagal memindahkan data 'orang_tua': " . $conn->error, 'error');
    }
} else {
    logMsg("Tabel 'orang_tua' tidak ditemukan atau sudah dipindahkan sebelumnya.", 'warning');
}


// ─── TAHAP 2: PEMBUATAN TABEL PENILAIAN & MIGRASI DATA ───────────────────────
logMsg("Membuat tabel baru 'penilaian'...", 'info');
// Hapus tabel penilaian jika ada (untuk membersihkan run sebelumnya yang gagal)
$conn->query("DROP TABLE IF EXISTS penilaian");

$sqlCreatePenilaian = "
    CREATE TABLE IF NOT EXISTS penilaian (
        id INT AUTO_INCREMENT PRIMARY KEY,
        tipe ENUM('checklist', 'anekdot', 'karya') NOT NULL,
        id_anak INT NOT NULL,
        id_guru INT NOT NULL, -- merujuk langsung ke users.id
        tanggal DATE NOT NULL,
        
        -- Khusus Checklist
        id_aspek INT DEFAULT NULL,
        id_tujuan INT DEFAULT NULL,
        id_kegiatan INT DEFAULT NULL,
        status ENUM('TM', 'MM', 'M') DEFAULT NULL,
        catatan TEXT DEFAULT NULL,
        konteks TEXT DEFAULT NULL,
        hasil TEXT DEFAULT NULL,
        kejadian TEXT DEFAULT NULL,
        
        -- Khusus Anekdot
        waktu TIME DEFAULT NULL,
        lokasi VARCHAR(255) DEFAULT NULL,
        aspek_perkembangan VARCHAR(100) DEFAULT NULL,
        peristiwa TEXT DEFAULT NULL,
        interpretasi TEXT DEFAULT NULL,
        tindak_lanjut TEXT DEFAULT NULL,
        
        -- Khusus Karya
        waktu_kegiatan TIME DEFAULT NULL,
        kategori VARCHAR(50) DEFAULT NULL,
        judul VARCHAR(255) DEFAULT NULL,
        deskripsi TEXT DEFAULT NULL,
        bahan TEXT DEFAULT NULL,
        url_foto VARCHAR(255) DEFAULT NULL,
        catatan_guru TEXT DEFAULT NULL,
        
        -- Metadata Bersama
        semester TINYINT DEFAULT 1,
        minggu_ke TINYINT DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        
        FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
        FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (id_aspek) REFERENCES aspek_penilaian(id) ON DELETE SET NULL,
        FOREIGN KEY (id_tujuan) REFERENCES tujuan_pembelajaran(id) ON DELETE SET NULL,
        FOREIGN KEY (id_kegiatan) REFERENCES kegiatan_pembelajaran(id) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

if ($conn->query($sqlCreatePenilaian)) {
    logMsg("Tabel 'penilaian' berhasil dibuat.", 'success');
} else {
    logMsg("Gagal membuat tabel 'penilaian': " . $conn->error, 'error');
}

// Migrasi data penilaian_checklist
$checkPC = $conn->query("SHOW TABLES LIKE 'penilaian_checklist'");
if ($checkPC && $checkPC->num_rows > 0) {
    // Pastikan data belum termigrasi
    $cnt = $conn->query("SELECT COUNT(*) as c FROM penilaian WHERE tipe = 'checklist'")->fetch_assoc()['c'];
    if ($cnt == 0) {
        $sqlMigrateChecklist = "
            INSERT INTO penilaian (tipe, id_anak, id_guru, tanggal, id_aspek, id_tujuan, id_kegiatan, status, catatan, konteks, hasil, kejadian, semester, minggu_ke, created_at)
            SELECT 'checklist', pc.id_anak, g.id_user, pc.tanggal, pc.id_aspek, pc.id_tujuan, pc.id_kegiatan, pc.status, pc.catatan, pc.konteks, pc.hasil, pc.kejadian, pc.semester, pc.minggu_ke, pc.created_at
            FROM penilaian_checklist pc
            JOIN guru g ON pc.id_guru = g.id
        ";
        if ($conn->query($sqlMigrateChecklist)) {
            logMsg("Data 'penilaian_checklist' berhasil dimigrasi ke 'penilaian'.", 'success');
        } else {
            logMsg("Gagal memigrasi data 'penilaian_checklist': " . $conn->error, 'error');
        }
    } else {
        logMsg("Data 'penilaian_checklist' sudah pernah dimigrasi sebelumnya.", 'info');
    }
}

// Migrasi data anekdot
$checkAnekdot = $conn->query("SHOW TABLES LIKE 'anekdot'");
if ($checkAnekdot && $checkAnekdot->num_rows > 0) {
    $cnt = $conn->query("SELECT COUNT(*) as c FROM penilaian WHERE tipe = 'anekdot'")->fetch_assoc()['c'];
    if ($cnt == 0) {
        $sqlMigrateAnekdot = "
            INSERT INTO penilaian (tipe, id_anak, id_guru, tanggal, waktu, lokasi, aspek_perkembangan, peristiwa, interpretasi, tindak_lanjut)
            SELECT 'anekdot', a.id_anak, g.id_user, a.tanggal, a.waktu, a.lokasi, a.aspek_perkembangan, a.peristiwa, a.interpretasi, a.tindak_lanjut
            FROM anekdot a
            JOIN guru g ON a.id_guru = g.id
        ";
        if ($conn->query($sqlMigrateAnekdot)) {
            logMsg("Data 'anekdot' berhasil dimigrasi ke 'penilaian'.", 'success');
        } else {
            logMsg("Gagal memigrasi data 'anekdot': " . $conn->error, 'error');
        }
    } else {
        logMsg("Data 'anekdot' sudah pernah dimigrasi sebelumnya.", 'info');
    }
}

// Migrasi data karya_anak
$checkKarya = $conn->query("SHOW TABLES LIKE 'karya_anak'");
if ($checkKarya && $checkKarya->num_rows > 0) {
    $cnt = $conn->query("SELECT COUNT(*) as c FROM penilaian WHERE tipe = 'karya'")->fetch_assoc()['c'];
    if ($cnt == 0) {
        $sqlMigrateKarya = "
            INSERT INTO penilaian (tipe, id_anak, id_guru, tanggal, waktu_kegiatan, kategori, judul, deskripsi, bahan, url_foto, catatan_guru)
            SELECT 'karya', k.id_anak, g.id_user, k.tanggal, k.waktu_kegiatan, k.kategori, k.judul, k.deskripsi, k.bahan, k.url_foto, k.catatan_guru
            FROM karya_anak k
            JOIN guru g ON k.id_guru = g.id
        ";
        if ($conn->query($sqlMigrateKarya)) {
            logMsg("Data 'karya_anak' berhasil dimigrasi ke 'penilaian'.", 'success');
        } else {
            logMsg("Gagal memigrasi data 'karya_anak': " . $conn->error, 'error');
        }
    } else {
        logMsg("Data 'karya_anak' sudah pernah dimigrasi sebelumnya.", 'info');
    }
}


// ─── TAHAP 3: PEMBUATAN TABEL REFLEKSI & MIGRASI DATA ────────────────────────
logMsg("Membuat tabel baru 'refleksi'...", 'info');
$conn->query("DROP TABLE IF EXISTS refleksi");

$sqlCreateRefleksi = "
    CREATE TABLE IF NOT EXISTS refleksi (
        id INT AUTO_INCREMENT PRIMARY KEY,
        tipe ENUM('guru', 'orang_tua') NOT NULL,
        id_user INT NOT NULL, -- merujuk langsung ke users.id
        id_anak INT DEFAULT NULL,
        id_kelas INT DEFAULT NULL,
        semester TINYINT DEFAULT 1,
        minggu_ke TINYINT DEFAULT 1,
        bulan TINYINT DEFAULT 1,
        tanggal DATE DEFAULT NULL,
        
        -- Khusus Orang Tua
        judul VARCHAR(200) DEFAULT NULL,
        isi TEXT DEFAULT NULL,
        
        -- Khusus Guru
        pencapaian TEXT DEFAULT NULL,
        hambatan TEXT DEFAULT NULL,
        solusi TEXT DEFAULT NULL,
        rencana_tindak_lanjut TEXT DEFAULT NULL,
        catatan_perilaku TEXT DEFAULT NULL,
        catatan_pembelajaran TEXT DEFAULT NULL,
        catatan_sosial TEXT DEFAULT NULL,
        kinerja_guru ENUM('sangat_baik', 'baik', 'cukup', 'kurang') DEFAULT NULL,
        kehadiran_guru TINYINT DEFAULT 0,
        kesiapan_materi ENUM('siap', 'cukup_siap', 'belum_siap') DEFAULT NULL,
        
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        
        FOREIGN KEY (id_user) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (id_anak) REFERENCES anak(id) ON DELETE CASCADE,
        FOREIGN KEY (id_kelas) REFERENCES kelas(id) ON DELETE SET NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

if ($conn->query($sqlCreateRefleksi)) {
    logMsg("Tabel 'refleksi' berhasil dibuat.", 'success');
} else {
    logMsg("Gagal membuat tabel 'refleksi': " . $conn->error, 'error');
}

// Migrasi data refleksi_guru
$checkRefleksiGuru = $conn->query("SHOW TABLES LIKE 'refleksi_guru'");
if ($checkRefleksiGuru && $checkRefleksiGuru->num_rows > 0) {
    $cnt = $conn->query("SELECT COUNT(*) as c FROM refleksi WHERE tipe = 'guru'")->fetch_assoc()['c'];
    if ($cnt == 0) {
        $sqlMigrateRefGuru = "
            INSERT INTO refleksi (tipe, id_user, id_kelas, id_anak, semester, minggu_ke, tanggal, pencapaian, hambatan, solusi, rencana_tindak_lanjut, catatan_perilaku, catatan_pembelajaran, catatan_sosial, kinerja_guru, kehadiran_guru, kesiapan_materi, created_at, updated_at)
            SELECT 'guru', g.id_user, rg.id_kelas, rg.id_anak, rg.semester, rg.minggu_ke, rg.tanggal, rg.pencapaian, rg.hambatan, rg.solusi, rg.rencana_tindak_lanjut, rg.catatan_perilaku, rg.catatan_pembelajaran, rg.catatan_sosial, rg.kinerja_guru, rg.kehadiran_guru, rg.kesiapan_materi, rg.created_at, rg.updated_at
            FROM refleksi_guru rg
            JOIN guru g ON rg.id_guru = g.id
        ";
        if ($conn->query($sqlMigrateRefGuru)) {
            logMsg("Data 'refleksi_guru' berhasil dimigrasi ke 'refleksi'.", 'success');
        } else {
            logMsg("Gagal memigrasi data 'refleksi_guru': " . $conn->error, 'error');
        }
    } else {
        logMsg("Data 'refleksi_guru' sudah pernah dimigrasi sebelumnya.", 'info');
    }
}

// Migrasi data refleksi_ortu
$checkRefleksiOrtu = $conn->query("SHOW TABLES LIKE 'refleksi_ortu'");
if ($checkRefleksiOrtu && $checkRefleksiOrtu->num_rows > 0) {
    $cnt = $conn->query("SELECT COUNT(*) as c FROM refleksi WHERE tipe = 'orang_tua'")->fetch_assoc()['c'];
    if ($cnt == 0) {
        $sqlMigrateRefOrtu = "
            INSERT INTO refleksi (tipe, id_user, id_anak, semester, bulan, judul, isi, created_at, updated_at)
            SELECT 'orang_tua', o.id_user, ro.id_anak, ro.semester, ro.bulan, ro.judul, ro.isi, ro.created_at, ro.updated_at
            FROM refleksi_ortu ro
            JOIN orang_tua o ON ro.id_ortu = o.id
        ";
        if ($conn->query($sqlMigrateRefOrtu)) {
            logMsg("Data 'refleksi_ortu' berhasil dimigrasi ke 'refleksi'.", 'success');
        } else {
            logMsg("Gagal memigrasi data 'refleksi_ortu': " . $conn->error, 'error');
        }
    } else {
        logMsg("Data 'refleksi_ortu' sudah pernah dimigrasi sebelumnya.", 'info');
    }
}


// ─── TAHAP 4: PEMETAAN ULANG FOREIGN KEYS ─────────────────────────────────────
logMsg("Memetakan ulang referensi foreign keys ke tabel 'users'...", 'info');

// 1. Update tabel anak (id_ortu lama merujuk orang_tua.id -> ubah ke users.id)
if ($checkOrtuTable && $checkOrtuTable->num_rows > 0) {
    $conn->query("
        UPDATE anak a
        JOIN orang_tua o ON a.id_ortu = o.id
        SET a.id_ortu = o.id_user
    ");
    logMsg("Referensi id_ortu di tabel 'anak' berhasil diperbarui ke users.id.", 'success');
}

// Drop & Recreate FK on anak
// Cari nama constraint
$resFK = $conn->query("
    SELECT CONSTRAINT_NAME 
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'monak_db' 
      AND TABLE_NAME = 'anak' 
      AND COLUMN_NAME = 'id_ortu' 
      AND REFERENCED_TABLE_NAME = 'orang_tua'
");
if ($resFK && $row = $resFK->fetch_assoc()) {
    querySilent($conn, "ALTER TABLE anak DROP FOREIGN KEY " . $row['CONSTRAINT_NAME']);
}
// Selalu hapus fk_anak_ortu_users jika sudah ada
querySilent($conn, "ALTER TABLE anak DROP FOREIGN KEY fk_anak_ortu_users");
$conn->query("ALTER TABLE anak ADD CONSTRAINT fk_anak_ortu_users FOREIGN KEY (id_ortu) REFERENCES users(id) ON DELETE SET NULL");

// 2. Update tabel absensi (id_guru lama merujuk guru.id -> ubah ke users.id)
if ($checkGuruTable && $checkGuruTable->num_rows > 0) {
    $conn->query("
        UPDATE absensi ab
        JOIN guru g ON ab.id_guru = g.id
        SET ab.id_guru = g.id_user
    ");
    logMsg("Referensi id_guru di tabel 'absensi' berhasil diperbarui ke users.id.", 'success');
}
// Re-bind constraint absensi
$resFK = $conn->query("
    SELECT CONSTRAINT_NAME 
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'monak_db' 
      AND TABLE_NAME = 'absensi' 
      AND COLUMN_NAME = 'id_guru' 
      AND REFERENCED_TABLE_NAME = 'guru'
");
if ($resFK && $row = $resFK->fetch_assoc()) {
    querySilent($conn, "ALTER TABLE absensi DROP FOREIGN KEY " . $row['CONSTRAINT_NAME']);
}
querySilent($conn, "ALTER TABLE absensi DROP FOREIGN KEY fk_absensi_guru_users");
$conn->query("ALTER TABLE absensi ADD CONSTRAINT fk_absensi_guru_users FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE");

// 3. Update tabel anak_ekstrakurikuler
if ($checkGuruTable && $checkGuruTable->num_rows > 0) {
    $conn->query("
        UPDATE anak_ekstrakurikuler ae
        JOIN guru g ON ae.id_guru = g.id
        SET ae.id_guru = g.id_user
    ");
    logMsg("Referensi id_guru di tabel 'anak_ekstrakurikuler' berhasil diperbarui ke users.id.", 'success');
}
$resFK = $conn->query("
    SELECT CONSTRAINT_NAME 
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'monak_db' 
      AND TABLE_NAME = 'anak_ekstrakurikuler' 
      AND COLUMN_NAME = 'id_guru' 
      AND REFERENCED_TABLE_NAME = 'guru'
");
if ($resFK && $row = $resFK->fetch_assoc()) {
    querySilent($conn, "ALTER TABLE anak_ekstrakurikuler DROP FOREIGN KEY " . $row['CONSTRAINT_NAME']);
}
querySilent($conn, "ALTER TABLE anak_ekstrakurikuler DROP FOREIGN KEY fk_ekskul_guru_users");
$conn->query("ALTER TABLE anak_ekstrakurikuler ADD CONSTRAINT fk_ekskul_guru_users FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE");

// 4. Update tabel jadwal_kelas
if ($checkGuruTable && $checkGuruTable->num_rows > 0) {
    $conn->query("
        UPDATE jadwal_kelas jk
        JOIN guru g ON jk.id_guru = g.id
        SET jk.id_guru = g.id_user
    ");
    logMsg("Referensi id_guru di tabel 'jadwal_kelas' berhasil diperbarui ke users.id.", 'success');
}
$resFK = $conn->query("
    SELECT CONSTRAINT_NAME 
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'monak_db' 
      AND TABLE_NAME = 'jadwal_kelas' 
      AND COLUMN_NAME = 'id_guru' 
      AND REFERENCED_TABLE_NAME = 'guru'
");
if ($resFK && $row = $resFK->fetch_assoc()) {
    querySilent($conn, "ALTER TABLE jadwal_kelas DROP FOREIGN KEY " . $row['CONSTRAINT_NAME']);
}
querySilent($conn, "ALTER TABLE jadwal_kelas DROP FOREIGN KEY fk_jadwal_guru_users");
$conn->query("ALTER TABLE jadwal_kelas ADD CONSTRAINT fk_jadwal_guru_users FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE");

// 5. Update tabel rekap_penilaian_bulanan
if ($checkGuruTable && $checkGuruTable->num_rows > 0) {
    $conn->query("
        UPDATE rekap_penilaian_bulanan rp
        JOIN guru g ON rp.id_guru = g.id
        SET rp.id_guru = g.id_user
    ");
    logMsg("Referensi id_guru di tabel 'rekap_penilaian_bulanan' berhasil diperbarui ke users.id.", 'success');
}
$resFK = $conn->query("
    SELECT CONSTRAINT_NAME 
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'monak_db' 
      AND TABLE_NAME = 'rekap_penilaian_bulanan' 
      AND COLUMN_NAME = 'id_guru' 
      AND REFERENCED_TABLE_NAME = 'guru'
");
if ($resFK && $row = $resFK->fetch_assoc()) {
    querySilent($conn, "ALTER TABLE rekap_penilaian_bulanan DROP FOREIGN KEY " . $row['CONSTRAINT_NAME']);
}
querySilent($conn, "ALTER TABLE rekap_penilaian_bulanan DROP FOREIGN KEY fk_rekap_pen_guru_users");
$conn->query("ALTER TABLE rekap_penilaian_bulanan ADD CONSTRAINT fk_rekap_pen_guru_users FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE");

// 6. Update tabel rekap_aspek_bulanan
if ($checkGuruTable && $checkGuruTable->num_rows > 0) {
    $conn->query("
        UPDATE rekap_aspek_bulanan ra
        JOIN guru g ON ra.id_guru = g.id
        SET ra.id_guru = g.id_user
    ");
    logMsg("Referensi id_guru di tabel 'rekap_aspek_bulanan' berhasil diperbarui ke users.id.", 'success');
}
$resFK = $conn->query("
    SELECT CONSTRAINT_NAME 
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'monak_db' 
      AND TABLE_NAME = 'rekap_aspek_bulanan' 
      AND COLUMN_NAME = 'id_guru' 
      AND REFERENCED_TABLE_NAME = 'guru'
");
if ($resFK && $row = $resFK->fetch_assoc()) {
    querySilent($conn, "ALTER TABLE rekap_aspek_bulanan DROP FOREIGN KEY " . $row['CONSTRAINT_NAME']);
}
querySilent($conn, "ALTER TABLE rekap_aspek_bulanan DROP FOREIGN KEY fk_rekap_asp_guru_users");
$conn->query("ALTER TABLE rekap_aspek_bulanan ADD CONSTRAINT fk_rekap_asp_guru_users FOREIGN KEY (id_guru) REFERENCES users(id) ON DELETE CASCADE");


// ─── TAHAP 5: HAPUS TABEL LAMA ────────────────────────────────────────────────
logMsg("Membersihkan tabel lama yang sudah digabung...", 'info');
$oldTables = ['guru', 'orang_tua', 'penilaian_checklist', 'anekdot', 'karya_anak', 'refleksi_guru', 'refleksi_ortu'];
foreach ($oldTables as $tbl) {
    $checkTbl = $conn->query("SHOW TABLES LIKE '$tbl'");
    if ($checkTbl && $checkTbl->num_rows > 0) {
        if ($conn->query("DROP TABLE `$tbl`")) {
            logMsg("Tabel lama '$tbl' berhasil dihapus.", 'success');
        } else {
            logMsg("Gagal menghapus tabel '$tbl': " . $conn->error, 'error');
        }
    } else {
        logMsg("Tabel lama '$tbl' sudah terhapus/bersih.", 'info');
    }
}

// 6. Aktifkan kembali checks foreign key
$conn->query("SET FOREIGN_KEY_CHECKS = 1");
logMsg("Foreign key checks diaktifkan kembali.", 'info');

logMsg("Seluruh proses migrasi database selesai!", 'success');
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Migrasi Database V2 — monak</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background:#121214; color:#e1e1e6; padding:40px; line-height: 1.6; }
        .container { max-width: 800px; margin: 0 auto; background: #202024; padding: 30px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.3); }
        h2   { color:#04d361; border-bottom: 1px solid #29292e; padding-bottom: 15px; margin-top: 0; }
        ul   { list-style: none; padding: 0; }
        li   { padding: 8px 12px; border-radius: 6px; margin-bottom: 8px; font-size: 14px; font-family: monospace; }
        .info { background: #29292e; color: #a8a8b3; }
        .success { background: rgba(4, 211, 97, 0.1); color: #04d361; border: 1px solid rgba(4, 211, 97, 0.2); }
        .error { background: rgba(223, 71, 71, 0.1); color: #df4747; border: 1px solid rgba(223, 71, 71, 0.2); }
        .warning { background: rgba(240, 165, 0, 0.1); color: #f0a500; border: 1px solid rgba(240, 165, 0, 0.2); }
    </style>
</head>
<body>
<div class="container">
    <h2>🔧 Hasil Migrasi Database V2 — monak</h2>
    <ul>
    <?php foreach ($results as $r): ?>
        <li class="<?= $r['type'] ?>">
            <?= htmlspecialchars($r['msg']) ?>
        </li>
    <?php endforeach; ?>
    </ul>
    <p style="margin-top: 30px; text-align: center; color: #a8a8b3;">Anda sekarang dapat menutup halaman ini dan kembali ke terminal/editor.</p>
</div>
</body>
</html>
