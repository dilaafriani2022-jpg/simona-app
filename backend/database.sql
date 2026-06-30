-- Create Database
CREATE DATABASE IF NOT EXISTS monak_db;
USE monak_db;

-- ════════════════════════════════════════════════════════════════════
-- Users Table (Operator, Guru, Kepsek, Orang Tua)
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS users (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    name             VARCHAR(100) NOT NULL,
    role             ENUM('operator', 'kepsek', 'guru', 'orang_tua') NOT NULL,
    username         VARCHAR(50) UNIQUE,       -- Operator
    nip              VARCHAR(20) UNIQUE,       -- Guru
    nisn             VARCHAR(20) UNIQUE,       -- Orang Tua (NISN anak, legacy)
    email            VARCHAR(100) UNIQUE,
    password         VARCHAR(255) NOT NULL,
    -- Timestamps
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ════════════════════════════════════════════════════════════════════
-- Guru Table (Profile)
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS guru (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_user INT NOT NULL,
    nama VARCHAR(100) NOT NULL,
    nip VARCHAR(20) UNIQUE DEFAULT NULL,
    nik VARCHAR(20) DEFAULT NULL,
    jenis_kelamin ENUM('L', 'P') DEFAULT NULL,
    tempat_lahir VARCHAR(100) DEFAULT NULL,
    tanggal_lahir DATE DEFAULT NULL,
    agama VARCHAR(30) DEFAULT NULL,
    status_nikah ENUM('Belum Menikah','Menikah','Cerai') DEFAULT NULL,
    status_kepeg ENUM('PNS','PPPK','Honorer','GTT','PTT') DEFAULT NULL,
    jabatan VARCHAR(100) DEFAULT NULL,
    pendidikan ENUM('SMA/SMK','D3','S1','S2','S3') DEFAULT NULL,
    jurusan VARCHAR(100) DEFAULT NULL,
    tahun_mulai YEAR DEFAULT NULL,
    no_telp VARCHAR(20) DEFAULT NULL,
    email_guru VARCHAR(100) DEFAULT NULL,
    alamat TEXT DEFAULT NULL,
    id_kelas INT DEFAULT NULL,
    FOREIGN KEY (id_user) REFERENCES users(id) ON DELETE CASCADE
);

-- ════════════════════════════════════════════════════════════════════
-- Orang Tua Table (Profile)
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS orang_tua (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_user INT NOT NULL,
    nama VARCHAR(100) NOT NULL,
    no_hp VARCHAR(20) DEFAULT NULL,
    pekerjaan VARCHAR(100) DEFAULT NULL,
    alamat TEXT DEFAULT NULL,
    -- Data Ayah
    ayah_nama VARCHAR(100) DEFAULT NULL,
    ayah_nik VARCHAR(20)  DEFAULT NULL,
    ayah_ttl VARCHAR(100) DEFAULT NULL,
    ayah_agama VARCHAR(30)  DEFAULT NULL,
    ayah_pendidikan VARCHAR(50)  DEFAULT NULL,
    ayah_pekerjaan VARCHAR(100) DEFAULT NULL,
    ayah_penghasilan VARCHAR(50)  DEFAULT NULL,
    ayah_hp          VARCHAR(20)  DEFAULT NULL,
    ayah_status      VARCHAR(20)  DEFAULT 'Hidup',
    -- Data Ibu
    ibu_nama         VARCHAR(100) DEFAULT NULL,
    ibu_nik          VARCHAR(20)  DEFAULT NULL,
    ibu_ttl          VARCHAR(100) DEFAULT NULL,
    ibu_agama        VARCHAR(30)  DEFAULT NULL,
    ibu_pendidikan   VARCHAR(50)  DEFAULT NULL,
    ibu_pekerjaan    VARCHAR(100) DEFAULT NULL,
    ibu_penghasilan  VARCHAR(50)  DEFAULT NULL,
    ibu_hp           VARCHAR(20)  DEFAULT NULL,
    ibu_status       VARCHAR(20)  DEFAULT 'Hidup',
    -- Data Wali
    wali_nama        VARCHAR(100) DEFAULT NULL,
    wali_hubungan    VARCHAR(50)  DEFAULT NULL,
    wali_pekerjaan   VARCHAR(100) DEFAULT NULL,
    wali_hp          VARCHAR(20)  DEFAULT NULL,
    -- Alamat detail
    rt_rw            VARCHAR(20)  DEFAULT NULL,
    kelurahan        VARCHAR(100) DEFAULT NULL,
    kecamatan        VARCHAR(100) DEFAULT NULL,
    kota             VARCHAR(100) DEFAULT NULL,
    provinsi         VARCHAR(100) DEFAULT NULL,
    kode_pos         VARCHAR(10)  DEFAULT NULL,
    FOREIGN KEY (id_user) REFERENCES users(id) ON DELETE CASCADE
);

-- Seed Data Users
INSERT IGNORE INTO users (id, name, role, username, password) VALUES
    (1, 'Admin Operator', 'operator', 'admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

INSERT IGNORE INTO users (id, name, role, nip, password) VALUES
    (2, 'Budi Santoso', 'guru', '123456789', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

INSERT IGNORE INTO users (id, name, role, email, password) VALUES
    (3, 'H. Ahmad', 'kepsek', 'kepsek@school.id', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

INSERT IGNORE INTO users (id, name, role, nisn, email, password) VALUES
    (4, 'Wali Murid Ani', 'orang_tua', '9988776655', 'ani@mail.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');

-- Seed Data Profiles
INSERT IGNORE INTO guru (id, id_user, nama, nip) VALUES
    (1, 2, 'Budi Santoso', '123456789');

INSERT IGNORE INTO orang_tua (id, id_user, nama, no_hp, pekerjaan, alamat, ayah_nama, ayah_status, ibu_nama, ibu_status) VALUES
    (1, 4, 'Wali Murid Ani', '08123456789', 'Wiraswasta', 'Jl. Merdeka No.1', 'Bapak Andi', 'Hidup', 'Ibu Sari', 'Hidup');

-- ════════════════════════════════════════════════════════════════════
-- Tahun Ajaran
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tahun_ajaran (
    id     INT AUTO_INCREMENT PRIMARY KEY,
    tahun  VARCHAR(20) NOT NULL,
    status ENUM('aktif', 'nonaktif') DEFAULT 'aktif'
);

INSERT IGNORE INTO tahun_ajaran (id, tahun, status) VALUES
    (1, '2024/2025', 'nonaktif'),
    (2, '2025/2026', 'aktif');

-- ════════════════════════════════════════════════════════════════════
-- Kelas
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS kelas (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    nama_kelas      VARCHAR(50) NOT NULL,
    id_tahun_ajaran INT,
    FOREIGN KEY (id_tahun_ajaran) REFERENCES tahun_ajaran(id)
);

INSERT IGNORE INTO kelas (id, nama_kelas, id_tahun_ajaran) VALUES
    (1, 'Kelompok A', 2),
    (2, 'Kelompok B', 2),
    (3, 'Kelompok A', 1),
    (4, 'Kelompok B', 1);

-- ════════════════════════════════════════════════════════════════════
-- Anak (formerly Anak)
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS anak (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    nama_anak     VARCHAR(100) NOT NULL,
    nisn          VARCHAR(20) UNIQUE,
    nik           VARCHAR(20) DEFAULT NULL,
    jenis_kelamin ENUM('L', 'P'),
    tempat_lahir  VARCHAR(100) DEFAULT NULL,
    tanggal_lahir DATE,
    agama         VARCHAR(30)  DEFAULT NULL,
    status_anak   VARCHAR(20)  DEFAULT NULL,
    anak_ke       TINYINT UNSIGNED DEFAULT NULL,
    berat_badan   DECIMAL(5,2) DEFAULT NULL,
    tinggi_badan  DECIMAL(5,2) DEFAULT NULL,
    alamat        TEXT,
    id_kelas      INT,
    id_ortu       INT, -- FK to orang_tua
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_kelas) REFERENCES kelas(id),
    FOREIGN KEY (id_ortu) REFERENCES orang_tua(id)
);

-- ════════════════════════════════════════════════════════════════════
-- Aspek Penilaian
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS aspek_penilaian (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    nama_aspek VARCHAR(100) NOT NULL,
    deskripsi  TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO aspek_penilaian (id, nama_aspek) VALUES
    (1, 'Agama & Moral'),
    (2, 'Fisik Motorik'),
    (3, 'Kognitif'),
    (4, 'Bahasa'),
    (5, 'Sosial Emosional'),
    (6, 'Seni');

-- ════════════════════════════════════════════════════════════════════
-- Activity Log
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS activity_log (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    judul      VARCHAR(255) NOT NULL,
    deskripsi  TEXT,
    jenis      VARCHAR(50) DEFAULT 'info',
    aksi       VARCHAR(50) DEFAULT 'info',
    created_by INT,
    role       VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ════════════════════════════════════════════════════════════════════
-- Profil Sekolah
-- ════════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS sekolah (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    nama_sekolah       VARCHAR(150) NOT NULL,
    npsn               VARCHAR(20) UNIQUE,
    jenjang            VARCHAR(50),
    `status`           VARCHAR(50),
    alamat             TEXT,
    kelurahan          VARCHAR(100),
    kecamatan          VARCHAR(100),
    kabupaten          VARCHAR(100),
    kota_kabupaten     VARCHAR(100),
    provinsi           VARCHAR(100),
    kode_pos           VARCHAR(10),
    no_telp            VARCHAR(20),
    telepon            VARCHAR(20),
    email              VARCHAR(100),
    website            VARCHAR(100),
    kepala_sekolah     VARCHAR(100),
    operator_nama      VARCHAR(100),
    nip_kepala_sekolah VARCHAR(20),
    visi               TEXT,
    misi               TEXT,
    logo_url           VARCHAR(255),
    tahun_berdiri      YEAR,
    akreditasi         VARCHAR(10),
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT IGNORE INTO sekolah (
    nama_sekolah, npsn, alamat, kelurahan, kecamatan, kota_kabupaten,
    provinsi, kode_pos, telepon, email, website, kepala_sekolah,
    nip_kepala_sekolah, visi, misi, tahun_berdiri, akreditasi
) VALUES (
    'TK Negeri 2 Bengkalis',
    '6901094',
    'Jl. Pendidikan No. 1',
    'Sungai Alam',
    'Bengkalis',
    'Bengkalis',
    'Riau',
    '28711',
    '(0766) 123456',
    'tknegeri2@bengkalis.sch.id',
    'www.tknegeri2bengkalis.sch.id',
    'H. Ahmad, M.Pd',
    '123456789',
    'Mewujudkan generasi penerus yang cerdas, berkarakter, dan beriman',
    'Memberikan pendidikan berkualitas yang mengembangkan potensi anak secara holistik',
    2010,
    'A'
);